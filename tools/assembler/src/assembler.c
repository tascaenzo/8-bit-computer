#include "assembler.h"

#include "isa.h"
#include "parser.h"

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define CPU8_MAX_SYMBOLS 256
#define CPU8_MAX_SYMBOL_NAME 64
#define CPU8_MAX_OPERANDS 3

/*
 * Simbolo risolto dall'assembler.
 *
 * Un simbolo puo essere:
 * - una label, per esempio "loop:";
 * - una costante definita con .equ.
 *
 * In entrambi i casi il nome viene associato a un valore numerico a 16 bit.
 */
typedef struct {
    char name[CPU8_MAX_SYMBOL_NAME];
    uint16_t value;
} Cpu8Symbol;

/*
 * Stato condiviso durante una passata di assemblaggio.
 *
 * L'assembler lavora in due passate:
 * - pass 1: calcola indirizzi e simboli, senza scrivere byte definitivi;
 * - pass 2: usa i simboli risolti per generare i byte macchina.
 */
typedef struct {
    Cpu8Symbol symbols[CPU8_MAX_SYMBOLS];
    size_t symbol_count;
    size_t address;
    size_t max_written;
    size_t line_number;
    int pass;
    Cpu8Program *program;
} Cpu8AssemblyContext;

/*
 * Rappresentazione semplificata di una riga assembly gia tokenizzata.
 *
 * Esempi:
 *   "LDI R0, 0x0A" -> mnemonic = LDI, operands = R0 / 0x0A
 *   "MOV RA, R0"  -> mnemonic = MOV, operands = RA / R0
 */
typedef struct {
    char mnemonic[CPU8_MAX_SYMBOL_NAME];
    char operands[CPU8_MAX_OPERANDS][CPU8_MAX_SYMBOL_NAME];
    size_t operand_count;
} Cpu8Statement;

static Cpu8Status fail_at_line(const Cpu8AssemblyContext *context, Cpu8Status status, const char *message)
{
    cpu8_set_error_detail(context->line_number, message);
    return status;
}

/* Rimuove spazi iniziali e finali modificando la stringa originale. */
static char *trim(char *text)
{
    char *end;

    while (isspace((unsigned char)*text)) {
        text += 1;
    }

    if (*text == '\0') {
        return text;
    }

    end = text + strlen(text) - 1;
    while (end > text && isspace((unsigned char)*end)) {
        *end = '\0';
        end -= 1;
    }

    return text;
}

/* Normalizza una stringa in maiuscolo: la sintassi assembly e case-insensitive. */
static void uppercase(char *text)
{
    while (*text != '\0') {
        *text = (char)toupper((unsigned char)*text);
        text += 1;
    }
}

/* Elimina la parte di riga dopo ';', che nella nostra sintassi indica commento. */
static void strip_comment(char *text)
{
    char *comment = strchr(text, ';');

    if (comment != NULL) {
        *comment = '\0';
    }
}

/*
 * Copia un nome simbolico in un buffer a dimensione fissa e lo normalizza.
 *
 * Questo evita che "loop", "Loop" e "LOOP" diventino tre simboli diversi.
 */
static int copy_symbol_name(char *destination, size_t destination_size, const char *source)
{
    size_t length = strlen(source);

    if (length == 0 || length >= destination_size) {
        return 0;
    }

    memcpy(destination, source, length + 1);
    uppercase(destination);
    return 1;
}

/* Controlla la forma di una label: deve essere leggibile e non ambigua. */
static int is_valid_label_name(const char *name)
{
    size_t i;

    if (!(isalpha((unsigned char)name[0]) || name[0] == '_')) {
        return 0;
    }

    for (i = 1; name[i] != '\0'; i++) {
        if (!(isalnum((unsigned char)name[i]) || name[i] == '_')) {
            return 0;
        }
    }

    return 1;
}

