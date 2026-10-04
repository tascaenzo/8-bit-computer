/*
 * Motore del generatore: descrive fetch, microsequenze e dispatch opcode,
 * valida i bus e converte la parola logica nei tre byte fisici delle EEPROM.
 * Non conosce dettagli di cablaggio oltre alle tabelle in config/.
 */

#include "../include/microcode.h"
#include "../config/control_signals.h"

#include <stdio.h>

/*
 * Questo modulo contiene il cuore del generatore.
 *
 * Il lavoro avviene in due livelli:
 * 1. microcode_word() descrive la microistruzione in termini logici;
 * 2. encode_control_word() la converte nei livelli fisici delle EEPROM.
 *
 * Tenere separati i due livelli permette di cambiare piedinatura e polarita
 * senza riscrivere le microsequenze delle istruzioni.
 */

/* Converte il codice 00..11 del selettore in due bit della ControlWord. */
#define ADDRESS_WORD(code)                            \
    ((((code) & 0x01u) != 0 ? CTRL_ADDR_SEL_0 : 0u) | \
     (((code) & 0x02u) != 0 ? CTRL_ADDR_SEL_1 : 0u))

/* Valore sicuro usato quando nessun registro deve pilotare A[15:0]. */
static const ControlWord ADDRESS_NONE = ADDRESS_WORD(CPU8_ADDR_SEL_NONE);

/* T1 comune: PC presenta l'indirizzo, la memoria presenta l'opcode, IR salva. */
static const ControlWord FETCH =
    ADDRESS_WORD(CPU8_ADDR_SEL_PC) |
    CTRL_RAM_OE | CTRL_IR_WE | CTRL_PC_INC;

/* Microoperazioni condivise dalle istruzioni con operando addr16. */
static const ControlWord READ_ADDRESS_LOW =
    ADDRESS_WORD(CPU8_ADDR_SEL_PC) |
    CTRL_RAM_OE | CTRL_MAR_L_WE | CTRL_PC_INC;

static const ControlWord READ_ADDRESS_HIGH =
    ADDRESS_WORD(CPU8_ADDR_SEL_PC) |
    CTRL_RAM_OE | CTRL_MAR_H_WE | CTRL_PC_INC;

/* Valuta la condizione di salto usando i flag gia memorizzati dalla CPU. */
static bool jump_is_taken(MicroOp uop, CpuFlags flags)
{
    switch (uop)
    {
    case UOP_JMP:
        return true;
    case UOP_JZ:
        return flags.zero;
    case UOP_JNZ:
        return !flags.zero;
    case UOP_JC:
        return flags.carry;
    case UOP_JNC:
        return !flags.carry;
    case UOP_JN:
        return flags.negative;
    case UOP_JNN:
        return !flags.negative;
    case UOP_JO:
        return flags.overflow;
    case UOP_JNO:
        return !flags.overflow;
    default:
        return false;
    }
}

/* I codici dei salti sono consecutivi nell'enum, quindi basta un intervallo. */
static bool is_jump(MicroOp uop)
{
    return uop >= UOP_JMP && uop <= UOP_JNO;
}

/* A3..A7 sono IR[7:3]: questa tabella traduce il gruppo fisico in sequenza. */
static MicroOp microop_for_ir_group(uint8_t group)
{
    switch (group) {
    case 0x00: return UOP_SYSTEM;
    case 0x04: return UOP_LDI;
    case 0x08: return UOP_LDA;
    case 0x09: return UOP_STA;
    case 0x0A: return UOP_LDA_IDX;
    case 0x0B: return UOP_STA_IDX;
    case 0x0C: return UOP_ALU;
    case 0x0D: return UOP_CMP;
    case 0x0F: return UOP_ALU; /* SUB=0x78 conserva IR[3:0]=1000. */
    case 0x14: return UOP_JMP;
    case 0x15: return UOP_JNO;
    case 0x16: return UOP_JZ;
    case 0x17: return UOP_JNZ;
    case 0x1C: return UOP_JC;
    case 0x1D: return UOP_JNC;
    case 0x1E: return UOP_JN;
    case 0x1F: return UOP_JNN;
    case 0x06: return UOP_JO;
    case 0x18: return UOP_MOV_RA_RN;
    case 0x19: return UOP_MOV_RB_RN;
    case 0x1A: return UOP_MOV_RN_RA;
    case 0x1B: return UOP_LDX;
    default: return UOP_NOP;
    }
}

