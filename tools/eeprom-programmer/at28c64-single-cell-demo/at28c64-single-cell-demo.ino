/*
 * Minimal AT28C64 single-cell read/write test for Arduino Mega.
 *
 * Tests only address 0000 with a few byte patterns.
 *
 * Important AT28C64B PDIP-28 pins:
 *   pin 20 CE -> Arduino Mega 43
 *   pin 22 OE -> Arduino Mega 44
 *   pin 27 WE -> Arduino Mega 45
 *   pin 26 NC -> not connected
 */

#include <Arduino.h>

static const uint8_t ADDRESS_PINS[13] = {
    22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34
};

static const uint8_t DATA_PINS[8] = {
    35, 36, 37, 38, 39, 40, 41, 42
};

static const uint8_t PIN_CE = 43;
static const uint8_t PIN_OE = 44;
static const uint8_t PIN_WE = 45;

static const uint16_t TEST_ADDRESS = 0x0000;
static const uint8_t TEST_VALUES[] = {
    0b00000000,
    0b11111111,
    0b10101010,
    0b01010101,
    0b00100000
};

static void printHexByte(uint8_t value)
{
    if (value < 0x10) {
        Serial.print('0');
    }
    Serial.print(value, HEX);
}

static void printHexAddress(uint16_t value)
{
    if (value < 0x1000) {
        Serial.print('0');
    }
    if (value < 0x0100) {
        Serial.print('0');
    }
    if (value < 0x0010) {
        Serial.print('0');
    }
    Serial.print(value, HEX);
}

static void printBinaryByte(uint8_t value)
{
    for (int8_t bit = 7; bit >= 0; bit--) {
        Serial.print((value & (1U << bit)) ? '1' : '0');
    }
}

static void setAddress(uint16_t address)
{
    for (uint8_t bit = 0; bit < 13; bit++) {
        digitalWrite(ADDRESS_PINS[bit], (address & (1U << bit)) ? HIGH : LOW);
    }
}

static void setDataInput()
{
    for (uint8_t bit = 0; bit < 8; bit++) {
        pinMode(DATA_PINS[bit], INPUT);
    }
}

static void setDataOutput()
{
    for (uint8_t bit = 0; bit < 8; bit++) {
        pinMode(DATA_PINS[bit], OUTPUT);
    }
}

static void writeData(uint8_t value)
{
    for (uint8_t bit = 0; bit < 8; bit++) {
        digitalWrite(DATA_PINS[bit], (value & (1U << bit)) ? HIGH : LOW);
    }
}

static uint8_t readData()
{
    uint8_t value = 0;

    for (uint8_t bit = 0; bit < 8; bit++) {
        if (digitalRead(DATA_PINS[bit]) == HIGH) {
            value |= (uint8_t)(1U << bit);
        }
    }

    return value;
}

/*
 * Carica un byte nel registro interno di write della EEPROM.
 *
 * Questa funzione NON aspetta il completamento della programmazione interna:
 * genera solo il ciclo elettrico di scrittura.
 *
 * Sequenza teorica:
 *   1. indirizzo stabile su A0..A12;
 *   2. dati stabili su I/O0..I/O7;
 *   3. OE alto, cosi la EEPROM non pilota il bus dati;
 *   4. CE basso, chip selezionato;
 *   5. impulso basso su WE;
 *   6. WE torna alto e il byte viene acquisito dalla EEPROM.
 *
 * La stessa funzione viene usata sia per una scrittura normale sia per i byte
 * comando della Software Data Protection.
 */
static void loadByte(uint16_t address, uint8_t value)
{
    setAddress(address);
    setDataOutput();
    writeData(value);

    digitalWrite(PIN_OE, HIGH);
    digitalWrite(PIN_CE, LOW);

    digitalWrite(PIN_WE, LOW);
    delayMicroseconds(10);
    digitalWrite(PIN_WE, HIGH);

    digitalWrite(PIN_CE, HIGH);
}

/*
 * Modalita lettura.
 *
 * In lettura il bus dati deve essere lasciato alla EEPROM, quindi i pin dati
 * dell'Arduino sono INPUT.
 *
 * Stati dei segnali:
 *   CE = LOW   chip selezionato
 *   OE = LOW   uscite dati abilitate
 *   WE = HIGH  nessuna scrittura
 */
static uint8_t readByte(uint16_t address)
{
    setDataInput();
    setAddress(address);

    digitalWrite(PIN_WE, HIGH);
    digitalWrite(PIN_CE, LOW);
    digitalWrite(PIN_OE, LOW);
    delayMicroseconds(2);

    uint8_t value = readData();

    digitalWrite(PIN_OE, HIGH);
    digitalWrite(PIN_CE, HIGH);

    return value;
}

/*
 * Modalita scrittura normale.
 *
 * Si usa quando la EEPROM non ha la Software Data Protection attiva.
 * Dopo il ciclo elettrico di scrittura aspettiamo 20 ms, piu del massimo
 * tipico di 10 ms indicato per il ciclo interno della AT28C64B.
 */
static void writeByte(uint16_t address, uint8_t value)
{
    loadByte(address, value);
    delay(20);
    setDataInput();
}

