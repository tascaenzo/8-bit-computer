#ifndef CPU8_ASSEMBLER_H
#define CPU8_ASSEMBLER_H

#include <stddef.h>
#include <stdint.h>

#include "errors.h"

/*
 * Dimensione massima temporanea del programma generato.
 *
 * La CPU usa un address bus a 16 bit, quindi lo spazio indirizzabile massimo
 * e 65536 byte. L'assembler mantiene un'immagine completa della memoria: le
 * zone non scritte restano a 0x00.
 */
#define CPU8_MAX_PROGRAM_BYTES 65536

/*
 * Rappresenta il programma gia assemblato.
 *
 * bytes  contiene i byte macchina pronti da scrivere in un file .bin.
 * length dice quanti byte dell'array sono realmente usati.
 */
typedef struct {
    uint8_t bytes[CPU8_MAX_PROGRAM_BYTES];
    size_t length;
} Cpu8Program;

/*
 * Opzioni passate dalla CLI al motore dell'assembler.
 *
 * input_path     e il file .asm da leggere.
 * output_prefix  e il prefisso usato per generare .bin, .hex, .bits e .h.
 */
typedef struct {
    const char *input_path;
    const char *output_prefix;
} Cpu8AssemblerOptions;

/*
 * Punto di ingresso della logica di assemblaggio.
 *
 * La CLI prepara Cpu8AssemblerOptions, poi questa funzione legge il sorgente
 * assembly e riempie Cpu8Program con i byte macchina.
 */
Cpu8Status cpu8_assemble_file(const Cpu8AssemblerOptions *options, Cpu8Program *program);

#endif