static int address_bit_from_pin(uint8_t pin)
{
    static const uint8_t address_pins[] = {
        CPU8_AT28C64_PIN_A0, CPU8_AT28C64_PIN_A1, CPU8_AT28C64_PIN_A2,
        CPU8_AT28C64_PIN_A3, CPU8_AT28C64_PIN_A4, CPU8_AT28C64_PIN_A5,
        CPU8_AT28C64_PIN_A6, CPU8_AT28C64_PIN_A7, CPU8_AT28C64_PIN_A8,
        CPU8_AT28C64_PIN_A9, CPU8_AT28C64_PIN_A10, CPU8_AT28C64_PIN_A11,
        CPU8_AT28C64_PIN_A12};
    uint8_t bit;
    for (bit = 0; bit < sizeof(address_pins); bit++)
        if (address_pins[bit] == pin) return bit;
    return -1;
}

static bool address_signal_value(ControlEepromAddressSignal signal, uint8_t step,
                                 MicroOp uop, CpuFlags flags, CpuMode mode)
{
    switch (signal) {
    case CTRL_EEPROM_ADDR_USTEP_0: return (step & 0x01u) != 0;
    case CTRL_EEPROM_ADDR_USTEP_1: return (step & 0x02u) != 0;
    case CTRL_EEPROM_ADDR_USTEP_2: return (step & 0x04u) != 0;
    case CTRL_EEPROM_ADDR_IR_3: return ((uint8_t)uop & 0x01u) != 0;
    case CTRL_EEPROM_ADDR_IR_4: return ((uint8_t)uop & 0x02u) != 0;
    case CTRL_EEPROM_ADDR_IR_5: return ((uint8_t)uop & 0x04u) != 0;
    case CTRL_EEPROM_ADDR_IR_6: return ((uint8_t)uop & 0x08u) != 0;
    case CTRL_EEPROM_ADDR_IR_7: return ((uint8_t)uop & 0x10u) != 0;
    case CTRL_EEPROM_ADDR_FLAG_C: return flags.carry;
    case CTRL_EEPROM_ADDR_FLAG_Z: return flags.zero;
    case CTRL_EEPROM_ADDR_FLAG_N: return flags.negative;
    case CTRL_EEPROM_ADDR_FLAG_O: return flags.overflow;
    case CTRL_EEPROM_ADDR_BOOT_RUN:
        return mode == CPU_MODE_RUN ? CPU8_RUN_ADDRESS_LEVEL != 0
                                    : CPU8_BOOT_ADDRESS_LEVEL != 0;
    }
    return false;
}

uint16_t microcode_address(uint8_t step, MicroOp uop, CpuFlags flags,
                           CpuMode mode)
{
    uint16_t address = 0;
    size_t index;
    for (index = 0; index < CPU8_CONTROL_EEPROM_ADDRESS_CONFIG_COUNT; index++) {
        const ControlEepromAddressConfig *config =
            &CPU8_CONTROL_EEPROM_ADDRESS_CONFIGS[index];
        int bit = address_bit_from_pin(config->pin);
        if (bit >= 0 && address_signal_value(config->signal, step, uop, flags, mode))
            address |= (uint16_t)1u << bit;
    }
    return address;
}

