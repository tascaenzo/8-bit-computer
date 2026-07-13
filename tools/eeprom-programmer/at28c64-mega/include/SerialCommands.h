#ifndef CPU8_AT28C64_SERIAL_COMMANDS_H
#define CPU8_AT28C64_SERIAL_COMMANDS_H

/* Stampa l'elenco dei comandi disponibili nel monitor seriale. */
void serialCommandsPrintHelp();

/* Legge dalla seriale una riga alla volta e la passa al parser comandi. */
void serialCommandsHandleInput();

#endif
