#include "../include/SerialCommands.h"

#include <Arduino.h>

#include <ctype.h>
#include <string.h>

#include "../include/EepromBus.h"
#include "../include/ProgrammerConfig.h"

static char lineBuffer[SERIAL_LINE_BUFFER_SIZE];
static uint8_t lineLength = 0;
static bool protectedHexWrites = false;

static uint16_t crc16Update(uint16_t crc, uint8_t value)
{
    crc ^= (uint16_t)value << 8;
    for (uint8_t bit = 0; bit < 8; bit++) {
        crc = (crc & 0x8000) ? (uint16_t)((crc << 1) ^ 0x1021) : (uint16_t)(crc << 1);
    }
    return crc;
}

static uint16_t crc16Block(uint16_t address, const uint8_t *data, uint16_t count)
{
    uint16_t crc = 0xFFFF;
    crc = crc16Update(crc, (uint8_t)(address >> 8));
    crc = crc16Update(crc, (uint8_t)address);
    crc = crc16Update(crc, (uint8_t)(count >> 8));
    crc = crc16Update(crc, (uint8_t)count);
    for (uint16_t index = 0; index < count; index++) {
        crc = crc16Update(crc, data[index]);
    }
    return crc;
}

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

static char *skipSpaces(char *text)
{
    while (*text == ' ' || *text == '\t') {
        text++;
    }

    return text;
}

static bool parseNumber(char **cursor, uint16_t *value)
{
    /*
     * I numeri senza prefisso sono esadecimali: "00FF" e "0x00FF".
     * Il prefisso "0b" seleziona il binario: "0b10100110".
     */
    char *text = skipSpaces(*cursor);
    uint16_t result = 0;
    uint8_t digits = 0;
    uint8_t base = 16;

    if (text[0] == '0' && (text[1] == 'x' || text[1] == 'X')) {
        text += 2;
    } else if (text[0] == '0' && (text[1] == 'b' || text[1] == 'B')) {
        base = 2;
        text += 2;
    }

    while (true) {
        char ch = *text;
        uint8_t nibble;

        if (ch >= '0' && ch <= '1') {
            nibble = (uint8_t)(ch - '0');
        } else if (base == 16 && ch >= '2' && ch <= '9') {
            nibble = (uint8_t)(ch - '0');
        } else if (base == 16 && ch >= 'a' && ch <= 'f') {
            nibble = (uint8_t)(ch - 'a' + 10);
        } else if (base == 16 && ch >= 'A' && ch <= 'F') {
            nibble = (uint8_t)(ch - 'A' + 10);
        } else {
            break;
        }

        result = (uint16_t)(result * base + nibble);
        digits++;
        text++;
    }

    if (digits == 0) {
        return false;
    }

    *value = result;
    *cursor = text;
    return true;
}

static bool validateAddress(uint16_t address)
{
    if (address >= EEPROM_SIZE) {
        Serial.println(F("ERR address outside AT28C64 range 0000-1FFF"));
        return false;
    }

    return true;
}

static bool validateByte(uint16_t value)
{
    if (value > 0xFF) {
        Serial.println(F("ERR byte value must be 00-FF"));
        return false;
    }

    return true;
}

static bool parseHexBytes(char *cursor, uint8_t count, uint8_t *data)
{
    cursor = skipSpaces(cursor);
    if (strlen(cursor) != (size_t)count * 2U) {
        return false;
    }
    for (uint8_t index = 0; index < count; index++) {
        char pair[3] = { cursor[index * 2], cursor[index * 2 + 1], '\0' };
        char *pairCursor = pair;
        uint16_t value;
        if (!parseNumber(&pairCursor, &value) || *pairCursor != '\0' || value > 0xFF) {
            return false;
        }
        data[index] = (uint8_t)value;
    }
    return true;
}

static void commandBlockWrite(char *cursor)
{
    uint16_t address;
    uint16_t count;
    uint16_t expectedCrc;
    uint8_t data[UPLOAD_BLOCK_MAX_BYTES];

    if (!parseNumber(&cursor, &address) || !parseNumber(&cursor, &count) ||
        !parseNumber(&cursor, &expectedCrc) || count == 0 || count > UPLOAD_BLOCK_MAX_BYTES ||
        (uint32_t)address + count > EEPROM_SIZE || !parseHexBytes(cursor, (uint8_t)count, data)) {
        Serial.println(F("ERR B usage: B addr count crc16 hexbytes"));
        return;
    }
    uint16_t actualCrc = crc16Block(address, data, count);
    if (actualCrc != expectedCrc) {
        Serial.println(F("ERR B crc"));
        return;
    }
    for (uint8_t index = 0; index < count; index++) {
        uint16_t target = (uint16_t)(address + index);
        if (protectedHexWrites) eepromWriteByteProtected(target, data[index]);
        else eepromWriteByte(target, data[index]);
        if (eepromReadByte(target) != data[index]) {
            Serial.print(F("ERR B verify "));
            printHexAddress(target);
            Serial.print(F(" expected "));
            printHexByte(data[index]);
            Serial.print(F(" got "));
            printHexByte(eepromReadByte(target));
            Serial.println();
            return;
        }
    }
    Serial.print(F("OK B "));
    printHexAddress(address);
    Serial.print(' ');
    printHexAddress((uint16_t)count);
    Serial.print(F(" CRC "));
    printHexAddress(actualCrc);
    Serial.println();
}

