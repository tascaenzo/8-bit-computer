# Verifiche della Control Unit

Questo documento raccoglie, una fase alla volta, le operazioni da provare sulla
CPU fisica, i livelli attesi e le misure effettuate. Le tabelle qui sotto
riguardano il BOOT: ogni riga corrisponde a un preciso intervallo temporale
T1, T2 o T3. La prima tabella mostra gli ingressi delle tre Control ROM in
quell'intervallo; la seconda mostra le uscite della Control ROM 0.

**Stato delle misure:** da eseguire. I valori nelle tabelle sono quelli
generati dal microcodice, non letture gia effettuate sulla scheda.

**Versione della ROM0 da testare:** il binario aggiornato contiene `0x91` in
T1, `0xB5` in T2 e `0x31` in T3. Il 23 settembre 2026 la EEPROM fisica e
stata riprogrammata con questo binario: 8192 byte scritti e verifica CRC-16
finale riuscita. Restano da misurare i livelli sulla CU.

Riferimenti: [configurazione dei pin](../tools/cu-bytecode/config/control_signals.c),
[generatore del microcodice](../tools/cu-bytecode/src/microcode.c),
[mappa completa delle uscite](control-unit-eeprom-output-map.md).

## BOOT: copia EPROM → RAM

T1, T2 e T3 sono **tre fasi temporali distinte**, una dopo l'altra; non sono
tre pin della EEPROM. Il contatore le codifica sui suoi tre bit `µSTEP[2:0]`,
che entrano nelle EEPROM come parte dell'indirizzo. La sequenza e
`T1 (000) → clock → T2 (001) → clock → T3 (010) → NEXT_FETCH → T1 (000)`.

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

| Fase temporale | `D7`<br>`/CLR_µSTEP` | `D6`<br>`/OE_EPROM` | `D5`<br>`/WE_RAM` | `D4`<br>`/OE_MDR` | `D3`<br>`MDR_WE` | `D2`<br>`PC_INC` | `D1`<br>`ADDR_SEL_1` | `D0`<br>`ADDR_SEL_0` | Byte ROM0 `D7..D0` in binario |
| --- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | ---: |
| **T1 — copia** | 1 | 0 | 0 | 1 | 0 | 0 | 0 | 1 | `10010001` |
| **T2 — chiusura scrittura e PC++** | 1 | 0 | 1 | 1 | 0 | 1 | 0 | 1 | `10110101` |
| **T3 — reset del microstep** | 0 | 0 | 1 | 1 | 0 | 0 | 0 | 1 | `00110001` |

La coppia `D1:D0=01` mantiene il PC come sorgente dell'indirizzo. I byte
`D7..D0` sono `10010001` (`0x91`) in T1, `10110101` (`0xB5`) in T2 e
`00110001` (`0x31`) in T3. Durante BOOT la Control ROM 1 genera `0x00` e la
Control ROM 2 genera `0x09`: in particolare `/OE_RAM` (ROM2 `D3`) deve restare
alto per evitare che la RAM piloti il bus dati insieme alla EPROM.

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

## Prossime fasi

Le verifiche della modalita RUN verranno aggiunte qui con lo stesso schema:
ingressi, uscite attese, operazioni da provare e risultati misurati.
