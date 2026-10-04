# Verifiche della Control Unit

Questo documento raccoglie, una fase alla volta, le operazioni da provare sulla
CPU fisica, i livelli attesi e le misure effettuate. Ogni riga delle tabelle
BOOT e RUN corrisponde a un preciso intervallo temporale `T1..T8` del
contatore dei microstep. Gli ingressi `A0..A12` sono comuni alle tre Control
ROM; ogni ROM presenta contemporaneamente il proprio byte `D7..D0`.

**Stato delle misure:** da eseguire. I valori nelle tabelle sono quelli
generati dal microcodice, non letture gia effettuate sulla scheda.

**Versione della ROM0 da testare:** il binario aggiornato contiene `0x91` in
T1, `0xB5` in T2 e `0x31` in T3. Il 23 settembre 2026 la EEPROM fisica e
stata riprogrammata con questo binario: 8192 byte scritti e verifica CRC-16
finale riuscita. Il nuovo binario RUN descritto sotto **non e ancora stato
caricato nelle tre EEPROM fisiche**. Restano da misurare i livelli sulla CU.

Riferimenti: [configurazione dei pin](../tools/cu-bytecode/config/control_signals.c),
[generatore del microcodice](../tools/cu-bytecode/src/microcode.c),
[mappa completa delle uscite](control-unit-eeprom-output-map.md).

## BOOT: copia EPROM → RAM

T1, T2 e T3 sono **tre fasi temporali distinte**, una dopo l'altra; non sono
tre pin della EEPROM. Il contatore le codifica sui suoi tre bit `µSTEP[2:0]`,
che entrano nelle EEPROM come parte dell'indirizzo. La sequenza e
`T1 (000) → clock → T2 (001) → clock → T3 (010) → clock con NEXT_FETCH → T1 (000)`
se D7 pilota `/LOAD` del 74161. Sul cablaggio con `/CLR` asincrono il ritorno
puo avvenire gia durante T3: questo va misurato sulla scheda.

Il PC seleziona il bus indirizzi in tutte e tre le fasi. In T1 l'EPROM presenta
il byte e la RAM lo scrive; in T2 la RAM termina la scrittura, l'EPROM continua
a presentare il dato e il PC avanza al clock; in T3 l'EPROM continua a pilotare
il bus dati mentre la CU riporta il contatore alla fase T1.

### Tabella di verita 1 — ingressi comuni alle tre Control ROM

`0` = livello logico basso, `1` = livello logico alto. Per questa prova fissiamo
`IR[7:3]=00000` e i quattro flag a `0000`, cosi ogni ingresso e l'indirizzo
risultante hanno un valore preciso. Su tutte e tre le EEPROM la piedinatura e:
`A12` pin 1 = `BOOT_RUN`; `A11..A8` pin 21, 19, 22, 23 = `O,N,Z,C`;
`A7..A3` pin 2, 3, 4, 5, 6 = `IR[7:3]`;
`A2` pin 7 = `µSTEP[0]`, `A1` pin 8 = `µSTEP[1]`,
`A0` pin 24 = `µSTEP[2]`.

| Fase temporale | Bit logici del contatore `µSTEP[2:0]` | `A12` | `A11..A8` | `A7..A3` | `A2` | `A1` | `A0` | Indirizzo EEPROM `A12..A0` in binario |
| --- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | ---: |
| **T1 — copia** | `000` | 0 | `0000` | `00000` | 0 | 0 | 0 | `0 0000 00000 000` |
| **T2 — chiusura scrittura e PC++** | `001` | 0 | `0000` | `00000` | 1 | 0 | 0 | `0 0000 00000 100` |
| **T3 — reset del microstep** | `010` | 0 | `0000` | `00000` | 0 | 1 | 0 | `0 0000 00000 010` |

I bit fisici `A2:A1:A0` passano quindi da `000` a `100` a `010`.
Se IR o flag non sono a zero, `A3..A11` seguono i loro valori reali e
l'indirizzo numerico cambia. Nel banco BOOT le uscite attese restano identiche.

### Tabella di verita 2 — uscite Control ROM 0

Ogni cella e il livello logico atteso **sul pin di uscita della Control ROM 0
durante quella fase**, non il contenuto del registro controllato. Uno `0` su
un segnale con `/` nel nome lo attiva. I pin `D7..D0` della AT28C64 DIP-28
sono rispettivamente `17, 16, 15, 14, 13, 11, 10, 9`.

| Fase temporale | `D7`<br>`NEXT_FETCH_n` | `D6`<br>`/OE_EPROM` | `D5`<br>`/WE_RAM` | `D4`<br>`/OE_MDR` | `D3`<br>`MDR_WE` | `D2`<br>`PC_INC` | `D1`<br>`ADDR_SEL_1` | `D0`<br>`ADDR_SEL_0` | Byte ROM0 `D7..D0` in binario |
| --- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | ---: |
| **T1 — copia** | 1 | 0 | 0 | 1 | 0 | 0 | 0 | 1 | `10010001` |
| **T2 — chiusura scrittura e PC++** | 1 | 0 | 1 | 1 | 0 | 1 | 0 | 1 | `10110101` |
| **T3 — reset del microstep** | 0 | 0 | 1 | 1 | 0 | 0 | 0 | 1 | `00110001` |

La coppia `D1:D0=01` mantiene il PC come sorgente dell'indirizzo. I byte
`D7..D0` sono `10010001` (`0x91`) in T1, `10110101` (`0xB5`) in T2 e
`00110001` (`0x31`) in T3. Durante BOOT la Control ROM 1 genera `0x00` e la
Control ROM 2 genera `0x49`: in particolare `/OE_RAM` (ROM2 `D3`) deve restare
alto per evitare che la RAM piloti il bus dati insieme alla EPROM.

