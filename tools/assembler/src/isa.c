#include "isa.h"

#include <stddef.h>
#include <string.h>

/*
 * Tabella delle istruzioni riconosciute dall'assembler.
 *
 * Nota didattica:
 * questa tabella e il ponte tra il testo assembly ("LDI", "OUT", ...)
 * e il byte opcode che finira in ROM.
 *
 * La struttura binaria dell'opcode e quella definita in docs/isa.md:
 *
 *   bit:    7 6 5 4 3 2 1 0
 *           c c c x x x x x
 *
 *   ccc     = macrocategoria dell'istruzione
 *   xxxxx   = dettagli specifici della categoria
 *
 * Quando una istruzione usa un registro generale, gli ultimi 3 bit sono:
 *
 *   opcode = cccssrrr
 *
 *   rrr = codice registro R0..R7
 *
 * Per esempio:
 *
 *   LDI R0, imm8 -> 0b00100000 -> 0x20
 *   LDI R7, imm8 -> 0b00100111 -> 0x27
 *
 * Il campo opcode_base contiene la parte fissa dell'opcode. Se uses_register
 * e true, cpu8_encode_opcode aggiunge i bit rrr del registro.
 */
static const Cpu8InstructionDef instruction_set[] = {
    /*
     * ccc = 000, range 0x00-0x1F
     * Sistema / controllo.
     *
     * Opcode completamente fissi:
     *   NOP = 0b00000000
     *   HLT = 0b00000001
     */
    {"NOP", 0x00, 0xFF, CPU8_FORMAT_IMP, false},
    {"HLT", 0x01, 0xFF, CPU8_FORMAT_IMP, false},

    /*
     * ccc = 001, range 0x20-0x3F
     * Load immediate.
     *
     * Formato opcode:
     *   0b00100rrr
     *
     * Esempi:
     *   LDI R0, imm8 = 0b00100000 = 0x20
     *   LDI R7, imm8 = 0b00100111 = 0x27
     */
    {"LDI", 0x20, 0xF8, CPU8_FORMAT_IMM8, true},

    /*
     * ccc = 010, range 0x40-0x5F
     * Accesso memoria assoluto a 16 bit.
     *
     * Formati opcode:
     *   LDA = 0b01000rrr, range 0x40-0x47
     *   STA = 0b01001rrr, range 0x48-0x4F
     *
     * L'indirizzo addr16 viene scritto dopo l'opcode in little-endian:
     *   addr_low, addr_high
     */
    {"LDA", 0x40, 0xF8, CPU8_FORMAT_ADDR16, true},
    {"STA", 0x48, 0xF8, CPU8_FORMAT_ADDR16, true},

    /*
     * ccc = 011, range 0x60-0x7F
     * Operazioni ALU.
     *
     * Formato opcode:
     *   0b0110aaaa
     *
     * I bit aaaa sono il codice operazione cablato della ALU:
     *   AND  = 0000 -> 0x60
     *   OR   = 0001 -> 0x61
     *   ...
     *   CMP  = 1001 -> 0x69
     *
     * Queste istruzioni non selezionano R0..R7: lavorano su RA/RB.
     */
    {"AND", 0x60, 0xFF, CPU8_FORMAT_IMP, false},
    {"OR", 0x61, 0xFF, CPU8_FORMAT_IMP, false},
    {"XOR", 0x62, 0xFF, CPU8_FORMAT_IMP, false},
    {"NOR", 0x63, 0xFF, CPU8_FORMAT_IMP, false},
    {"NAND", 0x64, 0xFF, CPU8_FORMAT_IMP, false},
    {"XNOR", 0x65, 0xFF, CPU8_FORMAT_IMP, false},
    {"NOT", 0x66, 0xFF, CPU8_FORMAT_IMP, false},
    {"ADD", 0x67, 0xFF, CPU8_FORMAT_IMP, false},
    {"SUB", 0x68, 0xFF, CPU8_FORMAT_IMP, false},
    {"CMP", 0x69, 0xFF, CPU8_FORMAT_IMP, false},

    /*
     * ccc = 100, range 0x80-0x9F
     * Input / output.
     *
     * Formati opcode:
     *   IN  = 0b10000rrr, range 0x80-0x87
     *   OUT = 0b10001rrr, range 0x88-0x8F
     */
    {"IN", 0x80, 0xF8, CPU8_FORMAT_IMP, true},
    {"OUT", 0x88, 0xF8, CPU8_FORMAT_IMP, true},

    /*
     * ccc = 101, range 0xA0-0xBF
     * Salti assoluti e condizionati.
     *
     * Formato:
     *   opcode addr_low addr_high
     *
     * I bit bassi identificano la condizione:
     *   JMP = 0b10100000 = 0xA0
     *   JZ  = 0b10100001 = 0xA1
     *   JNZ = 0b10100010 = 0xA2
     *   ...
     */
    {"JMP", 0xA0, 0xFF, CPU8_FORMAT_ADDR16, false},
    {"JZ", 0xA1, 0xFF, CPU8_FORMAT_ADDR16, false},
    {"JNZ", 0xA2, 0xFF, CPU8_FORMAT_ADDR16, false},
    {"JC", 0xA3, 0xFF, CPU8_FORMAT_ADDR16, false},
    {"JNC", 0xA4, 0xFF, CPU8_FORMAT_ADDR16, false},
    {"JN", 0xA5, 0xFF, CPU8_FORMAT_ADDR16, false},
    {"JNN", 0xA6, 0xFF, CPU8_FORMAT_ADDR16, false},
    {"JO", 0xA7, 0xFF, CPU8_FORMAT_ADDR16, false},
    {"JNO", 0xA8, 0xFF, CPU8_FORMAT_ADDR16, false}
};

const Cpu8InstructionDef *cpu8_find_instruction(const char *mnemonic)
{
    size_t i;

    /*
     * Restituire NULL e il modo C piu semplice per dire "non trovato".
     * Il parser potra trasformare NULL in un errore tipo:
     * "mnemonic sconosciuto alla riga N".
     */
    if (mnemonic == NULL) {
        return NULL;
    }

    /*
     * Ricerca lineare.
     *
     * Per una ISA piccola e didattica va benissimo: poche decine di istruzioni
     * non richiedono strutture piu complesse come hash table.
     */
    for (i = 0; i < sizeof(instruction_set) / sizeof(instruction_set[0]); i++) {
        if (strcmp(instruction_set[i].mnemonic, mnemonic) == 0) {
            return &instruction_set[i];
        }
    }

    return NULL;
}

uint8_t cpu8_encode_opcode(const Cpu8InstructionDef *instruction, uint8_t register_code)
{
    if (instruction == NULL) {
        return 0;
    }

    /*
     * Alcune istruzioni hanno opcode completamente fisso, ad esempio NOP.
     * In quel caso il registro non partecipa alla codifica.
     */
    if (!instruction->uses_register) {
        return instruction->opcode_base;
    }

    /*
     * I registri generali R0..R7 occupano 3 bit.
     * La maschera 0x07 conserva solo i bit 0..2, cosi valori fuori range non
     * sporcano i bit alti dell'opcode.
     *
     * Esempio con LDI:
     *
     *   opcode_base = 0b00100000
     *   R3          = 0b00000011
     *   risultato   = 0b00100011
     *
     * In questo modo i bit alti restano la macrocategoria 001 e i bit bassi
     * selezionano direttamente il registro generale.
     */
    return (uint8_t)(instruction->opcode_base | (register_code & 0x07));
}