ControlWord microcode_word(uint8_t step, MicroOp uop, CpuFlags flags,
                           CpuMode mode)
{
    if (mode != CPU_MODE_BOOT && mode != CPU_MODE_RUN)
    {
        return ADDRESS_NONE;
    }
    if (step >= CPU8_MICROSTEP_COUNT)
    {
        return ADDRESS_NONE;
    }

    /*
     * BOOT usa tre microstep per cella: T1 copia EPROM -> RAM con PC stabile;
     * T2 disabilita la scrittura, mantiene il dato EPROM valido e incrementa
     * PC; T3 azzera il sequencer mantenendo l'EPROM abilitata.
     * Il PC resta selezionato come sorgente dell'indirizzo. MDR non partecipa.
     */
    if (mode == CPU_MODE_BOOT)
    {
        if (step == 0)
            return ADDRESS_WORD(CPU8_ADDR_SEL_PC) |
                   CTRL_EPROM_OE | CTRL_RAM_WE;
        if (step == 1)
            return ADDRESS_WORD(CPU8_ADDR_SEL_PC) |
                   CTRL_EPROM_OE | CTRL_PC_INC;
        if (step == 2)
            return ADDRESS_WORD(CPU8_ADDR_SEL_PC) |
                   CTRL_EPROM_OE | CTRL_NEXT_FETCH;
        return ADDRESS_NONE;
    }

    /* T1 deve essere identico per ogni uOP: IR cambia solo a fine ciclo. */
    if (step == 0)
    {
        return FETCH;
    }

    /*
     * Il ritorno a T1 ha un microstep dedicato. Se NEXT_FETCH azzera
     * asincronamente il contatore, non deve troncare il ciclo che scrive
     * RAM/registri o aggiorna il PC. Anche con /LOAD sincrono, questa
     * separazione rende osservabili e verificabili i trasferimenti.
     */
    if ((step == 2 && (uop == UOP_INVALID || uop == UOP_NOP ||
                       uop == UOP_SYSTEM ||
                       uop == UOP_HLT ||
                       uop == UOP_ALU || uop == UOP_CMP ||
                       uop == UOP_MOV_RA_RN || uop == UOP_MOV_RB_RN ||
                       uop == UOP_MOV_RN_RA)) ||
        (step == 3 && (uop == UOP_LDI || uop == UOP_LDX ||
                       uop == UOP_LDA_IDX || uop == UOP_STA_IDX)) ||
        (step == 4 && is_jump(uop)) ||
        (step == 5 && (uop == UOP_LDA || uop == UOP_STA)))
        return ADDRESS_NONE | CTRL_NEXT_FETCH;

    /*
     * Ogni case e un microprogramma. Quando lo step non appartiene alla
     * sequenza, viene restituito ADDRESS_NONE: nessun trasferimento avviene e
     * nessuna memoria viene letta o scritta.
     */
    switch (uop)
    {
    case UOP_INVALID:
        return ADDRESS_NONE;
    case UOP_NOP:
        return ADDRESS_NONE;
    case UOP_SYSTEM:
        /* Solo RUN/T2 del gruppo IR[7:3]=00000: il pin fisico va a zero.
           La OR esterna con IR[2:0] distingue HLT=000 da NOP=001. */
        return step == 1 ? ADDRESS_NONE | CTRL_SYSTEM_STEP : ADDRESS_NONE;
    case UOP_HLT:
        /* L'arresto di IR=0x00 in RUN/T2 e affidato alla logica esterna.
           La ROM vede solo IR[7:3] e produce la sequenza comune al NOP. */
        return ADDRESS_NONE;
    case UOP_LDI:
        /* T2 legge l'immediato; T3 lo copia da MDR al registro IR[2:0]. */
        if (step == 1)
        {
            return ADDRESS_WORD(CPU8_ADDR_SEL_PC) |
                   CTRL_RAM_OE | CTRL_MDR_WE | CTRL_PC_INC;
        }
        return step == 2
                   ? ADDRESS_NONE | CTRL_MDR_OE | CTRL_RF_EN |
                         CTRL_RF_RW
                   : ADDRESS_NONE;
    case UOP_LDA:
        /* T2/T3 formano MAR, T4 legge il dato, T5 scrive il registro. */
        if (step == 1)
            return READ_ADDRESS_LOW;
        if (step == 2)
            return READ_ADDRESS_HIGH;
        if (step == 3)
            return ADDRESS_WORD(CPU8_ADDR_SEL_MAR) |
                   CTRL_RAM_OE | CTRL_MDR_WE;
        return step == 4
                   ? ADDRESS_NONE | CTRL_MDR_OE | CTRL_RF_EN |
                         CTRL_RF_RW
                   : ADDRESS_NONE;
    case UOP_STA:
        /* T2/T3 formano MAR, T4 salva Rn in MDR, T5 scrive la memoria. */
        if (step == 1)
            return READ_ADDRESS_LOW;
        if (step == 2)
            return READ_ADDRESS_HIGH;
        if (step == 3)
            return ADDRESS_NONE | CTRL_RF_EN | CTRL_MDR_WE;
        return step == 4
                   ? ADDRESS_WORD(CPU8_ADDR_SEL_MAR) |
                         CTRL_MDR_OE | CTRL_RAM_WE
                   : ADDRESS_NONE;
    case UOP_ALU:
        /* IR[3:0] sceglie l'operazione; la CU salva risultato e flag. */
        return step == 1
                   ? ADDRESS_NONE | CTRL_ALU_EN | CTRL_RA_EN | CTRL_RA_RB_RW |
                         CTRL_FLAGS_WE
                   : ADDRESS_NONE;
    case UOP_CMP:
        /* CMP aggiorna i flag ma non riporta il risultato in RA. */
        return step == 1
                   ? ADDRESS_NONE | CTRL_FLAGS_WE
                   : ADDRESS_NONE;
    case UOP_MOV_RA_RN:
        return step == 1
                   ? ADDRESS_NONE | CTRL_RF_EN | CTRL_RA_EN | CTRL_RA_RB_RW
                   : ADDRESS_NONE;
    case UOP_MOV_RB_RN:
        return step == 1
                   ? ADDRESS_NONE | CTRL_RF_EN | CTRL_RB_EN | CTRL_RA_RB_RW
                   : ADDRESS_NONE;
    case UOP_MOV_RN_RA:
        return step == 1
                   ? ADDRESS_NONE | CTRL_RA_EN | CTRL_RF_EN |
                         CTRL_RF_RW
                   : ADDRESS_NONE;
    case UOP_LDX:
        /* LDX addr16 carica IDX in little-endian dal flusso istruzioni. */
        if (step == 1)
            return ADDRESS_WORD(CPU8_ADDR_SEL_PC) |
                   CTRL_RAM_OE | CTRL_IDX_L_WE | CTRL_PC_INC;
        return step == 2
                   ? ADDRESS_WORD(CPU8_ADDR_SEL_PC) |
                         CTRL_RAM_OE | CTRL_IDX_H_WE | CTRL_PC_INC
                   : ADDRESS_NONE;
    case UOP_LDA_IDX:
        /* LDA Rn, [IDX]: IDX seleziona RAM, MDR conserva il dato. */
        if (step == 1)
            return ADDRESS_WORD(CPU8_ADDR_SEL_IDX) |
                   CTRL_RAM_OE | CTRL_MDR_WE;
        return step == 2
                   ? ADDRESS_NONE | CTRL_MDR_OE | CTRL_RF_EN |
                         CTRL_RF_RW
                   : ADDRESS_NONE;
    case UOP_STA_IDX:
        /* STA Rn, [IDX]: prima Rn -> MDR, poi MDR -> RAM selezionata da IDX. */
        if (step == 1)
            return ADDRESS_NONE | CTRL_RF_EN | CTRL_MDR_WE;
        return step == 2
                   ? ADDRESS_WORD(CPU8_ADDR_SEL_IDX) |
                         CTRL_MDR_OE | CTRL_RAM_WE
                   : ADDRESS_NONE;
    default:
        /* Tutti i salti condividono il fetch dell'indirizzo a 16 bit. */
        if (is_jump(uop))
        {
            if (step == 1)
                return READ_ADDRESS_LOW;
            if (step == 2)
                return READ_ADDRESS_HIGH;
            if (step == 3)
            {
                return ADDRESS_NONE |
                       (jump_is_taken(uop, flags) ? CTRL_PC_LOAD : 0);
            }
        }
        return ADDRESS_NONE;
    }
}

