/*
 * Test automatici del generatore CU.
 * Coprono dispatch, indirizzi condivisi, microsequenze, polarita, immagini
 * EEPROM e assenza di contese sul data bus.
 */
#include "../include/microcode.h"
#include "../config/control_signals.h"

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

static bool expected_jump_taken(MicroOp op, CpuFlags flags)
{
    switch (op) {
    case UOP_JMP: return true;
    case UOP_JZ: return flags.zero;
    case UOP_JNZ: return !flags.zero;
    case UOP_JC: return flags.carry;
    case UOP_JNC: return !flags.carry;
    case UOP_JN: return flags.negative;
    case UOP_JNN: return !flags.negative;
    case UOP_JO: return flags.overflow;
    case UOP_JNO: return !flags.overflow;
    default: return false;
    }
}

static void test_dispatch(void)
{
    /* Verifica gli estremi dei range e alcuni opcode singoli importanti. */
    assert(dispatch_opcode(0x00) == UOP_HLT);
    assert(dispatch_opcode(0x01) == UOP_NOP);
    assert(dispatch_opcode(0x20) == UOP_LDI);
    assert(dispatch_opcode(0x27) == UOP_LDI);
    assert(dispatch_opcode(0x40) == UOP_LDA);
    assert(dispatch_opcode(0x4f) == UOP_STA);
    assert(dispatch_opcode(0x50) == UOP_LDA_IDX);
    assert(dispatch_opcode(0x5f) == UOP_STA_IDX);
    assert(dispatch_opcode(0x60) == UOP_ALU);
    assert(dispatch_opcode(0x69) == UOP_CMP);
    assert(dispatch_opcode(0x78) == UOP_ALU);
    assert(dispatch_opcode(0x68) == UOP_INVALID);
    assert(dispatch_opcode(0xa8) == UOP_JNO);
    assert(dispatch_opcode(0xb0) == UOP_JZ);
    assert(dispatch_opcode(0xb8) == UOP_JNZ);
    assert(dispatch_opcode(0xe0) == UOP_JC);
    assert(dispatch_opcode(0xe8) == UOP_JNC);
    assert(dispatch_opcode(0xf0) == UOP_JN);
    assert(dispatch_opcode(0xf8) == UOP_JNN);
    assert(dispatch_opcode(0x30) == UOP_JO);
    assert(dispatch_opcode(0xc7) == UOP_MOV_RA_RN);
    assert(dispatch_opcode(0xcf) == UOP_MOV_RB_RN);
    assert(dispatch_opcode(0xd7) == UOP_MOV_RN_RA);
    assert(dispatch_opcode(0xd8) == UOP_LDX);
    assert(dispatch_opcode(0x80) == UOP_INVALID);
    assert(dispatch_opcode(0xff) == UOP_INVALID);
}

static void test_shared_address_input_config(void)
{
    static const uint8_t expected_pins[] = {
        CPU8_CONTROL_ROM_PIN_USTEP_2, CPU8_CONTROL_ROM_PIN_USTEP_1,
        CPU8_CONTROL_ROM_PIN_USTEP_0, CPU8_CONTROL_ROM_PIN_IR_3,
        CPU8_CONTROL_ROM_PIN_IR_4, CPU8_CONTROL_ROM_PIN_IR_5,
        CPU8_CONTROL_ROM_PIN_IR_6, CPU8_CONTROL_ROM_PIN_IR_7,
        CPU8_CONTROL_ROM_PIN_FLAG_C, CPU8_CONTROL_ROM_PIN_FLAG_Z,
        CPU8_CONTROL_ROM_PIN_FLAG_N, CPU8_CONTROL_ROM_PIN_FLAG_O,
        CPU8_CONTROL_ROM_PIN_BOOT_RUN};
    size_t index;

    assert(CPU8_CONTROL_EEPROM_ADDRESS_CONFIG_COUNT == 13);
    for (index = 0; index < CPU8_CONTROL_EEPROM_ADDRESS_CONFIG_COUNT; index++)
    {
        assert(CPU8_CONTROL_EEPROM_ADDRESS_CONFIGS[index].signal == index);
        assert(CPU8_CONTROL_EEPROM_ADDRESS_CONFIGS[index].pin ==
               expected_pins[index]);
    }
}

