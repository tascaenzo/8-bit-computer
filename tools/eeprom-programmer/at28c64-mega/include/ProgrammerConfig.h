#ifndef CPU8_AT28C64_PROGRAMMER_CONFIG_H
#define CPU8_AT28C64_PROGRAMMER_CONFIG_H

#include <Arduino.h>

/*
 * Configurazione hardware del programmatore.
 *
 * Se in futuro cambi cablaggio, questa dovrebbe essere la prima sezione da
 * modificare. La logica in src/EepromBus.cpp usa questi valori senza conoscere
 * direttamente il numero dei pin Arduino.
 */

static const uint16_t EEPROM_SIZE = 8192;
static const uint16_t EEPROM_LAST_ADDRESS = EEPROM_SIZE - 1;

static const uint32_t SERIAL_BAUD = 115200;
static const uint8_t SERIAL_LINE_BUFFER_SIZE = 96;

/*
 * A0..A12 della EEPROM AT28C64.
 * L'indice dell'array corrisponde al bit dell'indirizzo:
 * ADDRESS_PINS[0] -> A0, ADDRESS_PINS[12] -> A12.
 */
static const uint8_t ADDRESS_PINS[13] = {
    22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34
};

/*
 * I/O0..I/O7 della EEPROM.
 * Anche qui l'indice dell'array corrisponde al bit del byte.
 */
static const uint8_t DATA_PINS[8] = {
    35, 36, 37, 38, 39, 40, 41, 42
};

static const uint8_t PIN_CE = 43;
static const uint8_t PIN_OE = 44;
static const uint8_t PIN_WE = 45;

/*
 * Timing conservativi per byte write.
 * Il ciclo interno della EEPROM viene poi controllato con data polling su I/O7.
 */
static const uint8_t READ_SETTLE_US = 1;
static const uint8_t WRITE_PULSE_US = 2;
static const uint16_t WRITE_TIMEOUT_MS = 20;

#endif
