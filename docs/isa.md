# ISA CPU 8-bit

Bozza della Instruction Set Architecture della CPU didattica a 8 bit.

Questa specifica descrive il formato delle istruzioni visto finora nella serie: CPU a 8 bit, architettura di Von Neumann, memoria unica per codice e dati, bus dati a 8 bit e bus indirizzi a 16 bit.

## Stato del documento

Questo documento e la sorgente di verita per la progettazione della ISA. In questa fase non riguarda l'implementazione dell'assembler: prima si stabiliscono formato istruzioni, registri, opcode e comportamento semantico.

## Decisioni confermate

- La CPU usa architettura di Von Neumann.
- Codice e dati condividono la stessa memoria.
- Il data bus e a 8 bit.
- L'address bus e a 16 bit.
- Ogni istruzione inizia con un opcode a 8 bit.
- Le istruzioni possono occupare 1, 2 o 3 byte.
- Gli indirizzi a 16 bit sono salvati in memoria in ordine little-endian: prima byte basso, poi byte alto.
- La CPU dispone di 8 registri generali: `R0`...`R7`.
- I registri generali sono codificati con 3 bit.
- La ALU usa due registri operando dedicati: `RA` e `RB`.
- Il registro `RA` contiene il primo operando della ALU e riceve anche il risultato dell'operazione.
- Il registro `RB` contiene il secondo operando della ALU.
- Il registro `RA` puo leggere e scrivere sul bus dati; il registro `RB` viene usato come registro temporaneo in ingresso alla ALU.
- Per usare i registri generali con la ALU servono istruzioni di trasferimento tra `R0`...`R7` e i registri `RA`/`RB`.
- Non e ammesso il trasferimento diretto `MOV Rx, Ry` tra due registri generali.
- La CPU espone i flag `C`, `Z`, `N`, `O`: carry/borrow, zero, negativo, overflow.
- La ALU genera i segnali di flag in base all'operazione selezionata.
- Il salvataggio dei flag nel registro flag e controllato dalla control unit durante il microcodice dell'istruzione.
- Le istruzioni ALU salvano i flag; le istruzioni di load, store, trasferimento, input/output e salto non salvano nuovi flag.
- I primi 3 bit dell'opcode identificano la macrocategoria dell'istruzione.
- I 5 bit bassi dell'opcode contengono informazioni interpretate in modo diverso in base alla macrocategoria.
- Il confronto viene fatto con una istruzione `CMP`: la logica cablata della ALU esegue internamente la sottrazione di confronto e produce i segnali di flag.
- Il salto condizionato e una istruzione successiva che legge i flag.

## Architettura di memoria

La CPU usa una architettura di Von Neumann:

- codice e dati condividono la stessa memoria;
- la memoria e indirizzata tramite un address bus a 16 bit;
- ogni locazione di memoria contiene 8 bit, quindi 1 byte;
- il data bus e largo 8 bit.

La memoria puo essere vista come una sequenza di byte:

```text
address         value
0x0000          byte
0b0000000000000000

0x0001          byte
0b0000000000000001

0x0002          byte
0b0000000000000010
...
0xFFFF          byte
0b1111111111111111
```

Anche se i chip fisici usati nei primi test possono avere meno linee indirizzo, la CPU viene progettata per lavorare con indirizzi a 16 bit.

## Registri coinvolti nel fetch

Dalle trascrizioni risultano questi registri rilevanti per il formato istruzioni:

| Registro | Dimensione | Ruolo |
| --- | ---: | --- |
| `PC` | 16 bit | Program Counter, punta al prossimo byte da leggere |
| `MAR` | 16 bit | Memory Address Register, pilota l'address bus |
| `IR` | 8 bit | Instruction Register, contiene l'opcode |
| `MDR` | 8 bit | Memory Data Register, contiene dati letti/scritti in memoria |

`PC` e `MAR` sono registri a 16 bit, ma vengono caricati tramite data bus a 8 bit. Per questo sono divisi logicamente in parte bassa e parte alta.

## Formato generale

Ogni istruzione inizia sempre con un opcode a 8 bit.

