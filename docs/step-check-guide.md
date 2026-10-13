# Step check: registri e stati della CPU passo per passo — somma 4 + 1

Programma: `examples/assembly/step_check.asm`, 8 byte `26 04 27 01 C7 CE 67 00`.
**LDI:** T2 carica MDR, T3 scrive Rn, T4 torna al fetch.
**ALU:** T2 prepara il risultato, T3 salva MDR e flag, T4 prepara MDR sul bus,
T5 copia MDR in RA, T6 mantiene MDR sul bus e torna al fetch. Il programma carica R6=4 e R7=1,
poi calcola **1 + 4 = 5** tramite RA e RB.

Dopo BOOT prepara RUN con PC=`0000 / 0000000000000000`, microstep=`000` e clock manuale fermo basso.
T1=`000` (il tuo T0), T2=`001`, T3=`010`, T4=`011`, T5=`100`, T6=`101`.

Per ogni riga **fermati prima dell'impulso**, misura, poi dai un solo impulso
basso→alto→basso. La colonna DOPO indica il risultato atteso dopo quel fronte.
I numeri contano gli impulsi RUN: bastano 21; il punto 22 è già fermo.

Tester in V DC, nero su GND, rosso su un bit alla volta. `DB` è il bus dati;
`Q` sono le uscite del registro. Nella tabella i valori sono **esadecimale / binario**:
8 bit per dati e registri (bit7..0), 16 bit per PC (bit15..0).
Nel binario **1 = livello alto**, **0 = livello basso**; i flag sono in ordine C/Z/N/O.

## Programma e byte in memoria

```asm
.code 0x0000
LDI R6, 4
LDI R7, 1
MOV RA, R7
MOV RB, R6
ADD
HLT
```

| Indirizzo RAM | Byte hex / binario | Significato |
|---|---|---|
| `0000` | `26 / 00100110` | Opcode `LDI R6` |
| `0001` | `04 / 00000100` | Immediato 4 |
| `0002` | `27 / 00100111` | Opcode `LDI R7` |
| `0003` | `01 / 00000001` | Immediato 1 |
| `0004` | `C7 / 11000111` | `MOV RA, R7` |
| `0005` | `CE / 11001110` | `MOV RB, R6` |
| `0006` | `67 / 01100111` | `ADD` |
| `0007` | `00 / 00000000` | `HLT` |

La somma richiesta è **4 + 1 = 5**. Questo programma usa gli operandi
in ordine inverso: **RA=1, RB=4**, quindi la ALU esegue `RA + RB = 1 + 4`.
Il risultato viene salvato in MDR e poi in RA; R6 e R7 conservano gli operandi.

## Contenuto completo dei registri dopo ogni impulso

La tabella seguente mostra il **contenuto memorizzato dopo l'impulso**,
quando il clock è tornato basso e i segnali si sono assestati. Il microstep
eseguito è quello presente **prima** dell'impulso; la colonna «Step dopo»
indica la fase pronta per l'impulso successivo. Esempio: dopo l'impulso 2
sei già in T3, con MDR=04, ma R6 riceverà 04 all'impulso 3.

I valori dei registri sono in **esadecimale**; PC ha 16 bit, gli altri
registri elencati hanno 8 bit. Per i bit da misurare usa la tabella sotto.
`?` significa **contenuto iniziale non garantito**, non zero. `F₀` indica i
quattro flag iniziali: restano invariati fino all'impulso 17. Nel simulatore
il reset li azzera, quindi `?=00` per i registri a 8 bit e `F₀=0000`;
sulla scheda vale solo se è previsto e verificato il reset di quei registri.

