# Guida allo studio del programmatore AT28C64

Questa guida serve a chi vuole capire il progetto del programmatore EEPROM partendo da zero.

Il programmatore e uno sketch Arduino per Arduino Mega. Il suo compito e ricevere comandi dalla seriale e usarli per leggere o scrivere una EEPROM parallela AT28C64.

## Idea generale

La AT28C64 e una memoria parallela:

- 13 linee indirizzo selezionano una cella da `0x0000` a `0x1FFF`;
- 8 linee dati trasportano il byte letto o scritto;
- `CE`, `OE` e `WE` controllano quando il chip e attivo, quando mette dati sul bus e quando salva un byte.

Il programmatore fa questo lavoro:

1. Riceve una riga dal monitor seriale.
2. Capisce se e un comando manuale o una riga `.hex` prodotta da `cpu8asm`.
3. Se deve scrivere, imposta indirizzo e dati sui pin Arduino.
4. Genera l'impulso di scrittura su `WE`.
5. Aspetta un tempo fisso conservativo per il ciclo interno della EEPROM.
6. Rilegge il byte per verificarlo.
7. Stampa `OK` o un errore sulla seriale.

Esempio di riga accettata:

```text
0000: 20
```

Significa:

```text
indirizzo 0x0000 <- byte 0x20
```

## Da dove iniziare

L'ordine consigliato di lettura e:

1. `at28c64-mega.ino`
2. `include/ProgrammerConfig.h`
3. `include/EepromBus.h`
4. `src/EepromBus.cpp`
5. `include/SerialCommands.h`
6. `src/SerialCommands.cpp`
7. `README.md`
8. `docs/at28c64-arduino-mega-programmer.md`

## `at28c64-mega.ino`

Questo e il punto di ingresso dello sketch Arduino.

Contiene:

```cpp
void setup()
void loop()
```

`setup`:

- apre la seriale a `115200 baud`;
- inizializza il bus verso la EEPROM;
- stampa l'aiuto dei comandi.

`loop`:

- controlla continuamente se arrivano caratteri dalla seriale;
- delega il lavoro a `serialCommandsHandleInput`.

Questo file deve restare piccolo. Non deve conoscere i dettagli elettrici della EEPROM e non deve contenere il parser dei comandi.

## `include/ProgrammerConfig.h`

Questo file contiene la configurazione del programmatore.

Qui trovi:

- dimensione della EEPROM;
- baud rate seriale;
- dimensione del buffer di riga;
- pin Arduino collegati ad `A0`...`A12`;
- pin Arduino collegati a `I/O0`...`I/O7`;
- pin dei segnali `CE`, `OE`, `WE`;
- tempi usati per lettura, impulso di scrittura e attesa del ciclo interno.

Esempio:

```cpp
static const uint8_t PIN_WE = 45;
```

Se cambi cablaggio, questo e il primo file da modificare.

## `include/EepromBus.h`

Questo header espone le funzioni usate dal resto del programma per parlare con la EEPROM:

```cpp
void eepromBusBegin();
uint8_t eepromReadByte(uint16_t address);
void eepromWriteByte(uint16_t address, uint8_t value);
void eepromWriteByteProtected(uint16_t address, uint8_t value);
```

Il resto del codice non deve sapere come sono collegati i pin fisici. Deve solo poter chiedere:

- inizializza il bus;
- leggi un byte;
- scrivi un byte normale o con sequenza Software Data Protection.

## `src/EepromBus.cpp`

Questo file contiene la parte piu vicina all'hardware.

Le funzioni interne principali sono:

- `setAddress`: mette sui pin `A0`...`A12` il valore dell'indirizzo;
- `setDataBusInput`: mette i pin dati in lettura;
- `setDataBusOutput`: mette i pin dati in scrittura;
- `writeDataBus`: scrive un byte sui pin `I/O0`...`I/O7`;
- `readDataBus`: legge un byte dai pin `I/O0`...`I/O7`;
- `pulseWriteByte`: genera il ciclo elettrico di scrittura.

### Lettura

Per leggere dalla EEPROM:

```text
CE = 0
OE = 0
WE = 1
```

Arduino mette il bus dati in `INPUT`, imposta l'indirizzo, abilita la EEPROM e legge gli 8 bit.

### Scrittura

Per scrivere nella EEPROM:

```text
CE = 0
OE = 1
WE = impulso basso
```