In base all'opcode, la CPU sa quanti byte aggiuntivi deve leggere durante la fase di fetch.

Sono previste tre categorie:

| Formato | Byte totali | Struttura | Uso |
| --- | ---: | --- | --- |
| `IMP` | 1 | `opcode` | istruzioni senza operando |
| `IMM8` | 2 | `opcode immediate` | istruzioni con valore immediato a 8 bit |
| `ADDR16` | 3 | `opcode addr_low addr_high` | istruzioni con indirizzo di memoria a 16 bit |

In binario:

```text
IMP
byte 0: oooooooo

IMM8
byte 0: oooooooo
byte 1: iiiiiiii

ADDR16
byte 0: oooooooo
byte 1: aaaaaaaa  indirizzo bit 7..0
byte 2: AAAAAAAA  indirizzo bit 15..8
```

Dove:

- `o` indica i bit dell'opcode;
- `i` indica i bit dell'immediato;
- `a` indica la parte bassa dell'indirizzo;
- `A` indica la parte alta dell'indirizzo.

## Ordine degli indirizzi

Per gli operandi a 16 bit si usa ordine little-endian:

```text
addr_low  = bit 7..0
addr_high = bit 15..8
```

Esempio:

```asm
LDA 0x1234
```

viene codificata come:

```text
opcode 0x34 0x12
opcode 0b00110100 0b00010010
```

Questa scelta e coerente con il fatto che `MAR` viene caricato dal bus dati in due passaggi: prima la parte bassa, poi la parte alta.

## Formati assembly

### Istruzione implicita

```asm
HLT
```

Formato:

```text
[opcode]
```

### Istruzione con immediato a 8 bit

```asm
LDI R0, 0x2A
```

Formato:

```text
[opcode] [immediate]
```

### Istruzione con indirizzo a 16 bit

```asm
LDA R0, 0x1234
```

Formato:

```text
[opcode] [addr_low] [addr_high]
```

## Convenzioni assembly

Queste convenzioni definiscono la sintassi assembly associata alla ISA.

### Numeri

Formati numerici supportati:

| Sintassi | Base | Esempio |
| --- | ---: | --- |
| `0xNN` | 16 | `0x2A` |
| `$NN` | 16 | `$2A` |
| `0bNNNN` | 2 | `0b10101010` |
| `NN` | 10 | `42` |

Per evitare ambiguita, negli esempi ufficiali si preferisce `0x`.

Esempio equivalente:

```text
0x2A = 0b00101010 = 42
```

### Commenti

I commenti iniziano con `;`.

```asm
; carica 42 nel registro R0
LDI R0, 0x2A
```

### Maiuscole e minuscole

Mnemonic e nomi dei registri sono case-insensitive.

Queste due righe sono equivalenti:

```asm
LDI R0, 0x2A
ldi r0, 0x2A
```

## Registri assembly

La CPU dispone di 8 registri generali:

```text
R0, R1, R2, R3, R4, R5, R6, R7
```

Servono 3 bit per selezionare un registro:

```text
2^3 = 8 registri
```

| Registro | Codice bin | Codice dec |
| --- | --- | ---: |
| `R0` | `0b000` | 0 |
| `R1` | `0b001` | 1 |
| `R2` | `0b010` | 2 |
| `R3` | `0b011` | 3 |
| `R4` | `0b100` | 4 |
| `R5` | `0b101` | 5 |
| `R6` | `0b110` | 6 |
| `R7` | `0b111` | 7 |

Oltre ai registri generali, la ALU usa due registri dedicati:

| Registro | Dimensione | Uso |
| --- | ---: | --- |
| `RA` | 8 bit | primo operando della ALU e destinazione del risultato |
| `RB` | 8 bit | secondo operando della ALU |

Il flusso operativo della ALU e:

```text
registro generale -> RA
registro generale -> RB
ALU(RA, RB) -> RA
RA -> registro generale
```

Questa scelta deriva dall'hardware gia costruito:

