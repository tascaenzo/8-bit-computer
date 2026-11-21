# Programmi assembly

Questa cartella contiene programmi di esempio per la CPU a 8 bit.

I file `.asm` vengono assemblati dallo strumento in `tools/assembler`.

La sintassi usata negli esempi e descritta in [`docs/assembly-language.md`](../../docs/assembly-language.md). La semantica e la codifica macchina delle istruzioni sono definite in [`docs/isa.md`](../../docs/isa.md).

## Esempi disponibili

| File | Cosa mostra |
| --- | --- |
| `demo.asm` | template generale commentato con `.equ`, sezioni, label, variabili e schema della memoria |
| `01_numeric_formats.asm` | valori decimali, esadecimali e binari |
| `02_memory_and_directives.asm` | direttive, costanti, label e memoria |
| `03_add_two_numbers.asm` | somma con `RA`, `RB`, `ADD` e copia del risultato in un registro generale |
| `04_alu_operations.asm` | operazioni `AND`, `OR`, `XOR`, `NOR`, `NAND`, `XNOR`, `NOT` e `SUB` |
| `05_compare_unsigned.asm` | confronto unsigned con `CMP`, `JZ`, `JC` e `JMP` |
| `06_labels_and_two_passes.asm` | label in avanti e assemblaggio in due passate |
| `07_jump_conditions.asm` | panoramica di `JZ`, `JNZ`, `JC`, `JNC`, `JN`, `JNN`, `JO` e `JNO` |
| `08_count_to_ten.asm` | contatore in RAM da un valore iniziale a 10 con `LDA`, `STA`, `ADD`, `CMP`, `JZ` e `JMP`, poi `HLT` |
| `video_hello_counter.asm` | HELLO WORLD e contatore RAM in decimale da 000 a 255, con ritorno a zero e ciclo infinito |
| `video_hello_minimal.asm` | HELLO WORLD e FROM 8 BIT COMPUTER su due righe: LDX, LDI, STAI e HLT; 101 byte, Tang da resettare e attendere pronta prima di RUN |
| `video_hello_mar.asm` | Stesso testo con STA e MAR, senza IDX; 154 byte, confronto con video_hello_minimal.asm |
| `cu_isa_smoke.asm` | prova fisica senza IN/OUT: SUB, CMP, JNZ, memoria diretta/IDX e HLT; scrive tre byte verificabili in RAM |
| `test_mar_pc.asm` | esegue subito `JMP 4` per verificare il caricamento MAR -> PC; distingue il salto riuscito dall'arresto a indirizzo 3 |
| `countdown_from_ram.asm` | conto alla rovescia di 7 istruzioni: legge 3 dalla RAM e conta fino a zero con `SUB` e `JNZ`; 13 byte incluso il dato |

`demo.asm` non e numerato perche serve come template autonomo. Gli altri file seguono l'ordine didattico consigliato da `01` a `08`.
Riassemblare gli esempi prima di caricarli nella EPROM programma: i nuovi
opcode di `SUB` e dei salti condizionati non sono compatibili con i vecchi
binari.

## Sequenza per il video sull'assembler

Per il video dedicato all'assembler si possono mostrare `demo.asm`, `01`, `02` e `06`. I commenti possono essere letti o evidenziati mentre si analizzano le singole righe.

| File | Risultato previsto |
| --- | --- |
| `01_numeric_formats.asm` | `R0`...`R3` contengono tutti `0x2A` |
| `02_memory_and_directives.asm` | `R0` e `R1` contengono entrambi `0x0A` |
| `06_labels_and_two_passes.asm` | `R2` contiene `1` quando i valori sono uguali |

Compilazione dell'assembler:

```sh
make -C tools/assembler
```

Assemblaggio dei tre esempi dalla root del repository:

```sh
tools/assembler/build/cpu8asm examples/assembly/01_numeric_formats.asm -o tools/assembler/build/video-01
tools/assembler/build/cpu8asm examples/assembly/02_memory_and_directives.asm -o tools/assembler/build/video-02
tools/assembler/build/cpu8asm examples/assembly/06_labels_and_two_passes.asm -o tools/assembler/build/video-06
```

Dimensioni attese:

```text
01_numeric_formats.asm           9 byte
02_memory_and_directives.asm    10 byte
06_labels_and_two_passes.asm    18 byte
```

Durante la registrazione si puo seguire questa sequenza:

1. Confrontare le quattro scritture dello stesso valore in `01_numeric_formats.asm`.
2. Aprire `video-01.hex` e verificare che il byte immediato sia sempre `2A`.
3. Usare `02_memory_and_directives.asm` per distinguere istruzioni e direttive.
4. Aprire `video-02.hex` e mostrare la label `counter`, calcolata automaticamente e tradotta in `09 00` little-endian.
5. Usare `06_labels_and_two_passes.asm` per spiegare la tabella dei simboli.
6. Aprire `video-06.hex` e mostrare gli indirizzi `0F 00` per `equal` e `11 00` per `done`.

## Copertura ISA