static void commandCrc(char *cursor)
{
    uint16_t address;
    uint16_t count;
    uint16_t expectedCrc;
    if (!parseNumber(&cursor, &address) || !parseNumber(&cursor, &count) ||
        !parseNumber(&cursor, &expectedCrc) || count == 0 ||
        (uint32_t)address + count > EEPROM_SIZE) {
        Serial.println(F("ERR C usage: C addr count crc16"));
        return;
    }
    uint16_t crc = 0xFFFF;
    crc = crc16Update(crc, (uint8_t)(address >> 8));
    crc = crc16Update(crc, (uint8_t)address);
    crc = crc16Update(crc, (uint8_t)(count >> 8));
    crc = crc16Update(crc, (uint8_t)count);
    for (uint16_t index = 0; index < count; index++) crc = crc16Update(crc, eepromReadByte(address + index));
    if (crc != expectedCrc) {
        Serial.println(F("ERR C crc"));
        return;
    }
    Serial.println(F("OK C"));
}

static bool equalsIgnoreCase(const char *left, const char *right)
{
    while (*left != '\0' && *right != '\0') {
        if (toupper(*left) != toupper(*right)) {
            return false;
        }
        left++;
        right++;
    }

    return *left == '\0' && *right == '\0';
}

static void commandWrite(uint16_t address, uint8_t value, bool protectedWrite)
{
    /*
     * Ogni scrittura viene verificata subito rileggendo lo stesso indirizzo.
     * Questo rende il programmatore piu lento ma molto piu utile in didattica.
     */
    if (!validateAddress(address)) {
        return;
    }

    if (protectedWrite) {
        eepromWriteByteProtected(address, value);
    } else {
        eepromWriteByte(address, value);
    }

    uint8_t readBack = eepromReadByte(address);
    if (readBack != value) {
        Serial.print(F("ERR verify at "));
        printHexAddress(address);
        Serial.print(F(" expected "));
        printHexByte(value);
        Serial.print(F(" got "));
        printHexByte(readBack);
        Serial.println();
        return;
    }

    Serial.print(F("OK "));
    printHexAddress(address);
    Serial.print(F(": "));
    printHexByte(value);
    Serial.println();
}

static void commandRead(uint16_t address)
{
    if (!validateAddress(address)) {
        return;
    }

    Serial.print(F("OK "));
    printHexAddress(address);
    Serial.print(F(": "));
    printHexByte(eepromReadByte(address));
    Serial.println();
}

static void commandDump(uint16_t start, uint16_t count)
{
    /* Dump lineare: stampa lo stesso formato addr: byte prodotto da cpu8asm. */
    if (!validateAddress(start)) {
        return;
    }

    for (uint16_t offset = 0; offset < count; offset++) {
        uint16_t address = (uint16_t)(start + offset);

        if (address >= EEPROM_SIZE) {
            break;
        }

        printHexAddress(address);
        Serial.print(F(": "));
        printHexByte(eepromReadByte(address));
        Serial.println();
    }
}

static void commandFill(uint16_t start, uint16_t end, uint8_t value)
{
    if (!validateAddress(start) || !validateAddress(end)) {
        return;
    }

    if (end < start) {
        Serial.println(F("ERR end address before start address"));
        return;
    }

    for (uint16_t address = start; address <= end; address++) {
        eepromWriteByte(address, value);

        uint8_t readBack = eepromReadByte(address);
        if (readBack != value) {
            Serial.print(F("ERR verify at "));
            printHexAddress(address);
            Serial.print(F(" expected "));
            printHexByte(value);
            Serial.print(F(" got "));
            printHexByte(readBack);
            Serial.println();
            return;
        }
    }

    Serial.println(F("OK fill complete"));
}

