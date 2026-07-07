#ifndef CPU8_AT28C64_EEPROM_BUS_H
#define CPU8_AT28C64_EEPROM_BUS_H

#include <Arduino.h>

/* Inizializza pin indirizzo, dati e controllo in stato inattivo. */
void eepromBusBegin();

/* Legge un byte dalla EEPROM. Il chiamante deve passare un indirizzo valido. */
uint8_t eepromReadByte(uint16_t address);

/* Scrive un byte e attende il completamento tramite data polling. */
bool eepromWriteByte(uint16_t address, uint8_t value);

#endif
