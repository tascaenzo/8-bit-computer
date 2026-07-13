#include "parser.h"

#include <stdio.h>

Cpu8Status cpu8_read_source_line(void *file, Cpu8SourceLine *line, int *has_line)
{
    /*
     * Il chiamante passa un void* per non esporre FILE nell'header.
     * Qui lo riportiamo al tipo reale usato dalla libreria standard C.
     */
    FILE *source = (FILE *)file;

    if (source == NULL || line == NULL || has_line == NULL) {
        return CPU8_ERROR_INVALID_ARGUMENT;
    }

    /*
     * fgets legge al massimo sizeof(line->text) - 1 caratteri e aggiunge il
     * terminatore '\0'. Questo evita overflow del buffer.
     */
    if (fgets(line->text, sizeof(line->text), source) == NULL) {
        *has_line = 0;
        return CPU8_OK;
    }

    /*
     * line_number viene mantenuto dentro Cpu8SourceLine.
     * Il chiamante inizializza la struct a zero e ogni lettura incrementa il
     * contatore. In futuro questo numero apparira nei messaggi di errore.
     */
    line->line_number += 1;
    *has_line = 1;
    return CPU8_OK;
}