MicroOp dispatch_opcode(uint8_t opcode)
{
    /*
     * Raggruppa opcode con microsequenza identica. I bit che selezionano Rn o
     * l'operazione ALU arrivano direttamente ai rispettivi blocchi hardware.
     */
    if (opcode == 0x00)
        return UOP_HLT;
    if (opcode == 0x01)
        return UOP_NOP;
    if (opcode >= 0x20 && opcode <= 0x27)
        return UOP_LDI;
    if (opcode >= 0x40 && opcode <= 0x47)
        return UOP_LDA;
    if (opcode >= 0x48 && opcode <= 0x4f)
        return UOP_STA;
    if (opcode >= 0x50 && opcode <= 0x57)
        return UOP_LDA_IDX;
    if (opcode >= 0x58 && opcode <= 0x5f)
        return UOP_STA_IDX;
    if ((opcode >= 0x60 && opcode <= 0x67) || opcode == 0x78)
        return UOP_ALU;
    if (opcode == 0x69)
        return UOP_CMP;
    if (opcode >= 0xc0 && opcode <= 0xc7)
        return UOP_MOV_RA_RN;
    if (opcode >= 0xc8 && opcode <= 0xcf)
        return UOP_MOV_RB_RN;
    if (opcode >= 0xd0 && opcode <= 0xd7)
        return UOP_MOV_RN_RA;
    if (opcode == 0xd8)
        return UOP_LDX;

    /* I salti restano distinti perche ognuno interpreta i flag diversamente. */
    switch (opcode)
    {
    case 0xa0:
        return UOP_JMP;
    case 0xb0:
        return UOP_JZ;
    case 0xb8:
        return UOP_JNZ;
    case 0xe0:
        return UOP_JC;
    case 0xe8:
        return UOP_JNC;
    case 0xf0:
        return UOP_JN;
    case 0xf8:
        return UOP_JNN;
    case 0x30:
        return UOP_JO;
    case 0xa8:
        return UOP_JNO;
    default:
        return UOP_INVALID;
    }
}