| Impulso | Fase eseguita | PC dopo | IR | MDR | R6 | R7 | RA | RB | Flag C/Z/N/O | Step dopo | Stato CPU dopo |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 0 | Preparazione RUN | `0000` | `?` | `?` | `?` | `?` | `?` | `?` | `F₀` | T1 `000` | Pronta al fetch |
| 1 | LDI R6 · T1 | `0001` | `26` | `?` | `?` | `?` | `?` | `?` | `F₀` | T2 `001` | Legge l'immediato |
| 2 | LDI R6 · T2 | `0002` | `26` | `04` | `?` | `?` | `?` | `?` | `F₀` | T3 `010` | Pronta a scrivere R6 |
| 3 | LDI R6 · T3 | `0002` | `26` | `04` | `04` | `?` | `?` | `?` | `F₀` | T4 `011` | R6 caricato |
| 4 | LDI R6 · T4 | `0002` | `26` | `04` | `04` | `?` | `?` | `?` | `F₀` | T1 `000` | Fetch successivo |
| 5 | LDI R7 · T1 | `0003` | `27` | `04` | `04` | `?` | `?` | `?` | `F₀` | T2 `001` | Legge l'immediato |
| 6 | LDI R7 · T2 | `0004` | `27` | `01` | `04` | `?` | `?` | `?` | `F₀` | T3 `010` | Pronta a scrivere R7 |
| 7 | LDI R7 · T3 | `0004` | `27` | `01` | `04` | `01` | `?` | `?` | `F₀` | T4 `011` | R7 caricato |
| 8 | LDI R7 · T4 | `0004` | `27` | `01` | `04` | `01` | `?` | `?` | `F₀` | T1 `000` | Fetch successivo |
| 9 | MOV RA · T1 | `0005` | `C7` | `01` | `04` | `01` | `?` | `?` | `F₀` | T2 `001` | Pronta a copiare R7 |
| 10 | MOV RA · T2 | `0005` | `C7` | `01` | `04` | `01` | `01` | `?` | `F₀` | T3 `010` | Operando A caricato |
| 11 | MOV RA · T3 | `0005` | `C7` | `01` | `04` | `01` | `01` | `?` | `F₀` | T1 `000` | Fetch successivo |
| 12 | MOV RB · T1 | `0006` | `CE` | `01` | `04` | `01` | `01` | `?` | `F₀` | T2 `001` | Pronta a copiare R6 |
| 13 | MOV RB · T2 | `0006` | `CE` | `01` | `04` | `01` | `01` | `04` | `F₀` | T3 `010` | Operando B caricato |
| 14 | MOV RB · T3 | `0006` | `CE` | `01` | `04` | `01` | `01` | `04` | `F₀` | T1 `000` | Fetch di ADD |
| 15 | ADD · T1 | `0007` | `67` | `01` | `04` | `01` | `01` | `04` | `F₀` | T2 `001` | ALU presenta 05 |
| 16 | ADD · T2 | `0007` | `67` | `01` | `04` | `01` | `01` | `04` | `F₀` | T3 `010` | Pronta a salvare risultato e flag |
| 17 | ADD · T3 | `0007` | `67` | `05` | `04` | `01` | `01` | `04` | `0000` | T4 `011` | Risultato salvato in MDR |
| 18 | ADD · T4 | `0007` | `67` | `05` | `04` | `01` | `01` | `04` | `0000` | T5 `100` | Pronta a scrivere RA |
| 19 | ADD · T5 | `0007` | `67` | `05` | `04` | `01` | `05` | `04` | `0000` | T6 `101` | Risultato salvato in RA |
| 20 | ADD · T6 | `0007` | `67` | `05` | `04` | `01` | `05` | `04` | `0000` | T1 `000` | Fetch di HLT |
| 21 | HLT · T1 | `0008` | `00` | `05` | `04` | `01` | `05` | `04` | `0000` | T2 `001` | Arrestata in HLT |
| 22 (solo misura) | HLT · T2 | `0008` | `00` | `05` | `04` | `01` | `05` | `04` | `0000` | T2 `001` | Resta arrestata |

**Registri invariati in tutte le righe:** R0, R1, R2, R3, R4, R5, MAR e IDX
mantengono ciascuno il proprio valore iniziale. Il programma non li scrive.
Nel simulatore sono tutti zero dopo reset (MAR=IDX=`0000`); sulla scheda
annota i valori iniziali se noti, altrimenti considerali `?`.
Il fetch legge la RAM tramite **PC**, senza caricare MAR. Non avvengono
scritture RAM né operazioni di ingresso/uscita durante questo programma.

I flag memorizzati all'impulso 17 sono: **C=0** (nessun riporto oltre 8 bit),
**Z=0** (5 non è zero), **N=0** (bit 7 del risultato a zero),
**O=0** (nessun overflow con segno). Dopo l'impulso 19 la ALU combinatoria
può calcolare `05 + 04 = 09`, ma MDR e flag conservano il risultato catturato
al 17 e RA conserva il dato copiato al 19.

## Stati e segnali della control unit prima dell'impulso

Questi sono i **segnali funzionalmente attivi** nella fase misurata prima
di ciascun impulso. Un nome attivo non implica sempre un livello elettrico
alto: per le polarità e i pin usa la
[mappa delle uscite CU](control-unit-eeprom-output-map.md).
`ADDR_SEL` è riportato nell'ordine bit 1, bit 0; `—` sul bus indica nessuna
sorgente abilitata, quindi nessun valore dati garantito.