| Fase BOOT | ROM1 `D7..D0` | ROM2 `D7..D0` |
| --- | :---: | :---: |
| T1 | `00000000` | `01001001` |
| T2 | `00000000` | `01001001` |
| T3 | `00000000` | `01001001` |

La sequenza della scrittura RAM e `+5 V → 0 V → +5 V` su `/WE_RAM`:
T3 della copia precedente = alto, T1 = basso, T2 = alto. Il dato della EPROM
pilota il bus in T1, T2 e T3. Dopo l'incremento del PC, in T3 l'EPROM puo
presentare gia il byte dell'indirizzo successivo; `/WE_RAM` e alto, quindi
questo byte non deve modificare la RAM.

### Programma EPROM usato per la prova

Il 23 settembre 2026 e stato assemblato
[`examples/assembly/demo.asm`](../examples/assembly/demo.asm) e caricato nella
EEPROM programma tramite Arduino. Il primo caricamento non ha superato il CRC
finale; il secondo ha superato il CRC e una rilettura indipendente ha confermato
tutti i 10 byte seguenti. La colonna dati indica sia il valore della EPROM
programma sia quello atteso nella RAM dopo la copia:

| Indirizzo `A15..A0` (16 bit) | Dato `D7..D0` (8 bit) |
| --- | --- |
| `0000 0000 0000 0000` | `0010 0000` |
| `0000 0000 0000 0001` | `0000 1010` |
| `0000 0000 0000 0010` | `0100 1000` |
| `0000 0000 0000 0011` | `0000 1001` |
| `0000 0000 0000 0100` | `0000 0000` |
| `0000 0000 0000 0101` | `0100 0001` |
| `0000 0000 0000 0110` | `0000 1001` |
| `0000 0000 0000 0111` | `0000 0000` |
| `0000 0000 0000 1000` | `0000 0001` |
| `0000 0000 0000 1001` | `0000 0000` |

Durante il BOOT i primi dieci byte della RAM devono diventare identici ai
valori della tabella, allo stesso indirizzo. Sono stati scritti soltanto gli
indirizzi `0x0000..0x0009` della EEPROM programma: gli altri byte mantengono il loro
contenuto precedente e non costituiscono un riferimento noto per questa prova.
Questa tabella documenta la **EEPROM programma gia caricata il 23 settembre**:
il byte `0x01` a `0x0008` era il vecchio `HLT`, ma con la nuova ISA e `NOP`.
Riassemblando `demo.asm` oggi, a `0x0008` viene generato `0x00`; la tabella
della prova fisica va aggiornata solo dopo un nuovo caricamento verificato.
Con il vecchio binario non presumere che il programma si fermi: dopo il NOP
il PC leggerebbe `counter` a `0x0009`, che il programma puo aver modificato.

## Operazioni e risultati dei test BOOT

- [ ] **Power-on reset esterno (schema proposto):** all'accensione misurare
  `/POR=0`, `PC=0`, `µSTEP=000` e `/WE_RAM` **sul pin della RAM** alto;
  dopo il rilascio di `/POR`, verificare `PC=0`, `µSTEP=000` e il primo
  avanzamento solo al clock successivo. Data/misura: _da compilare_.
- [ ] **Versione ROM0:** verificare `0x91`, `0xB5`, `0x31` rispettivamente in
  T1, T2, T3. Data/misura: _da compilare_.
- [ ] **Ingressi:** misurare `BOOT_RUN=0` e `A2:A1:A0 = 000 → 100 → 010` sui
  pin delle tre Control ROM. Data/misura: _da compilare_.
- [ ] **Selezione indirizzo:** verificare `D1:D0=01` in T1, T2 e T3 e che il
  bus indirizzi segua il PC. Data/misura: _da compilare_.
- [ ] **Scrittura:** misurare `/WE_RAM` direttamente sul pin della RAM:
  basso in T1, alto in T2 e T3; controllare che `/OE_EPROM` resti basso in
  tutte e tre le fasi. Data/misura: _da compilare_.
- [ ] **Bus dati:** con un byte EPROM noto e diverso da `0x00`, verificare che
  lo stesso byte sia presente sul bus in T1 e in T2 prima del clock che
  incrementa il PC. Data/misura: _da compilare_.
- [ ] **PC:** verificare che resti fermo durante T1, avanzi di uno al clock
  previsto in T2 e resti fermo in T3. Data/misura: _da compilare_.
- [ ] **Reset microstep:** verificare `D7=0` in T3 e il ritorno a T1.
  Data/misura: _da compilare_.
- [ ] **Dato memorizzato:** rileggere la RAM all'indirizzo precedente del PC e
  confrontarla con il byte della EPROM allo stesso indirizzo; ripetere su due
  indirizzi consecutivi. Data/misura: _da compilare_.

Se il bus appare a `0` in T3 quando il byte EPROM atteso e diverso da zero,
controllare `/OE_EPROM` e l'indirizzo presentato dal PC. Se la RAM cambia
contenuto in T2 o T3, misurare `/WE_RAM` sul pin della RAM e verificare che
`/OE_RAM` resti alto durante il BOOT. La prova sul clock del PC presuppone che
`PC_INC` sia campionato una sola volta; anche la durata del reset microstep
va confermata sulla scheda reale.

## RUN: ingressi e uscite di tutte le microsequenze cablate

Queste tabelle descrivono i **tre binari generati oggi**, non tutte le
distinzioni previste dall'ISA teorica. Su ciascuna ROM `A12=1` seleziona RUN,
`A11..A8=O,N,Z,C` sono i flag e `A7..A3=IR[7:3]` identificano il gruppo.
Per gli indirizzi numerici della tabella fissiamo `O=N=Z=C=0`, salvo le righe
esplicitamente indicate con `O=1`. Per qualsiasi altra combinazione di flag,
somma all'indirizzo indicato `0x100` se `C=1`, `0x200` se `Z=1`, `0x400` se
`N=1` e `0x800` se `O=1`. Le uscite restano uguali, tranne `PC_LOAD` nel
salto `JNO`.