const char *microop_name(MicroOp uop)
{
    /* L'indice dell'array coincide intenzionalmente con il valore di MicroOp. */
    static const char *const names[] = {
        "INVALID", "NOP", "HLT", "LDI", "LDA", "STA", "ALU", "CMP",
        "MOV_RA_RN", "MOV_RB_RN", "MOV_RN_RA", "LDX", "LDA_IDX",
        "STA_IDX", "JMP", "JZ", "JNZ",
        "JC", "JNC", "JN", "JNN", "JO", "JNO", "SYSTEM"};

    return (unsigned)uop < sizeof(names) / sizeof(names[0])
               ? names[uop]
               : "UNUSED";
}

bool validate_signal_config(char *message, size_t message_size)
{
    /*
     * used_bits rileva due segnali assegnati allo stesso pin fisico.
     * configured_signals rileva invece duplicati o segnali logici mancanti.
     */
    unsigned used_bits[3] = {0, 0, 0};
    ControlWord configured_signals = 0;
    const ControlWord valid_signals = (1u << CPU8_CONTROL_SIGNAL_COUNT) - 1u;
    const unsigned selectors[] = {
        CPU8_ADDR_SEL_IDX,
        CPU8_ADDR_SEL_PC,
        CPU8_ADDR_SEL_MAR,
        CPU8_ADDR_SEL_NONE};
    /* AT28C64 DIP-28: I/O0..I/O7 non sono numerati consecutivamente per GND. */
    static const uint8_t at28c64_data_pins[8] = {
        CPU8_AT28C64_PIN_IO0, CPU8_AT28C64_PIN_IO1,
        CPU8_AT28C64_PIN_IO2, CPU8_AT28C64_PIN_IO3,
        CPU8_AT28C64_PIN_IO4, CPU8_AT28C64_PIN_IO5,
        CPU8_AT28C64_PIN_IO6, CPU8_AT28C64_PIN_IO7};
    size_t index;
    size_t other;

    /* Tre EEPROM da 8 bit offrono al massimo 24 uscite. */
    if (CPU8_CONTROL_SIGNAL_COUNT > 24 ||
        CPU8_CONTROL_SIGNAL_CONFIG_COUNT != CPU8_CONTROL_SIGNAL_COUNT)
    {
        snprintf(message, message_size,
                 "numero di segnali configurati diverso da %u",
                 CPU8_CONTROL_SIGNAL_COUNT);
        return false;
    }

    /* Controlla ogni riga di config/control_signals.c. */
    for (index = 0; index < CPU8_CONTROL_SIGNAL_CONFIG_COUNT; index++)
    {
        const ControlSignalConfig *signal = &CPU8_CONTROL_SIGNAL_CONFIGS[index];
        ControlWord logical_mask = (ControlWord)signal->signal;
        unsigned mask;

        /* Un segnale valido deve contenere uno e un solo bit della ControlWord. */
        if (logical_mask == 0 ||
            (logical_mask & (logical_mask - 1u)) != 0 ||
            (logical_mask & ~valid_signals) != 0)
        {
            snprintf(message, message_size,
                     "%s non identifica un segnale logico valido", signal->name);
            return false;
        }
        if ((configured_signals & logical_mask) != 0)
        {
            snprintf(message, message_size,
                     "%s e configurato piu di una volta", signal->name);
            return false;
        }
        configured_signals |= logical_mask;

        if (signal->rom >= 3 || signal->bit >= 8)
        {
            snprintf(message, message_size,
                     "%s usa ROM o bit fuori intervallo", signal->name);
            return false;
        }
        if (signal->eeprom_pin != at28c64_data_pins[signal->bit])
        {
            snprintf(message, message_size,
                     "%s ha un pin AT28C64 non coerente con D%u", signal->name,
                     signal->bit);
            return false;
        }
        /* Trasforma D0..D7 in una maschera per la ROM selezionata. */
        mask = 1u << signal->bit;
        if ((used_bits[signal->rom] & mask) != 0)
        {
            snprintf(message, message_size,
                     "%s usa una uscita EEPROM gia assegnata", signal->name);
            return false;
        }
        used_bits[signal->rom] |= mask;

        if (signal->polarity != ACTIVE_HIGH && signal->polarity != ACTIVE_LOW)
        {
            snprintf(message, message_size,
                     "%s usa una polarita non valida", signal->name);
            return false;
        }
    }

    if (configured_signals != valid_signals)
    {
        snprintf(message, message_size,
                 "uno o piu segnali logici non sono configurati");
        return false;
    }

    /* I quattro codici del selettore devono coprire 00, 01, 10 e 11. */
    for (index = 0; index < sizeof(selectors) / sizeof(selectors[0]); index++)
    {
        if (selectors[index] > 3)
        {
            snprintf(message, message_size,
                     "codice del selettore indirizzi fuori intervallo");
            return false;
        }
        for (other = index + 1;
             other < sizeof(selectors) / sizeof(selectors[0]); other++)
        {
            if (selectors[index] == selectors[other])
            {
                snprintf(message, message_size,
                         "codici del selettore indirizzi duplicati");
                return false;
            }
        }
    }

    if (CPU8_BOOT_ADDRESS_LEVEL > 1 || CPU8_RUN_ADDRESS_LEVEL > 1 ||
        CPU8_BOOT_ADDRESS_LEVEL == CPU8_RUN_ADDRESS_LEVEL)
    {
        snprintf(message, message_size,
                 "livelli BOOT/RUN non validi o uguali");
        return false;
    }

    if (message_size > 0)
        message[0] = '\0';
    return true;
}