/* Cerca una label o costante nella tabella dei simboli gia risolti. */
static const Cpu8Symbol *find_symbol(const Cpu8AssemblyContext *context, const char *name)
{
    char normalized[CPU8_MAX_SYMBOL_NAME];
    size_t i;

    if (!copy_symbol_name(normalized, sizeof(normalized), name)) {
        return NULL;
    }

    for (i = 0; i < context->symbol_count; i++) {
        if (strcmp(context->symbols[i].name, normalized) == 0) {
            return &context->symbols[i];
        }
    }

    return NULL;
}

/* Aggiunge un simbolo durante la prima passata. */
static Cpu8Status add_symbol(Cpu8AssemblyContext *context, const char *name, uint16_t value)
{
    char normalized[CPU8_MAX_SYMBOL_NAME];

    if (!copy_symbol_name(normalized, sizeof(normalized), name) || !is_valid_label_name(normalized)) {
        return fail_at_line(context, CPU8_ERROR_PARSE, "invalid label or symbol name");
    }

    if (find_symbol(context, normalized) != NULL) {
        return fail_at_line(context, CPU8_ERROR_PARSE, "duplicate label or symbol");
    }

    if (context->symbol_count >= CPU8_MAX_SYMBOLS) {
        return fail_at_line(context, CPU8_ERROR_ASSEMBLE, "too many symbols");
    }

    strcpy(context->symbols[context->symbol_count].name, normalized);
    context->symbols[context->symbol_count].value = value;
    context->symbol_count += 1;
    return CPU8_OK;
}

/*
 * Converte un numero scritto nel sorgente assembly.
 *
 * Formati supportati:
 * - 42       decimale
 * - 0x2A     esadecimale
 * - $2A      esadecimale stile assembly
 * - 0b101010 binario
 */
static int parse_number(const char *text, uint16_t *value)
{
    char *end = NULL;
    unsigned long parsed;
    int base = 10;

    if (text[0] == '$') {
        text += 1;
        base = 16;
    } else if (text[0] == '0' && (text[1] == 'x' || text[1] == 'X')) {
        base = 16;
    } else if (text[0] == '0' && (text[1] == 'b' || text[1] == 'B')) {
        text += 2;
        base = 2;
    }

    parsed = strtoul(text, &end, base);
    if (end == text || *end != '\0' || parsed > 0xFFFFUL) {
        return 0;
    }

    *value = (uint16_t)parsed;
    return 1;
}

/*
 * Risolve un operando numerico.
 *
 * Prima prova a leggerlo come numero; se non e un numero, lo cerca nella
 * tabella dei simboli. Questo permette istruzioni come "JMP loop".
 */
static Cpu8Status resolve_value(const Cpu8AssemblyContext *context, const char *text, uint16_t *value)
{
    const Cpu8Symbol *symbol;

    if (parse_number(text, value)) {
        return CPU8_OK;
    }

    symbol = find_symbol(context, text);
    if (symbol == NULL) {
        cpu8_set_error_detail(context->line_number, "unknown number, label or constant");
        return CPU8_ERROR_PARSE;
    }

    *value = symbol->value;
    return CPU8_OK;
}

/* Converte R0..R7 nel codice binario a 3 bit usato negli opcode. */
static int parse_register(const char *text, uint8_t *register_code)
{
    if ((text[0] == 'R' || text[0] == 'r') && text[1] >= '0' && text[1] <= '7' && text[2] == '\0') {
        *register_code = (uint8_t)(text[1] - '0');
        return 1;
    }

    return 0;
}

/*
 * Scrive un byte nella posizione corrente.
 *
 * In passata 1 avanza solo l'indirizzo: serve a calcolare dove finiranno label
 * e dati. In passata 2 scrive davvero dentro program->bytes.
 */
static Cpu8Status write_byte(Cpu8AssemblyContext *context, uint8_t value)
{
    if (context->address >= CPU8_MAX_PROGRAM_BYTES) {
        return fail_at_line(context, CPU8_ERROR_ASSEMBLE, "program address outside 16-bit memory");
    }

    if (context->pass == 2) {
        context->program->bytes[context->address] = value;
    }

    context->address += 1;
    if (context->address > context->max_written) {
        context->max_written = context->address;
    }

    return CPU8_OK;
}