- `RA` e `RB` alimentano direttamente gli ingressi della ALU;
- l'uscita della ALU viene salvata nuovamente in `RA`;
- `RA` puo essere riportato sul bus dati tramite buffer;
- `RB` e un registro temporaneo usato come secondo ingresso della ALU;
- per copiare un valore tra due registri generali si passa da `RA`.

Esempio di copia tra registri generali:

```asm
MOV RA, R0   ; R0 -> RA
MOV R1, RA   ; RA -> R1
```

## Struttura dell'opcode

L'opcode e largo 8 bit.

La struttura scelta e:

```text
bit:    7 6 5 4 3 2 1 0
        c c c x x x x x
```

Dove:

- `ccc` identifica la macrocategoria dell'istruzione;
- `xxxxx` e un campo dati interno all'opcode;
- il significato di `xxxxx` dipende dalla macrocategoria.

Questa struttura serve anche a semplificare l'hardware. La control unit puo decodificare principalmente i 3 bit alti per capire il tipo generale di istruzione. I bit bassi possono invece essere portati, tramite buffer dati, verso blocchi specifici come:

- selezione dei registri generali;
- codice operazione della ALU;
- selezione di condizioni di salto;
- sotto-operazioni della stessa macrocategoria.

In questo modo non serve generare tutte queste informazioni come uscite separate della control unit: una parte del lavoro viene codificata direttamente dentro l'opcode.

## Macrocategorie

Proposta iniziale per i 3 bit alti:

| Bit `ccc` | Hex range | Macrocategoria | Uso |
| --- | --- | --- | --- |
| `000` | `0x00-0x1F` | sistema / controllo | `NOP`, `HLT`, istruzioni senza operando speciale |
| `001` | `0x20-0x3F` | load immediate | caricamento immediato in registro |
| `010` | `0x40-0x5F` | memoria | load/store tra memoria e registri |
| `011` | `0x60-0x7F` | ALU | operazioni aritmetico-logiche |
| `100` | `0x80-0x9F` | I/O | lettura input e scrittura output |
| `101` | `0xA0-0xBF` | jump | salti assoluti e condizionati |
| `110` | `0xC0-0xDF` | trasferimenti | passaggio dati tra registri generali, `RA` e `RB` |
| `111` | `0xE0-0xFF` | riservata | espansioni future |

Questa tabella e una bozza. La cosa importante gia decisa e la separazione:

```text
ccc   = macrocategoria
xxxxx = campo interno riusabile
```

## Campo registro

Per le istruzioni che lavorano su un registro, i 3 bit bassi dell'opcode codificano il registro.

Schema:

```text
opcode = cccssrrr
```

Dove:

- `ccc` identifica la macrocategoria;
- `ss` e un sotto-campo dipendente dalla categoria;
- `rrr` identifica il registro `R0`...`R7`.

I bit `rrr`, cioe `IR[2:0]`, possono essere collegati tramite buffer alla logica di selezione dei registri generali.

Esempio:

| Istruzione | Opcode hex | Opcode bin |
| --- | ---: | --- |
| `LDI R0, imm8` | `0x20` | `0b00100000` |
| `LDI R1, imm8` | `0x21` | `0b00100001` |
| `LDI R2, imm8` | `0x22` | `0b00100010` |
| `LDI R3, imm8` | `0x23` | `0b00100011` |
| `LDI R4, imm8` | `0x24` | `0b00100100` |
| `LDI R5, imm8` | `0x25` | `0b00100101` |
| `LDI R6, imm8` | `0x26` | `0b00100110` |
| `LDI R7, imm8` | `0x27` | `0b00100111` |

In questo esempio:

```text
ccc = 001  load immediate
ss  = 00   sotto-operazione base
rrr = registro
```

## Campo ALU

Per la macrocategoria ALU, i bit bassi dell'opcode possono essere usati per portare direttamente alla ALU il codice operazione.

Schema proposto:

```text
opcode = 011maaaa
```

Dove:

- `011` identifica una istruzione ALU;
- `m` e un bit di modo ancora da definire;
- `aaaa` e il codice operazione interno della ALU.

I bit `aaaa`, cioe `IR[3:0]`, possono essere collegati tramite buffer al decoder del codice operazione della ALU.

Operazioni ALU previste:

| ALU op | Codice bin | Note |
| --- | --- | --- |
| `AND` | `0b0000` | rete AND |
| `OR` | `0b0001` | rete OR |
| `XOR` | `0b0010` | rete XOR |
| `NOR` | `0b0011` | rete NOR |
| `NAND` | `0b0100` | rete NAND |
| `XNOR` | `0b0101` | rete XNOR |
| `NOT` | `0b0110` | rete NOT |
| `ADD` | `0b0111` | somma |
| `SUB` | `0b1000` | sottrazione |
| `CMP` | `0b1001` | confronto cablato nella ALU, produce i flag |

Le istruzioni ALU non selezionano direttamente un registro generale. Operano sui registri dedicati `RA` e `RB`.

Per le operazioni binarie:

```text
RA = RA op RB
```

Per `NOT`:

```text
RA = NOT RA
```

Per `CMP`:

```text
flag_signals = compare(RA, RB)
```

`CMP` seleziona la rete di confronto gia cablata nella ALU. La ALU esegue internamente la sottrazione necessaria al confronto e produce i segnali di flag. La control unit deve poi abilitare, nel microcodice di `CMP`, il salvataggio di questi segnali nel registro flag.

`CMP` non deve essere considerata una copia esplicita del risultato in un registro generale. Una eventuale istruzione di salto successiva legge il registro flag.

## Flag

La CPU usa quattro flag principali:

| Flag | Nome | Significato |
| --- | --- | --- |
| `C` | Carry / Borrow | riporto in somma oppure prestito in sottrazione/confronto |
| `Z` | Zero | il risultato e `0b00000000` |
| `N` | Negative | il bit 7 del risultato e `1` |
| `O` | Overflow | overflow aritmetico con numeri signed in complemento a due |

La ALU produce i segnali di flag. Il registro flag li memorizza solo quando la control unit abilita il caricamento dei flag.

Le istruzioni che devono salvare i flag nel registro flag sono:

- operazioni ALU: `AND`, `OR`, `XOR`, `NOR`, `NAND`, `XNOR`, `NOT`, `ADD`, `SUB`;
- confronto: `CMP`.

Le istruzioni che non devono salvare nuovi flag sono:

- `NOP`, `HLT`;
- `LDI`, `LDA`, `STA`;
- `MOV RA, Rn`, `MOV RB, Rn`, `MOV Rn, RA`;
- `IN`, `OUT`;
- tutti i salti.

Per le operazioni logiche:

```text
Z = 1 se il risultato e 0
N = bit 7 del risultato
C = 0
O = 0
```

Per `ADD`:

```text
RA = RA + RB
C = carry out unsigned
Z = 1 se RA e 0 dopo l'operazione
N = bit 7 di RA dopo l'operazione
O = overflow signed in complemento a due
```

Per `SUB`:

```text
RA = RA - RB
C = borrow unsigned
Z = 1 se RA e 0 dopo l'operazione
N = bit 7 di RA dopo l'operazione
O = overflow signed in complemento a due
```

Per `CMP`:

```text
la ALU seleziona l'operazione cablata di confronto
la logica di confronto equivale a valutare RA - RB
i segnali C, Z, N, O vengono prodotti dalla ALU
la control unit salva questi segnali nel registro flag
RA non viene modificato
RB non viene modificato
```

Con questa convenzione, dopo `CMP`:

- `Z = 1` indica `RA == RB`;
- `Z = 0` indica `RA != RB`;
- `C = 1` indica `RA < RB` in confronto unsigned;
- `C = 0` indica `RA >= RB` in confronto unsigned.

## Trasferimenti tra registri generali e registri ALU

Per usare la ALU con i registri generali servono istruzioni di trasferimento esplicite.

Schema proposto per la macrocategoria `110`:

```text
opcode = 110ssrrr
```

Dove:

- `110` identifica una istruzione di trasferimento;
- `ss` identifica il tipo di trasferimento;
- `rrr` identifica il registro generale `R0`...`R7`.

Sotto-operazioni proposte:

