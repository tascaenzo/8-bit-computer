#include "../include/EepromBus.h"
#include "../include/ProgrammerConfig.h"

static void setAddress(uint16_t address)
{
    /*
     * Scrive l'indirizzo sui pin A0..A12.
     * ADDRESS_PINS[bit] e collegato alla linea di indirizzo con lo stesso bit.
     */
    for (uint8_t bit = 0; bit < 13; bit++) {
        digitalWrite(ADDRESS_PINS[bit], (address & (1U << bit)) ? HIGH : LOW);
    }
}

static void setDataBusInput()
{
    /* In lettura il bus dati deve essere pilotato dalla EEPROM, non da Arduino. */
    for (uint8_t bit = 0; bit < 8; bit++) {
        pinMode(DATA_PINS[bit], INPUT);
    }
}

static void setDataBusOutput()
{
    /* In scrittura Arduino deve pilotare I/O0..I/O7 con il byte da salvare. */
    for (uint8_t bit = 0; bit < 8; bit++) {
        pinMode(DATA_PINS[bit], OUTPUT);
    }
}

static void writeDataBus(uint8_t value)
{
    for (uint8_t bit = 0; bit < 8; bit++) {
        digitalWrite(DATA_PINS[bit], (value & (1U << bit)) ? HIGH : LOW);
    }
}

static uint8_t readDataBus()
{
    uint8_t value = 0;

    for (uint8_t bit = 0; bit < 8; bit++) {
        if (digitalRead(DATA_PINS[bit]) == HIGH) {
            value |= (uint8_t)(1U << bit);
        }
    }

    return value;
}

static bool waitForWriteComplete(uint16_t address, uint8_t expected)
{
    uint32_t start = millis();

    /*
     * Data polling: durante il ciclo interno di scrittura I/O7 restituisce il
     * complemento del bit 7 scritto. Quando I/O7 torna uguale al valore atteso,
     * la EEPROM ha completato la programmazione del byte.
     */
    setDataBusInput();
    setAddress(address);

    while ((uint32_t)(millis() - start) < WRITE_TIMEOUT_MS) {
        digitalWrite(PIN_CE, LOW);
        digitalWrite(PIN_WE, HIGH);
        digitalWrite(PIN_OE, LOW);
        delayMicroseconds(READ_SETTLE_US);

        uint8_t value = readDataBus();

        digitalWrite(PIN_OE, HIGH);
        digitalWrite(PIN_CE, HIGH);

        if ((value & 0x80) == (expected & 0x80)) {
            return true;
        }
    }

    return false;
}

void eepromBusBegin()
{
    /* Stato iniziale: indirizzo zero, bus dati in alta impedenza, chip spento. */
    for (uint8_t bit = 0; bit < 13; bit++) {
        pinMode(ADDRESS_PINS[bit], OUTPUT);
        digitalWrite(ADDRESS_PINS[bit], LOW);
    }

    setDataBusInput();

    pinMode(PIN_CE, OUTPUT);
    pinMode(PIN_OE, OUTPUT);
    pinMode(PIN_WE, OUTPUT);

    digitalWrite(PIN_CE, HIGH);
    digitalWrite(PIN_OE, HIGH);
    digitalWrite(PIN_WE, HIGH);
}

uint8_t eepromReadByte(uint16_t address)
{
    /* Ciclo di lettura: CE=0, OE=0, WE=1. */
    setDataBusInput();
    setAddress(address);

    digitalWrite(PIN_CE, LOW);
    digitalWrite(PIN_WE, HIGH);
    digitalWrite(PIN_OE, LOW);
    delayMicroseconds(READ_SETTLE_US);

    uint8_t value = readDataBus();

    digitalWrite(PIN_OE, HIGH);
    digitalWrite(PIN_CE, HIGH);

    return value;
}

bool eepromWriteByte(uint16_t address, uint8_t value)
{
    /*
     * Ciclo di scrittura byte: indirizzo e dati stabili, OE alto, poi impulso
     * basso su WE. Dopo il fronte di risalita la EEPROM programma internamente.
     */
    setAddress(address);
    setDataBusOutput();
    writeDataBus(value);

    digitalWrite(PIN_OE, HIGH);
    digitalWrite(PIN_CE, LOW);

    digitalWrite(PIN_WE, LOW);
    delayMicroseconds(WRITE_PULSE_US);
    digitalWrite(PIN_WE, HIGH);

    digitalWrite(PIN_CE, HIGH);

    return waitForWriteComplete(address, value);
}
