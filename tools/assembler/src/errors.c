#include "errors.h"

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
