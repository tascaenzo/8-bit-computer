#include "isa.h"

#include <stddef.h>
#include <string.h>

/*
 * Tabella delle istruzioni riconosciute dall'assembler.
 *
 * Nota didattica:
 * questa tabella e il ponte tra il testo assembly ("LDI", "OUT", ...)
 * e il byte opcode che finira in ROM. Al momento e ancora provvisoria e andra
 * riallineata alla ISA documentata in docs/isa.md prima dell'implementazione
 * completa del parser.
 */
static const Cpu8InstructionDef instruction_set[] = {
    {"NOP", 0x00, 0xFF, CPU8_FORMAT_IMP, false},
    {"LDI", 0x10, 0xF8, CPU8_FORMAT_IMM8, true},
    {"LDA", 0x20, 0xF8, CPU8_FORMAT_ADDR16, true},
    {"STA", 0x28, 0xF8, CPU8_FORMAT_ADDR16, true},
    {"ADD", 0x30, 0xF8, CPU8_FORMAT_ADDR16, true},
    {"SUB", 0x38, 0xF8, CPU8_FORMAT_ADDR16, true},
    {"CMP", 0x48, 0xF8, CPU8_FORMAT_ADDR16, true},
    {"JMP", 0x40, 0xFF, CPU8_FORMAT_ADDR16, false},
    {"JZ", 0x41, 0xFF, CPU8_FORMAT_ADDR16, false},
    {"JC", 0x42, 0xFF, CPU8_FORMAT_ADDR16, false},
    {"OUT", 0x50, 0xF8, CPU8_FORMAT_IMP, true},
    {"HLT", 0xFF, 0xFF, CPU8_FORMAT_IMP, false}
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
     */
    return (uint8_t)(instruction->opcode_base | (register_code & 0x07));
}