Arduino mette il bus dati in `OUTPUT`, imposta indirizzo e byte, poi genera un breve impulso basso su `WE`.

La scrittura interna non e immediata. Per questo il codice aspetta un ritardo fisso conservativo e poi rilegge il byte per verificarlo.

## Attesa e verifica

La AT28C64B dichiara un ciclo di scrittura massimo di circa `10 ms`.
Per mantenere il programmatore semplice e leggibile, questa versione usa un'attesa fissa leggermente piu lunga.

L'idea semplificata e:

1. scrivo un byte;
2. aspetto il ciclo interno della EEPROM;
3. rileggo lo stesso indirizzo;
4. se il valore letto coincide con quello scritto, stampo `OK`.

Questa tecnica e piu lenta del data polling, ma e piu adatta a una prima versione didattica su breadboard.

## `include/SerialCommands.h`

Questo header espone il modulo che gestisce il protocollo seriale:

```cpp
void serialCommandsPrintHelp();
void serialCommandsHandleInput();
```

Il modulo seriale non deve conoscere i dettagli dei pin. Quando deve leggere o scrivere, chiama le funzioni pubbliche di `EepromBus`.

## `src/SerialCommands.cpp`

Questo file contiene il parser dei comandi seriali.

Supporta due famiglie di input.

### Formato `.hex` di `cpu8asm`

```text
0000: 20
0001: 0A
```

Questo formato e comodo per copiare direttamente l'output dell'assembler nel monitor seriale.

### Comandi manuali

```text
W 0000 20
R 0000
D 0000 0010
F 0000 00FF FF
HELP
```

Il parser fa questi passaggi:

1. accumula caratteri fino a newline;
2. rimuove spazi iniziali;
3. se trova `:`, interpreta la riga come formato `.hex`;
4. altrimenti legge il primo carattere come comando;
5. converte i numeri esadecimali;
6. valida indirizzo e byte;
7. chiama `EepromBus`;
8. stampa il risultato.

## Funzioni di supporto importanti

`parseHexValue` converte testo esadecimale in numero:

```text
00FF -> 255
0x00FF -> 255
```

`validateAddress` controlla che l'indirizzo sia nel range della AT28C64:

```text
0x0000 - 0x1FFF
```

`validateByte` controlla che il valore stia in 8 bit:

```text
0x00 - 0xFF
```

`commandWrite` scrive un byte e lo rilegge subito per verificare che la programmazione sia riuscita.

## Concetti Arduino/C++ da conoscere

Per studiare questo progetto conviene conoscere:

- `setup` e `loop`;
- `pinMode`;
- `digitalWrite`;
- `digitalRead`;
- `delayMicroseconds`;
- `millis`;
- `Serial.begin`;
- `Serial.available`;
- `Serial.read`;
- `Serial.print`;
- array;
- funzioni;
- header `.h` e implementazioni `.cpp`;
- costanti `static const`;
- tipi `uint8_t`, `uint16_t`, `uint32_t`;
- differenza tra pin in `INPUT` e pin in `OUTPUT`.

## Percorso pratico consigliato

1. Compila lo sketch senza EEPROM collegata.
2. Leggi `ProgrammerConfig.h` e confronta ogni pin con il cablaggio reale.
3. Collega solo alimentazione e segnali principali della EEPROM.
4. Prova un comando di lettura:

```text
R 0000
```

5. Scrivi un byte:

```text
W 0000 AA
```

6. Rileggilo:

```text
R 0000
```

7. Prova un dump:

```text
D 0000 0010
```

8. Solo dopo questi test invia un file `.hex` generato da `cpu8asm`.

## Stato attuale

Il programmatore ha una prima versione funzionante.

Supporta:

- scrittura byte singolo;
- lettura byte singolo;
- dump di un intervallo;
- fill di un intervallo;
- formato `.hex` prodotto da `cpu8asm`;
- verifica immediata dopo ogni scrittura;
- attesa fissa dopo ogni scrittura;
- configurazione pin centralizzata in `ProgrammerConfig.h`.

Le prossime parti da implementare possono essere:

1. invio automatico del file `.hex` da PC;
2. verifica completa della EEPROM dopo la programmazione;
3. comando per cancellare o riempire tutta la EEPROM;
4. scrittura a pagine da 64 byte;
5. supporto diretto al formato `.bin`;
6. test manuali documentati con tabella dei segnali attesi.
