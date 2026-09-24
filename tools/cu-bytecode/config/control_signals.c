/*
 * Configurazione modificabile della Control Unit: indirizzi comuni alle tre
 * EEPROM e assegnazione delle loro uscite ai segnali di controllo.
 * Il generatore usa direttamente queste tabelle per produrre i binari.
 */

#include "control_signals.h"

/*
 * Modificare questa tabella per scegliere EEPROM, uscita e polarita.
 *
 * Campi: segnale logico, nome, numero ROM (0..2), bit D (0..7), pin DIP,
 * polarita. Il pin e quello della AT28C64 in package DIP-28.
 * Ogni segnale e ogni coppia ROM/bit devono comparire una sola volta.
 *
 * Esempio:
 * {CTRL_RAM_OE, "RAM_OE", 0, 6, 16, ACTIVE_LOW}
 * significa che RAM_OE usa D6 della Control ROM 0 e vale elettricamente 0
 * quando la RAM deve presentare un byte sul data bus.
 */

/* Indirizzi comuni a Control ROM 0, 1 e 2. */
const ControlEepromAddressConfig CPU8_CONTROL_EEPROM_ADDRESS_CONFIGS[] = {
    {CTRL_EEPROM_ADDR_USTEP_0, CPU8_CONTROL_ROM_PIN_USTEP_2},   /* A2, bit meno significativo */
    {CTRL_EEPROM_ADDR_USTEP_1, CPU8_CONTROL_ROM_PIN_USTEP_1},   /* A1 */
    {CTRL_EEPROM_ADDR_USTEP_2, CPU8_CONTROL_ROM_PIN_USTEP_0},   /* A0, bit piu significativo */
    {CTRL_EEPROM_ADDR_IR_3, CPU8_CONTROL_ROM_PIN_IR_3},         /* A3 */
    {CTRL_EEPROM_ADDR_IR_4, CPU8_CONTROL_ROM_PIN_IR_4},         /* A4 */
    {CTRL_EEPROM_ADDR_IR_5, CPU8_CONTROL_ROM_PIN_IR_5},         /* A5 */
    {CTRL_EEPROM_ADDR_IR_6, CPU8_CONTROL_ROM_PIN_IR_6},         /* A6 */
    {CTRL_EEPROM_ADDR_IR_7, CPU8_CONTROL_ROM_PIN_IR_7},         /* A7 Bit piu significativo */
    {CTRL_EEPROM_ADDR_FLAG_C, CPU8_CONTROL_ROM_PIN_FLAG_C},     /* A8 */
    {CTRL_EEPROM_ADDR_FLAG_Z, CPU8_CONTROL_ROM_PIN_FLAG_Z},     /* A9 */
    {CTRL_EEPROM_ADDR_FLAG_N, CPU8_CONTROL_ROM_PIN_FLAG_N},     /* A10 */
    {CTRL_EEPROM_ADDR_FLAG_O, CPU8_CONTROL_ROM_PIN_FLAG_O},     /* A11 */
    {CTRL_EEPROM_ADDR_BOOT_RUN, CPU8_CONTROL_ROM_PIN_BOOT_RUN}, /* A12 */
};

const size_t CPU8_CONTROL_EEPROM_ADDRESS_CONFIG_COUNT =
    sizeof(CPU8_CONTROL_EEPROM_ADDRESS_CONFIGS) /
    sizeof(CPU8_CONTROL_EEPROM_ADDRESS_CONFIGS[0]);