Come in BOOT, i bit fisici `A2:A1:A0` sono nell'ordine
`µSTEP[0]:µSTEP[1]:µSTEP[2]`: `T1=000`, `T2=100`, `T3=010`, `T4=110`,
`T5=001`, `T6=101`. Dopo l'ultima operazione c'e un microstep dedicato che
attiva solo `NEXT_FETCH`: T3 per NOP/ALU/CMP/MOV, T4 per LDI/LDX/LDA-STA IDX,
T5 per i salti, T6 per LDA/STA diretti. **A T1 IR contiene ancora l'opcode
precedente**: il nuovo opcode viene acquisito al clock che chiude T1. Per
questo T1 e identico per tutti i gruppi; da T2 in poi `A7..A3` contiene il
gruppo della nuova istruzione.

Ogni byte di uscita sotto e il livello fisico dei pin `D7..D0`, non una lista
di segnali attivi. Le posizioni si leggono cosi (un nome con `/` e attivo a
`0`; gli altri segnali sono attivi a `1`):

| ROM | `D7` | `D6` | `D5` | `D4` | `D3` | `D2` | `D1` | `D0` |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 0 | `NEXT_FETCH_n` | `/OE_EPROM` | `/WE_RAM` | `/OE_MDR` | `MDR_WE` | `PC_INC` | `ADDR_SEL_1` | `ADDR_SEL_0` |
| 1 | `RB_EN` | `RA_RB_RW` | `RA_EN` | `RF_RW` | `RF_EN` | `MAR_L_WE` | `PC_LOAD` | `IR_WE` |
| 2 | riservato | `SYS_STEP_n` | `IDX_H_WE` | `IDX_L_WE` | `/OE_RAM` | `MAR_H_WE` | `FLAGS_WE` | `/OE_ALU` (`ALU_EN`) |

I pin DIP-28 corrispondenti a `D7..D0` sono `17,16,15,14,13,11,10,9`.
Le uscite della ROM non includono le ulteriori porte presenti sul cablaggio:
per esempio `/WE_RAM` **sul pin della RAM** puo essere forzato alto dalla
logica di protezione indirizzi/reset anche quando ROM0 `D5=0`.

### Istruzioni e segnali di sistema: HLT, NOP, reset e ritorno al fetch

Gli opcode di sistema **implementati** sono `HLT=0x00` (`00000000`) e
`NOP=0x01` (`00000001`); entrambi appartengono al gruppo CU
`IR[7:3]=00000`. Le Control ROM non ricevono `IR[2:0]`, quindi emettono
gli stessi byte per i due opcode. L'arresto di HLT non e un'uscita delle
EEPROM: ROM2 emette `SYS_STEP_n`, mentre la distinzione HLT/NOP avviene
nella logica cablata esterna, **da collegare e verificare sulla CPU fisica**.
I byte ROM qui sotto sono generati dal tool; il cablaggio di `µSTEP_EN` e
`/POR` e uno schema previsto, non una
misura gia confermata. Gli opcode `0x02..0x07` condividono per ora
la stessa sequenza delle ROM, ma sono riservati e non vanno considerati
istruzioni di sistema implementate. Anche `0x08..0x1F` sono riservati
nella ISA e nei binari attuali eseguono un NOP fisico come gruppo diverso.

I segnali coinvolti sono i seguenti; `µSTEP_EN` indica l'abilitazione al
conteggio del 74161, **non** il suo ingresso di clock.

| Segnale | Provenienza | Livello/effetto da verificare |
| --- | --- | --- |
| `BOOT_RUN` | esterno, EEPROM `A12` | `0` seleziona BOOT, `1` seleziona RUN; HLT deve agire solo in RUN. |
| `/POR` | circuito di reset esterno | Nello schema proposto, basso azzera PC e microstep tramite `/CLR` e inibisce `/WE_RAM` sul pin della RAM; non e un'uscita EEPROM. |
| `IR_WE` | ROM1 `D0` | Alto solo nel fetch T1: l'IR acquisisce il nuovo opcode al clock che chiude T1. |
| `PC_INC` | ROM0 `D2` | Alto nel fetch T1: il PC avanza anche quando l'opcode letto e HLT. |
| `/OE_RAM` | ROM2 `D3` | Basso nel fetch T1 per presentare l'opcode al bus dati; alto in T2/T3 di questo gruppo. |
| `NEXT_FETCH_n` | ROM0 `D7` | Alto in T1/T2; basso in T3 per chiedere il ritorno a T1. Con `/LOAD` del 74161 il ritorno avviene al clock che chiude T3. |
| `SYS_STEP_n` | ROM2 `D6`, pin 16 | Basso solo in RUN, gruppo `IR[7:3]=00000`, T2; alto durante BOOT, T1 e T3. |
| `µSTEP_EN` | OR esterno verso il 74161 | `1` lascia contare; `0` mantiene T2. Non interrompere direttamente il filo del clock. |

Formula della logica prevista, assumendo che non esistano altri motivi per
disabilitare il contatore:

```text
µSTEP_EN = SYS_STEP_n OR IR2 OR IR1 OR IR0
```

Il livello alto di `SYS_STEP_n` in T1 e indispensabile: dopo reset, o durante il fetch, l'IR puo
ancora contenere `0x00` **prima** di aver acquisito l'opcode corrente. Per
queste misure `O=N=Z=C=0`, dunque `A11..A8=0000`; i flag non cambiano le
uscite del gruppo di sistema. In T2/T3 `A7..A3=00000`; il valore fisico
`A2:A1:A0=100` corrisponde al T2 logico `001` per la mappatura attuale.

