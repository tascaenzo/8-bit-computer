/*
 * Demo minimale: programma e verifica alcuni byte su una AT28C64B.
 *
 * Segnali di controllo, tutti attivi a livello basso:
 *
 *   Operazione       /CE  /OE  /WE  Bus dati
 *   Lettura           0    0    1   EEPROM -> Arduino
 *   Scrittura         0    1   0->1 Arduino -> EEPROM
 *   Riposo            1    1    1   alta impedenza
 */

#include <Arduino.h>

static const uint8_t ADDRESS_PINS[13] = {
    22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34};

static const uint8_t DATA_PINS[8] = {
    35, 36, 37, 38, 39, 40, 41, 42};

static const uint8_t PIN_CE = 43;
static const uint8_t PIN_OE = 44;
static const uint8_t PIN_WE = 45;

/* Tempi volutamente conservativi per una AT28C64B. */
static const uint8_t READ_SETTLE_US = 1;
static const uint8_t WRITE_PULSE_US = 1;
static const uint8_t WRITE_SETTLE_MS = 15;

/*
 * I byte che il demo scrive a partire dall'indirizzo 0000.
 * Ogni cifra binaria corrisponde a una linea del bus, da I/O7 a I/O0:
 *
 *   0b10100110  -> I/O7=1, I/O6=0, I/O5=1, I/O4=0,
 *                  I/O3=0, I/O2=1, I/O1=1, I/O0=0
 *
 * Cambia o aggiungi qui i byte che vuoi passare alla EEPROM.
 */
static const uint8_t DEMO_PROGRAM[] = {
    0b00000000,
    0b00000001,
    0b00000010,
    0b00000011,
    0b01010101,
    0b10101010,
    0b11110000,
    0b00001111,
    0b10100110,
    0b11111111};

/*
 * Imposta A0..A12 della EEPROM.
 * Il bit 0 dell'indirizzo va su A0, il bit 12 va su A12.
 */
static void setAddress(uint16_t address)
{
  for (uint8_t bit = 0; bit < 13; bit++)
  {
    digitalWrite(ADDRESS_PINS[bit], bitRead(address, bit) ? HIGH : LOW);
  }
}

/*
 * Rilascia il bus dati affinche la EEPROM possa pilotarlo durante una lettura.
 * Prima azzera il latch del pin per evitare di abilitare involontariamente le
 * resistenze di pull-up interne dell'Arduino quando il pin diventa INPUT.
 */
static void setDataBusInput() // Lettura dealla EEPROM
{
  for (uint8_t bit = 0; bit < 8; bit++)
  {
    digitalWrite(DATA_PINS[bit], LOW);
    pinMode(DATA_PINS[bit], INPUT);
  }
}

/*
 * Configura I/O0..I/O7 come uscite, cosi Arduino puo presentare un byte alla
 * EEPROM. Va chiamata solo quando /OE e alto, quindi con le uscite EEPROM spente.
 */
static void setDataBusOutput() // Scrittura verso la EEPROM
{
  for (uint8_t bit = 0; bit < 8; bit++)
  {
    pinMode(DATA_PINS[bit], OUTPUT);
  }
}

/* Scrive gli otto bit di value sul bus dati Arduino -> EEPROM. */
static void writeDataBus(uint8_t value)
{
  for (uint8_t bit = 0; bit < 8; bit++)
  {
    digitalWrite(DATA_PINS[bit], bitRead(value, bit) ? HIGH : LOW);
  }
}

/* Legge gli otto bit presenti sul bus dati EEPROM -> Arduino. */
static uint8_t readDataBus()
{
  uint8_t value = 0b00000000;

  for (uint8_t bit = 0; bit < 8; bit++)
  {
    if (digitalRead(DATA_PINS[bit]) == HIGH)
    {
      bitSet(value, bit);
    }
  }

  return value;
}

/*
 * Esegue una scrittura di un byte.
 * Indirizzo e dato sono gia stabili prima dell'impulso basso su /WE; il fronte
 * di risalita di /WE avvia la programmazione interna della EEPROM.
 */