const ControlSignalConfig CPU8_CONTROL_SIGNAL_CONFIGS[] = {
    /* ROM 0: tutti i segnali necessari al ciclo BOOT EPROM -> RAM. */
    {CTRL_ADDR_SEL_0, "ADDR_SEL_0", 0, 0, CPU8_CONTROL_ROM_PIN_D0, ACTIVE_HIGH}, /* ROM0 D0 */
    {CTRL_ADDR_SEL_1, "ADDR_SEL_1", 0, 1, CPU8_CONTROL_ROM_PIN_D1, ACTIVE_HIGH}, /* ROM0 D1 */
    {CTRL_PC_INC, "PC_INC", 0, 2, CPU8_CONTROL_ROM_PIN_D2, ACTIVE_HIGH},         /* ROM0 D2 */
    {CTRL_MDR_WE, "MDR_WE", 0, 3, CPU8_CONTROL_ROM_PIN_D3, ACTIVE_HIGH},         /* ROM0 D3 */
    {CTRL_MDR_OE, "MDR_OE", 0, 4, CPU8_CONTROL_ROM_PIN_D4, ACTIVE_LOW},          /* ROM0 D4 */
    {CTRL_RAM_WE, "RAM_WE", 0, 5, CPU8_CONTROL_ROM_PIN_D5, ACTIVE_LOW},          /* ROM0 D5 */
    {CTRL_EPROM_OE, "EPROM_OE", 0, 6, CPU8_CONTROL_ROM_PIN_D6, ACTIVE_LOW},      /* ROM0 D6 */
    {CTRL_NEXT_FETCH, "NEXT_FETCH", 0, 7, CPU8_CONTROL_ROM_PIN_D7, ACTIVE_LOW},  /* ROM0 D7 */

    {CTRL_IR_WE, "IR_WE", 1, 0, CPU8_CONTROL_ROM_PIN_D0, ACTIVE_HIGH},       /* ROM1 D0 */
    {CTRL_PC_LOAD, "PC_LOAD", 1, 1, CPU8_CONTROL_ROM_PIN_D1, ACTIVE_HIGH},   /* ROM1 D1 */
    {CTRL_MAR_L_WE, "MAR_L_WE", 1, 2, CPU8_CONTROL_ROM_PIN_D2, ACTIVE_HIGH}, /* ROM1 D2 */
    {CTRL_RF_EN, "RF_EN", 1, 3, CPU8_CONTROL_ROM_PIN_D3, ACTIVE_HIGH},       /* ROM1 D3 */
    {CTRL_RF_RW, "RF_RW", 1, 4, CPU8_CONTROL_ROM_PIN_D4, ACTIVE_HIGH},       /* ROM1 D4 */
    {CTRL_RA_EN, "RA_EN", 1, 5, CPU8_CONTROL_ROM_PIN_D5, ACTIVE_HIGH},       /* ROM1 D5 */
    {CTRL_RA_RB_RW, "RA_RB_RW", 1, 6, CPU8_CONTROL_ROM_PIN_D6, ACTIVE_HIGH}, /* ROM1 D6 */
    {CTRL_RB_EN, "RB_EN", 1, 7, CPU8_CONTROL_ROM_PIN_D7, ACTIVE_HIGH},       /* ROM1 D7 */

    {CTRL_ALU_EN, "ALU_EN", 2, 0, CPU8_CONTROL_ROM_PIN_D0, ACTIVE_LOW},      /* ROM2 D0 */
    {CTRL_FLAGS_WE, "FLAGS_WE", 2, 1, CPU8_CONTROL_ROM_PIN_D1, ACTIVE_HIGH}, /* ROM2 D1 */
    {CTRL_MAR_H_WE, "MAR_H_WE", 2, 2, CPU8_CONTROL_ROM_PIN_D2, ACTIVE_HIGH}, /* ROM2 D2 */
    {CTRL_RAM_OE, "RAM_OE", 2, 3, CPU8_CONTROL_ROM_PIN_D3, ACTIVE_LOW},      /* ROM2 D3 */
    {CTRL_IDX_L_WE, "IDX_L_WE", 2, 4, CPU8_CONTROL_ROM_PIN_D4, ACTIVE_HIGH}, /* ROM2 D4 */
    {CTRL_IDX_H_WE, "IDX_H_WE", 2, 5, CPU8_CONTROL_ROM_PIN_D5, ACTIVE_HIGH}, /* ROM2 D5 */
};

/* Il numero viene calcolato dal compilatore e usato nei cicli di validazione. */
const size_t CPU8_CONTROL_SIGNAL_CONFIG_COUNT =
    sizeof(CPU8_CONTROL_SIGNAL_CONFIGS) /
    sizeof(CPU8_CONTROL_SIGNAL_CONFIGS[0]);
