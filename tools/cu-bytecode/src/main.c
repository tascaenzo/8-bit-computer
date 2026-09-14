#include "../include/microcode.h"
#include "../include/output.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/*
 * Costruisce un nome come "build/microcode-rom0.bin" in modo sicuro.
 * snprintf() restituisce la lunghezza che avrebbe scritto: se supera size,
 * il percorso e stato troncato e la funzione segnala l'errore.
 */
static bool make_path(char *path, size_t size, const char *prefix,
                      const char *suffix)
{
    int length = snprintf(path, size, "%s%s", prefix, suffix);
    return length >= 0 && (size_t)length < size;
}

static void usage(FILE *stream)
{
    fprintf(stream, "Uso: cpu8microcode [-o prefisso_output]\n");
}

int main(int argc, char **argv)
{
    /*
     * Le immagini vengono tenute in memoria durante la generazione:
     * 3 x 8192 byte per le Control ROM e 8192 byte per il dispatch.
     */
    const char *prefix = "build/microcode";
    uint8_t roms[3][CPU8_CONTROL_ROM_SIZE];
    uint8_t dispatch[CPU8_DISPATCH_ROM_SIZE];
    const char *suffixes[] = {"-rom0.bin", "-rom1.bin", "-rom2.bin"};
    char path[1024];
    char message[256];
    int index;

    path[0] = '\0';
    message[0] = '\0';

    /* Senza argomenti usa build/microcode; -o cambia il prefisso dei file. */
    if (argc == 3 && strcmp(argv[1], "-o") == 0)
    {
        prefix = argv[2];
    }
    else if (argc != 1)
    {
        usage(stderr);
        return EXIT_FAILURE;
    }

    /* Prima si calcolano e validano le tabelle, poi si scrivono su disco. */
    if (!build_control_roms(roms, message, sizeof(message)))
    {
        fprintf(stderr, "cpu8microcode: microcodice non valido: %s\n", message);
        return EXIT_FAILURE;
    }
    build_dispatch_rom(dispatch);

    /* Ogni iterazione salva il byte appartenente a una delle tre EEPROM. */
    for (index = 0; index < 3; index++)
    {
        if (!make_path(path, sizeof(path), prefix, suffixes[index]))
        {
            fprintf(stderr, "cpu8microcode: percorso output troppo lungo\n");
            return EXIT_FAILURE;
        }
        if (!write_binary_file(path, roms[index], sizeof(roms[index]),
                               message, sizeof(message)))
        {
            fprintf(stderr, "cpu8microcode: %s\n", message);
            return EXIT_FAILURE;
        }
    }
    /* La quarta immagine contiene la tabella opcode -> uOP. */
    if (!make_path(path, sizeof(path), prefix, "-dispatch.bin"))
    {
        fprintf(stderr, "cpu8microcode: percorso output troppo lungo\n");
        return EXIT_FAILURE;
    }
    if (!write_binary_file(path, dispatch, sizeof(dispatch),
                           message, sizeof(message)))
    {
        fprintf(stderr, "cpu8microcode: %s\n", message);
        return EXIT_FAILURE;
    }

    printf("Generate 4 immagini EEPROM da %u byte con prefisso %s\n",
           CPU8_CONTROL_ROM_SIZE, prefix);
    return EXIT_SUCCESS;
}