| `ss` | Opcode bin | Assembly | Effetto |
| --- | --- | --- | --- |
| `00` | `0b11000rrr` | `MOV RA, Rn` | copia `Rn` in `RA` |
| `01` | `0b11001rrr` | `MOV RB, Rn` | copia `Rn` in `RB` |
| `10` | `0b11010rrr` | `MOV Rn, RA` | copia `RA` in `Rn` |
| `11` | `0b11011rrr` | riservata | disponibile per estensioni future |

Queste istruzioni rispettano il circuito visto nei video:

- un registro generale selezionato puo mettere il proprio valore sul bus dati;
- `RA` o `RB` possono salvare il valore presente sul bus;
- solo `RA` puo essere usato per riportare il risultato della ALU sul bus dati;
- per scrivere un risultato in un registro generale si copia `RA` nel registro scelto.

Non esiste una istruzione hardware `MOV Rn, Rm` per copiare direttamente tra due registri generali. Il blocco dei registri generali consente di selezionare un solo registro alla volta per lettura o scrittura, quindi la copia deve passare da `RA`.

Esempio di copia tra registri generali:

```asm
MOV RA, R0
MOV R1, RA
```

Esempio di somma:

```asm
LDI R0, 10
LDI R1, 20
MOV RA, R0
MOV RB, R1
ADD
MOV R2, RA
```

Effetto:

```text
RA = R0
RB = R1
RA = RA + RB
R2 = RA
```

## Input e output

La categoria `100` e usata per le istruzioni di I/O.

Schema proposto:

```text
opcode = 100ssrrr
```

Dove:

- `100` identifica una istruzione di I/O;
- `ss` identifica il tipo di I/O;
- `rrr` identifica il registro generale `R0`...`R7`.

Sotto-operazioni proposte:

| `ss` | Opcode bin | Assembly | Effetto |
| --- | --- | --- | --- |
| `00` | `0b10000rrr` | `IN Rn` | copia il valore della periferica di input in `Rn` |
| `01` | `0b10001rrr` | `OUT Rn` | copia `Rn` nel registro/periferica di output |
| `10` | `0b10010rrr` | riservata | disponibile per estensioni future |
| `11` | `0b10011rrr` | riservata | disponibile per estensioni future |

`IN` rappresenta l'input a 8 bit collegato al bus dati tramite buffer, come lo switch usato nei test hardware.

`OUT` rappresenta un registro o periferica di output a 8 bit.

## Salti

La categoria `101` e usata per i salti assoluti e condizionati.

Tutti i salti usano un indirizzo a 16 bit in formato little-endian:

```text
opcode addr_low addr_high
```

Tabella condizioni:

| Mnemonic | Opcode hex | Opcode bin | Condizione |
| --- | ---: | --- | --- |
| `JMP addr16` | `0xA0` | `0b10100000` | sempre |
| `JZ addr16` | `0xA1` | `0b10100001` | `Z = 1` |
| `JNZ addr16` | `0xA2` | `0b10100010` | `Z = 0` |
| `JC addr16` | `0xA3` | `0b10100011` | `C = 1` |
| `JNC addr16` | `0xA4` | `0b10100100` | `C = 0` |
| `JN addr16` | `0xA5` | `0b10100101` | `N = 1` |
| `JNN addr16` | `0xA6` | `0b10100110` | `N = 0` |
| `JO addr16` | `0xA7` | `0b10100111` | `O = 1` |
| `JNO addr16` | `0xA8` | `0b10101000` | `O = 0` |

Per confronti unsigned dopo `CMP`:

- `JZ` salta se `RA == RB`;
- `JNZ` salta se `RA != RB`;
- `JC` salta se `RA < RB`;
- `JNC` salta se `RA >= RB`.

## Bozza tabella opcode

La seguente tabella e una proposta iniziale. Gli opcode non sono ancora definitivi.

