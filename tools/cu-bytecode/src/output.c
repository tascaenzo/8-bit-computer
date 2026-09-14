#include "../include/output.h"

#include <errno.h>
#include <stdio.h>
#include <string.h>

/*
 * Apre il file in modalita binaria ("wb") per non alterare nessun byte.
 * Il chiamante riceve nel buffer message una descrizione dell'eventuale errore.
 */
bool write_binary_file(const char *path, const uint8_t *data, size_t size,
                       char *message, size_t message_size)
{
    FILE *file = fopen(path, "wb");
    if (file == NULL)
    {
        snprintf(message, message_size, "%s: %s", path, strerror(errno));
        return false;
    }
    /* fwrite deve trasferire l'immagine completa, non solo una sua parte. */
    if (fwrite(data, 1, size, file) != size)
    {
        snprintf(message, message_size, "%s: scrittura incompleta", path);
        fclose(file);
        return false;
    }
    /* Anche fclose puo segnalare un errore di scrittura rimasto nel buffer. */
    if (fclose(file) != 0)
    {
        snprintf(message, message_size, "%s: %s", path, strerror(errno));
        return false;
    }
    return true;
}