bool get_control_signal_config(ControlSignal signal, uint8_t *rom, uint8_t *bit,
                               bool *active_low)
{
    /*
     * Ricerca lineare: con soli 23 segnali e semplice e viene usata soprattutto
     * da test e diagnostica, quindi non serve una struttura piu complessa.
     */
    size_t index;

    for (index = 0; index < CPU8_CONTROL_SIGNAL_CONFIG_COUNT; index++)
    {
        const ControlSignalConfig *config = &CPU8_CONTROL_SIGNAL_CONFIGS[index];
        if (config->signal == signal)
        {
            if (rom != NULL)
                *rom = config->rom;
            if (bit != NULL)
                *bit = config->bit;
            if (active_low != NULL)
                *active_low = config->polarity == ACTIVE_LOW;
            return true;
        }
    }
    return false;
}

bool validate_control_word(ControlWord word, char *message, size_t message_size)
{
    /* Conta quante sorgenti tentano di pilotare contemporaneamente D[7:0]. */
    unsigned data_sources = 0;

    data_sources += (word & CTRL_RAM_OE) != 0;
    data_sources += (word & CTRL_EPROM_OE) != 0;
    data_sources += (word & CTRL_MDR_OE) != 0;
    /* RF_EN senza RF_RW mette il registro selezionato in lettura sul bus. */
    data_sources += ((word & CTRL_RF_EN) != 0 && (word & CTRL_RF_RW) == 0);
    /* RA_EN con RA_RB_RW=0 mette RA in lettura sul bus. */
    data_sources += ((word & CTRL_RA_EN) != 0 &&
                     (word & CTRL_RA_RB_RW) == 0);
    data_sources += (word & CTRL_ALU_EN) != 0;

    if (data_sources > 1)
    {
        snprintf(message, message_size, "piu sorgenti pilotano il data bus");
        return false;
    }
    if ((word & CTRL_RAM_OE) && (word & CTRL_RAM_WE))
    {
        snprintf(message, message_size, "RAM_OE e RAM_WE sono attivi insieme");
        return false;
    }
    if ((word & CTRL_RF_RW) && !(word & CTRL_RF_EN))
    {
        snprintf(message, message_size, "RF_RW richiede RF_EN");
        return false;
    }
    if ((word & CTRL_RA_RB_RW) &&
        !(word & (CTRL_RA_EN | CTRL_RB_EN)))
    {
        snprintf(message, message_size, "RA_RB_RW richiede RA_EN o RB_EN");
        return false;
    }

    if (message_size > 0)
        message[0] = '\0';
    return true;
}

