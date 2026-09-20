# Control Unit a microcodice — segnali di controllo

> **Stato:** bozza da verificare sul cablaggio reale
> **Versione:** 0.1
> **Ambito:** CPU TTL a 8 bit, bus dati a 8 bit e bus indirizzi a 16 bit.

Questo documento raccoglie i segnali logici che la Control Unit deve generare
per la CPU attuale. Il generatore converte ciascun segnale nel livello elettrico
richiesto dalla configurazione, per esempio attivo basso per `/OE`, `/WE` o
`/CLR`.

Non sono inclusi:

- i segnali `IN` e `OUT` usati provvisoriamente per test sulla board;
- segnali specifici per video, tastiera e timer: questi dispositivi sono memory-mapped e usano i normali cicli `RAM_OE` e `RAM_WE`.

## 1. Vincoli dei bus

La CPU ha un data bus condiviso `D[7:0]` e un address bus `A[15:0]`.

```text
Su D[7:0]:  al massimo una sorgente puo guidare il bus in ogni microciclo.
Su A[15:0]: il selettore abilita PC, MAR, IDX oppure nessuna sorgente.
```

Le sorgenti del data bus previste sono:

```text
memoria selezionata, MDR, banco registri, RA, ALU
```

Le destinazioni possono invece catturare il medesimo valore sul fronte di clock, se la microistruzione lo richiede.

## 2. Segnali generati dal microcodice

| Gruppo | Segnale | Azione | Note hardware |
| --- | --- | --- | --- |
| Address bus | `ADDR_SEL_0` | Bit 0 del selettore della sorgente di `A[15:0]`. | Con la configurazione attuale: `00=IDX`, `01=PC`, `10=MAR`, `11=nessuna`. |
| Address bus | `ADDR_SEL_1` | Bit 1 del selettore della sorgente di `A[15:0]`. | Pilota con `ADDR_SEL_0` il decoder 74LS138. |
| Program Counter | `PC_INC` | Incrementa il PC di uno. | Avviene dopo ogni byte letto dal flusso istruzioni. |
| Program Counter | `PC_LOAD` | Carica il PC con l'indirizzo presente nel MAR. | Usato dai salti. |
| MAR | `MAR_L_WE` | Salva `D[7:0]` nella parte bassa del MAR. | Primo byte di un indirizzo little-endian. |
| MAR | `MAR_H_WE` | Salva `D[7:0]` nella parte alta del MAR. | Secondo byte di un indirizzo little-endian. |
| IDX | `IDX_L_WE` | Salva `D[7:0]` nella parte bassa di IDX. | Usato da `LDX addr16`. |
| IDX | `IDX_H_WE` | Salva `D[7:0]` nella parte alta di IDX. | Usato da `LDX addr16`. |
| RAM | `RAM_OE` | Abilita la RAM a pilotare `D[7:0]`. | `/OE` attivo basso. |
| RAM | `RAM_WE` | Scrive `D[7:0]` nella RAM. | `/WE` attivo basso; indirizzo e dato devono gia essere stabili. |
| EPROM | `EPROM_OE` | Abilita l'EPROM a pilotare `D[7:0]`. | `/OE` attivo basso, previsto per il boot. |
| Fetch | `IR_WE` | Salva l'opcode letto nel registro `IR`. | Il byte letto viene dal data bus. |
| Registro dati memoria | `MDR_WE` | Salva un byte letto o da scrivere. | Ponte opzionale ma consigliato per gli accessi dati. |
| Registro dati memoria | `MDR_OE` | Porta il contenuto di MDR su `D[7:0]`. | Non attivarlo insieme a un'altra sorgente del bus. |
| Banco registri | `RF_EN` | Abilita il banco dei registri generali. | Il registro e scelto direttamente da `IR[2:0]`. |
| Banco registri | `RF_RW` | Con `RF_EN`, scrive nel registro selezionato. | Con `RF_RW=0`, il registro selezionato e la sorgente del bus. |
| Registri ALU | `RA_EN`, `RB_EN`, `RA_RB_RW` | Abilitano RA/RB e ne definiscono la direzione. | `RA_RB_RW=1` carica il registro abilitato; `0` legge RA sul bus. |
| ALU | `ALU_EN` | Porta il risultato ALU su `D[7:0]`. | Enable attivo basso; l'operazione e selezionata da `IR[3:0]`. |
| Flag | `FLAGS_WE` | Salva `C`, `Z`, `N`, `O` nel registro flag. | Attivo per operazioni ALU e `CMP`, non per load/store/mov/jump. |
| Sequencer | `NEXT_FETCH` | Riporta il microsequencer al primo microciclo di fetch. | Normalmente azzera il contatore dei microstep. |

Il reset globale non e una normale microoperazione:

| Segnale esterno | Azione |
| --- | --- |
| `RESET` | Inizializza PC, microsequencer e gli altri blocchi che richiedono uno stato iniziale noto. |