| Mnemonic | Opcode hex | Opcode bin | Formato | Byte | Descrizione |
| --- | ---: | --- | --- | ---: | --- |
| `NOP` | `0x00` | `0b00000000` | `IMP` | 1 | Nessuna operazione |
| `HLT` | `0x01` | `0b00000001` | `IMP` | 1 | Ferma la CPU |
| `LDI Rn, imm8` | `0x20-0x27` | `0b00100rrr` | `IMM8` | 2 | Carica un valore immediato nel registro `Rn` |
| `LDA Rn, addr16` | `0x40-0x47` | `0b01000rrr` | `ADDR16` | 3 | Carica in `Rn` il byte letto dalla memoria |
| `STA Rn, addr16` | `0x48-0x4F` | `0b01001rrr` | `ADDR16` | 3 | Scrive `Rn` in memoria |
| `AND` | `0x60` | `0b01100000` | `IMP` | 1 | Seleziona operazione ALU `AND` |
| `OR` | `0x61` | `0b01100001` | `IMP` | 1 | Seleziona operazione ALU `OR` |
| `XOR` | `0x62` | `0b01100010` | `IMP` | 1 | Seleziona operazione ALU `XOR` |
| `NOR` | `0x63` | `0b01100011` | `IMP` | 1 | Seleziona operazione ALU `NOR` |
| `NAND` | `0x64` | `0b01100100` | `IMP` | 1 | Seleziona operazione ALU `NAND` |
| `XNOR` | `0x65` | `0b01100101` | `IMP` | 1 | Seleziona operazione ALU `XNOR` |
| `NOT` | `0x66` | `0b01100110` | `IMP` | 1 | Esegue `RA = NOT RA` |
| `ADD` | `0x67` | `0b01100111` | `IMP` | 1 | Esegue `RA = RA + RB` |
| `SUB` | `0x68` | `0b01101000` | `IMP` | 1 | Esegue `RA = RA - RB` |
| `CMP` | `0x69` | `0b01101001` | `IMP` | 1 | Confronta `RA` e `RB` tramite logica ALU cablata, salva i flag |
| `IN Rn` | `0x80-0x87` | `0b10000rrr` | `IMP` | 1 | Copia input in `Rn` |
| `OUT Rn` | `0x88-0x8F` | `0b10001rrr` | `IMP` | 1 | Copia `Rn` nel registro/periferica di output |
| `JMP addr16` | `0xA0` | `0b10100000` | `ADDR16` | 3 | Carica il PC con un nuovo indirizzo |
| `JZ addr16` | `0xA1` | `0b10100001` | `ADDR16` | 3 | Salta se il flag zero e attivo |
| `JNZ addr16` | `0xA2` | `0b10100010` | `ADDR16` | 3 | Salta se il flag zero non e attivo |
| `JC addr16` | `0xA3` | `0b10100011` | `ADDR16` | 3 | Salta se il flag carry/borrow e attivo |
| `JNC addr16` | `0xA4` | `0b10100100` | `ADDR16` | 3 | Salta se il flag carry/borrow non e attivo |
| `JN addr16` | `0xA5` | `0b10100101` | `ADDR16` | 3 | Salta se il flag negative e attivo |
| `JNN addr16` | `0xA6` | `0b10100110` | `ADDR16` | 3 | Salta se il flag negative non e attivo |
| `JO addr16` | `0xA7` | `0b10100111` | `ADDR16` | 3 | Salta se il flag overflow e attivo |
| `JNO addr16` | `0xA8` | `0b10101000` | `ADDR16` | 3 | Salta se il flag overflow non e attivo |
| `MOV RA, Rn` | `0xC0-0xC7` | `0b11000rrr` | `IMP` | 1 | Copia `Rn` nel registro `RA` |
| `MOV RB, Rn` | `0xC8-0xCF` | `0b11001rrr` | `IMP` | 1 | Copia `Rn` nel registro `RB` |
| `MOV Rn, RA` | `0xD0-0xD7` | `0b11010rrr` | `IMP` | 1 | Copia `RA` nel registro `Rn` |

## Confronti e salti condizionati

Il confronto viene diviso in due momenti:

1. `CMP`, che seleziona la logica di confronto cablata nella ALU e fa salvare i flag alla control unit;
2. una eventuale istruzione di salto, che legge il registro flag e decide se modificare il `PC`.

Esempio:

```asm
CMP
JZ 0x0200
```