| Istruzione/fase | IR dopo il fetch | `BOOT_RUN` | `µSTEP[2:0]` | EEPROM `A2:A1:A0` | Indirizzo EEPROM con flag `0000` | `SYS_STEP_n` | `µSTEP_EN` |
| --- | :---: | :---: | :---: | :---: | ---: | :---: | :---: |
| Fetch comune T1 | precedente, poi nuovo al clock | 1 | `000` | `000` | `0x1000 + 8G_precedente` | 1 | 1 |
| HLT T2 | `00000000` | 1 | `001` | `100` | `0x1004` | 0 | 0 |
| NOP T2 | `00000001` | 1 | `001` | `100` | `0x1004` | 0 | 1 |
| NOP T3 | `00000001` | 1 | `010` | `010` | `0x1002` | 1 | 1 |
| Riservati `0x02..0x07`, T2/T3 | `00000xxx` | 1 | `001`/`010` | `100`/`010` | `0x1004`/`0x1002` | 0/1 | 1 |

Per HLT la riga T3 esiste **nel binario delle ROM**, ma non deve essere
raggiunta se l'OR e collegato: il contatore resta in T2. Per NOP T3 e
raggiunta e `NEXT_FETCH_n=0`; con `/LOAD` sincrono e dati paralleli `0000`,
il clock successivo riporta il microstep a T1. Se D7 e ancora collegato
a `/CLR` asincrono, il ritorno puo avvenire gia durante T3 e la durata
dell'impulso va misurata.

| Fase | ROM0 `D7..D0` | ROM1 `D7..D0` | ROM2 `D7..D0` | Controlli attivi della CU | Comportamento esterno |
| --- | :---: | :---: | :---: | --- | --- |
| T1, fetch comune | `11110101` (`0xF5`) | `00000001` (`0x01`) | `01000001` (`0x41`) | `ADDR_SEL=PC`, `/OE_RAM=0`, `IR_WE=1`, `PC_INC=1` | Il nuovo IR vale `0x00` o `0x01` solo **dopo** il clock; PC punta al byte seguente. |
| T2, HLT | `11110011` (`0xF3`) | `00000000` (`0x00`) | `00001001` (`0x09`) | Nessuna lettura/scrittura; `SYS_STEP_n=0` | `µSTEP_EN=0`: T2 resta stabile ai clock successivi. |
| T2, NOP | `11110011` (`0xF3`) | `00000000` (`0x00`) | `00001001` (`0x09`) | Identico a HLT per le EEPROM | `IR0=1` tiene `µSTEP_EN=1`: al clock il microstep diventa T3. |
| T3, NOP | `01110011` (`0x73`) | `00000000` (`0x00`) | `01001001` (`0x49`) | Solo `NEXT_FETCH_n=0`; nessuna scrittura | Il ritorno a T1 dipende dal collegamento `/LOAD` o `/CLR` del microstep. |

In T2 di HLT/NOP le uscite attive basse `/WE_RAM`, `/OE_EPROM`, `/OE_MDR`,
`/OE_RAM` e `/OE_ALU` sono tutte alte (inattive); `IR_WE`, `PC_INC`,
`PC_LOAD`, `MDR_WE`, `RF_EN`, `RA_EN`, `RB_EN`, `FLAGS_WE`, `MAR_*_WE` e
`IDX_*_WE` sono basse. Il PC ha gia avanzato in T1 e deve rimanere fermo
durante T2. Il reset `/POR` resta indipendente da HLT e deve poter
riportare PC e microstep allo stato iniziale.

Prove da registrare separatamente dalla tabella teorica:

- [ ] **Decode:** applicare `IR=0x00`, `RUN=1`, T2 e misurare `SYS_STEP_n=0` e
  `µSTEP_EN=0`; ripetere con `IR=0x01` e ottenere `SYS_STEP_n=0`, `µSTEP_EN=1`.
  Data/misura: _da compilare_.
- [ ] **Qualificatori:** con `IR=0x00`, verificare `SYS_STEP_n=1` durante BOOT e
  durante T1 RUN; con `IR=0x02..0x07`, verificare `SYS_STEP_n=0` ma `µSTEP_EN=1` in T2.
  Data/misura: _da compilare_.
- [ ] **HLT reale:** caricare un programma terminato da `0x00`; al fetch
  verificare `IR=0x00`, PC avanzato di uno e microstep bloccato in T2
  anche dopo altri fronti di clock, senza scritture RAM/registri.
  Data/misura: _da compilare_.
- [ ] **NOP reale:** con `0x01`, verificare T1 → T2 → T3 → T1 e il PC
  incrementato una sola volta; in T3 misurare ROM0 `D7=0`.
  Data/misura: _da compilare_.
- [ ] **Reset dall'arresto:** con HLT bloccato in T2, applicare `/POR=0` e
  verificare PC=0, microstep=000 e `/WE_RAM` fisico alto; dopo il rilascio
  ripartire dal fetch senza un arresto dovuto al vecchio contenuto dell'IR.
  Data/misura: _da compilare_.

La prova HLT richiede il **nuovo binario del programma**: la EEPROM
programma descritta nella tabella BOOT sopra contiene ancora `0x01` a
`0x0008` e quindi, con questa ISA, esegue NOP. Lo scambio di opcode non
modifica la sequenza dei due opcode, che condividono il gruppo CU. La nuova
uscita `SYS_STEP_n` modifica pero il binario di **ROM2**, da rigenerare e
riprogrammare prima della prova fisica; ROM0 e ROM1 non cambiano per questo.

### Tabella di verita RUN 1 — ingressi comuni alle tre EEPROM