## 3. Collegamenti diretti dall'Instruction Register

Questi segnali **non devono consumare bit della microistruzione**.

| Bit di IR | Destinazione | Uso |
| --- | --- | --- |
| `IR[2:0]` | selettori del banco registri | Seleziona `R0`…`R7` per `LDI`, `LDA`, `STA` e `MOV`. |
| `IR[3:0]` | decoder ALU | Seleziona AND, OR, XOR, NOR, NAND, XNOR, NOT, ADD, SUB o CMP. |
| `IR[3:0]` | logica delle condizioni | Identifica `JMP`, `JZ`, `JNZ`, `JC`, `JNC`, `JN`, `JNN`, `JO`, `JNO`. |
| `IR[7:5]` | decoder/dispatch | Identifica la macrocategoria: sistema, immediate, memoria, ALU, I/O, jump o trasferimento. |

Per `CMP` serve evitare il salvataggio del risultato in RA:

```text
IS_CMP          = (IR == 0x69)
RA_EN_effettivo = RA_EN AND NOT(IS_CMP)
```

In questo modo `CMP` aggiorna i flag ma non modifica ne RA ne RB.

## 4. Flag come ingressi del microcodice

I flag sono ingressi della Control ROM, non uscite da generare:

```text
C = carry / borrow
Z = zero
N = negative
O = overflow
```

Una possibile mappa per AT28C64 e:

```text
A0..A2   = µSTEP[2:0]
A3..A7   = IR[7:3] (i cinque bit alti dell'opcode, come nel video 25)
A8       = C
A9       = Z
A10      = N
A11      = O
A12      = BOOT_RUN
```

La configurazione fisica mostrata nel video usa direttamente `IR[7:3]`. La
ISA corrente richiede pero di distinguere anche opcode con gli stessi cinque
bit alti (per esempio i salti condizionati); per questo il generatore supporta
un identificatore `µOP` prodotto da un piccolo decoder TTL o da una EEPROM di
dispatch, come estensione opzionale:

```text
IR[7:0] -> decoder/EEPROM dispatch -> µOP[4:0]
```

Il dispatch deve assegnare `µOP` diversi almeno a `LDA` e `STA`, ai tre `MOV` e ai salti condizionati. In questo modo, nella fase finale di un salto la Control ROM puo attivare `PC_LOAD` solo per le combinazioni di flag corrette.

Il contatore `µSTEP[2:0]` identifica i tempi da `T1` a `T8`: `000` corrisponde a `T1` e `111` a `T8`. `NEXT_FETCH` riporta il sequencer a `T1`, quindi un'istruzione puo terminare prima di `T8`; i tempi successivi restano inattivi e disponibili per microsequenze future.

## 5. Microsequenze di riferimento

Ogni riga rappresenta un microciclo. I segnali di scrittura (`*_WE`) catturano il dato sul fronte attivo del clock; i segnali `*_OE` devono essere stabili prima di quel fronte.

### Fetch comune

| Microstep | Segnali | Effetto |
| --- | --- | --- |
| `T1` | `ADDR_SEL=PC`, `RAM_OE`, `IR_WE`, `PC_INC` | Legge l'opcode puntato dal PC, lo salva in IR e avanza al byte seguente. |

### Boot EPROM → RAM

Con `BOOT_RUN=0`, la CU ignora opcode e flag e ripete questi due microcicli.
L'operatore porta poi `BOOT_RUN` a RUN e azzera PC tramite reset esterno prima
di eseguire il programma copiato.

| Microstep | Segnali | Effetto |
| --- | --- | --- |
| `T1` | `ADDR_SEL=PC`, `EPROM_OE`, `MDR_WE` | Legge `EPROM[PC]` in MDR. |
| `T2` | `ADDR_SEL=PC`, `MDR_OE`, `RAM_WE`, `PC_INC`, `NEXT_FETCH` | Scrive MDR in `RAM[PC]` e passa alla cella successiva. |

### `LDI Rn, imm8`

| Microstep | Segnali | Effetto |
| --- | --- | --- |
| `T2` | `ADDR_SEL=PC`, `RAM_OE`, `MDR_WE`, `PC_INC` | Legge l'immediato. |
| `T3` | `MDR_OE`, `RF_EN`, `RF_RW`, `NEXT_FETCH` | Salva l'immediato in `Rn`. |

### `LDA Rn, addr16`

| Microstep | Segnali | Effetto |
| --- | --- | --- |
| `T2` | `ADDR_SEL=PC`, `RAM_OE`, `MAR_L_WE`, `PC_INC` | Legge `addr_low`. |
| `T3` | `ADDR_SEL=PC`, `RAM_OE`, `MAR_H_WE`, `PC_INC` | Legge `addr_high`. |
| `T4` | `ADDR_SEL=MAR`, `RAM_OE`, `MDR_WE` | Legge il byte dati all'indirizzo nel MAR. |
| `T5` | `MDR_OE`, `RF_EN`, `RF_RW`, `NEXT_FETCH` | Salva il byte in `Rn`. |

