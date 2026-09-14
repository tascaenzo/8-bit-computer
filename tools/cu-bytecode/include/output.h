#ifndef CPU8_MICROCODE_OUTPUT_H
#define CPU8_MICROCODE_OUTPUT_H

/* Funzioni dedicate alla scrittura su disco delle immagini generate. */

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

/* Scrive size byte senza conversioni testuali; restituisce false su errore. */
bool write_binary_file(const char *path, const uint8_t *data, size_t size,
                       char *message, size_t message_size);

#endif
