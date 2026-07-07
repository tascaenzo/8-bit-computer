# AT28C64 Arduino Mega Programmer

Sketch Arduino per programmare una EEPROM parallela AT28C64 usando un Arduino Mega.

L'obiettivo e caricare nella EEPROM il binario prodotto dagli strumenti del progetto, per esempio l'output `.hex` generato da `cpu8asm`.

Per la guida completa passo passo, inclusa la base teorica, vedere:

```text
docs/at28c64-arduino-mega-programmer.md
```

## Struttura sorgenti

| File | Responsabilita |
| --- | --- |
| `at28c64-mega.ino` | inizializza seriale e bus EEPROM, poi chiama il gestore comandi nel `loop` |
| `include/ProgrammerConfig.h` | configurazione pin, baud rate, dimensione EEPROM e timing |
| `include/EepromBus.h` | interfaccia del modulo che controlla la EEPROM |
| `src/EepromBus.cpp` | gestisce pin, bus indirizzi, bus dati, lettura, scrittura e data polling |
| `include/SerialCommands.h` | interfaccia del parser dei comandi seriali |
| `src/SerialCommands.cpp` | gestisce parsing, validazione, dump, fill e formato `.hex` di `cpu8asm` |

## Perche Arduino Mega

La AT28C64 usa:

- 13 linee indirizzo: `A0`...`A12`;
- 8 linee dati bidirezionali: `D0`...`D7`;
- 3 segnali di controllo: `CE`, `OE`, `WE`.

Un Arduino Uno non ha abbastanza pin liberi per collegare tutto in modo diretto. Arduino Mega permette invece un collegamento semplice, senza shift register.

## Mappa pin Arduino

Questa mappa descrive i segnali logici. Prima di collegare la EEPROM controlla sempre il pinout del package reale nel datasheet della tua AT28C64.

| Segnale EEPROM | Pin Arduino Mega |
| --- | ---: |
| `A0` | `22` |
| `A1` | `23` |
| `A2` | `24` |
| `A3` | `25` |
| `A4` | `26` |
| `A5` | `27` |
| `A6` | `28` |
| `A7` | `29` |
| `A8` | `30` |
| `A9` | `31` |
| `A10` | `32` |
| `A11` | `33` |
| `A12` | `34` |
| `D0` | `35` |
| `D1` | `36` |
| `D2` | `37` |
| `D3` | `38` |
| `D4` | `39` |
| `D5` | `40` |
| `D6` | `41` |
| `D7` | `42` |
| `CE` | `43` |
| `OE` | `44` |
| `WE` | `45` |

Collegamenti alimentazione:

- `VCC` EEPROM a `5V`;
- `GND` EEPROM a `GND`;
- condensatore da `100 nF` tra `VCC` e `GND`, vicino alla EEPROM.

## Formati supportati via seriale

Apri il monitor seriale a `115200 baud`, con terminatore newline.

### Scrivere una riga prodotta da `cpu8asm`

```text
0000: 20
0001: 0A
0002: 8A
0003: 01
```

Ogni riga scrive un byte all'indirizzo indicato.

### Comandi manuali

```text
W 0000 20
R 0000
D 0000 0010
F 0000 00FF FF
```

Significato:

| Comando | Effetto |
| --- | --- |
| `W addr byte` | scrive un byte |
| `R addr` | legge un byte |
| `D start count` | stampa un dump di `count` byte |
| `F start end byte` | riempie un intervallo inclusivo |
| `HELP` | stampa l'aiuto |

I numeri sono esadecimali. Il prefisso `0x` e opzionale.

## Esempio con l'assembler

Compila un programma assembly:

```sh
tools/assembler/build/cpu8asm examples/assembly/demo.asm -o tools/assembler/build/demo
```

Poi invia il contenuto di:

```text
tools/assembler/build/demo.hex
```

allo sketch Arduino. Ogni riga `addr: byte` programma un byte della EEPROM.

## Note elettriche

- La AT28C64 lavora a 5V: usa Arduino Mega a 5V.
- Durante la lettura, i pin dati Arduino devono essere `INPUT`.
- Durante la scrittura, i pin dati Arduino devono essere `OUTPUT`.
- `OE` deve restare alto durante la scrittura.
- L'impulso di scrittura viene dato portando `WE` basso per pochi microsecondi.
- Lo sketch attende la fine della scrittura tramite data polling su `D7`.

Non collegare la EEPROM anche alla CPU mentre la programmi, a meno che i bus della CPU siano sicuramente in alta impedenza.
