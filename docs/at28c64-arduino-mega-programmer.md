# Programmatore AT28C64 con Arduino Mega

Questa guida spiega come configurare Arduino CLI e usare un Arduino Mega per programmare una EEPROM parallela AT28C64/AT28C64B.

Il progetto Arduino si trova in:

```text
tools/eeprom-programmer/at28c64-mega/
```

Struttura principale:

```text
tools/eeprom-programmer/at28c64-mega/
├── at28c64-mega.ino
├── include/
│   ├── EepromBus.h
│   ├── ProgrammerConfig.h
│   └── SerialCommands.h
└── src/
    ├── EepromBus.cpp
    └── SerialCommands.cpp
```

`ProgrammerConfig` contiene pin, baud rate, dimensione EEPROM e timing. `EepromBus` contiene la parte elettrica verso la EEPROM. `SerialCommands` contiene il protocollo testuale usato dal monitor seriale.

## Obiettivo

L'obiettivo e scrivere nella EEPROM i byte prodotti dagli strumenti del progetto, per esempio il file `.hex` generato da `cpu8asm`.

Flusso completo:

```text
programma.asm
  -> cpu8asm
  -> programma.hex
  -> Arduino Mega
  -> AT28C64
```

## Base teorica

La AT28C64 e una EEPROM parallela da 64 Kbit, organizzata come:

```text
8192 celle x 8 bit
```

Quindi:

- ogni indirizzo contiene 1 byte;
- gli indirizzi validi vanno da `0x0000` a `0x1FFF`;
- servono 13 linee di indirizzo, perche `2^13 = 8192`;
- servono 8 linee dati, una per ogni bit del byte.

Il datasheet AT28C64B descrive la memoria come `8K x 8` e indica che usa una singola alimentazione a 5V.

## Linee principali

### Bus indirizzi

Le linee `A0`...`A12` selezionano quale cella della EEPROM leggere o scrivere.

Esempio:

```text
A12..A0 = 0b0000000000000 -> indirizzo 0x0000
A12..A0 = 0b0000000000001 -> indirizzo 0x0001
A12..A0 = 0b1111111111111 -> indirizzo 0x1FFF
```

### Bus dati

Le linee `I/O0`...`I/O7` sono bidirezionali:

- in lettura vengono pilotate dalla EEPROM;
- in scrittura vengono pilotate da Arduino.

Per questo lo sketch cambia la direzione dei pin:

```text
lettura   -> pin Arduino in INPUT
scrittura -> pin Arduino in OUTPUT
```

### Segnali di controllo

| Segnale | Significato | Uso nello sketch |
| --- | --- | --- |
| `CE` | Chip Enable | abilita la EEPROM |
| `OE` | Output Enable | abilita l'uscita dati durante la lettura |
| `WE` | Write Enable | genera l'impulso di scrittura |

In lettura:

```text
CE = 0
OE = 0
WE = 1
```

In scrittura:

```text
CE = 0
OE = 1
WE = impulso basso
```

Il datasheet specifica che la lettura avviene con `CE` e `OE` bassi e `WE` alto; per la scrittura viene avviato un ciclo con impulso basso su `WE` o `CE`, tenendo `OE` alto.

## Data polling

La scrittura interna della EEPROM non e istantanea. Dopo l'impulso su `WE`, il chip impiega alcuni millisecondi per completare realmente la programmazione della cella.

Lo sketch usa il data polling su `I/O7`:

1. scrive il byte;
2. mette il bus dati in lettura;
3. legge ripetutamente lo stesso indirizzo;
4. considera completata la scrittura quando il bit `I/O7` letto corrisponde al bit 7 del byte scritto.

Questo evita di usare un ritardo fisso troppo lungo dopo ogni byte.

## Pinout fisico AT28C64B PDIP-28

Questa tabella e riferita al package PDIP/SOIC a 28 pin, vista dall'alto. Prima di saldare o cablare controlla comunque il datasheet del chip che hai in mano.

| Pin EEPROM | Segnale | Pin Arduino Mega |
| ---: | --- | ---: |
| 1 | `NC` | non collegare |
| 2 | `A12` | `34` |
| 3 | `A7` | `29` |
| 4 | `A6` | `28` |
| 5 | `A5` | `27` |
| 6 | `A4` | `26` |
| 7 | `A3` | `25` |
| 8 | `A2` | `24` |
| 9 | `A1` | `23` |
| 10 | `A0` | `22` |
| 11 | `I/O0` | `35` |
| 12 | `I/O1` | `36` |
| 13 | `I/O2` | `37` |
| 14 | `GND` | `GND` |
| 15 | `I/O3` | `38` |
| 16 | `I/O4` | `39` |
| 17 | `I/O5` | `40` |
| 18 | `I/O6` | `41` |
| 19 | `I/O7` | `42` |
| 20 | `CE` | `43` |
| 21 | `A10` | `32` |
| 22 | `OE` | `44` |
| 23 | `A11` | `33` |
| 24 | `A9` | `31` |
| 25 | `A8` | `30` |
| 26 | `WE` | `45` |
| 27 | `NC` | non collegare |
| 28 | `VCC` | `5V` |

Metti un condensatore da `100 nF` tra `VCC` e `GND`, il piu vicino possibile alla EEPROM.

## Installazione Arduino CLI

