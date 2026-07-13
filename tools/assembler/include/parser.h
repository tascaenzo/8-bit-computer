#ifndef CPU8_PARSER_H
#define CPU8_PARSER_H

#include <stddef.h>

#include "errors.h"

/* Lunghezza massima di una riga assembly letta dal sorgente. */
#define CPU8_MAX_LINE_LENGTH 256

/*
 * Numero massimo di token previsto dalla prima sintassi.
 *
 * Esempi:
 *   HLT              -> 1 token
 *   OUT R0           -> 2 token
 *   LDI R0, 0x2A     -> 3 token logici
 */
#define CPU8_MAX_TOKENS 3

/*
 * Una riga del file sorgente.
 *
 * Conserviamo sia il testo sia il numero di riga, per poter produrre errori
 * didattici e precisi: "errore alla riga 12" e molto piu utile di un errore
 * generico.
 */
typedef struct {
    char text[CPU8_MAX_LINE_LENGTH];
    size_t line_number;
} Cpu8SourceLine;

/*
 * Legge una riga dal file sorgente.
 *
 * file e void* per evitare di esporre FILE nei file header pubblici.
 * has_line vale 1 quando una riga e stata letta, 0 a fine file.
 */
Cpu8Status cpu8_read_source_line(void *file, Cpu8SourceLine *line, int *has_line);

#endif
