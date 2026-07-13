# Linguaggio assembly CPU 8-bit

Questa specifica descrive la sintassi del linguaggio assembly accettato da `cpu8asm`, l'assembler della CPU didattica a 8 bit.

Il linguaggio assembly e una rappresentazione testuale dei programmi. Label, costanti e direttive esistono solo nel sorgente e vengono risolte dall'assembler; la CPU esegue esclusivamente i byte macchina definiti nella [specifica della ISA](isa.md).

## Stato del documento

Questo documento e la sorgente di verita per la sintassi assembly v0.1.

Le responsabilita della documentazione sono separate in questo modo:

- [ISA](isa.md): architettura visibile al software, semantica delle istruzioni, formati e opcode;
- questo documento: sintassi di programmi, operandi, label, costanti e direttive;
- [README dell'assembler](../tools/assembler/README.md): compilazione e utilizzo dello strumento `cpu8asm`.

## Struttura di un programma

Un programma puo contenere istruzioni, commenti, label e direttive dell'assembler.

Esempio minimo:

```asm
.code 0x0000
LDI R0, 0x0A
STA R0, counter
LDA R1, counter
HLT

.data
counter: .byte 0x00
```

In questo esempio:

- il codice inizia all'indirizzo `0x0000`;
- `LDI` carica il valore `0x0A` in `R0`;
- `counter` viene collocata automaticamente nel primo indirizzo libero, `0x0009`;
- `STA` scrive il valore in memoria e `LDA` lo rilegge in `R1`;
- `HLT` arresta la CPU.

Una sequenza di sorgenti ampiamente commentati, pensata per la spiegazione nel video, e disponibile nella [cartella principale degli esempi](../examples/assembly/README.md#sequenza-per-il-video-sullassembler).

## Istruzioni e formati

Ogni istruzione e composta da un mnemonic seguito dagli eventuali operandi:

```text
MNEMONIC operando1, operando2
```

Esempi dei tre formati macchina:

```asm
HLT              ; IMP: solo opcode
LDI R0, 0x2A     ; IMM8: opcode e valore immediato a 8 bit
LDA R0, 0x1234   ; ADDR16: opcode e indirizzo a 16 bit
```

La dimensione, la semantica e la codifica di ogni istruzione sono definite nella [tabella opcode della ISA](isa.md#tabella-opcode-riassuntiva).

### Operandi registro

I registri generali validi sono:

```text
R0, R1, R2, R3, R4, R5, R6, R7
```

Le istruzioni di trasferimento ammettono solamente queste forme:

```asm
MOV RA, R0
MOV RB, R1
MOV R2, RA
```

In forma generale:

```text
MOV RA, Rn
MOV RB, Rn
MOV Rn, RA
```

Il trasferimento diretto `MOV Rn, Rm` tra due registri generali non e valido, perche non e previsto dall'hardware della CPU.

### Separazione degli operandi

La virgola e la forma consigliata per separare gli operandi:

```asm
LDI R0, 0x2A
```

La versione attuale dell'assembler accetta anche la forma senza virgola:

```asm
LDI R0 0x2A
```

Gli esempi ufficiali usano sempre la virgola per migliorare la leggibilita.

## Numeri

Sono supportati quattro formati numerici:

| Sintassi | Base | Esempio      |
| -------- | ---: | ------------ |
| `0xNN`   |   16 | `0x2A`       |
| `$NN`    |   16 | `$2A`        |
| `0bNNNN` |    2 | `0b10101010` |
| `NN`     |   10 | `42`         |

Queste scritture rappresentano lo stesso valore:

```text
0x2A = $2A = 0b00101010 = 42
```

Negli esempi ufficiali si preferisce la notazione esadecimale con prefisso `0x`.

Un operando `imm8` deve essere compreso tra `0x00` e `0xFF`. Un indirizzo `addr16` deve essere compreso tra `0x0000` e `0xFFFF`.

## Commenti

I commenti iniziano con `;` e continuano fino alla fine della riga:

```asm
; Questa intera riga e un commento.
LDI R0, 0x2A  ; Carica 42 nel registro R0.
```

I commenti non generano byte macchina.

## Maiuscole e minuscole

Mnemonic, registri, direttive e simboli sono case-insensitive.

Queste righe sono equivalenti:

```asm
LDI R0, 0x2A
ldi r0, 0x2a
```

Gli esempi ufficiali usano mnemonic e registri in maiuscolo, direttive e label in minuscolo.

## Label

Una label associa un nome all'indirizzo dell'istruzione o del dato che segue. Non genera byte da sola.

```asm
loop:
LDI R0, 0x01
JMP loop
```

Le label possono essere usate come operandi `addr16`:

```asm
JMP start
JZ equal
LDA R0, counter
STA R0, result
```

Regole per i nomi:

- una definizione di label termina con `:`;
- il nome deve iniziare con una lettera o `_`;
- dopo il primo carattere sono ammessi lettere, numeri e `_`;
- i nomi sono case-insensitive;
- lo stesso nome non puo essere definito due volte.

Una label puo essere scritta da sola oppure prima di una istruzione o direttiva sulla stessa riga:

```asm
start:
counter: .byte 0x00
```

L'assembler usa due passate, quindi una istruzione puo fare riferimento a una label definita piu avanti nel file.

Esempio con salti condizionati:

```asm
MOV RA, R0
MOV RB, R1
CMP
JZ equal

LDI R2, 0x00
JMP done

equal:
LDI R2, 0x01

done:
HLT
```

`JZ equal` e `JMP done` vengono tradotte in salti `ADDR16`, sostituendo le label con i rispettivi indirizzi.

## Costanti simboliche

La direttiva `.equ` associa un nome a un valore numerico:

```asm
.equ SCREEN, 0x8000
.equ NEWLINE, 0x0A

LDI R0, NEWLINE
STA R0, SCREEN
```

La direttiva non genera byte macchina. Nella versione attuale, una costante usata per definire un'altra costante deve essere gia stata dichiarata.

## Direttive

Le direttive controllano il lavoro dell'assembler e non vengono eseguite dalla CPU.

| Direttiva           | Effetto                                                               |
| ------------------- | --------------------------------------------------------------------- |
| `.code`             | inizia il codice dall'indirizzo predefinito `0x0000`                   |
| `.code addr16`      | inizia il codice dall'indirizzo indicato                               |
| `.data`             | colloca i dati dal primo indirizzo libero dopo i byte gia generati     |
| `.data addr16`      | colloca i dati dall'indirizzo indicato                                 |
| `.byte value`       | scrive un byte nella posizione corrente                               |
| `.equ name, value`  | associa una costante simbolica a un valore                             |

### `.code` e `.data`

La CPU usa un'architettura di Von Neumann: codice e dati condividono la stessa memoria. `.code` e `.data` non creano memorie separate, ma cambiano solamente l'indirizzo corrente usato dall'assembler.

La forma consigliata per un programma che parte dal reset e non richiede una mappa di memoria specifica e:

```asm
.code 0x0000
start:
LDI R0, 0x01
STA R0, counter
HLT

.data
counter: .byte 0x00
```

In questo esempio il programma inizia a `0x0000`. Le istruzioni occupano sei byte, quindi `counter` viene posizionata automaticamente a `0x0006`.

L'indirizzo puo essere omesso anche da `.code`:

```asm
.code
```

In questo caso viene usato il valore predefinito `0x0000`. Negli esempi didattici si preferisce comunque `.code 0x0000`, per mostrare esplicitamente l'indirizzo iniziale del Program Counter.

La collocazione automatica richiede che la sezione `.code` venga scritta prima della sezione `.data`. Se `.data` senza indirizzo fosse usata all'inizio del file, partirebbe da `0x0000`; una successiva `.code` riporterebbe l'indirizzo a `0x0000` e potrebbe sovrascrivere i dati. La versione attuale dell'assembler non segnala ancora le sovrapposizioni tra sezioni.

Quando l'hardware richiede una mappa di memoria precisa, si puo continuare a indicare l'indirizzo dei dati:

```asm
.data 0x8000
counter: .byte 0x00
```

Per la versione v0.1 non viene usata `.org` come sintassi ufficiale.

### `.byte`

`.byte` inserisce un singolo valore a 8 bit nell'immagine di memoria:

```asm
.data 0x0100
counter: .byte 0x00
total:   .byte 0x00
flag:    .byte 0x01
```

Nella versione v0.1 ogni direttiva `.byte` accetta un solo valore. Per inserire piu byte si usano piu righe.

## Variabili

Nel linguaggio assembly v0.1 una variabile e una label associata a una cella di memoria da 8 bit:

```asm
counter: .byte 0x00
```

La CPU non conosce il concetto di variabile: vede solamente un indirizzo di memoria. Il nome simbolico viene risolto dall'assembler.

Valori e variabili a 16 bit non fanno parte della sintassi v0.1. Potranno essere rappresentati in futuro mediante coppie di byte.

## Esempio con codice e dati

Sorgente:

```asm
.code 0x0000
LDI R0, 0x05
STA R0, counter
LDA R1, counter
HLT

.data
counter: .byte 0x00
```

La parte di codice occupa gli indirizzi da `0x0000` a `0x0008`, quindi la label `counter` viene calcolata automaticamente come `0x0009`. Gli operandi a 16 bit vengono emessi in ordine little-endian, come stabilito dalla ISA:

```text
LDI R0, 0x05    -> 20 05
STA R0, counter -> 48 09 00
LDA R1, counter -> 41 09 00
HLT             -> 01
```

La direttiva `.byte` posiziona infine il valore `0x00` all'indirizzo `0x0009`.

## Errori

L'assembler rifiuta, tra gli altri:

- mnemonic o direttive sconosciuti;
- numero errato di operandi;
- registri diversi da `R0`...`R7` dove e richiesto un registro generale;
- valori immediati che non entrano in 8 bit;
- indirizzi oltre lo spazio a 16 bit;
- label duplicate o non valide;
- simboli non definiti;
- forme `MOV` non supportate.

Quando possibile, il messaggio include il numero della riga sorgente.

## Limiti della versione v0.1

La sintassi attuale non prevede:

- macro;
- inclusione di altri file;
- espressioni aritmetiche tra simboli;
- stringhe;
- liste di valori in una singola `.byte`;
- dati multi-byte;
- indirizzamento indiretto o indicizzato.

Queste funzionalita potranno essere aggiunte senza modificare la codifica macchina delle istruzioni gia definite nella ISA.
