#ifndef CPU8_ISA_H
#define CPU8_ISA_H

#include <stdbool.h>
#include <stdint.h>

/*
 * Formati supportati da una istruzione macchina.
 *
 * IMP    = solo opcode, nessun byte aggiuntivo.
 * IMM8   = opcode + valore immediato a 8 bit.
 * ADDR16 = opcode + indirizzo a 16 bit little-endian.
 */
typedef enum {
    CPU8_FORMAT_IMP,
    CPU8_FORMAT_IMM8,
    CPU8_FORMAT_ADDR16
} Cpu8InstructionFormat;

/*
 * Descrizione di una istruzione della ISA.
 *
 * mnemonic     e il nome scritto nel file assembly.
 * opcode_base  e il valore di partenza dell'opcode.
 * opcode_mask  descrive quali bit sono fissi nell'opcode.
 * format       dice quanti byte occupa l'istruzione.
 * uses_register indica se i bit bassi dell'opcode contengono R0..R7.
 */
typedef struct {
    const char *mnemonic;
    uint8_t opcode_base;
    uint8_t opcode_mask;
    Cpu8InstructionFormat format;
    bool uses_register;
} Cpu8InstructionDef;

/* Cerca una istruzione nella tabella ISA usando il mnemonic. */
const Cpu8InstructionDef *cpu8_find_instruction(const char *mnemonic);

/*
 * Combina opcode_base e codice registro.
 *
 * Per istruzioni come LDI R3, imm8 i bit bassi dell'opcode selezionano R3.
 */
uint8_t cpu8_encode_opcode(const Cpu8InstructionDef *instruction, uint8_t register_code);

#endif
