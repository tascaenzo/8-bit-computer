#ifndef CPU8_MICROCODE_H
#define CPU8_MICROCODE_H

/*
 * API e tipi condivisi del generatore di microcodice.
 * Dichiara segnali, microoperazioni, immagini EEPROM e funzioni chiamate da
 * main, test e moduli di configurazione; non contiene la loro implementazione.
 */

/*
 * Interfaccia pubblica del generatore di microcodice.
 *
 * Qui sono definiti il formato logico di una microistruzione, i codici dei
 * microprogrammi e le funzioni usate per costruire le immagini EEPROM.
 * La disposizione fisica e la polarita dei segnali sono invece configurate in
 * config/control_signals.c.
 */

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#include "../config/architecture.h"

/* Dimensioni imposte dalla AT28C64: 2^13 indirizzi, un byte per indirizzo. */
enum
{
    CPU8_CONTROL_ROM_SIZE = 8192,
    CPU8_DISPATCH_ROM_SIZE = 8192,
    CPU8_MICROSTEP_COUNT = 8,
    CPU8_UOP_COUNT = 32
};

/*
 * Parola di controllo LOGICA. Ogni bit posto a 1 significa "segnale attivo".
 * encode_control_word() la converte nei tre byte fisici, applicando anche
 * l'eventuale logica negata configurata per ciascuna uscita.
 */
typedef uint32_t ControlWord;

/* Maschere usate con l'operatore | per comporre una ControlWord. */
typedef enum
{
    /* Campo a 2 bit che seleziona chi pilota il bus indirizzi. */
    CTRL_ADDR_SEL_0 = 1u << 0,
    CTRL_ADDR_SEL_1 = 1u << 1,
    /* Program Counter, MAR e memoria. */
    CTRL_PC_INC = 1u << 2,
    CTRL_PC_LOAD = 1u << 3,
    CTRL_MAR_L_WE = 1u << 4,
    CTRL_MAR_H_WE = 1u << 5,
    CTRL_RAM_OE = 1u << 6,
    CTRL_RAM_WE = 1u << 7,
    /* Registri collegati al bus dati. */
    CTRL_IR_WE = 1u << 8,
    CTRL_MDR_WE = 1u << 9,
    CTRL_MDR_OE = 1u << 10,
    CTRL_RF_EN = 1u << 11,
    CTRL_RF_RW = 1u << 12,
    CTRL_RA_EN = 1u << 13,
    CTRL_RA_RB_RW = 1u << 14,
    CTRL_RB_EN = 1u << 15,
    /* ALU, sequencer e nuovo Index Register. */
    CTRL_ALU_EN = 1u << 16,
    CTRL_FLAGS_WE = 1u << 17,
    CTRL_NEXT_FETCH = 1u << 18,
    CTRL_EPROM_OE = 1u << 19,
    CTRL_IDX_L_WE = 1u << 20,
    CTRL_IDX_H_WE = 1u << 21
} ControlSignal;

enum
{
    CPU8_CONTROL_SIGNAL_COUNT = 22
};

typedef enum
{
    ACTIVE_HIGH = 0,
    ACTIVE_LOW = 1
} ControlPolarity;

/* Associazione tra un segnale logico e un pin fisico delle tre EEPROM. */
typedef struct
{
    ControlSignal signal;
    const char *name;
    uint8_t rom;
    uint8_t bit;
    /* Pin DIP AT28C64 corrispondente a D0..D7 (9,10,11,13..17). */
    uint8_t eeprom_pin;
    ControlPolarity polarity;
} ControlSignalConfig;

/*
 * Identificatore a 5 bit del microprogramma. Piu opcode possono condividere lo
 * stesso uOP: per esempio 0x20..0x27 usano tutti UOP_LDI, mentre IR[2:0]
 * seleziona direttamente il registro generale.
 */
typedef enum
{
    UOP_INVALID = 0,
    UOP_NOP,
    UOP_HLT,
    UOP_LDI,
    UOP_LDA,
    UOP_STA,
    UOP_ALU,
    UOP_CMP,
    UOP_MOV_RA_RN,
    UOP_MOV_RB_RN,
    UOP_MOV_RN_RA,
    UOP_LDX,
    UOP_LDA_IDX,
    UOP_STA_IDX,
    UOP_JMP,
    UOP_JZ,
    UOP_JNZ,
    UOP_JC,
    UOP_JNC,
    UOP_JN,
    UOP_JNN,
    UOP_JO,
    UOP_JNO
} MicroOp;

/* Valori memorizzati nel registro dei flag e collegati ad A8..A11. */
typedef struct
{
    bool carry;
    bool zero;
    bool negative;
    bool overflow;
} CpuFlags;

/* Il modo CPU seleziona con A12 una delle due meta della Control ROM. */
typedef enum
{
    CPU_MODE_BOOT = 0,
    CPU_MODE_RUN = 1
} CpuMode;

/* Compone A0..A12 a partire dagli ingressi logici della Control ROM. */
uint16_t microcode_address(uint8_t step, MicroOp uop, CpuFlags flags,
                           CpuMode mode);
/* Restituisce i segnali logici attivi per un singolo microstep. */
ControlWord microcode_word(uint8_t step, MicroOp uop, CpuFlags flags,
                           CpuMode mode);
/* Converte l'opcode a 8 bit nel codice uOP scritto nella ROM di dispatch. */
MicroOp dispatch_opcode(uint8_t opcode);
/* Nome leggibile del microprogramma, utile per diagnostica e debug. */
const char *microop_name(MicroOp uop);

/* Verifica che configurazione fisica, selettori e polarita siano validi. */
bool validate_signal_config(char *message, size_t message_size);
/* Cerca ROM, bit e polarita configurati per un segnale. */
bool get_control_signal_config(ControlSignal signal, uint8_t *rom, uint8_t *bit,
                               bool *active_low);
/* Rifiuta combinazioni elettricamente o logicamente pericolose. */
bool validate_control_word(ControlWord word, char *message, size_t message_size);
/* Trasforma una parola logica nei tre byte realmente presenti sulle uscite. */
void encode_control_word(ControlWord word, uint8_t bytes[3]);
/* Riempie tutti gli 8192 indirizzi delle tre Control ROM. */
bool build_control_roms(uint8_t roms[3][CPU8_CONTROL_ROM_SIZE],
                        char *message, size_t message_size);
/* Riempie la EEPROM che converte IR[7:0] in uOP[4:0]. */
void build_dispatch_rom(uint8_t rom[CPU8_DISPATCH_ROM_SIZE]);

#endif