/*
 * Modalita scrittura protetta.
 *
 * Serve quando la Software Data Protection e attiva. Prima del byte reale
 * bisogna inviare tre byte comando agli indirizzi speciali del datasheet:
 *
 *   0xAA -> 0x1555
 *   0x55 -> 0x0AAA
 *   0xA0 -> 0x1555
 *
 * Subito dopo si invia il byte reale all'indirizzo reale.
 * Questi quattro cicli devono essere vicini nel tempo, quindi qui non mettiamo
 * delay(20) tra un loadByte e il successivo.
 */
static void writeByteProtected(uint16_t address, uint8_t value)
{
    loadByte(0x1555, 0xAA);
    loadByte(0x0AAA, 0x55);
    loadByte(0x1555, 0xA0);
    loadByte(address, value);
    delay(20);
    setDataInput();
}

/*
 * Modalita disabilitazione Software Data Protection.
 *
 * Questa sequenza serve a riportare la EEPROM in modalita di scrittura normale,
 * se la protezione software era stata abilitata in precedenza.
 *
 * Anche qui i byte comando devono essere caricati in sequenza ravvicinata.
 * Dopo la sequenza aspettiamo il ciclo interno prima di fare altre operazioni.
 */
static void disableSoftwareDataProtection()
{
    loadByte(0x1555, 0xAA);
    loadByte(0x0AAA, 0x55);
    loadByte(0x1555, 0x80);
    loadByte(0x1555, 0xAA);
    loadByte(0x0AAA, 0x55);
    loadByte(0x1555, 0x20);
    delay(20);
    setDataInput();
}

static void printRead(uint16_t address)
{
    uint8_t value = readByte(address);

    Serial.print(F("READ "));
    printHexAddress(address);
    Serial.print(F(" = 0b"));
    printBinaryByte(value);
    Serial.print(F(" / 0x"));
    printHexByte(value);
    Serial.println();
}

static bool runWriteTest(const __FlashStringHelper *label, uint8_t expected, bool protectedWrite)
{
    Serial.print(label);
    Serial.print(F(" WRITE "));
    printHexAddress(TEST_ADDRESS);
    Serial.print(F(" = 0b"));
    printBinaryByte(expected);
    Serial.print(F(" / 0x"));
    printHexByte(expected);
    Serial.println();

    if (protectedWrite) {
        writeByteProtected(TEST_ADDRESS, expected);
    } else {
        writeByte(TEST_ADDRESS, expected);
    }

    uint8_t actual = readByte(TEST_ADDRESS);

    Serial.print(label);
    Serial.print(F(" VERIFY expected "));
    Serial.print(F("0b"));
    printBinaryByte(expected);
    Serial.print(F(" / 0x"));
    printHexByte(expected);
    Serial.print(F(" got "));
    Serial.print(F("0b"));
    printBinaryByte(actual);
    Serial.print(F(" / 0x"));
    printHexByte(actual);
    Serial.print(F(" -> "));
    Serial.println(actual == expected ? F("OK") : F("ERR"));

    return actual == expected;
}

void setup()
{
    Serial.begin(115200);
    delay(1000);

    for (uint8_t bit = 0; bit < 13; bit++) {
        pinMode(ADDRESS_PINS[bit], OUTPUT);
        digitalWrite(ADDRESS_PINS[bit], LOW);
    }

    setDataInput();

    pinMode(PIN_CE, OUTPUT);
    pinMode(PIN_OE, OUTPUT);
    pinMode(PIN_WE, OUTPUT);

    digitalWrite(PIN_CE, HIGH);
    digitalWrite(PIN_OE, HIGH);
    digitalWrite(PIN_WE, HIGH);

    Serial.println(F("AT28C64 single-cell test"));
    Serial.println(F("Check wiring: EEPROM WE pin 27 -> Arduino Mega 45"));
    printRead(TEST_ADDRESS);

    /*
     * Test 1: scrittura normale.
     * Se questa sezione funziona, il circuito base e corretto e la EEPROM
     * accetta normali byte write.
     */
    Serial.println(F("--- Normal byte writes ---"));
    for (uint8_t i = 0; i < sizeof(TEST_VALUES); i++) {
        runWriteTest(F("NORMAL"), TEST_VALUES[i], false);
    }

    /*
     * Test 2: scrittura protetta.
     * Questa sezione verifica anche la sequenza AA/55/A0 richiesta dal
     * datasheet per scrivere quando la Software Data Protection e attiva.
     */
    Serial.println(F("--- Software protected writes ---"));
    for (uint8_t i = 0; i < sizeof(TEST_VALUES); i++) {
        runWriteTest(F("PROTECTED"), TEST_VALUES[i], true);
    }

    /*
     * Test 3: disable della Software Data Protection.
     * Dopo la sequenza di disable, riproviamo normali byte write.
     */
    Serial.println(F("--- Disable Software Data Protection, then normal writes ---"));
    disableSoftwareDataProtection();
    for (uint8_t i = 0; i < sizeof(TEST_VALUES); i++) {
        runWriteTest(F("AFTER DISABLE"), TEST_VALUES[i], false);
    }

    Serial.println(F("Done"));
}

void loop()
{
}