### `STA Rn, addr16`

| Microstep | Segnali | Effetto |
| --- | --- | --- |
| `T2` | `ADDR_SEL=PC`, `RAM_OE`, `MAR_L_WE`, `PC_INC` | Legge `addr_low`. |
| `T3` | `ADDR_SEL=PC`, `RAM_OE`, `MAR_H_WE`, `PC_INC` | Legge `addr_high`. |
| `T4` | `RF_EN`, `MDR_WE` | Porta `Rn` sul bus e lo salva in MDR. |
| `T5` | `ADDR_SEL=MAR`, `MDR_OE`, `RAM_WE`, `NEXT_FETCH` | Scrive MDR nell'indirizzo del MAR. |

### ALU e trasferimenti

| Istruzione | Microstep execute | Segnali |
| --- | --- | --- |
| ALU eccetto `CMP` | `T2` | `ALU_EN`, `RA_EN`, `RA_RB_RW`, `FLAGS_WE`, `NEXT_FETCH` |
| `CMP` | `T2` | `FLAGS_WE`, `NEXT_FETCH` |
| `MOV RA, Rn` | `T2` | `RF_EN`, `RA_EN`, `RA_RB_RW`, `NEXT_FETCH` |
| `MOV RB, Rn` | `T2` | `RF_EN`, `RB_EN`, `RA_RB_RW`, `NEXT_FETCH` |
| `MOV Rn, RA` | `T2` | `RA_EN`, `RF_EN`, `RF_RW`, `NEXT_FETCH` |
| `LDX addr16` | `T2` | `ADDR_SEL=PC`, `RAM_OE`, `IDX_L_WE`, `PC_INC` |
| `LDX addr16` | `T3` | `ADDR_SEL=PC`, `RAM_OE`, `IDX_H_WE`, `PC_INC`, `NEXT_FETCH` |
| `LDAI Rn` | `T2` | `ADDR_SEL=IDX`, `RAM_OE`, `MDR_WE` |
| `LDAI Rn` | `T3` | `MDR_OE`, `RF_EN`, `RF_RW`, `NEXT_FETCH` |
| `STAI Rn` | `T2` | `RF_EN`, `MDR_WE` |
| `STAI Rn` | `T3` | `ADDR_SEL=IDX`, `MDR_OE`, `RAM_WE`, `NEXT_FETCH` |

### Salti

| Microstep | Segnali | Effetto |
| --- | --- | --- |
| `T2` | `ADDR_SEL=PC`, `RAM_OE`, `MAR_L_WE`, `PC_INC` | Legge `addr_low`. |
| `T3` | `ADDR_SEL=PC`, `RAM_OE`, `MAR_H_WE`, `PC_INC` | Legge `addr_high`. |
| `T4` | `PC_LOAD` se la condizione e vera; `NEXT_FETCH` | Carica il PC dal MAR oppure prosegue sequenzialmente. |

## 6. Organizzazione suggerita delle EEPROM

Una microistruzione ha 22 segnali principali. Tre EEPROM da 8 bit in parallelo
forniscono 24 uscite, lasciando due bit disponibili:

```text
EEPROM 0  -> PC, MAR, address bus, memoria
EEPROM 1  -> IR, MDR, banco registri, RA/RB
EEPROM 2  -> ALU, flag, sequencer, IDX, bit riservati
```

Le linee di indirizzo sono condivise; le tre EEPROM generano tre porzioni della stessa microistruzione da 24 bit.

Una EEPROM di dispatch opzionale usa `IR[7:0]` come indirizzo e produce `µOP[4:0]`. Essa non pilota direttamente i blocchi della CPU.

## 7. Checklist prima del cablaggio finale

- [ ] Verificare sul cablaggio reale i codici `00=IDX`, `01=PC`, `10=MAR`, `11=nessuna sorgente`.
- [ ] Verificare il percorso fisico `MAR -> PC` necessario a `PC_LOAD`.
- [ ] Verificare che il banco registri implementi esattamente la semantica `RF_EN` e `RF_RW` descritta qui.
- [ ] Verificare se il risultato ALU ha un enable indipendente (`ALU_EN`).
- [ ] Verificare se MDR e realmente richiesto in ogni accesso dati o solo nelle scritture.
- [ ] Predisporre un decoder di indirizzo che selezioni RAM, ROM e FPGA senza conflitti sul data bus.
- [ ] Verificare tempi di accesso EEPROM, RAM e propagazione dei buffer prima di scegliere la frequenza di clock.
- [ ] Definire il comportamento esatto del reset e dell'istruzione `HLT`.
