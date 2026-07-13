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

| Segnale | Significato   | Uso nello sketch                         |
| ------- | ------------- | ---------------------------------------- |
| `CE`    | Chip Enable   | abilita la EEPROM                        |
| `OE`    | Output Enable | abilita l'uscita dati durante la lettura |
| `WE`    | Write Enable  | genera l'impulso di scrittura            |

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

## Schema teorico del bus

Vista logica del collegamento:

```text
Arduino Mega                         AT28C64B

pin 22..34  -----------------------> A0..A12
                                     bus indirizzi

pin 35..42  <----------------------> I/O0..I/O7
                                     bus dati bidirezionale

pin 43      -----------------------> CE
pin 44      -----------------------> OE
pin 45      -----------------------> WE

5V          -----------------------> VCC pin 28
GND         -----------------------> GND pin 14
100 nF      -----------------------> tra VCC e GND, vicino al chip
```

Il bus dati cambia direzione:

```text
lettura:
  EEPROM -> Arduino
  pin dati Arduino = INPUT

scrittura:
  Arduino -> EEPROM
  pin dati Arduino = OUTPUT
```

## Diagrammi temporali teorici

Nei diagrammi seguenti `0` significa livello basso e `1` significa livello alto.
`ADDR` e `DATA` devono essere stabili prima dell'impulso di scrittura.

### Lettura

```text
tempo  --->

ADDR  ----< indirizzo valido >--------------------------
DATA  ZZZZ< dato dalla EEPROM >ZZZZZZZZZZZZZZZZZZZZZZZZ

CE    1111\____________________/1111111111111111111111
OE    111111\________________/111111111111111111111111
WE    111111111111111111111111111111111111111111111111

fase       imposta addr   abilita uscite   leggi dato
```

Sequenza:

1. Arduino mette i pin dati in `INPUT`.
2. Arduino imposta `A0`...`A12`.
3. Arduino porta `CE=0` e `OE=0`.
4. La EEPROM pilota `I/O0`...`I/O7`.
5. Arduino legge il byte.
6. Arduino riporta `OE=1` e `CE=1`.

### Scrittura byte normale

```text
tempo  --->

ADDR  ----< indirizzo valido >--------------------------
DATA  ----< dato valido >-------------------------------

OE    111111111111111111111111111111111111111111111111
CE    1111\____________________/1111111111111111111111
WE    11111111\______/11111111111111111111111111111111

fase       addr+dato stabili  impulso WE   ciclo interno
```

Sequenza:

1. Arduino imposta `A0`...`A12`.
2. Arduino mette i pin dati in `OUTPUT`.
3. Arduino mette il byte su `I/O0`...`I/O7`.
4. Arduino tiene `OE=1`, per non far pilotare il bus alla EEPROM.
5. Arduino porta `CE=0`.
6. Arduino genera un impulso basso su `WE`.
7. Arduino riporta `WE=1` e `CE=1`.
8. La EEPROM programma internamente la cella.
9. Lo sketch aspetta un tempo fisso e poi rilegge per verificare.

### Scrittura con Software Data Protection

La AT28C64B puo avere la Software Data Protection attiva. In quel caso una
scrittura normale puo essere ignorata. Per scrivere comunque un byte, bisogna
prima inviare una sequenza speciale:

```text
tempo  --->

write 1:  address 1555, data AA
write 2:  address 0AAA, data 55
write 3:  address 1555, data A0
write 4:  address XXXX, data DD

WE        _|--|__|--|__|--|__|--|_
CE        _|--|__|--|__|--|__|--|_
OE        111111111111111111111111

DD = byte reale da programmare
XXXX = indirizzo reale da programmare
```

I primi tre cicli non sono dati del programma: sono il codice di sblocco.
Il quarto ciclo e la scrittura reale del byte.

## Attesa e verifica della scrittura

La scrittura interna della EEPROM non e istantanea. Dopo l'impulso su `WE`, il chip impiega alcuni millisecondi per completare realmente la programmazione della cella.

Questa versione dello sketch usa una strategia volutamente semplice:

1. scrive il byte;
2. aspetta un ritardo fisso conservativo;
3. rilegge lo stesso indirizzo;
4. stampa `OK` solo se il byte letto coincide con quello scritto.

La AT28C64B dichiara un ciclo di scrittura massimo di circa `10 ms`; lo sketch usa un margine leggermente piu alto per funzionare bene anche su breadboard.

## Pinout fisico AT28C64B PDIP-28

Questa tabella e riferita al package PDIP/SOIC a 28 pin, vista dall'alto. Prima di saldare o cablare controlla comunque il datasheet del chip che hai in mano.

| Pin EEPROM | Segnale | Pin Arduino Mega |
| ---------: | ------- | ---------------: |
|          1 | `NC`    |    non collegare |
|          2 | `A12`   |             `34` |
|          3 | `A7`    |             `29` |
|          4 | `A6`    |             `28` |
|          5 | `A5`    |             `27` |
|          6 | `A4`    |             `26` |
|          7 | `A3`    |             `25` |
|          8 | `A2`    |             `24` |
|          9 | `A1`    |             `23` |
|         10 | `A0`    |             `22` |
|         11 | `I/O0`  |             `35` |
|         12 | `I/O1`  |             `36` |
|         13 | `I/O2`  |             `37` |
|         14 | `GND`   |            `GND` |
|         15 | `I/O3`  |             `38` |
|         16 | `I/O4`  |             `39` |
|         17 | `I/O5`  |             `40` |
|         18 | `I/O6`  |             `41` |
|         19 | `I/O7`  |             `42` |
|         20 | `CE`    |             `43` |
|         21 | `A10`   |             `32` |
|         22 | `OE`    |             `44` |
|         23 | `A11`   |             `33` |
|         24 | `A9`    |             `31` |
|         25 | `A8`    |             `30` |
|         26 | `NC`    |    non collegare |
|         27 | `WE`    |             `45` |
|         28 | `VCC`   |             `5V` |

