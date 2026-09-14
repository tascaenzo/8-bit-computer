#include "../include/microcode.h"

#include <assert.h>
#include <stdio.h>

/* Ricostruisce nel test lo stesso campo a 2 bit usato dal generatore. */
static ControlWord address_word(unsigned code)
{
    return ((code & 1u) != 0 ? CTRL_ADDR_SEL_0 : 0u) |
           ((code & 2u) != 0 ? CTRL_ADDR_SEL_1 : 0u);
}

/* Legge il livello fisico di un segnale senza assumere ROM, bit o polarita. */
static bool physical_level(const uint8_t bytes[3], ControlSignal signal,
                           bool *active_low)
{
    uint8_t rom;
    uint8_t bit;

    assert(get_control_signal_config(signal, &rom, &bit, active_low));
    return (bytes[rom] & (1u << bit)) != 0;
}

static void test_dispatch(void)
{
    /* Verifica gli estremi dei range e alcuni opcode singoli importanti. */
    assert(dispatch_opcode(0x00) == UOP_NOP);
    assert(dispatch_opcode(0x01) == UOP_HLT);
    assert(dispatch_opcode(0x20) == UOP_LDI);
    assert(dispatch_opcode(0x27) == UOP_LDI);
    assert(dispatch_opcode(0x40) == UOP_LDA);
    assert(dispatch_opcode(0x4f) == UOP_STA);
    assert(dispatch_opcode(0x60) == UOP_ALU);
    assert(dispatch_opcode(0x69) == UOP_CMP);
    assert(dispatch_opcode(0xa8) == UOP_JNO);
    assert(dispatch_opcode(0xc7) == UOP_MOV_RA_RN);
    assert(dispatch_opcode(0xcf) == UOP_MOV_RB_RN);
    assert(dispatch_opcode(0xd7) == UOP_MOV_RN_RA);
    assert(dispatch_opcode(0x80) == UOP_INVALID);
    assert(dispatch_opcode(0xff) == UOP_INVALID);
}

static void test_sequences(void)
{
    /* Confronta alcune microistruzioni complete con i segnali attesi. */
    CpuFlags clear = { false, false, false, false };
    CpuFlags zero = { false, true, false, false };

    assert(microcode_word(0, UOP_LDI, clear, CPU_MODE_RUN) ==
           (address_word(CPU8_ADDR_SEL_PC) |
            CTRL_MEM_RD | CTRL_IR_WE | CTRL_PC_INC));
    assert(microcode_word(2, UOP_LDI, clear, CPU_MODE_RUN) ==
           (address_word(CPU8_ADDR_SEL_NONE) |
            CTRL_MDR_OE | CTRL_RF_EN | CTRL_RF_WR | CTRL_NEXT_FETCH));
    assert(microcode_word(4, UOP_LDA, clear, CPU_MODE_RUN) ==
           (address_word(CPU8_ADDR_SEL_NONE) |
            CTRL_MDR_OE | CTRL_RF_EN | CTRL_RF_WR | CTRL_NEXT_FETCH));
    assert(microcode_word(1, UOP_CMP, clear, CPU_MODE_RUN) ==
           (address_word(CPU8_ADDR_SEL_NONE) |
            CTRL_FLAGS_WE | CTRL_NEXT_FETCH));
    assert((microcode_word(3, UOP_JZ, clear, CPU_MODE_RUN) &
            CTRL_PC_LOAD) == 0);
    assert((microcode_word(3, UOP_JZ, zero, CPU_MODE_RUN) &
            CTRL_PC_LOAD) != 0);
}

static void test_addresses_and_images(void)
{
    /* Controlla A12, dimensione dei banchi e replica della ROM di dispatch. */
    CpuFlags flags = { true, true, true, true };
    uint8_t roms[3][CPU8_CONTROL_ROM_SIZE];
    uint8_t dispatch[CPU8_DISPATCH_ROM_SIZE];
    char message[128];
    uint16_t low = microcode_address(7, UOP_JNO, flags, CPU_MODE_BOOT);
    uint16_t high = microcode_address(7, UOP_JNO, flags, CPU_MODE_RUN);

    assert(high == low + 4096);
    assert(build_control_roms(roms, message, sizeof(message)));
    assert(roms[0][low] == roms[0][high]);
    assert(roms[1][low] == roms[1][high]);
    assert(roms[2][low] == roms[2][high]);

    build_dispatch_rom(dispatch);
    assert(dispatch[0x20] == UOP_LDI);
    assert(dispatch[0x120] == UOP_LDI);
}

static void test_validation(void)
{
    /* Una parola valida passa; contese e lettura/scrittura insieme falliscono. */
    char message[128];
    assert(validate_signal_config(message, sizeof(message)));
    assert(validate_control_word(CTRL_MDR_OE | CTRL_RF_EN | CTRL_RF_WR,
                                 message, sizeof(message)));
    assert(!validate_control_word(CTRL_MDR_OE | CTRL_RA_OE,
                                  message, sizeof(message)));
    assert(!validate_control_word(CTRL_MEM_RD | CTRL_MEM_WR,
                                  message, sizeof(message)));
}

static void test_polarity_and_idx_outputs(void)
{
    /*
     * Il test consulta la configurazione anziche fissare ROM e bit: continua
     * quindi a funzionare anche dopo una rimappatura delle uscite.
     */
    uint8_t inactive[3];
    uint8_t active[3];
    bool active_low;

    encode_control_word(0, inactive);
    encode_control_word(CTRL_MEM_RD | CTRL_NEXT_FETCH |
                            CTRL_IDX_L_WE | CTRL_IDX_H_WE,
                        active);

    assert(physical_level(inactive, CTRL_MEM_RD, &active_low) == active_low);
    assert(physical_level(active, CTRL_MEM_RD, NULL) != active_low);
    assert(physical_level(inactive, CTRL_NEXT_FETCH, &active_low) == active_low);
    assert(physical_level(active, CTRL_NEXT_FETCH, NULL) != active_low);
    assert(physical_level(inactive, CTRL_IDX_L_WE, &active_low) == active_low);
    assert(physical_level(active, CTRL_IDX_L_WE, NULL) != active_low);
    assert(physical_level(inactive, CTRL_IDX_H_WE, &active_low) == active_low);
    assert(physical_level(active, CTRL_IDX_H_WE, NULL) != active_low);
}

int main(void)
{
    /* assert() termina immediatamente il programma se una verifica fallisce. */
    test_dispatch();
    test_sequences();
    test_addresses_and_images();
    test_validation();
    test_polarity_and_idx_outputs();
    puts("microcode tests: ok");
    return 0;
}