void serialCommandsPrintHelp()
{
    Serial.println(F("Comandi programmatore AT28C64:"));
    Serial.println(F("  Numeri: esadecimali oppure binari con prefisso 0b."));
    Serial.println(F("  Esempio binario: W 0b0 0b10100110"));
    Serial.println(F("  0000: 20          scrive una riga .hex di cpu8asm"));
    Serial.println(F("  W 0000 20         scrive il byte 20 all'indirizzo 0000"));
    Serial.println(F("  P 0000 20         scrittura con protezione software"));
    Serial.println(F("  M W               righe .hex: scrittura normale"));
    Serial.println(F("  M P               righe .hex: scrittura protetta"));
    Serial.println(F("  R 0000            legge un byte"));
    Serial.println(F("  D 0000 0010       legge 0010 byte da 0000"));
    Serial.println(F("  F 0000 00FF FF    riempie 0000-00FF con FF"));
    Serial.println(F("  B addr n crc data blocco CRC-16, ACK dopo scrittura e verifica"));
    Serial.println(F("  C addr n crc      verifica CRC-16 di un intervallo EEPROM"));
    Serial.println(F("  HELP oppure ?      mostra questo aiuto"));
}

static void handleCpu8HexLine(char *line)
{
    /*
     * Formato generato da cpu8asm:
     *   0000: 20
     * La parte a sinistra e l'indirizzo, quella a destra il byte da scrivere.
     */
    char *cursor = line;
    uint16_t address;
    uint16_t value;

    if (!parseNumber(&cursor, &address)) {
        Serial.println(F("ERR expected address"));
        return;
    }

    cursor = skipSpaces(cursor);
    if (*cursor != ':') {
        Serial.println(F("ERR expected ':'"));
        return;
    }
    cursor++;

    if (!parseNumber(&cursor, &value) || !validateByte(value)) {
        return;
    }

    commandWrite(address, (uint8_t)value, protectedHexWrites);
}

static void handleCommand(char *line)
{
    /*
     * Se la riga contiene ':' la trattiamo come dump cpu8asm.
     * Altrimenti il primo carattere seleziona il comando manuale.
     */
    char *cursor = skipSpaces(line);
    uint16_t a;
    uint16_t b;
    uint16_t c;

    if (*cursor == '\0' || *cursor == ';' || *cursor == '#') {
        return;
    }

    if (strchr(cursor, ':') != NULL) {
        handleCpu8HexLine(cursor);
        return;
    }

    if (equalsIgnoreCase(cursor, "HELP") || strcmp(cursor, "?") == 0) {
        serialCommandsPrintHelp();
        return;
    }

    char command = (char)toupper(*cursor);
    cursor++;

    switch (command) {
        case 'W':
            if (!parseNumber(&cursor, &a) || !parseNumber(&cursor, &b) || !validateByte(b)) {
                Serial.println(F("ERR usage: W addr byte"));
                return;
            }
            commandWrite(a, (uint8_t)b, false);
            return;

        case 'P':
            if (!parseNumber(&cursor, &a) || !parseNumber(&cursor, &b) || !validateByte(b)) {
                Serial.println(F("ERR usage: P addr byte"));
                return;
            }
            commandWrite(a, (uint8_t)b, true);
            return;

        case 'M': {
            char mode = (char)toupper(*skipSpaces(cursor));
            if (mode == 'W') {
                protectedHexWrites = false;
                Serial.println(F("OK hex write mode normal"));
                return;
            }
            if (mode == 'P') {
                protectedHexWrites = true;
                Serial.println(F("OK hex write mode protected"));
                return;
            }
            Serial.println(F("ERR usage: M W|P"));
            return;
        }

        case 'R':
            if (!parseNumber(&cursor, &a)) {
                Serial.println(F("ERR usage: R addr"));
                return;
            }
            commandRead(a);
            return;

        case 'D':
            if (!parseNumber(&cursor, &a) || !parseNumber(&cursor, &b)) {
                Serial.println(F("ERR usage: D start count"));
                return;
            }
            commandDump(a, b);
            return;

        case 'F':
            if (!parseNumber(&cursor, &a) || !parseNumber(&cursor, &b) ||
                !parseNumber(&cursor, &c) || !validateByte(c)) {
                Serial.println(F("ERR usage: F start end byte"));
                return;
            }
            commandFill(a, b, (uint8_t)c);
            return;

        case 'B':
            commandBlockWrite(cursor);
            return;

        case 'C':
            commandCrc(cursor);
            return;

        default:
            Serial.println(F("ERR unknown command; type HELP"));
            return;
    }
}

void serialCommandsHandleInput()
{
    while (Serial.available() > 0) {
        char ch = (char)Serial.read();

        if (ch == '\r') {
            continue;
        }

        if (ch == '\n') {
            lineBuffer[lineLength] = '\0';
            handleCommand(lineBuffer);
            lineLength = 0;
            return;
        }

        if (lineLength < sizeof(lineBuffer) - 1) {
            lineBuffer[lineLength++] = ch;
        } else {
            lineLength = 0;
            Serial.println(F("ERR line too long"));
        }
    }
}