static void test_sequences(void)
{
    /* Confronta alcune microistruzioni complete con i segnali attesi. */
    CpuFlags clear = {false, false, false, false};
    CpuFlags zero = {false, true, false, false};

    assert(microcode_word(0, UOP_LDI, clear, CPU_MODE_RUN) ==
           (address_word(CPU8_ADDR_SEL_PC) |
            CTRL_RAM_OE | CTRL_IR_WE | CTRL_PC_INC));
    assert(microcode_word(2, UOP_LDI, clear, CPU_MODE_RUN) ==
           (address_word(CPU8_ADDR_SEL_NONE) |
            CTRL_MDR_OE | CTRL_RF_EN | CTRL_RF_RW));
    assert(microcode_word(4, UOP_LDA, clear, CPU_MODE_RUN) ==
           (address_word(CPU8_ADDR_SEL_NONE) |
            CTRL_MDR_OE | CTRL_RF_EN | CTRL_RF_RW));
    assert(microcode_word(1, UOP_CMP, clear, CPU_MODE_RUN) ==
           (address_word(CPU8_ADDR_SEL_NONE) |
            CTRL_FLAGS_WE));
    assert((microcode_word(3, UOP_JZ, clear, CPU_MODE_RUN) &
            CTRL_PC_LOAD) == 0);
    assert((microcode_word(3, UOP_JZ, zero, CPU_MODE_RUN) &
            CTRL_PC_LOAD) != 0);
    assert(microcode_word(0, UOP_LDX, clear, CPU_MODE_RUN) ==
           (address_word(CPU8_ADDR_SEL_PC) |
            CTRL_RAM_OE | CTRL_IR_WE | CTRL_PC_INC));
    assert(microcode_word(1, UOP_LDX, clear, CPU_MODE_RUN) ==
           (address_word(CPU8_ADDR_SEL_PC) | CTRL_RAM_OE |
            CTRL_IDX_L_WE | CTRL_PC_INC));
    assert(microcode_word(1, UOP_LDA_IDX, clear, CPU_MODE_RUN) ==
           (address_word(CPU8_ADDR_SEL_IDX) | CTRL_RAM_OE | CTRL_MDR_WE));
    assert(microcode_word(1, UOP_STA_IDX, clear, CPU_MODE_RUN) ==
           (address_word(CPU8_ADDR_SEL_NONE) | CTRL_RF_EN | CTRL_MDR_WE));
    assert(microcode_word(1, UOP_SYSTEM, clear, CPU_MODE_RUN) ==
           (address_word(CPU8_ADDR_SEL_NONE) | CTRL_SYSTEM_STEP));
    assert((microcode_word(0, UOP_SYSTEM, clear, CPU_MODE_RUN) &
            CTRL_SYSTEM_STEP) == 0);
}

static void test_dedicated_fetch_return(void)
{
    static const struct {
        MicroOp op;
        uint8_t action_step;
    } cases[] = {
        {UOP_INVALID, 1}, {UOP_NOP, 1}, {UOP_HLT, 1},
        {UOP_SYSTEM, 1}, {UOP_ALU, 1},
        {UOP_CMP, 1}, {UOP_MOV_RA_RN, 1}, {UOP_MOV_RB_RN, 1},
        {UOP_MOV_RN_RA, 1}, {UOP_LDI, 2}, {UOP_LDX, 2},
        {UOP_LDA_IDX, 2}, {UOP_STA_IDX, 2},
        {UOP_JMP, 3}, {UOP_JNO, 3}, {UOP_LDA, 4}, {UOP_STA, 4}
    };
    CpuFlags clear = {false, false, false, false};
    size_t index;

    for (index = 0; index < sizeof(cases) / sizeof(cases[0]); index++) {
        uint8_t action = cases[index].action_step;
        assert((microcode_word(action, cases[index].op, clear,
                               CPU_MODE_RUN) & CTRL_NEXT_FETCH) == 0);
        assert(microcode_word((uint8_t)(action + 1), cases[index].op,
                              clear, CPU_MODE_RUN) ==
               (address_word(CPU8_ADDR_SEL_NONE) | CTRL_NEXT_FETCH));
    }
    assert(microcode_word(4, UOP_STA, clear, CPU_MODE_RUN) ==
           (address_word(CPU8_ADDR_SEL_MAR) | CTRL_MDR_OE | CTRL_RAM_WE));
    assert(microcode_word(2, UOP_STA_IDX, clear, CPU_MODE_RUN) ==
           (address_word(CPU8_ADDR_SEL_IDX) | CTRL_MDR_OE | CTRL_RAM_WE));
    assert(microcode_word(3, UOP_JNO, clear, CPU_MODE_RUN) ==
           (address_word(CPU8_ADDR_SEL_NONE) | CTRL_PC_LOAD));
}