In tutte le righe ordinarie `A12=1`, `A11..A8=0000`. La colonna
`µSTEP[2:0]` e il valore del contatore; `A2:A1:A0` mostra invece i livelli
che si misurano sui pin fisici delle EEPROM. `G` significa un qualsiasi
gruppo `IR[7:3]` a cinque bit. La riga T1 usa il gruppo **precedente**;
`0x1000` e solo l'esempio con gruppo precedente e flag entrambi a zero.

| Microsequenza | Fase | `µSTEP[2:0]` | `A7..A3` | `A2:A1:A0` | Indirizzo (flag indicati) |
| --- | :---: | :---: | :---: | :---: | ---: |
| Fetch comune | T1 | `000` | `G precedente` | `000` | `0x1000 + 8G` |
| HLT / NOP, uscite CU comuni | T2 | `001` | `00000` | `100` | `0x1004` |
| HLT / NOP, uscite CU comuni | T3 reset | `010` | `00000` | `010` | `0x1002` |
| LDI Rn, imm8 | T2 | `001` | `00100` | `100` | `0x1024` |
| LDI Rn, imm8 | T3 | `010` | `00100` | `010` | `0x1022` |
| LDI Rn, imm8 | T4 reset | `011` | `00100` | `110` | `0x1026` |
| LDA Rn, [addr16] | T2 | `001` | `01000` | `100` | `0x1044` |
| LDA Rn, [addr16] | T3 | `010` | `01000` | `010` | `0x1042` |
| LDA Rn, [addr16] | T4 | `011` | `01000` | `110` | `0x1046` |
| LDA Rn, [addr16] | T5 | `100` | `01000` | `001` | `0x1041` |
| LDA Rn, [addr16] | T6 reset | `101` | `01000` | `101` | `0x1045` |
| STA Rn, [addr16] | T2 | `001` | `01001` | `100` | `0x104C` |
| STA Rn, [addr16] | T3 | `010` | `01001` | `010` | `0x104A` |
| STA Rn, [addr16] | T4 | `011` | `01001` | `110` | `0x104E` |
| STA Rn, [addr16] | T5 | `100` | `01001` | `001` | `0x1049` |
| STA Rn, [addr16] | T6 reset | `101` | `01001` | `101` | `0x104D` |
| LDA Rn, [IDX] | T2 | `001` | `01010` | `100` | `0x1054` |
| LDA Rn, [IDX] | T3 | `010` | `01010` | `010` | `0x1052` |
| LDA Rn, [IDX] | T4 reset | `011` | `01010` | `110` | `0x1056` |
| STA Rn, [IDX] | T2 | `001` | `01011` | `100` | `0x105C` |
| STA Rn, [IDX] | T3 | `010` | `01011` | `010` | `0x105A` |
| STA Rn, [IDX] | T4 reset | `011` | `01011` | `110` | `0x105E` |
| ALU | T2 | `001` | `01100` | `100` | `0x1064` |
| ALU | T3 reset | `010` | `01100` | `010` | `0x1062` |
| SUB (`0x78`) | T2 | `001` | `01111` | `100` | `0x107C` |
| SUB (`0x78`) | T3 reset | `010` | `01111` | `010` | `0x107A` |
| CMP | T2 | `001` | `01101` | `100` | `0x106C` |
| CMP | T3 reset | `010` | `01101` | `010` | `0x106A` |
| JMP addr16 | T2 | `001` | `10100` | `100` | `0x10A4` |
| JMP addr16 | T3 | `010` | `10100` | `010` | `0x10A2` |
| JMP addr16 | T4 | `011` | `10100` | `110` | `0x10A6` |
| JMP addr16 | T5 reset | `100` | `10100` | `001` | `0x10A1` |
| JNO addr16, `O=0` | T2 | `001` | `10101` | `100` | `0x10AC` |
| JNO addr16, `O=0` | T3 | `010` | `10101` | `010` | `0x10AA` |
| JNO addr16, `O=0` | T4 | `011` | `10101` | `110` | `0x10AE` |
| JNO addr16, `O=0` | T5 reset | `100` | `10101` | `001` | `0x10A9` |
| JNO addr16, `O=1` | T2 | `001` | `10101` | `100` | `0x18AC` |
| JNO addr16, `O=1` | T3 | `010` | `10101` | `010` | `0x18AA` |
| JNO addr16, `O=1` | T4 | `011` | `10101` | `110` | `0x18AE` |
| JNO addr16, `O=1` | T5 reset | `100` | `10101` | `001` | `0x18A9` |
| MOV RA, Rn | T2 | `001` | `11000` | `100` | `0x10C4` |
| MOV RA, Rn | T3 reset | `010` | `11000` | `010` | `0x10C2` |
| MOV RB, Rn | T2 | `001` | `11001` | `100` | `0x10CC` |
| MOV RB, Rn | T3 reset | `010` | `11001` | `010` | `0x10CA` |
| MOV Rn, RA | T2 | `001` | `11010` | `100` | `0x10D4` |
| MOV Rn, RA | T3 reset | `010` | `11010` | `010` | `0x10D2` |
| LDX addr16 | T2 | `001` | `11011` | `100` | `0x10DC` |
| LDX addr16 | T3 | `010` | `11011` | `010` | `0x10DA` |
| LDX addr16 | T4 reset | `011` | `11011` | `110` | `0x10DE` |
| Altri gruppi (NOP fisico) | T2 | `001` | `G altro` | `100` | `0x1004 + 8G` |
| Altri gruppi (NOP fisico) | T3 reset | `010` | `G altro` | `010` | `0x1002 + 8G` |

### Tabella di verita RUN 2 — livelli fisici delle uscite

La riga T1 vale per **tutti** i gruppi, anche se il byte appena letto cambia
IR al termine della fase. Le altre righe corrispondono esattamente a quelle
della tabella degli ingressi. `D7..D0` e nell'ordine dei pin della tabella
di mappatura sopra; ROM2 D7 resta riservata a zero, mentre D6 e
`SYS_STEP_n` (normalmente alta, bassa solo nel T2 del gruppo di sistema).

