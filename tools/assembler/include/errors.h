#ifndef CPU8_ERRORS_H
#define CPU8_ERRORS_H

#include <stddef.h>

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

/* Salva un messaggio di errore piu specifico per il chiamante CLI. */
void cpu8_set_error_detail(size_t line_number, const char *message);

/* Restituisce l'ultimo errore dettagliato, oppure una stringa vuota. */
const char *cpu8_error_detail(void);

/* Azzera il dettaglio di errore prima di una nuova operazione. */
void cpu8_clear_error_detail(void);

#endif