static void test_boot_sequence(void)
{
    CpuFlags clear = { false, false, false, false };

    assert(microcode_word(0, UOP_INVALID, clear, CPU_MODE_BOOT) ==
           (address_word(CPU8_ADDR_SEL_PC) | CTRL_EPROM_OE | CTRL_RAM_WE));
    assert(microcode_word(1, UOP_LDI, clear, CPU_MODE_BOOT) ==
           (address_word(CPU8_ADDR_SEL_PC) | CTRL_EPROM_OE |
            CTRL_PC_INC));
    assert(microcode_word(2, UOP_JNO, clear, CPU_MODE_BOOT) ==
           (address_word(CPU8_ADDR_SEL_PC) | CTRL_EPROM_OE |
            CTRL_NEXT_FETCH));
}

static void test_addresses_and_images(void)
{
    /* Controlla A12, dimensione dei banchi e replica della ROM di dispatch. */
    CpuFlags flags = {true, true, true, true};
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

static void test_system_decode_output(void)
{
    uint8_t roms[3][CPU8_CONTROL_ROM_SIZE];
    char message[128];
    unsigned address;
    unsigned opcode;
    unsigned mode;
    unsigned step;
    CpuFlags clear = {false, false, false, false};

    assert(build_control_roms(roms, message, sizeof(message)));
    for (address = 0; address < CPU8_CONTROL_ROM_SIZE; address++) {
        bool expected_low = (address & 0x1000u) != 0 &&
                            (address & 0x00f8u) == 0 &&
                            (address & 0x0007u) == 4;
        assert(((roms[2][address] & 0x40u) == 0) == expected_low);
    }
    assert(roms[2][0x0004] == 0x49); /* BOOT T2: inattivo. */
    assert(roms[2][0x1000] == 0x41); /* RUN T1: inattivo. */
    assert(roms[2][0x1004] == 0x09); /* RUN gruppo 0, T2: attivo. */
    assert(roms[2][0x1002] == 0x49); /* RUN gruppo 0, T3: inattivo. */
    assert(roms[2][0x100c] == 0x49); /* RUN gruppo 1, T2: inattivo. */

    /* L'OR esterno blocca soltanto HLT in RUN/T2, per tutti gli opcode. */
    for (mode = CPU_MODE_BOOT; mode <= CPU_MODE_RUN; mode++)
        for (step = 0; step < CPU8_MICROSTEP_COUNT; step++)
            for (opcode = 0; opcode < 256; opcode++) {
                uint16_t location = microcode_address((uint8_t)step,
                    (MicroOp)(opcode >> 3), clear, (CpuMode)mode);
                unsigned sys_high = (roms[2][location] & 0x40u) != 0;
                bool enabled = (sys_high | (opcode & 7u)) != 0;
                assert(enabled == !(mode == CPU_MODE_RUN &&
                                    step == 1 && opcode == 0));
            }
}

static void test_active_group_partition(void)
{
    /* Un gruppo condiviso e ammesso solo quando la microsequenza e identica. */
    static const uint8_t family_opcodes[] = {
        0x00, 0x20, 0x40, 0x48, 0x50, 0x58, 0x60, 0x69, 0x78,
        0xa0, 0xa8, 0xb0, 0xb8, 0xe0, 0xe8, 0xf0, 0xf8, 0x30,
        0xc0, 0xc8, 0xd0, 0xd8
    };
    size_t left;
    size_t right;

    for (left = 0; left < sizeof(family_opcodes); left++)
        for (right = left + 1; right < sizeof(family_opcodes); right++)
            assert((family_opcodes[left] >> 3) !=
                   (family_opcodes[right] >> 3));
}

static void test_isa_groups_and_jump_flags(void)
{
    static const struct {
        uint8_t opcode;
        MicroOp uop;
    } jumps[] = {
        {0xa0, UOP_JMP}, {0xb0, UOP_JZ}, {0xb8, UOP_JNZ},
        {0xe0, UOP_JC}, {0xe8, UOP_JNC}, {0xf0, UOP_JN},
        {0xf8, UOP_JNN}, {0x30, UOP_JO}, {0xa8, UOP_JNO}
    };
    uint8_t roms[3][CPU8_CONTROL_ROM_SIZE];
    char message[128];
    unsigned index;
    unsigned bits;

    assert(build_control_roms(roms, message, sizeof(message)));
    /* SUB e CMP devono avere gruppi diversi pur condividendo l'ALU. */
    assert(roms[1][0x1000u | 0x78u | 4u] == 0x62);
    assert(roms[2][0x1000u | 0x78u | 4u] == 0x4a);
    assert(roms[1][0x1000u | 0x68u | 4u] == 0x02);
    assert(roms[2][0x1000u | 0x68u | 4u] == 0x4b);

    for (index = 0; index < sizeof(jumps) / sizeof(jumps[0]); index++) {
        for (bits = 0; bits < 16; bits++) {
            CpuFlags flags = {
                (bits & 1u) != 0, (bits & 2u) != 0,
                (bits & 4u) != 0, (bits & 8u) != 0
            };
            uint16_t address = microcode_address(3,
                (MicroOp)(jumps[index].opcode >> 3), flags, CPU_MODE_RUN);
            bool pc_load = (roms[1][address] & 0x02u) == 0;
            assert(dispatch_opcode(jumps[index].opcode) == jumps[index].uop);
            assert(pc_load == expected_jump_taken(jumps[index].uop, flags));
            assert(roms[0][address] == 0xf3); /* Niente NEXT_FETCH in T4. */
            assert(roms[0][microcode_address(4,
                (MicroOp)(jumps[index].opcode >> 3), flags, CPU_MODE_RUN)] ==
                0x73); /* T5 ritorna al fetch. */
        }
    }
}

static void test_validation(void)
{
    /* Una parola valida passa; contese e lettura/scrittura insieme falliscono. */
    char message[128];
    assert(validate_signal_config(message, sizeof(message)));
    assert(validate_control_word(CTRL_MDR_OE | CTRL_RF_EN | CTRL_RF_RW,
                                 message, sizeof(message)));
    assert(!validate_control_word(CTRL_MDR_OE | CTRL_RA_EN,
                                  message, sizeof(message)));
    assert(!validate_control_word(CTRL_RAM_OE | CTRL_RAM_WE,
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
    encode_control_word(CTRL_RAM_OE | CTRL_EPROM_OE | CTRL_NEXT_FETCH |
                            CTRL_IDX_L_WE | CTRL_IDX_H_WE |
                            CTRL_SYSTEM_STEP,
                        active);

    assert(physical_level(inactive, CTRL_RAM_OE, &active_low) == active_low);
    assert(physical_level(active, CTRL_RAM_OE, NULL) != active_low);
    assert(physical_level(inactive, CTRL_EPROM_OE, &active_low) == active_low);
    assert(physical_level(active, CTRL_EPROM_OE, NULL) != active_low);
    assert(physical_level(inactive, CTRL_NEXT_FETCH, &active_low) == active_low);
    assert(physical_level(active, CTRL_NEXT_FETCH, NULL) != active_low);
    assert(physical_level(inactive, CTRL_IDX_L_WE, &active_low) == active_low);
    assert(physical_level(active, CTRL_IDX_L_WE, NULL) != active_low);
    assert(physical_level(inactive, CTRL_IDX_H_WE, &active_low) == active_low);
    assert(physical_level(active, CTRL_IDX_H_WE, NULL) != active_low);
    assert(physical_level(inactive, CTRL_SYSTEM_STEP, &active_low) == active_low);
    assert(physical_level(active, CTRL_SYSTEM_STEP, NULL) != active_low);
}

int main(void)
{
    /* assert() termina immediatamente il programma se una verifica fallisce. */
    test_dispatch();
    test_shared_address_input_config();
    test_sequences();
    test_dedicated_fetch_return();
    test_boot_sequence();
    test_addresses_and_images();
    test_system_decode_output();
    test_active_group_partition();
    test_isa_groups_and_jump_flags();
    test_validation();
    test_polarity_and_idx_outputs();
    puts("microcode tests: ok");
    return 0;
}