| Microsequenza | Fase | ROM0 `D7..D0` | ROM1 `D7..D0` | ROM2 `D7..D0` | Azione / controllo da verificare |
| --- | :---: | :---: | :---: | :---: | --- |
| Fetch comune | T1 | `11110101` | `00000001` | `01000001` | PC seleziona A; RAM pilota D; IR acquisisce opcode e PC avanza al clock. |
| HLT / NOP, uscite CU comuni | T2 | `11110011` | `00000000` | `00001001` | `SYS_STEP_n=0`; l'OR con `IR[2:0]` blocca il microstep solo per `HLT=0x00`. |
| HLT / NOP, uscite CU comuni | T3 reset | `01110011` | `00000000` | `01001001` | Solo `NEXT_FETCH`; raggiunto da `NOP=0x01`, non da HLT se il decoder e collegato. |
| LDI Rn, imm8 | T2 | `11111101` | `00000000` | `01000001` | RAM[PC] → MDR; PC avanza. |
| LDI Rn, imm8 | T3 | `11100011` | `00011000` | `01001001` | MDR → Rn; il segnale resta valido fino al clock. |
| LDI Rn, imm8 | T4 reset | `01110011` | `00000000` | `01001001` | Solo `NEXT_FETCH`. |
| LDA Rn, [addr16] | T2 | `11110101` | `00000100` | `01000001` | RAM[PC] → MAR basso; PC avanza. |
| LDA Rn, [addr16] | T3 | `11110101` | `00000000` | `01000101` | RAM[PC] → MAR alto; PC avanza. |
| LDA Rn, [addr16] | T4 | `11111010` | `00000000` | `01000001` | MAR seleziona A; RAM[MAR] → MDR. |
| LDA Rn, [addr16] | T5 | `11100011` | `00011000` | `01001001` | MDR → Rn. |
| LDA Rn, [addr16] | T6 reset | `01110011` | `00000000` | `01001001` | Solo `NEXT_FETCH`. |
| STA Rn, [addr16] | T2 | `11110101` | `00000100` | `01000001` | RAM[PC] → MAR basso; PC avanza. |
| STA Rn, [addr16] | T3 | `11110101` | `00000000` | `01000101` | RAM[PC] → MAR alto; PC avanza. |
| STA Rn, [addr16] | T4 | `11111011` | `00001000` | `01001001` | Rn → MDR. |
| STA Rn, [addr16] | T5 | `11000010` | `00000000` | `01001001` | MAR seleziona A; MDR pilota D; `/WE_RAM=0`. |
| STA Rn, [addr16] | T6 reset | `01110011` | `00000000` | `01001001` | `/WE_RAM=1`; solo `NEXT_FETCH`. |
| LDA Rn, [IDX] | T2 | `11111000` | `00000000` | `01000001` | IDX seleziona A; RAM[IDX] → MDR. |
| LDA Rn, [IDX] | T3 | `11100011` | `00011000` | `01001001` | MDR → Rn. |
| LDA Rn, [IDX] | T4 reset | `01110011` | `00000000` | `01001001` | Solo `NEXT_FETCH`. |
| STA Rn, [IDX] | T2 | `11111011` | `00001000` | `01001001` | Rn → MDR. |
| STA Rn, [IDX] | T3 | `11000000` | `00000000` | `01001001` | IDX seleziona A; MDR pilota D; `/WE_RAM=0`. |
| STA Rn, [IDX] | T4 reset | `01110011` | `00000000` | `01001001` | `/WE_RAM=1`; solo `NEXT_FETCH`. |
| ALU | T2 | `11110011` | `01100000` | `01001010` | ALU pilota D; RA scrive il risultato; flag acquisiti. |
| ALU | T3 reset | `01110011` | `00000000` | `01001001` | Solo `NEXT_FETCH`. |
| SUB (`0x78`) | T2 | `11110011` | `01100000` | `01001010` | Come ALU: `IR[3:0]=1000`, RA scrive il risultato e i flag si aggiornano. |
| SUB (`0x78`) | T3 reset | `01110011` | `00000000` | `01001001` | Solo `NEXT_FETCH`. |
| CMP | T2 | `11110011` | `00000000` | `01001011` | `FLAGS_WE=1`, senza `/OE_ALU`. |
| CMP | T3 reset | `01110011` | `00000000` | `01001001` | Solo `NEXT_FETCH`. |
| JMP addr16 | T2 | `11110101` | `00000100` | `01000001` | RAM[PC] → MAR basso; PC avanza. |
| JMP addr16 | T3 | `11110101` | `00000000` | `01000101` | RAM[PC] → MAR alto; PC avanza. |
| JMP addr16 | T4 | `11110011` | `00000010` | `01001001` | MAR → PC (`PC_LOAD=1`). |
| JMP addr16 | T5 reset | `01110011` | `00000000` | `01001001` | Solo `NEXT_FETCH`. |
| JNO addr16, `O=0` | T2 | `11110101` | `00000100` | `01000001` | RAM[PC] → MAR basso; PC avanza. |
| JNO addr16, `O=0` | T3 | `11110101` | `00000000` | `01000101` | RAM[PC] → MAR alto; PC avanza. |
| JNO addr16, `O=0` | T4 | `11110011` | `00000010` | `01001001` | Salto preso: `PC_LOAD=1`. |
| JNO addr16, `O=0` | T5 reset | `01110011` | `00000000` | `01001001` | Solo `NEXT_FETCH`. |
| JNO addr16, `O=1` | T2 | `11110101` | `00000100` | `01000001` | RAM[PC] → MAR basso; PC avanza. |
| JNO addr16, `O=1` | T3 | `11110101` | `00000000` | `01000101` | RAM[PC] → MAR alto; PC avanza. |
| JNO addr16, `O=1` | T4 | `11110011` | `00000000` | `01001001` | Salto non preso: PC resta dopo l'operando. |
| JNO addr16, `O=1` | T5 reset | `01110011` | `00000000` | `01001001` | Solo `NEXT_FETCH`. |
| MOV RA, Rn | T2 | `11110011` | `01101000` | `01001001` | Rn → RA. |
| MOV RA, Rn | T3 reset | `01110011` | `00000000` | `01001001` | Solo `NEXT_FETCH`. |
| MOV RB, Rn | T2 | `11110011` | `11001000` | `01001001` | Rn → RB. |
| MOV RB, Rn | T3 reset | `01110011` | `00000000` | `01001001` | Solo `NEXT_FETCH`. |
| MOV Rn, RA | T2 | `11110011` | `00111000` | `01001001` | RA → Rn. |
| MOV Rn, RA | T3 reset | `01110011` | `00000000` | `01001001` | Solo `NEXT_FETCH`. |
| LDX addr16 | T2 | `11110101` | `00000000` | `01010001` | RAM[PC] → IDX basso; PC avanza. |
| LDX addr16 | T3 | `11110101` | `00000000` | `01100001` | RAM[PC] → IDX alto; PC avanza. |
| LDX addr16 | T4 reset | `01110011` | `00000000` | `01001001` | Solo `NEXT_FETCH`. |
| Altri gruppi (NOP fisico) | T2 | `11110011` | `00000000` | `01001001` | Nessun trasferimento. |
| Altri gruppi (NOP fisico) | T3 reset | `01110011` | `00000000` | `01001001` | Solo `NEXT_FETCH`. |

