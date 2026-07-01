#ifndef CPU8_OUTPUT_H
#define CPU8_OUTPUT_H

#include "assembler.h"
#include "errors.h"

/*
 * Scrive su disco gli output generati dall'assembler.
 *
 * La versione finale dovra produrre almeno:
 * - .bin: bytes raw per ROM/EEPROM;
 * - .hex: dump leggibile per debug;
 * - .h: array C/C++ usabile da Arduino IDE.
 */
Cpu8Status cpu8_write_outputs(const char *output_prefix, const Cpu8Program *program);

#endif