Metti un condensatore da `100 nF` tra `VCC` e `GND`, il piu vicino possibile alla EEPROM. In pratica va messo tra il pin `28` e il pin `14` della EEPROM.

Attenzione: nel package PDIP-28 della AT28C64B il pin `26` e `NC`; `WE` e il pin fisico `27`.

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
/dev/cu.usbmodem21101
```

Carica lo sketch:

```sh
arduino-cli upload \
  -p /dev/cu.usbmodem21101 \
  --fqbn arduino:avr:mega \
  tools/eeprom-programmer/at28c64-mega
```

Sostituisci la porta con quella mostrata dal tuo computer.

## Aprire il monitor seriale

Lo sketch usa `115200 baud`.

```sh
arduino-cli monitor \
  -p /dev/cu.usbmodem21101 \
  --config baudrate=115200
```

Il monitor deve usare newline come terminatore riga.

## Procedura completa: da assembly a EEPROM

Questa e la sequenza operativa completa per prendere un file `.asm` e scriverlo nella AT28C64.

### 1. Scrivere o scegliere il programma assembly

Esempio:

```text
examples/assembly/demo.asm
```

### 2. Compilare l'assembler

Dalla root del repository:

```sh
make -C tools/assembler
```

### 3. Generare gli output dell'assembler

```sh
tools/assembler/build/cpu8asm examples/assembly/demo.asm -o tools/assembler/build/demo
```

Questo genera:

```text
tools/assembler/build/demo.bin
tools/assembler/build/demo.hex
tools/assembler/build/demo.bits
tools/assembler/build/demo.h
```

Per il programmatore Arduino il file piu comodo e:

```text
tools/assembler/build/demo.hex
```

### 4. Compilare lo sketch del programmatore

```sh
arduino-cli compile \
  --fqbn arduino:avr:mega \
  tools/eeprom-programmer/at28c64-mega
```

### 5. Trovare la porta di Arduino Mega

```sh
arduino-cli board list
```

Esempio:

```text
/dev/cu.usbmodem21101
```

### 6. Caricare lo sketch su Arduino Mega

```sh
arduino-cli upload \
  -p /dev/cu.usbmodem21101 \
  --fqbn arduino:avr:mega \
  tools/eeprom-programmer/at28c64-mega
```

Sostituisci `/dev/cu.usbmodem21101` con la porta reale mostrata da `arduino-cli board list`.

### 7. Aprire il monitor seriale

```sh
arduino-cli monitor \
  -p /dev/cu.usbmodem21101 \
  --config baudrate=115200
```

### 8. Inviare il contenuto del `.hex`

Apri il file:

```text
tools/assembler/build/demo.hex
```

e invia le righe nel monitor seriale. Il formato e:

```text
0000: 20
0001: 0A
0002: 48
0003: 10
0004: 00
```

Lo sketch risponde con una riga `OK` per ogni byte scritto e verificato:

```text
OK 0000: 20
OK 0001: 0A
```

### 9. Verificare la EEPROM

Per leggere i primi `0x10` byte:

```text
D 0000 0010
```

Il dump deve corrispondere alle prime righe del file `.hex` generato da `cpu8asm`.

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

| Comando            | Esempio          | Effetto               |
| ------------------ | ---------------- | --------------------- |
| `W addr byte`      | `W 0000 20`      | scrive un byte        |
| `P addr byte`      | `P 0000 20`      | scrive con Software Data Protection |
| `M W`              | `M W`            | usa scrittura normale per le righe `.hex` |
| `M P`              | `M P`            | usa scrittura protetta per le righe `.hex` |
| `R addr`           | `R 0000`         | legge un byte         |
| `D start count`    | `D 0000 0010`    | stampa un dump        |
| `F start end byte` | `F 0000 00FF FF` | riempie un intervallo |
| `HELP`             | `HELP`           | mostra l'aiuto        |

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

Se `W` fallisce con errori di verifica ma `R` legge comunque valori plausibili, prova un singolo byte con la sequenza Software Data Protection:

```text
P 0000 20
R 0000
```

Se `P` funziona e `W` no, la EEPROM ha probabilmente la protezione software attiva.
In quel caso invia prima `M P`, poi incolla il contenuto del file `.hex`.
Per tornare alla scrittura normale, invia `M W`.

Usa `P`/`M P` solo quando serve: sulla AT28C64B la sequenza protetta puo lasciare la Software Data Protection attiva. Con una EEPROM non protetta e cablata correttamente, il comando normale `W` e le righe `.hex` bastano.

Solo dopo questo test conviene inviare un programma completo prodotto da `cpu8asm`.

## Errori comuni

| Problema                        | Possibile causa                                                                   |
| ------------------------------- | --------------------------------------------------------------------------------- |
| Lettura sempre `FF`             | `CE` o `OE` non arrivano bassi, bus dati scollegato, EEPROM non alimentata        |
| Lettura sempre `00`             | bus dati in corto, collegamenti dati invertiti, chip non alimentato correttamente |
| Verifica fallita dopo scrittura | `WE` sul pin sbagliato, condensatore `100 nF` mancante, linee dati scambiate, protezione software attiva, indirizzi scambiati, contatti instabili |
| Upload Arduino fallisce         | porta sbagliata o board non selezionata                                           |

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