void encode_control_word(ControlWord word, uint8_t bytes[3])
{
    size_t index;

    /* Si parte da tre byte vuoti e si imposta ogni uscita configurata. */
    bytes[0] = 0;
    bytes[1] = 0;
    bytes[2] = 0;

    for (index = 0; index < CPU8_CONTROL_SIGNAL_CONFIG_COUNT; index++)
    {
        const ControlSignalConfig *signal = &CPU8_CONTROL_SIGNAL_CONFIGS[index];
        /*
         * active descrive la funzione logica; physical_high e il valore 0/1
         * realmente scritto nel file, eventualmente invertito da ACTIVE_LOW.
         */
        bool active = (word & (ControlWord)signal->signal) != 0;
        bool physical_high = signal->polarity == ACTIVE_LOW ? !active : active;

        if (physical_high)
            bytes[signal->rom] |= (uint8_t)(1u << signal->bit);
    }
}

bool build_control_roms(uint8_t roms[3][CPU8_CONTROL_ROM_SIZE],
                        char *message, size_t message_size)
{
    unsigned mode_value;
    unsigned flags_value;
    unsigned uop;
    unsigned step;

    /* Non generare immagini se la piedinatura configurata e ambigua. */
    if (!validate_signal_config(message, message_size))
        return false;

    /*
     * Visita l'intero spazio degli indirizzi:
     * 2 modi x 16 flag x 32 uOP x 8 step = 8192 celle.
     */
    for (mode_value = CPU_MODE_BOOT; mode_value <= CPU_MODE_RUN; mode_value++)
    {
        for (flags_value = 0; flags_value < 16; flags_value++)
        {
            CpuFlags flags = {
                (flags_value & 1u) != 0,
                (flags_value & 2u) != 0,
                (flags_value & 4u) != 0,
                (flags_value & 8u) != 0};
            for (uop = 0; uop < CPU8_UOP_COUNT; uop++)
            {
                for (step = 0; step < CPU8_MICROSTEP_COUNT; step++)
                {
                    CpuMode mode = (CpuMode)mode_value;
                    ControlWord word = microcode_word((uint8_t)step,
                                                      microop_for_ir_group((uint8_t)uop),
                                                      flags, mode);
                    uint16_t address;
                    uint8_t bytes[3];

                    /* Ogni microistruzione viene controllata prima di salvarla. */
                    if (!validate_control_word(word, message, message_size))
                    {
                        return false;
                    }

                    address = microcode_address((uint8_t)step, (MicroOp)uop,
                                                flags, mode);
                    /* La stessa parola logica diventa un byte per ciascuna ROM. */
                    encode_control_word(word, bytes);
                    roms[0][address] = bytes[0];
                    roms[1][address] = bytes[1];
                    roms[2][address] = bytes[2];
                }
            }
        }
    }
    return true;
}

void build_dispatch_rom(uint8_t rom[CPU8_DISPATCH_ROM_SIZE])
{
    /*
     * Solo A0..A7 dipendono da IR. Il cast a uint8_t replica la stessa tabella
     * di 256 opcode per tutte le combinazioni inutilizzate di A8..A12.
     */
    size_t address;
    for (address = 0; address < CPU8_DISPATCH_ROM_SIZE; address++)
    {
        rom[address] = (uint8_t)dispatch_opcode((uint8_t)address);
    }
}