Per i sette salti aggiuntivi la sequenza di uscite è identica a quella di
JNO salvo la condizione in T4. La tabella indica il gruppo CU (`G=opcode>>3`)
e il valore di `ROM1 D1=PC_LOAD` in T4; tutti leggono l'indirizzo in T2/T3
e attivano solo `NEXT_FETCH` in T5.

| Salto | Opcode | `G=IR[7:3]` | Condizione per `PC_LOAD=1` |
| --- | ---: | :---: | --- |
| `JMP` | `0xA0` | `10100` | Sempre |
| `JZ` | `0xB0` | `10110` | `Z=1` |
| `JNZ` | `0xB8` | `10111` | `Z=0` |
| `JC` | `0xE0` | `11100` | `C=1` |
| `JNC` | `0xE8` | `11101` | `C=0` |
| `JN` | `0xF0` | `11110` | `N=1` |
| `JNN` | `0xF8` | `11111` | `N=0` |
| `JO` | `0x30` | `00110` | `O=1` |
| `JNO` | `0xA8` | `10101` | `O=0` |

Definire `F = 0x100·C + 0x200·Z + 0x400·N + 0x800·O`. Tutti i salti
seguono questa tabella completa di indirizzi e byte fisici:

| Fase | Indirizzo EEPROM | ROM0 | ROM1 | ROM2 | Effetto |
| --- | --- | :---: | :---: | :---: | --- |
| T2 | `0x1000 + 8G + 4 + F` | `0xF5` | `0x04` | `0x41` | Legge `addr_low` in MAR. |
| T3 | `0x1000 + 8G + 2 + F` | `0xF5` | `0x00` | `0x45` | Legge `addr_high` in MAR. |
| T4 preso | `0x1000 + 8G + 6 + F` | `0xF3` | `0x02` | `0x49` | `PC_LOAD=1`. |
| T4 non preso | `0x1000 + 8G + 6 + F` | `0xF3` | `0x00` | `0x49` | PC continua dopo l'operando. |
| T5 | `0x1000 + 8G + 1 + F` | `0x73` | `0x00` | `0x49` | Solo `NEXT_FETCH`. |

La parola inattiva, prodotta nei microstep non usati dalla sequenza, e
`ROM0=11110011`, `ROM1=00000000`, `ROM2=01001001`: selettore indirizzi
`11=nessuna sorgente`, tutte le letture/scritture disabilitate e
`NEXT_FETCH=1` inattivo. Se il microstep arriva per errore in uno di questi
stati, **non viene riportato subito a T1**: il 74161 continua a contare e i
tre bit usati dalla CU tornano a `000` solo quando fanno il giro modulo 8.
L'indirizzo generico e `0x1000 + 8G + reverse3(µSTEP)` piu i bit di flag
descritti sopra; per esempio, per `LDI` in T4 e `0x1026`.

### Gruppi fisici, opcode condivisi e limiti da non confondere

| `IR[7:3]` | Opcode `IR[7:0]` che producono lo stesso gruppo | Sequenza RUN reale |
| :---: | --- | --- |
| `00000` | `0x00..0x07` | Uscite CU comuni: `HLT=0x00` richiede arresto esterno in T2; `NOP=0x01` prosegue fino a T3. |
| `00100` | `0x20..0x27` | LDI; `IR[2:0]` sceglie Rn. |
| `01000` | `0x40..0x47` | LDA addr16. |
| `01001` | `0x48..0x4F` | STA addr16. |
| `01010` | `0x50..0x57` | LDA [IDX]. |
| `01011` | `0x58..0x5F` | STA [IDX]. |
| `01100` | `0x60..0x67` | ALU; `IR[3:0]` seleziona l'operazione nel blocco ALU. |
| `01101` | `0x68..0x6F` | CMP solo per `0x69`; gli altri opcode del gruppo sono riservati e ne condividono le uscite fisiche. |
| `01111` | `0x78..0x7F` | SUB solo per `0x78`; conserva `IR[3:0]=1000` per la ALU. |
| `10100` | `0xA0..0xA7` | JMP solo per `0xA0`; gli altri opcode sono riservati e ne condividono le uscite fisiche. |
| `10101` | `0xA8..0xAF` | JNO, condizionato soltanto dal flag `O`. |
| `10110` / `10111` | `0xB0..0xB7` / `0xB8..0xBF` | JZ / JNZ, ciascuno con il proprio gruppo CU. |
| `11100` / `11101` | `0xE0..0xE7` / `0xE8..0xEF` | JC / JNC. |
| `11110` / `11111` | `0xF0..0xF7` / `0xF8..0xFF` | JN / JNN. |
| `00110` | `0x30..0x37` | JO solo per `0x30`. |
| `11000` | `0xC0..0xC7` | MOV RA, Rn. |
| `11001` | `0xC8..0xCF` | MOV RB, Rn. |
| `11010` | `0xD0..0xD7` | MOV Rn, RA. |
| `11011` | `0xD8..0xDF` | LDX addr16. |
| ogni altro gruppo | tutti gli altri opcode | NOP fisico: T2 inattivo, `NEXT_FETCH` in T3. |