| Punti | Fase | ADDR_SEL | Bus indirizzi prima | Bus dati prima | Segnali attivi / azione CU |
|---|---|---|---|---|---|
| 1, 5, 9, 12, 15, 21 | T1 · fetch | `01` PC | Rispettivamente `0000`, `0002`, `0004`, `0005`, `0006`, `0007` | RAM: `26`, `27`, `C7`, `CE`, `67`, `00` | `RAM_OE`, `IR_WE`, `PC_INC` |
| 2, 6 | T2 · immediato LDI | `01` PC | Rispettivamente `0001`, `0003` | RAM: `04`, `01` | `RAM_OE`, `MDR_WE`, `PC_INC` |
| 3, 7 | T3 · scrivi R6/R7 | `11` nessuna | — | MDR: `04`, `01` | `MDR_OE`, `RF_EN`, `RF_RW`; registro scelto da IR[2:0] |
| 4, 8 | T4 · fine LDI | `11` nessuna | — | — | `NEXT_FETCH` |
| 10 | T2 · scrivi RA | `11` nessuna | — | R7: `01` | `RF_EN`, `RA_EN`, `RA_RB_RW`; `RF_RW=0` |
| 11, 14 | T3 · fine MOV | `11` nessuna | — | — | `NEXT_FETCH` |
| 13 | T2 · scrivi RB | `11` nessuna | — | R6: `04` | `RF_EN`, `RB_EN`, `RA_RB_RW`; `RF_RW=0` |
| 16 | T2 · prepara ADD | `11` nessuna | — | ALU: `05` | `ALU_EN`; nessuna scrittura |
| 17 | T3 · cattura ADD | `11` nessuna | — | ALU: `05` | `ALU_EN`, `MDR_WE`, `FLAGS_WE` |
| 18 | T4 · prepara MDR | `11` nessuna | — | MDR: `05` | `MDR_OE`; nessuna scrittura |
| 19 | T5 · scrivi RA | `11` nessuna | — | MDR: `05` | `MDR_OE`, `RA_EN`, `RA_RB_RW` |
| 20 | T6 · fine ADD | `11` nessuna | — | MDR: `05` | `MDR_OE`, `NEXT_FETCH` |
| 22 (solo misura) | T2 · HLT | `11` nessuna | — | — | `SYS_STEP_n=0`; conteggio microstep disabilitato |

Durante tutta la sequenza **BOOT_RUN=1 (RUN)**. `SYS_STEP_n=1` nei punti
1–21 e diventa `0` entrando in HLT/T2 dopo l'impulso 21.
La logica esterna `µSTEP_EN = SYS_STEP_n OR IR2 OR IR1 OR IR0` vale allora
zero, perché IR=`00`: il contatore resta in `001`. **HLT blocca il conteggio
dei microstep**; il clock esterno può continuare a commutare. In T2 non
sono attive scritture né incremento PC, quindi ulteriori impulsi non
modificano lo stato. Il punto 22 serve solo a misurare questo stato fermo.

## Misure con il tester prima e dopo ogni impulso

