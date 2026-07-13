/*
 * AT28C64 programmer for Arduino Mega.
 *
 * The hardware-specific EEPROM bus code lives in EepromBus.*.
 * The serial command parser lives in SerialCommands.*.
 */

#include <Arduino.h>

#include "include/EepromBus.h"
#include "include/ProgrammerConfig.h"
#include "include/SerialCommands.h"

void setup()
{
    Serial.begin(SERIAL_BAUD);

    eepromBusBegin();

    Serial.println(F("AT28C64 programmer ready"));
    serialCommandsPrintHelp();
}

void loop()
{
    serialCommandsHandleInput();
}
