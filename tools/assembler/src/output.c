#include "output.h"

#include <stdio.h>

Cpu8Status cpu8_write_outputs(const char *output_prefix, const Cpu8Program *program)
{
    /*
     * Parametri non ancora usati.
     *
     * I cast a void evitano warning del compilatore mentre il modulo e ancora
     * uno scaffold. Quando scriveremo davvero .bin/.hex/.h, questi cast
     * verranno rimossi.
     */
    (void)output_prefix;
    (void)program;

    /*
     * TODO: write .bin, .hex and .h outputs.
     *
     * Formati previsti:
     *   output-prefix.bin  -> byte raw da caricare in ROM/EEPROM;
     *   output-prefix.hex  -> dump leggibile per controllare gli opcode;
     *   output-prefix.h    -> array C/C++ comodo per Arduino IDE.
     */
    return CPU8_OK;
}
