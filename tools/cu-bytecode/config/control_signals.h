#ifndef CPU8_CONTROL_SIGNALS_CONFIG_H
#define CPU8_CONTROL_SIGNALS_CONFIG_H

#include "../include/microcode.h"

/*
 * Dichiarazioni della tabella definita in control_signals.c.
 * extern evita di creare una copia della configurazione in ogni modulo.
 */
extern const ControlSignalConfig CPU8_CONTROL_SIGNAL_CONFIGS[];
extern const size_t CPU8_CONTROL_SIGNAL_CONFIG_COUNT;

#endif