La funzione `dispatch_opcode()` descrive gli opcode completi per il software;
le tre ROM sono invece generate direttamente da `IR[7:3]`. I nove salti
occupano gruppi diversi, dunque non serve una quarta ROM di dispatch.
`HLT` richiede ancora l'OR esterno fra ROM2 `SYS_STEP_n` e `IR[2:0]`
per fermare il conteggio del microstep.

### Operazioni e risultati dei test RUN

- [ ] **Fetch comune:** con `BOOT_RUN=1`, verificare T1:
  `ROM0=11110101`, `ROM1=00000001`, `ROM2=01000001`; al clock IR acquisisce
  `RAM[PC]` e PC avanza. Data/misura: _da compilare_.
- [ ] **Selezione del gruppo:** dopo T1 misurare `A7..A3=IR[7:3]` e
  `A2:A1:A0=100` in T2. Data/misura: _da compilare_.
- [ ] **LDI, LDA, STA:** provare separatamente i trasferimenti indicati nelle
  tabelle, verificando il dato effettivo su bus e registri a ogni fase.
  Data/misura: _da compilare_.
- [ ] **IDX:** verificare `LDX` basso/alto e `LDA/STA [IDX]` con un indirizzo
  noto. Data/misura: _da compilare_.
- [ ] **ALU, CMP, MOV:** verificare i livelli T2, poi risultato, flag e
  registro destinazione al clock che chiude T2; T3 deve avere solo
  `NEXT_FETCH`. Data/misura: _da compilare_.
- [ ] **Tutti i salti:** per ciascuno dei nove opcode provare sia flag che
  prende il salto sia flag che non lo prende; in T4 ROM1 `D1` deve essere
  rispettivamente `1` e `0`. Data/misura: _da compilare_.
- [ ] **Scrittura RAM:** per STA diretto/IDX misurare `/WE_RAM` sul pin della
  RAM e la sua disattivazione all'ingresso della fase di reset T6/T4;
  confermare che l'indirizzo
  selezioni RAM e non VRAM. Data/misura: _da compilare_.
- [ ] **HLT e NOP:** verificare che `0x00` si fermi in T2 con l'OR di
  `SYS_STEP_n` e `IR[2:0]`, mentre `0x01` raggiunga T3 e riparta dal fetch.
  Senza questo collegamento entrambi proseguono come NOP fisico.
  Data/misura: _da compilare_.
- [ ] **Vecchi binari:** verificare che la EPROM programma sia stata
  riassemblata con `SUB=0x78` e i nuovi opcode dei salti; non riusare
  programmi con `SUB=0x68` o `JZ..JO=0xA1..0xA7`.
  Data/misura: _da compilare_.

Le tabelle rappresentano i livelli delle EEPROM, **non** una misura gia
eseguita sulla CPU. `RAM_WE`, `RF_RW`, `PC_INC` e `PC_LOAD` non coincidono piu
con `NEXT_FETCH` nel microstep finale. Questo elimina il troncamento diretto
delle operazioni, ma la temporizzazione del reset resta da verificare sulla
scheda. La soluzione robusta con 74161 e collegare `NEXT_FETCH_n` a `/LOAD`
con dati paralleli `0000`, lasciando `/POR` su `/CLR`.

### Prova integrata prima del programma definitivo

Il sorgente [cu_isa_smoke.asm](../examples/assembly/cu_isa_smoke.asm) non usa
IN/OUT. Esercita `LDI`, `MOV`, `SUB`, `STA`, `LDA`, `CMP`, `JNZ`, `LDX`,
`STAI`, `LDAI` e `HLT`. Dal repository, generare le immagini abbinate:

```sh
make -C tools/cu-bytecode test generate
make -C tools/assembler test
tools/assembler/build/cpu8asm examples/assembly/cu_isa_smoke.asm -o tools/assembler/build/cu_isa_smoke
```

Programmare e verificare separatamente le **tre** immagini
`tools/cu-bytecode/build/microcode-rom{0,1,2}.bin` nelle rispettive
Control ROM e `tools/assembler/build/cu_isa_smoke.bin` nella EPROM programma.
La EPROM programma contiene 36 byte significativi a partire da `0x0000`;
il caricatore seriale accetta un `.bin` più corto di 8192 byte. Non scambiare
questa EPROM con una delle tre Control ROM.

Dopo il BOOT, selezionare RUN e azzerare PC/microstep con il reset esterno
prima di avviare i clock. Alla fine, `HLT` deve bloccare il microstep in T2
e la RAM deve contenere `0x05` a `0x0100`, `0x5A` a `0x0101`, `0x05` a
`0x0102`. Se `JNZ` non prende il salto, `0x0101` diventa `0xE1`.
Questa è un'aspettativa simulata, **non** una prova già riuscita sulla scheda.
