# Programmare una AT28C64 con Arduino Mega

Questa guida mostra il minimo necessario per leggere e scrivere una EEPROM parallela **AT28C64/AT28C64B** con lo sketch in:

```text
tools/eeprom-programmer/at28c64-mega/
```

La EEPROM contiene 8192 byte: gli indirizzi validi sono da `0000` a `1FFF`.

## Prima di iniziare

- Usa una EEPROM a 5 V e un Arduino Mega a 5 V.
- Collega **GND comune** tra Arduino ed EEPROM.
- Metti un condensatore ceramico da **100 nF** tra `VCC` (pin 28) e `GND` (pin 14), vicino al chip.
- Controlla il verso della EEPROM: il riferimento e la tacca del package, vista dall'alto.

## Collegamenti completi

Tabella riferita a una AT28C64B in package PDIP-28, vista dall'alto. I due pin `NC` non vanno collegati.

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

## Il concetto essenziale

Le linee `A0`–`A12` scelgono la cella; `I/O0`–`I/O7` trasportano il byte.
Il bus dati e condiviso: durante la lettura lo guida la EEPROM, durante la scrittura lo guida Arduino. Per evitare un conflitto elettrico, lo sketch imposta sempre i pin dati in `INPUT` prima di leggere e in `OUTPUT` prima di scrivere.

| Operazione | `CE` | `OE` | `WE`              | Chi guida il bus dati |
| ---------- | ---- | ---- | ----------------- | --------------------- |
| Riposo     | `1`  | `1`  | `1`               | nessuno               |
| Lettura    | `0`  | `0`  | `1`               | EEPROM                |
| Scrittura  | `0`  | `1`  | impulso `0` → `1` | Arduino               |

`0` significa livello basso, `1` livello alto.

## Flusso di lettura

```text
Arduino: dati INPUT → imposta indirizzo → CE=0, OE=0 → attende 1 µs → legge il byte → CE=1, OE=1
EEPROM:                         vede l'indirizzo → mette il byte sul bus →         rilascia il bus
```

L'attesa di **1 µs** e il tempo di assestamento impostato nello sketch (`READ_SETTLE_US`). Serve a lasciare il tempo alla EEPROM di rendere valido il dato dopo l'abilitazione delle uscite.

Esempio nel monitor seriale:

```text
R 0000
```

## Flusso di scrittura e tempi

```text
Arduino: imposta indirizzo → dati OUTPUT e byte valido → OE=1, CE=0 → WE=0 per 10 µs → WE=1, CE=1 → attende 15 ms → rilegge e verifica
EEPROM:   riceve indirizzo e dato                            avvio scrittura       programma internamente       byte pronto
```

Il fronte di risalita di `WE` avvia la programmazione interna. Il byte non e subito disponibile: la AT28C64B indica fino a circa **10 ms**. Lo sketch aspetta **15 ms** (`WRITE_SETTLE_MS`) per avere margine, poi legge di nuovo la cella e risponde `OK` solo se il valore coincide.

L'impulso `WE` usato dallo sketch dura **10 µs** (`WRITE_PULSE_US`).

Con la scrittura normale, ogni riga inviata richiede quindi almeno circa **15 ms**, piu il tempo di invio seriale e di elaborazione. In pratica e un programmatore didattico: semplice e verificabile, non pensato per la massima velocita.

## Installazione e caricamento

Installa una sola volta Arduino CLI e il core del Mega:

```sh
brew install arduino-cli
arduino-cli core update-index
arduino-cli core install arduino:avr
```

Compila lo sketch dalla root del repository:

```sh
arduino-cli compile --fqbn arduino:avr:mega tools/eeprom-programmer/at28c64-mega
```

Trova la porta del Mega:

```sh
arduino-cli board list
```

Carica lo sketch, sostituendo la porta di esempio con la tua:

```sh
arduino-cli upload -p /dev/cu.usbmodem21101 --fqbn arduino:avr:mega tools/eeprom-programmer/at28c64-mega
```

Apri poi il monitor seriale a 115200 baud:

```sh
arduino-cli monitor -p /dev/cu.usbmodem21201 --config baudrate=115200
```

Usa il terminatore di riga newline.

## Scrivere un programma

1. Genera il file `.hex` con l'assembler:

   ```sh
   make -C tools/assembler
   tools/assembler/build/cpu8asm examples/assembly/demo.asm -o tools/assembler/build/demo
   ```

2. Nel monitor seriale incolla le righe di `tools/assembler/build/demo.hex`. Ogni riga scrive un byte:

   ```text
   0000: 20
   0001: 0A
   0002: 48
   ```

3. Per ogni byte scritto e verificato, Arduino risponde:

   ```text
   OK 0000: 20
   ```

4. Controlla il risultato con un dump dei primi 16 byte:

   ```text
   D 0000 0010
   ```

## Comandi utili

I numeri senza prefisso sono esadecimali; `0x` e facoltativo. Per usare il
binario, anteponi `0b`: per esempio `W 0b0 0b10100110` scrive il byte `A6`
all'indirizzo `0000`. Il formato di risposta e dei dump resta esadecimale.

| Comando            | Esempio          | Funzione                     |
| ------------------ | ---------------- | ---------------------------- |
| `W addr byte`      | `W 0000 AA`      | scrive un byte e lo verifica |
| `R addr`           | `R 0000`         | legge un byte                |
| `D start count`    | `D 0000 0010`    | stampa un dump               |
| `F start end byte` | `F 0000 00FF FF` | riempie un intervallo        |
| `HELP`             | `HELP`           | mostra tutti i comandi       |

## Test iniziale

Prima di inviare un programma intero, esegui:

```text
W 0000 AA
R 0000
D 0000 0010
```

La lettura dell'indirizzo `0000` deve restituire `AA`. Se fallisce, spegni tutto e ricontrolla prima alimentazione, massa comune, condensatore, verso del chip e i tre segnali `CE`, `OE`, `WE`.

## Se la scrittura normale non funziona

Alcune AT28C64B possono avere la **Software Data Protection** attiva. In questo caso prova:

```text
P 0000 AA
R 0000
```

`P` invia prima la sequenza di sblocco `1555:AA`, `0AAA:55`, `1555:A0`, poi scrive il byte vero. Se funziona, invia `M P` prima di incollare il file `.hex`; torna alla modalita normale con `M W`.

Usa questa modalita solo se necessaria: con una EEPROM non protetta, `W` e le righe `.hex` sono sufficienti.

## Problemi tipici

| Sintomo                  | Controllo prioritario                                                           |
| ------------------------ | ------------------------------------------------------------------------------- |
| Legge sempre `FF`        | alimentazione, `CE`/`OE`, cavi dati                                             |
| Legge sempre `00`        | corti o ordine errato delle linee dati                                          |
| Scrittura non verificata | `WE` sul pin 27, condensatore, collegamenti dati/indirizzi, protezione software |

Riferimento: [datasheet AT28C64B](https://ww1.microchip.com/downloads/en/DeviceDoc/doc0270.pdf).
