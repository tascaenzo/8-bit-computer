#ifndef CPU8_ERRORS_H
#define CPU8_ERRORS_H

/*
 * Codici di stato condivisi da tutti i moduli.
 *
 * In C non abbiamo eccezioni: ogni funzione che puo fallire restituisce un
 * Cpu8Status. Il main traduce poi questo codice in un messaggio leggibile.
 */
typedef enum {
    CPU8_OK = 0,
    CPU8_ERROR_INVALID_ARGUMENT = 1,
    CPU8_ERROR_IO = 2,
    CPU8_ERROR_PARSE = 3,
    CPU8_ERROR_ASSEMBLE = 4
} Cpu8Status;

/* Converte un codice di errore in una stringa adatta per stderr. */
const char *cpu8_status_message(Cpu8Status status);

#endif