| Area | Esempi |
| --- | --- |
| Sistema | gli esempi finiti terminano con `HLT` (`0x00`); il contatore video usa un ciclo infinito; `NOP` vale `0x01` |
| Load immediate | `demo.asm` e gli esempi numerati coprono `LDI` |
| Memoria | `demo.asm` e `02_memory_and_directives.asm` coprono `LDA`, `STA`, `.data` e `.byte` |
| ALU | `03_add_two_numbers.asm` copre `ADD`; `04_alu_operations.asm` copre le altre operazioni; `05_compare_unsigned.asm` copre `CMP` |
| Salti | `05_compare_unsigned.asm` copre i salti unsigned principali; `07_jump_conditions.asm` elenca tutti i salti condizionali; `06_labels_and_two_passes.asm` mostra le label in avanti |
| Trasferimenti | `03_add_two_numbers.asm`, `04_alu_operations.asm` e `05_compare_unsigned.asm` coprono `MOV RA, Rn`, `MOV RB, Rn` e `MOV Rn, RA` |

## Esempio minimo

```asm
.code 0x0000
LDI R0, 0x0A
STA R0, counter
LDA R1, counter
HLT

.data
counter: .byte 0x00
```

## Scheda video FPGA con IDX

[video_idx.asm](video_idx.asm) scrive `HELLO WORLD FROM 8 BIT COMPUTER` nella prima riga
in bianco su nero e `A` color oro in riga 2, colonna 5 (coordinate da zero).
Usa la [mappa video corrente](../../docs/video-registers.md): VIDEO_DATA a `0x2000`,
attesa READY a `0x2018`, cancellazione schermo e puntatore interno alla Tang.
IDX resta su VIDEO_DATA durante le scritture; il puntatore avanza nella FPGA.
Non rilegge la VRAM: la versione corrente espone registri, non una finestra RAM leggibile.
Termina con HLT, lasciando il video attivo. Avviare la CPU in RUN con la nuova build.

```sh
tools/assembler/build/cpu8asm examples/assembly/video_idx.asm -o tools/assembler/build/video_idx
```

[video_color_demo.asm](video_color_demo.asm) dimostra anche righe, colori e cursore lampeggiante.

## HELLO WORLD e contatore continuo

[video_hello_counter.asm](video_hello_counter.asm) attende READY, configura il video
bianco su nero, cancella lo schermo e scrive:

```text
HELLO WORLD
VAR = 000
VAR = 001
VAR = 002
...
VAR = 255
VAR = 000
```

La variabile e' un byte RAM a `0x0100`, inizializzato a zero dal programma;
non richiede un byte dati separato nella EEPROM. Viene incrementato a ogni
giro, modulo 256. La conversione decimale produce tre cifre ASCII con zeri
iniziali. NEWLINE e AUTO_SCROLL continuano a far scorrere le righe; la
scritta iniziale esce dallo schermo quando lo scorrimento la raggiunge.

`DELAY_COUNT=32` inserisce una pausa tra righe; si puo' scegliere 1-255 e la
durata dipende dal clock CPU. Il programma non termina con HLT. Gli accessi
a variabile e registri video usano IDX; i salti usano comunque MAR e non
aggirano eventuali problemi elettrici del suo caricamento.

```sh
tools/assembler/build/cpu8asm examples/assembly/video_hello_counter.asm -o tools/assembler/build/video_hello_counter
node --test tools/simulator-web/tests/video-hello-counter.test.js
```

Questa versione genera 202 byte, tutti nei primi 256 indirizzi; RAM[0100]
resta fuori dal codice. I file pronti sono in `output/programmi/video_hello_counter.*`.
Il test verifica un giro completo 000-255 e il ritorno a 000, i percorsi di
attesa BUSY, l'inizializzazione della variabile e l'integrita' del codice.
E' un test logico con periferica simulata, non un collaudo dei tempi sul banco.

## Test isolato LDA / STA sulla RAM

[test_lda_sta_ram.asm](test_lda_sta_ram.asm) esegue solo:

```asm
LDA R0, 0x0100
STA R0, 0x0201
LDA R1, 0x0201
HLT
```

La sorgente 0100 parte da 5A e la destinazione 0201 da A5. Al termine
R0=R1=5A e RAM[0201]=5A. Non usa la Tang, IDX, ALU o salti.
Il BOOT deve copiare almeno fino a 0201 incluso. Ripetere BOOT prima di
una nuova prova se si vuole ripristinare il valore iniziale A5.

[Guida con tutti i microstep](../../output/pdf/test-lda-sta-ram-step-check.pdf):
19 impulsi, punto 20 in HLT. Il binario completo misura 514 byte perche
include i vuoti; il file `tools/assembler/build/test_lda_sta_ram.sparse.hex`
contiene soltanto i 12 byte necessari, da usare con il programmatore.

## Test video minimo: una H

[video_one_char.asm](video_one_char.asm) contiene solo `LDI R0, 0x48`,
`STA R0, 0x2000`, `HLT`. Sono 6 byte: `20 48 48 00 20 00`.
Con CU0 aggiornata il 12 novembre 2026, la prima richiesta di scrittura video
e al punto 10, STA/T6 (101); servono 13 impulsi per arrivare a HLT e il punto
14 e solo misura.

Non legge STATUS: prima del test bisogna resettare la Tang e attendere
READY in RUN. Senza reset Tang, ogni esecuzione scrive nella cella successiva.
[PDF di una pagina con i microstep](../../output/pdf/video-one-char-step-check.pdf).

```sh
tools/assembler/build/cpu8asm examples/assembly/video_one_char.asm -o tools/assembler/build/video_one_char
```