/* Scrive un valore a 16 bit in little-endian: prima byte basso, poi byte alto. */
static Cpu8Status write_u16(Cpu8AssemblyContext *context, uint16_t value)
{
    Cpu8Status status;

    status = write_byte(context, (uint8_t)(value & 0x00FF));
    if (status != CPU8_OK) {
        return status;
    }

    return write_byte(context, (uint8_t)((value >> 8) & 0x00FF));
}

/*
 * Divide una riga pulita in mnemonic e operandi.
 *
 * Separiamo su spazio, tab e virgola per accettare forme come:
 *   LDI R0, 0x0A
 *   LDI R0 0x0A
 */
static Cpu8Status parse_statement(char *text, Cpu8Statement *statement)
{
    char *token;

    memset(statement, 0, sizeof(*statement));

    token = strtok(text, " \t,");
    if (token == NULL) {
        return CPU8_OK;
    }

    if (!copy_symbol_name(statement->mnemonic, sizeof(statement->mnemonic), token)) {
        return CPU8_ERROR_PARSE;
    }

    while ((token = strtok(NULL, " \t,")) != NULL) {
        if (statement->operand_count >= CPU8_MAX_OPERANDS) {
            return CPU8_ERROR_PARSE;
        }

        if (!copy_symbol_name(
                statement->operands[statement->operand_count],
                sizeof(statement->operands[statement->operand_count]),
                token)) {
            return CPU8_ERROR_PARSE;
        }

        statement->operand_count += 1;
    }

    return CPU8_OK;
}

/*
 * Gestisce le direttive dell'assembler.
 *
 * Le direttive non sono istruzioni della CPU:
 * - .code/.data cambiano l'indirizzo corrente;
 * - .byte scrive un byte nella memoria generata;
 * - .equ crea una costante simbolica.
 */
static Cpu8Status encode_directive(Cpu8AssemblyContext *context, const Cpu8Statement *statement)
{
    uint16_t value;
    Cpu8Status status;

    if (strcmp(statement->mnemonic, ".CODE") == 0 || strcmp(statement->mnemonic, ".DATA") == 0) {
        if (statement->operand_count != 1) {
            return fail_at_line(context, CPU8_ERROR_PARSE, ".byte value must fit in 8 bit");
        }

        status = resolve_value(context, statement->operands[0], &value);
        if (status != CPU8_OK) {
            return status;
        }

        context->address = value;
        if (context->address > context->max_written) {
            context->max_written = context->address;
        }
        return CPU8_OK;
    }

    if (strcmp(statement->mnemonic, ".BYTE") == 0) {
        if (statement->operand_count != 1) {
            return fail_at_line(context, CPU8_ERROR_PARSE, ".equ requires name and value");
        }

        if (context->pass == 1) {
            return write_byte(context, 0);
        }

        status = resolve_value(context, statement->operands[0], &value);
        if (status != CPU8_OK || value > 0xFF) {
            return CPU8_ERROR_PARSE;
        }

        return write_byte(context, (uint8_t)value);
    }

    if (strcmp(statement->mnemonic, ".EQU") == 0) {
        if (statement->operand_count != 2) {
            return CPU8_ERROR_PARSE;
        }

        if (context->pass == 1) {
            status = resolve_value(context, statement->operands[1], &value);
            if (status != CPU8_OK) {
                return status;
            }

            return add_symbol(context, statement->operands[0], value);
        }

        return CPU8_OK;
    }

    return fail_at_line(context, CPU8_ERROR_PARSE, "unknown assembler directive");
}

/*
 * Codifica la famiglia MOV dedicata ai registri ALU.
 *
 * Sono ammesse solo queste forme:
 * - MOV RA, Rn  -> Rn entra nel registro operando RA
 * - MOV RB, Rn  -> Rn entra nel registro operando RB
 * - MOV Rn, RA  -> il risultato in RA torna in un registro generale
 *
 * Non accettiamo MOV Rn, Rm perche l'hardware dei registri generali seleziona
 * un solo registro alla volta.
 */
