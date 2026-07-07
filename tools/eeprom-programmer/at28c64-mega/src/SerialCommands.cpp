#include "../include/SerialCommands.h"

#include <Arduino.h>

#include <ctype.h>
#include <string.h>

#include "../include/EepromBus.h"
#include "../include/ProgrammerConfig.h"

static char lineBuffer[SERIAL_LINE_BUFFER_SIZE];
static uint8_t lineLength = 0;

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

static bool parseHexValue(char **cursor, uint16_t *value)
{
    /*
     * Parser minimale per numeri esadecimali.
     * Accetta sia "00FF" sia "0x00FF", cosi i comandi seriali restano comodi.
     */
    char *text = skipSpaces(*cursor);
    uint16_t result = 0;
    uint8_t digits = 0;

    if (text[0] == '0' && (text[1] == 'x' || text[1] == 'X')) {
        text += 2;
    }

    while (true) {
        char ch = *text;
        uint8_t nibble;

        if (ch >= '0' && ch <= '9') {
            nibble = (uint8_t)(ch - '0');
        } else if (ch >= 'a' && ch <= 'f') {
            nibble = (uint8_t)(ch - 'a' + 10);
        } else if (ch >= 'A' && ch <= 'F') {
            nibble = (uint8_t)(ch - 'A' + 10);
        } else {
            break;
        }

        result = (uint16_t)((result << 4) | nibble);
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

static void commandWrite(uint16_t address, uint8_t value)
{
    /*
     * Ogni scrittura viene verificata subito rileggendo lo stesso indirizzo.
     * Questo rende il programmatore piu lento ma molto piu utile in didattica.
     */
    if (!validateAddress(address)) {
        return;
    }

    if (!eepromWriteByte(address, value)) {
        Serial.print(F("ERR write timeout at "));
        printHexAddress(address);
        Serial.println();
        return;
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
        if (!eepromWriteByte(address, value)) {
            Serial.print(F("ERR write timeout at "));
            printHexAddress(address);
            Serial.println();
            return;
        }
    }

    Serial.println(F("OK fill complete"));
}

void serialCommandsPrintHelp()
{
    Serial.println(F("AT28C64 programmer commands:"));
    Serial.println(F("  0000: 20          write cpu8asm .hex line"));
    Serial.println(F("  W 0000 20         write byte"));
    Serial.println(F("  R 0000            read byte"));
    Serial.println(F("  D 0000 0010       dump count bytes"));
    Serial.println(F("  F 0000 00FF FF    fill inclusive range"));
    Serial.println(F("  HELP              show this help"));
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

    if (!parseHexValue(&cursor, &address)) {
        Serial.println(F("ERR expected address"));
        return;
    }

    cursor = skipSpaces(cursor);
    if (*cursor != ':') {
        Serial.println(F("ERR expected ':'"));
        return;
    }
    cursor++;

    if (!parseHexValue(&cursor, &value) || !validateByte(value)) {
        return;
    }

    commandWrite(address, (uint8_t)value);
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
            if (!parseHexValue(&cursor, &a) || !parseHexValue(&cursor, &b) || !validateByte(b)) {
                Serial.println(F("ERR usage: W addr byte"));
                return;
            }
            commandWrite(a, (uint8_t)b);
            return;

        case 'R':
            if (!parseHexValue(&cursor, &a)) {
                Serial.println(F("ERR usage: R addr"));
                return;
            }
            commandRead(a);
            return;

        case 'D':
            if (!parseHexValue(&cursor, &a) || !parseHexValue(&cursor, &b)) {
                Serial.println(F("ERR usage: D start count"));
                return;
            }
            commandDump(a, b);
            return;

        case 'F':
            if (!parseHexValue(&cursor, &a) || !parseHexValue(&cursor, &b) ||
                !parseHexValue(&cursor, &c) || !validateByte(c)) {
                Serial.println(F("ERR usage: F start end byte"));
                return;
            }
            commandFill(a, b, (uint8_t)c);
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
