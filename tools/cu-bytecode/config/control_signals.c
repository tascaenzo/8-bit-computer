#include "control_signals.h"

/*
 * Modificare questa tabella per scegliere EEPROM, uscita e polarita.
 *
 * Campi: segnale logico, nome, numero ROM (0..2), bit (0..7), polarita.
 * Ogni segnale e ogni coppia ROM/bit devono comparire una sola volta.
 *
 * Esempio:
 * {CTRL_MEM_RD, "MEM_RD", 0, 6, ACTIVE_LOW}
 * significa che MEM_RD usa D6 della Control ROM 0 e vale elettricamente 0
 * quando la microistruzione richiede una lettura.
 */
const ControlSignalConfig CPU8_CONTROL_SIGNAL_CONFIGS[] = {
    {CTRL_ADDR_SEL_0, "ADDR_SEL_0", 0, 0, ACTIVE_HIGH},
    {CTRL_ADDR_SEL_1, "ADDR_SEL_1", 0, 1, ACTIVE_HIGH},
    {CTRL_PC_INC, "PC_INC", 0, 2, ACTIVE_HIGH},
    {CTRL_PC_LOAD, "PC_LOAD", 0, 3, ACTIVE_HIGH},
    {CTRL_MAR_L_WE, "MAR_L_WE", 0, 4, ACTIVE_HIGH},
    {CTRL_MAR_H_WE, "MAR_H_WE", 0, 5, ACTIVE_HIGH},
    {CTRL_MEM_RD, "MEM_RD", 0, 6, ACTIVE_LOW},
    {CTRL_MEM_WR, "MEM_WR", 0, 7, ACTIVE_LOW},

    {CTRL_IR_WE, "IR_WE", 1, 0, ACTIVE_HIGH},
    {CTRL_MDR_WE, "MDR_WE", 1, 1, ACTIVE_HIGH},
    {CTRL_MDR_OE, "MDR_OE", 1, 2, ACTIVE_HIGH},
    {CTRL_RF_EN, "RF_EN", 1, 3, ACTIVE_HIGH},
    {CTRL_RF_WR, "RF_WR", 1, 4, ACTIVE_HIGH},
    {CTRL_RA_WE, "RA_WE", 1, 5, ACTIVE_HIGH},
    {CTRL_RA_OE, "RA_OE", 1, 6, ACTIVE_HIGH},
    {CTRL_RB_WE, "RB_WE", 1, 7, ACTIVE_HIGH},

    {CTRL_ALU_OE, "ALU_OE", 2, 0, ACTIVE_HIGH},
    {CTRL_FLAGS_WE, "FLAGS_WE", 2, 1, ACTIVE_HIGH},
    {CTRL_NEXT_FETCH, "NEXT_FETCH", 2, 2, ACTIVE_LOW},
    {CTRL_HALT, "HALT", 2, 3, ACTIVE_HIGH},
    {CTRL_IDX_L_WE, "IDX_L_WE", 2, 4, ACTIVE_HIGH},
    {CTRL_IDX_H_WE, "IDX_H_WE", 2, 5, ACTIVE_HIGH},
};

/* Il numero viene calcolato dal compilatore e usato nei cicli di validazione. */
const size_t CPU8_CONTROL_SIGNAL_CONFIG_COUNT =
    sizeof(CPU8_CONTROL_SIGNAL_CONFIGS) /
    sizeof(CPU8_CONTROL_SIGNAL_CONFIGS[0]);