| Punto | Istruzione | Step | Operazione | Misura PRIMA dell'impulso | Atteso DOPO |
|---|---|---|---|---|---|
| 1 | `LDI R6, 4` | T1 `000` | RAM -> IR; PC++ | DB=`26 / 00100110` dalla RAM | IR=`26 / 00100110`; PC=`0001 / 0000000000000001` |
| 2 | `LDI R6, 4` | T2 `001` | RAM -> MDR; PC++ | DB=`04 / 00000100` dalla RAM | MDR=`04 / 00000100`; PC=`0002 / 0000000000000010` |
| 3 | `LDI R6, 4` | T3 `010` | MDR -> R6 | MDR in lettura: DB=`04 / 00000100`; ingresso R6 uguale | R6 memorizza `04 / 00000100` |
| 4 | `LDI R6, 4` | T4 `011` | Ritorno al fetch | Nessuna sorgente DB | T1 `000`; PC=`0002 / 0000000000000010` |
| 5 | `LDI R7, 1` | T1 `000` | RAM -> IR; PC++ | DB=`27 / 00100111` dalla RAM | IR=`27 / 00100111`; PC=`0003 / 0000000000000011` |
| 6 | `LDI R7, 1` | T2 `001` | RAM -> MDR; PC++ | DB=`01 / 00000001` dalla RAM | MDR=`01 / 00000001`; PC=`0004 / 0000000000000100` |
| 7 | `LDI R7, 1` | T3 `010` | MDR -> R7 | MDR in lettura: DB=`01 / 00000001`; ingresso R7 uguale | R7 memorizza `01 / 00000001` |
| 8 | `LDI R7, 1` | T4 `011` | Ritorno al fetch | Nessuna sorgente DB | T1 `000`; PC=`0004 / 0000000000000100` |
| 9 | `MOV RA, R7` | T1 `000` | RAM -> IR; PC++ | DB=`C7 / 11000111` dalla RAM | IR=`C7 / 11000111`; PC=`0005 / 0000000000000101` |
| 10 | `MOV RA, R7` | T2 `001` | R7 -> RA | R7 in lettura: Q R7 e DB=`01 / 00000001` | RA memorizza `01 / 00000001` |
| 11 | `MOV RA, R7` | T3 `010` | Ritorno al fetch | Nessuna sorgente DB | T1 `000`; PC=`0005 / 0000000000000101` |
| 12 | `MOV RB, R6` | T1 `000` | RAM -> IR; PC++ | DB=`CE / 11001110` dalla RAM | IR=`CE / 11001110`; PC=`0006 / 0000000000000110` |
| 13 | `MOV RB, R6` | T2 `001` | R6 -> RB | R6 in lettura: Q R6 e DB=`04 / 00000100` | RB memorizza `04 / 00000100` |
| 14 | `MOV RB, R6` | T3 `010` | Ritorno al fetch | Nessuna sorgente DB | T1 `000`; PC=`0006 / 0000000000000110` |
| 15 | `ADD` | T1 `000` | RAM -> IR; PC++ | DB=`67 / 01100111` dalla RAM | IR=`67 / 01100111`; PC=`0007 / 0000000000000111` |
| 16 | `ADD` | T2 `001` | Prepara ALU; nessuna scrittura | ALU A=`01 / 00000001`, B=`04 / 00000100`; uscita e DB=`05 / 00000101` | RA resta `01 / 00000001`; ALU pronto per MDR |
| 17 | `ADD` | T3 `010` | ALU -> MDR; salva flag | DB e ingresso MDR=`05 / 00000101`; RA=`01 / 00000001` | MDR=`05 / 00000101`; C Z N O=0 0 0 0; RA invariato |
| 18 | `ADD` | T4 `011` | Prepara MDR sul bus; nessuna scrittura | MDR in lettura: DB=`05 / 00000101`; ingresso RA uguale | MDR=`05 / 00000101`; dato pronto per RA |
| 19 | `ADD` | T5 `100` | MDR -> RA | DB e ingresso RA=`05 / 00000101` da MDR | RA=`05 / 00000101`; MDR=`05 / 00000101`; flag invariati |
| 20 | `ADD` | T6 `101` | Mantiene MDR; ritorno al fetch | DB=`05 / 00000101` da MDR; RA=`05 / 00000101` | T1 `000`; PC=`0007 / 0000000000000111` |
| 21 | `HLT` | T1 `000` | RAM -> IR; PC++ | DB=`00 / 00000000` dalla RAM | IR=`00 / 00000000`; PC=`0008 / 0000000000001000`; T2 `001` fermo |
| 22 | `HLT` | T2 `001` | Arresto; nessun impulso necessario | PC=`0008 / 0000000000001000`; IR=`00 / 00000000`; flag=`0000` (C/Z/N/O) | Nessun cambiamento |

**Quando puoi leggere i registri:** un registro con `/OE` alto ha uscite
in alta impedenza: il tester su Q non mostra il suo contenuto. Perciò verifica
MDR sul bus nei punti **3, 7 e 18–20**, R7 nel **10**, R6 nel **13**, quando sono
in lettura. I valori DOPO dei registri sono attesi, ma misurabili sulle Q
solo se quelle uscite sono abilitate. Non forzare `/OE` per leggerli.

**Per verificare la somma:** dopo l'impulso **15**, misura ALU A=`01 / 00000001`,
B=`04 / 00000100`, uscita ALU e DB=`05 / 00000101`. Dopo il **17**, verifica
MDR sul bus al punto **18**: deve dare `05 / 00000101`. Dopo il **19**, verifica
RA sulle Q verso ALU: `05 / 00000101`; RB resta `04 / 00000100` e i flag sono `0000`.
L'uscita combinatoria ALU può ora diventare `09 / 00001001` perché RA è cambiato:
il dato da trasferire resta in MDR, con ALU disabilitata sul bus.
Alla fine R6=`04 / 00000100`, R7=`01 / 00000001`, RA=MDR=`05 / 00000101`.

**Aggiornare tutte e tre le ROM CU** prima di usare questa tabella; gli 8 byte
nella EEPROM programma restano gli stessi. Nei ritorni al fetch diversi da ADD
e durante HLT, DB non ha una sorgente prevista: una lettura `00` non verifica
un registro. Se una misura non coincide, annota punto, segnale e valore letto.
I valori DOPO descrivono le catture previste; con i clock ottenuti da porte AND,
una cattura può avvenire anche entrando nella fase mentre CK è alto.
Il tester verifica i livelli stabili; per stabilire l'ordine dei fronti serve
un oscilloscopio o un analizzatore logico.
