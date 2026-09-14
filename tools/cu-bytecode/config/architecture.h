#ifndef CPU8_MICROCODE_ARCHITECTURE_H
#define CPU8_MICROCODE_ARCHITECTURE_H

/*
 * Parametri legati al cablaggio generale della Control Unit.
 *
 * I valori del selettore sono scritti nei bit logici ADDR_SEL_1:0. Se il
 * cablaggio del 74LS138 usa un ordine diverso, e sufficiente cambiare qui i
 * quattro codici senza modificare le microsequenze.
 */
#define CPU8_ADDR_SEL_IDX  0x0u
#define CPU8_ADDR_SEL_PC   0x1u
#define CPU8_ADDR_SEL_MAR  0x2u
#define CPU8_ADDR_SEL_NONE 0x3u

/*
 * Livello presentato ad A12 dal flip-flop di modo. I valori devono essere
 * diversi e limitati a 0/1; validate_signal_config() controlla entrambe le cose.
 */
#define CPU8_BOOT_ADDRESS_LEVEL 0u
#define CPU8_RUN_ADDRESS_LEVEL  1u

#endif