static Cpu8Status encode_mov(Cpu8AssemblyContext *context, const Cpu8Statement *statement)
{
    uint8_t register_code;

    if (statement->operand_count != 2) {
        return fail_at_line(context, CPU8_ERROR_PARSE, "MOV requires two operands");
    }

    if (strcmp(statement->operands[0], "RA") == 0 && parse_register(statement->operands[1], &register_code)) {
        return write_byte(context, (uint8_t)(0xC0 | register_code));
    }

    if (strcmp(statement->operands[0], "RB") == 0 && parse_register(statement->operands[1], &register_code)) {
        return write_byte(context, (uint8_t)(0xC8 | register_code));
    }

    if (parse_register(statement->operands[0], &register_code) && strcmp(statement->operands[1], "RA") == 0) {
        return write_byte(context, (uint8_t)(0xD0 | register_code));
    }

    return fail_at_line(context, CPU8_ERROR_PARSE, "invalid MOV form; use MOV RA, Rn, MOV RB, Rn or MOV Rn, RA");
}

/*
 * Codifica una istruzione CPU reale.
 *
 * Le istruzioni normali sono cercate nella tabella ISA. MOV e gestita a parte
 * perche ha piu forme assembly, ma resta comunque una codifica hardware ben
 * definita.
 */
static Cpu8Status encode_instruction(Cpu8AssemblyContext *context, const Cpu8Statement *statement)
{
    const Cpu8InstructionDef *instruction;
    uint8_t register_code = 0;
    uint16_t value = 0;
    Cpu8Status status;

    if (strcmp(statement->mnemonic, "MOV") == 0) {
        return encode_mov(context, statement);
    }

    instruction = cpu8_find_instruction(statement->mnemonic);
    if (instruction == NULL) {
        return fail_at_line(context, CPU8_ERROR_PARSE, "unknown instruction");
    }

    if (instruction->uses_register) {
        if (statement->operand_count < 1 || !parse_register(statement->operands[0], &register_code)) {
            return fail_at_line(context, CPU8_ERROR_PARSE, "expected register R0..R7");
        }
    }

    switch (instruction->format) {
        case CPU8_FORMAT_IMP:
            /*
             * Formato implicito: solo opcode.
             * Esempi: HLT, ADD, CMP, OUT R0.
             */
            if (statement->operand_count != (instruction->uses_register ? 1U : 0U)) {
                return fail_at_line(context, CPU8_ERROR_PARSE, "wrong number of operands");
            }
            if (context->pass == 1) {
                return write_byte(context, 0);
            }
            return write_byte(context, cpu8_encode_opcode(instruction, register_code));

        case CPU8_FORMAT_IMM8:
            /*
             * Formato immediato: opcode + un byte.
             * Esempio: LDI R0, 0x0A.
             */
            if (statement->operand_count != 2) {
                return fail_at_line(context, CPU8_ERROR_PARSE, "wrong number of operands");
            }
            if (context->pass == 1) {
                status = write_byte(context, 0);
                if (status != CPU8_OK) {
                    return status;
                }
                return write_byte(context, 0);
            }
            status = resolve_value(context, statement->operands[1], &value);
            if (status != CPU8_OK || value > 0xFF) {
                return fail_at_line(context, CPU8_ERROR_PARSE, "immediate value must fit in 8 bit");
            }
            status = write_byte(context, cpu8_encode_opcode(instruction, register_code));
            if (status != CPU8_OK) {
                return status;
            }
            return write_byte(context, (uint8_t)value);

        case CPU8_FORMAT_ADDR16:
            /*
             * Formato indirizzo: opcode + addr_low + addr_high.
             * Esempi: JMP loop, LDA R0, counter, STA R0, counter.
             */
            if (statement->operand_count != (instruction->uses_register ? 2U : 1U)) {
                return fail_at_line(context, CPU8_ERROR_PARSE, "wrong number of operands");
            }
            if (context->pass == 1) {
                status = write_byte(context, 0);
                if (status != CPU8_OK) {
                    return status;
                }
                return write_u16(context, 0);
            }
            status = resolve_value(context, statement->operands[instruction->uses_register ? 1 : 0], &value);
            if (status != CPU8_OK) {
                return status;
            }
            status = write_byte(context, cpu8_encode_opcode(instruction, register_code));
            if (status != CPU8_OK) {
                return status;
            }
            return write_u16(context, value);

        default:
            return fail_at_line(context, CPU8_ERROR_ASSEMBLE, "unsupported instruction format");
    }
}

