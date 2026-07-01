#include "assembler.h"

#include <stdio.h>

Cpu8Status cpu8_assemble_file(const Cpu8AssemblerOptions *options, Cpu8Program *program)
{
    FILE *file;

    /*
     * Controllo difensivo degli argomenti.
     *
     * Ogni funzione pubblica deve validare i puntatori ricevuti: se il main o
     * un test passa NULL per errore, restituiamo un codice gestibile invece di
     * dereferenziare un puntatore nullo.
     */
    if (options == NULL || program == NULL || options->input_path == NULL) {
        return CPU8_ERROR_INVALID_ARGUMENT;
    }

    /*
     * Apertura del sorgente assembly.
     *
     * Usiamo modalita "r" per leggere testo. La gestione concreta delle righe
     * sara delegata al parser, cosi questo modulo restera responsabile del
     * flusso generale di assemblaggio.
     */
    file = fopen(options->input_path, "r");
    if (file == NULL) {
        return CPU8_ERROR_IO;
    }

    /*
     * TODO: parse source lines and encode instructions.
     * The scaffolding currently proves the CLI/build/output pipeline.
     *
     * Flusso previsto:
     *   1. leggere una riga con parser.c;
     *   2. rimuovere commenti e spazi;
     *   3. riconoscere mnemonic e operandi;
     *   4. cercare l'istruzione in isa.c;
     *   5. aggiungere opcode e operandi a program->bytes.
     */
    program->length = 0;

    /* Ogni fopen deve avere un fclose corrispondente. */
    fclose(file);
    return CPU8_OK;
}
