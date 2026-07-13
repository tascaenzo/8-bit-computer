#include "errors.h"

#include <stdio.h>

static char error_detail[256];

const char *cpu8_status_message(Cpu8Status status)
{
    /*
     * Centralizzare i messaggi evita stringhe duplicate nel codice.
     * Il main riceve solo un Cpu8Status e qui ottiene il testo da mostrare.
     */
    switch (status) {
        case CPU8_OK:
            return "ok";
        case CPU8_ERROR_INVALID_ARGUMENT:
            return "invalid argument";
        case CPU8_ERROR_IO:
            return "I/O error";
        case CPU8_ERROR_PARSE:
            return "parse error";
        case CPU8_ERROR_ASSEMBLE:
            return "assemble error";
        default:
            return "unknown error";
    }
}

void cpu8_set_error_detail(size_t line_number, const char *message)
{
    if (message == NULL) {
        message = "unknown error";
    }

    if (line_number > 0) {
        (void)snprintf(error_detail, sizeof(error_detail), "line %zu: %s", line_number, message);
    } else {
        (void)snprintf(error_detail, sizeof(error_detail), "%s", message);
    }
}

const char *cpu8_error_detail(void)
{
    return error_detail;
}

void cpu8_clear_error_detail(void)
{
    error_detail[0] = '\0';
}