/*
 * Elabora una singola riga sorgente.
 *
 * Ordine dei passaggi:
 * 1. rimuove commenti;
 * 2. gestisce eventuale label;
 * 3. riconosce direttiva o istruzione;
 * 4. aggiorna indirizzo o genera byte.
 */
static Cpu8Status process_line(Cpu8AssemblyContext *context, char *text)
{
    Cpu8Statement statement;
    Cpu8Status status;
    char *label_end;
    char *line;

    strip_comment(text);
    line = trim(text);
    if (*line == '\0') {
        return CPU8_OK;
    }

    label_end = strchr(line, ':');
    if (label_end != NULL) {
        *label_end = '\0';
        if (context->pass == 1) {
            if (context->address > 0xFFFFU) {
                return fail_at_line(context, CPU8_ERROR_ASSEMBLE, "label address outside 16-bit memory");
            }
            status = add_symbol(context, trim(line), (uint16_t)context->address);
            if (status != CPU8_OK) {
                return status;
            }
        }
        line = trim(label_end + 1);
        if (*line == '\0') {
            return CPU8_OK;
        }
    }

    status = parse_statement(line, &statement);
    if (status != CPU8_OK || statement.mnemonic[0] == '\0') {
        return status;
    }

    if (statement.mnemonic[0] == '.') {
        return encode_directive(context, &statement);
    }

    return encode_instruction(context, &statement);
}

/*
 * Esegue una passata completa sul file.
 *
 * Riapriamo il file per ogni passata: e semplice, prevedibile e sufficiente
 * per un assembler didattico.
 */
static Cpu8Status run_pass(const Cpu8AssemblerOptions *options, Cpu8AssemblyContext *context)
{
    FILE *file;
    Cpu8SourceLine line = {0};
    int has_line = 0;
    Cpu8Status status;

    file = fopen(options->input_path, "r");
    if (file == NULL) {
        return CPU8_ERROR_IO;
    }

    do {
        status = cpu8_read_source_line(file, &line, &has_line);
        if (status != CPU8_OK) {
            fclose(file);
            return status;
        }

        if (has_line) {
            context->line_number = line.line_number;
            status = process_line(context, line.text);
            if (status != CPU8_OK) {
                if (cpu8_error_detail()[0] == '\0') {
                    cpu8_set_error_detail(line.line_number, cpu8_status_message(status));
                }
                fclose(file);
                return status;
            }
        }
    } while (has_line);

    fclose(file);
    return CPU8_OK;
}

/*
 * API pubblica usata dal main.
 *
 * Qui si vede il flusso completo dell'assembler:
 * - azzera il programma;
 * - passata 1: costruisce la tabella dei simboli;
 * - passata 2: genera i byte usando i simboli risolti;
 * - espone la lunghezza finale del programma.
 */
Cpu8Status cpu8_assemble_file(const Cpu8AssemblerOptions *options, Cpu8Program *program)
{
    Cpu8AssemblyContext context;
    Cpu8Status status;

    if (options == NULL || program == NULL || options->input_path == NULL) {
        return CPU8_ERROR_INVALID_ARGUMENT;
    }

    memset(program, 0, sizeof(*program));
    cpu8_clear_error_detail();
    memset(&context, 0, sizeof(context));
    context.program = program;

    context.pass = 1;
    status = run_pass(options, &context);
    if (status != CPU8_OK) {
        return status;
    }

    context.pass = 2;
    context.address = 0;
    context.max_written = 0;
    status = run_pass(options, &context);
    if (status != CPU8_OK) {
        return status;
    }

    program->length = context.max_written;
    return CPU8_OK;
}