Su macOS con Homebrew:

```sh
brew install arduino-cli
```

Verifica:

```sh
arduino-cli version
```

Configura l'indice e installa il core AVR:

```sh
arduino-cli core update-index
arduino-cli core install arduino:avr
```

Controlla che il core sia presente:

```sh
arduino-cli core list
```

Deve comparire una riga simile:

```text
arduino:avr
```

## Compilare lo sketch

Dalla root del repository:

```sh
arduino-cli compile \
  --fqbn arduino:avr:mega \
  tools/eeprom-programmer/at28c64-mega
```

`arduino:avr:mega` identifica Arduino Mega/Mega 2560.

## Configurare VS Code o Cursor

Se l'editor mostra un errore tipo:

```text
impossibile aprire il file origine "Arduino.h"
```

ma `arduino-cli compile` funziona, il problema non e lo sketch: e l'editor che non conosce i path del core Arduino.

Nel repository e presente:

```text
.vscode/c_cpp_properties.json
```

Questa configurazione punta agli header installati da Arduino CLI:

```text
~/Library/Arduino15/packages/arduino/hardware/avr/1.8.8/cores/arduino
~/Library/Arduino15/packages/arduino/hardware/avr/1.8.8/variants/mega
```

Dopo aver installato il core AVR, riapri la cartella del repository nell'editor oppure riavvia il language server C/C++.

## Caricare lo sketch su Arduino Mega

Collega Arduino Mega via USB e trova la porta:

```sh
arduino-cli board list
```

Esempio di porta su macOS:

```text
/dev/cu.usbmodem1101
```

Carica lo sketch:

```sh
arduino-cli upload \
  -p /dev/cu.usbmodem1101 \
  --fqbn arduino:avr:mega \
  tools/eeprom-programmer/at28c64-mega
```

Sostituisci la porta con quella mostrata dal tuo computer.

## Aprire il monitor seriale

Lo sketch usa `115200 baud`.

```sh
arduino-cli monitor \
  -p /dev/cu.usbmodem1101 \
  --config baudrate=115200
```

Il monitor deve usare newline come terminatore riga.

## Comandi supportati

### Scrittura compatibile con `cpu8asm`

Lo sketch accetta direttamente le righe del file `.hex` generato dall'assembler:

```text
0000: 20
0001: 0A
0002: 8A
0003: 01
```

Ogni riga scrive un byte nella EEPROM.

### Comandi manuali

| Comando | Esempio | Effetto |
| --- | --- | --- |
| `W addr byte` | `W 0000 20` | scrive un byte |
| `R addr` | `R 0000` | legge un byte |
| `D start count` | `D 0000 0010` | stampa un dump |
| `F start end byte` | `F 0000 00FF FF` | riempie un intervallo |
| `HELP` | `HELP` | mostra l'aiuto |

I numeri sono in esadecimale. Il prefisso `0x` e opzionale.

## Esempio completo con assembler

Compila un programma:

```sh
make -C tools/assembler
tools/assembler/build/cpu8asm examples/assembly/demo.asm -o tools/assembler/build/demo
```

Il file da inviare alla EEPROM e:

```text
tools/assembler/build/demo.hex
```

Contenuto di esempio:

```text
0000: 20
0001: 0A
0002: 48
0003: 10
0004: 00
```

Puoi copiare queste righe nel monitor seriale oppure inviarle con uno script seriale in una fase successiva.

## Procedura consigliata di test

1. Carica lo sketch su Arduino Mega senza EEPROM inserita.
2. Scollega USB.
3. Inserisci la EEPROM e ricontrolla alimentazione, massa e verso del chip.
4. Ricollega USB.
5. Apri il monitor seriale.
6. Scrivi un byte:

```text
W 0000 AA
```

7. Leggilo:

```text
R 0000
```

Output atteso:

```text
OK 0000: AA
```

8. Prova un dump:

```text
D 0000 0010
```

Solo dopo questo test conviene inviare un programma completo prodotto da `cpu8asm`.

## Errori comuni

| Problema | Possibile causa |
| --- | --- |
| Lettura sempre `FF` | `CE` o `OE` non arrivano bassi, bus dati scollegato, EEPROM non alimentata |
| Lettura sempre `00` | bus dati in corto, collegamenti dati invertiti, chip non alimentato correttamente |
| `ERR write timeout` | `WE` non collegato, protezione scrittura attiva, alimentazione instabile |
| Verifica fallita dopo scrittura | linee dati scambiate, indirizzi scambiati, tempi o contatti instabili |
| Upload Arduino fallisce | porta sbagliata o board non selezionata |

## Limiti della versione attuale

Questa prima versione scrive un byte alla volta. La AT28C64 supporta anche page write fino a 64 byte, ma per una fase didattica il byte write e piu semplice da osservare e debuggare.

In futuro si puo aggiungere:

- invio automatico del file `.hex` da PC;
- verifica completa della EEPROM dopo la programmazione;
- erase/fill automatico prima del write;
- page write per velocizzare la programmazione;
- supporto diretto al file `.bin`.

## Riferimenti

- Datasheet Microchip/Atmel AT28C64B: `64K (8K x 8) Parallel EEPROM with Page Write and Software Data Protection`.
- URL: `https://ww1.microchip.com/downloads/en/DeviceDoc/doc0270.pdf`