In questo caso `CMP` confronta `RA` e `RB`. La ALU produce i segnali di flag usando la logica cablata di confronto; la control unit li salva nel registro flag. L'istruzione successiva, `JZ 0x0200`, controlla il flag `Z` salvato e salta all'indirizzo `0x0200` solo se quel flag e attivo.

Questa scelta evita di creare molte istruzioni ALU diverse per ogni confronto. La ALU produce i segnali di flag; la control unit decide quando salvarli e poi li usa per eseguire o ignorare il salto condizionato.

## Esempio di programma

Assembly:

```asm
; carica 10 in R0 e ferma la CPU
LDI R0, 0x0A
OUT R0
HLT
```

Codifica proposta:

```text
hex: 0x20 0x0A 0x88 0x01
bin: 0b00100000 0b00001010 0b10001000 0b00000001
```

Layout in memoria:

| Indirizzo hex | Indirizzo bin | Valore hex | Valore bin | Significato |
| --- | --- | --- | --- | --- |
| `0x0000` | `0b0000000000000000` | `0x20` | `0b00100000` | opcode `LDI R0, imm8` |
| `0x0001` | `0b0000000000000001` | `0x0A` | `0b00001010` | immediato |
| `0x0002` | `0b0000000000000010` | `0x88` | `0b10001000` | opcode `OUT R0` |
| `0x0003` | `0b0000000000000011` | `0x01` | `0b00000001` | opcode `HLT` |

## Esempio ALU con registri RA e RB

Assembly:

```asm
; R2 = R0 + R1
MOV RA, R0
MOV RB, R1
ADD
MOV R2, RA
```

Codifica proposta:

```text
hex: 0xC0 0xC9 0x67 0xD2
bin: 0b11000000 0b11001001 0b01100111 0b11010010
```

Layout in memoria:

| Indirizzo hex | Indirizzo bin | Valore hex | Valore bin | Significato |
| --- | --- | --- | --- | --- |
| `0x0000` | `0b0000000000000000` | `0xC0` | `0b11000000` | opcode `MOV RA, R0` |
| `0x0001` | `0b0000000000000001` | `0xC9` | `0b11001001` | opcode `MOV RB, R1` |
| `0x0002` | `0b0000000000000010` | `0x67` | `0b01100111` | opcode `ADD` |
| `0x0003` | `0b0000000000000011` | `0xD2` | `0b11010010` | opcode `MOV R2, RA` |

## Esempio con indirizzo a 16 bit

Assembly:

```asm
LDA R2, 0x1234
STA R2, 0x00FF
```

Codifica proposta:

```text
LDA R2, 0x1234
hex: 0x42 0x34 0x12
bin: 0b01000010 0b00110100 0b00010010

STA R2, 0x00FF
hex: 0x4A 0xFF 0x00
bin: 0b01001010 0b11111111 0b00000000
```

Layout in memoria:

| Indirizzo hex | Indirizzo bin | Valore hex | Valore bin | Significato |
| --- | --- | --- | --- | --- |
| `0x0000` | `0b0000000000000000` | `0x42` | `0b01000010` | opcode `LDA R2, addr16` |
| `0x0001` | `0b0000000000000001` | `0x34` | `0b00110100` | byte basso indirizzo `0x1234` |
| `0x0002` | `0b0000000000000010` | `0x12` | `0b00010010` | byte alto indirizzo `0x1234` |
| `0x0003` | `0b0000000000000011` | `0x4A` | `0b01001010` | opcode `STA R2, addr16` |
| `0x0004` | `0b0000000000000100` | `0xFF` | `0b11111111` | byte basso indirizzo `0x00FF` |
| `0x0005` | `0b0000000000000101` | `0x00` | `0b00000000` | byte alto indirizzo `0x00FF` |

## Punti ancora da decidere

- codifica definitiva degli opcode;
- eventuale uso del range riservato `0b11011rrr` nei trasferimenti;
- eventuali istruzioni di indirizzamento indiretto o indicizzato;
- eventuali estensioni per input/output aggiuntivi;
- eventuale supporto a confronti signed tramite combinazioni dei flag `N` e `O`.