static void writeByte(uint16_t address, uint8_t value)
{
  setAddress(address);

  /* /OE alto: la EEPROM non guida il bus mentre Arduino lo configura. */
  digitalWrite(PIN_OE, HIGH);
  setDataBusOutput();
  writeDataBus(value);

  digitalWrite(PIN_CE, LOW);
  digitalWrite(PIN_WE, LOW);
  delayMicroseconds(WRITE_PULSE_US);
  digitalWrite(PIN_WE, HIGH);
  digitalWrite(PIN_CE, HIGH);

  /* Il massimo dichiarato e 10 ms; 15 ms lascia margine. */
  delay(WRITE_SETTLE_MS);
}

/*
 * Legge un byte dalla EEPROM.
 * Arduino mette il bus in INPUT, seleziona la EEPROM e ne abilita le uscite.
 */
static uint8_t readByte(uint16_t address)
{
  /* La EEPROM e lasciata inattiva da writeByte() o dalla lettura precedente. */
  digitalWrite(PIN_OE, HIGH);
  digitalWrite(PIN_CE, HIGH);
  digitalWrite(PIN_WE, HIGH);

  setDataBusInput();
  setAddress(address);

  digitalWrite(PIN_CE, LOW);
  digitalWrite(PIN_OE, LOW);
  delayMicroseconds(READ_SETTLE_US);

  uint8_t value = readDataBus();

  /* Disabilita le uscite EEPROM prima di una futura scrittura o lettura. */
  digitalWrite(PIN_OE, HIGH);
  digitalWrite(PIN_CE, HIGH);

  return value;
}

/* Stampa un byte come otto bit, dal piu significativo I/O7 al meno significativo I/O0. */
static void printBinaryByte(uint8_t value)
{
  for (int8_t bit = 7; bit >= 0; bit--)
  {
    Serial.print(bitRead(value, bit) ? '1' : '0');
  }
}

/*
 * Scrive tutti i byte di DEMO_PROGRAM e confronta ogni lettura con il byte
 * atteso. Restituisce true solo se tutte le verifiche hanno successo.
 */
static bool writeDemoAndVerify()
{
  bool ok = true;

  for (uint16_t address = 0; address < sizeof(DEMO_PROGRAM); address++)
  {
    uint8_t expected = DEMO_PROGRAM[address];
    writeByte(address, expected);

    uint8_t readBack = readByte(address);
    Serial.print(F("indirizzo "));
    printBinaryByte(address);
    Serial.print(F(": scritto "));
    Serial.print(F(" (0b"));
    printBinaryByte(expected);
    Serial.print(F(")"));
    Serial.print(F(", letto "));
    Serial.print(F(" (0b"));
    printBinaryByte(readBack);
    Serial.print(F(")"));

    if (readBack == expected)
    {
      Serial.println(F(" OK"));
    }
    else
    {
      Serial.println(F(" ERRORE"));
      ok = false;
    }
  }

  return ok;
}

/*
 * Inizializza i pin, porta la EEPROM nello stato sicuro di riposo e avvia il
 * test una sola volta quando Arduino si accende o viene resettato.
 */
void setup()
{
  Serial.begin(115200);

  for (uint8_t bit = 0; bit < 13; bit++)
  {
    pinMode(ADDRESS_PINS[bit], OUTPUT);
    digitalWrite(ADDRESS_PINS[bit], LOW);
  }

  pinMode(PIN_CE, OUTPUT);
  pinMode(PIN_OE, OUTPUT);
  pinMode(PIN_WE, OUTPUT);
  digitalWrite(PIN_CE, HIGH);
  digitalWrite(PIN_OE, HIGH);
  digitalWrite(PIN_WE, HIGH);
  setDataBusInput();

  Serial.println(F("AT28C64B: scrittura demo"));

  if (writeDemoAndVerify())
  {
    Serial.println(F("OK: programma verificato"));
  }
  else
  {
    Serial.println(F("ERRORE: verifica fallita"));
  }
}

/* Il demo ha gia eseguito tutto in setup(), quindi non deve ripetere nulla. */
void loop()
{
}
