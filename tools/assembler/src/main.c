#include <stdio.h>
#include <string.h>

#include "assembler.h"
#include "output.h"

/*
 * Stampa l'interfaccia minima della CLI.
 *
 * In questa fase il programma accetta solo:
 *   cpu8asm input.asm -o output-prefix
 *
 * Mantenere pochi argomenti rende piu semplice testare lo scaffold prima di
 * aggiungere opzioni come formato output, listing o modalita verbose.
 */
static void print_usage(const char *program_name)
{
    printf("Usage: %s <input.asm> -o <output-prefix>\n", program_name);
    printf("\n");
    printf("Examples:\n");
    printf("  %s examples/assembly/demo.asm -o build/demo\n", program_name);
    printf("\n");
}

int main(int argc, char **argv)
{
    /*
     * Inizializzazione a zero.
     *
     * In C le variabili locali non vengono azzerate automaticamente. Usare
     * {0} evita puntatori casuali e length non inizializzate.
     */
    Cpu8AssemblerOptions options = {0};
    Cpu8Program program = {0};
    Cpu8Status status;

    /* --help e gestito prima della validazione degli argomenti obbligatori. */
    if (argc == 2 && strcmp(argv[1], "--help") == 0) {
        print_usage(argv[0]);
        return CPU8_OK;
    }

    /*
     * Validazione volutamente rigida:
     * argv[1] = input.asm
     * argv[2] = -o
     * argv[3] = prefisso output
     */
    if (argc != 4 || strcmp(argv[2], "-o") != 0) {
        print_usage(argv[0]);
        return CPU8_ERROR_INVALID_ARGUMENT;
    }

    options.input_path = argv[1];
    options.output_prefix = argv[3];

    /*
     * Primo passo: trasformare il sorgente assembly in un Cpu8Program.
     * Oggi questa funzione e ancora uno scaffold, ma questa restera la
     * separazione principale tra CLI e logica dell'assembler.
     */
    status = cpu8_assemble_file(&options, &program);
    if (status != CPU8_OK) {
        fprintf(stderr, "cpu8asm: %s\n", cpu8_status_message(status));
        return status;
    }

    /*
     * Secondo passo: scrivere su disco i formati richiesti.
     * La CLI non deve sapere come si scrive un .bin o un .h: delega tutto al
     * modulo output.
     */
    status = cpu8_write_outputs(options.output_prefix, &program);
    if (status != CPU8_OK) {
        fprintf(stderr, "cpu8asm: %s\n", cpu8_status_message(status));
        return status;
    }

    printf("Generated %zu byte(s).\n", program.length);
    return CPU8_OK;
}
