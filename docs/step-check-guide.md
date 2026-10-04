# Verifica manuale: 5 + 3, poi HLT

Programma: `examples/assembly/step_check.asm`. Immagine da 8 byte:
`20 05 21 03 C0 C9 67 00`.
Caricare `tools/assembler/build/step_check.hex` nella EEPROM **programma**.
Le EEPROM CU restano quelle già programmate.

## Come leggere la prova

1. Completa BOOT, poi prepara RUN con PC=0000 e contatore microstep=000,
   tramite il controllo/reset esterno previsto dalla scheda. Tieni il clock
   basso durante il cambio e lascia assestare le uscite.
2. Per ogni riga: PRIMA del fronte di esecuzione controlla microstep e segnali
   della prima tabella. DOPO il fronte e l'assestamento controlla i registri
   della seconda tabella. Le uscite CU dopo il fronte sono già quelle del
   passo seguente: non confrontarle con la riga appena eseguita.
3. Un impulso esegue un microstep, non una intera istruzione. La tabella
   descrive la sequenza funzionale a fronti corretti; eventuali clock locali
   anticipati/spuri vanno diagnosticati sul circuito.

T1=000 è il tuo T0; T2=001, T3=010, T4=011. Gli ingressi fisici EEPROM
sono invertiti: A0=µSTEP2, A1=µSTEP1, A2=µSTEP0. Gli offset EEPROM dei primi
quattro passi sono quindi 0,4,2,6.

Ogni valore dei registri e delle ROM è mostrato come **decimale / esadecimale / binario**.
Esempio: `5 / 0x05 / 00000101`. I binari si leggono da bit più significativo
a bit meno significativo (LED da sinistra a destra: bit 7..0; PC bit 15..0). `?` significa
non ancora inizializzato da questo programma: non richiediamo che il reset
azzerri tutti i registri. PC è a 16 bit, gli altri valori mostrati a 8 bit.
IR resta sull'opcode mentre vengono letti gli immediati: non deve mostrare
05 o 03. I flag sono scritti nell'ordine **C Z N O**.

## Segnali PRIMA del fronte

“Attivi” indica la funzione, non sempre un livello elettrico alto.
MDR_OE, RAM_OE, ALU_EN, NEXT_FETCH e SYS_STEP sono attivi bassi.
PC_LOAD è attivo basso e resta **inattivo (ROM1 D1=1)** per tutta la prova.
ADDR_SEL=01 sceglie PC; 11 nessuna sorgente. Le colonne ROM0/1/2 danno
anche tutti i livelli inattivi e permettono il confronto dei pin D7..D0.
In questo programma i byte non dipendono dai flag; al fetch non dipendono
neppure dal precedente contenuto di IR.

| # | Istruzione | Passo µSTEP | ADDR_SEL | Controlli attivi | ROM0 / ROM1 / ROM2 | Azione al fronte |
|---|---|---|---|---|---|---|
| 1 | LDI R0, 5 | T1 `000` | `01` | IR_WE, PC_INC, RAM_OE | ROM0: `245 / 0xF5 / 11110101`<br>ROM1: `3 / 0x03 / 00000011`<br>ROM2: `65 / 0x41 / 01000001` | Opcode → IR; PC++ |
| 2 | LDI R0, 5 | T2 `001` | `01` | MDR_WE, PC_INC, RAM_OE | ROM0: `253 / 0xFD / 11111101`<br>ROM1: `2 / 0x02 / 00000010`<br>ROM2: `65 / 0x41 / 01000001` | Immediato → MDR; PC++ |
| 3 | LDI R0, 5 | T3 `010` | `11` | MDR_OE, RF_EN, RF_RW | ROM0: `227 / 0xE3 / 11100011`<br>ROM1: `26 / 0x1A / 00011010`<br>ROM2: `73 / 0x49 / 01001001` | MDR → R0 |
| 4 | LDI R0, 5 | T4 `011` | `11` | NEXT_FETCH | ROM0: `115 / 0x73 / 01110011`<br>ROM1: `2 / 0x02 / 00000010`<br>ROM2: `73 / 0x49 / 01001001` | Carica 000 nel microstep; nessun registro dati cambia |
| 5 | LDI R1, 3 | T1 `000` | `01` | IR_WE, PC_INC, RAM_OE | ROM0: `245 / 0xF5 / 11110101`<br>ROM1: `3 / 0x03 / 00000011`<br>ROM2: `65 / 0x41 / 01000001` | Opcode → IR; PC++ |
| 6 | LDI R1, 3 | T2 `001` | `01` | MDR_WE, PC_INC, RAM_OE | ROM0: `253 / 0xFD / 11111101`<br>ROM1: `2 / 0x02 / 00000010`<br>ROM2: `65 / 0x41 / 01000001` | Immediato → MDR; PC++ |
| 7 | LDI R1, 3 | T3 `010` | `11` | MDR_OE, RF_EN, RF_RW | ROM0: `227 / 0xE3 / 11100011`<br>ROM1: `26 / 0x1A / 00011010`<br>ROM2: `73 / 0x49 / 01001001` | MDR → R1 |
| 8 | LDI R1, 3 | T4 `011` | `11` | NEXT_FETCH | ROM0: `115 / 0x73 / 01110011`<br>ROM1: `2 / 0x02 / 00000010`<br>ROM2: `73 / 0x49 / 01001001` | Carica 000 nel microstep; nessun registro dati cambia |
| 9 | MOV RA, R0 | T1 `000` | `01` | IR_WE, PC_INC, RAM_OE | ROM0: `245 / 0xF5 / 11110101`<br>ROM1: `3 / 0x03 / 00000011`<br>ROM2: `65 / 0x41 / 01000001` | Opcode → IR; PC++ |
| 10 | MOV RA, R0 | T2 `001` | `11` | RA_EN, RA_RB_RW, RF_EN | ROM0: `243 / 0xF3 / 11110011`<br>ROM1: `106 / 0x6A / 01101010`<br>ROM2: `73 / 0x49 / 01001001` | R0 → RA |
| 11 | MOV RA, R0 | T3 `010` | `11` | NEXT_FETCH | ROM0: `115 / 0x73 / 01110011`<br>ROM1: `2 / 0x02 / 00000010`<br>ROM2: `73 / 0x49 / 01001001` | Carica 000 nel microstep; nessun registro dati cambia |
| 12 | MOV RB, R1 | T1 `000` | `01` | IR_WE, PC_INC, RAM_OE | ROM0: `245 / 0xF5 / 11110101`<br>ROM1: `3 / 0x03 / 00000011`<br>ROM2: `65 / 0x41 / 01000001` | Opcode → IR; PC++ |
| 13 | MOV RB, R1 | T2 `001` | `11` | RA_RB_RW, RB_EN, RF_EN | ROM0: `243 / 0xF3 / 11110011`<br>ROM1: `202 / 0xCA / 11001010`<br>ROM2: `73 / 0x49 / 01001001` | R1 → RB |
| 14 | MOV RB, R1 | T3 `010` | `11` | NEXT_FETCH | ROM0: `115 / 0x73 / 01110011`<br>ROM1: `2 / 0x02 / 00000010`<br>ROM2: `73 / 0x49 / 01001001` | Carica 000 nel microstep; nessun registro dati cambia |
| 15 | ADD | T1 `000` | `01` | IR_WE, PC_INC, RAM_OE | ROM0: `245 / 0xF5 / 11110101`<br>ROM1: `3 / 0x03 / 00000011`<br>ROM2: `65 / 0x41 / 01000001` | Opcode → IR; PC++ |
| 16 | ADD | T2 `001` | `11` | ALU_EN, FLAGS_WE, RA_EN, RA_RB_RW | ROM0: `243 / 0xF3 / 11110011`<br>ROM1: `98 / 0x62 / 01100010`<br>ROM2: `74 / 0x4A / 01001010` | RA + RB → RA; salva flag |
| 17 | ADD | T3 `010` | `11` | NEXT_FETCH | ROM0: `115 / 0x73 / 01110011`<br>ROM1: `2 / 0x02 / 00000010`<br>ROM2: `73 / 0x49 / 01001001` | Carica 000 nel microstep; nessun registro dati cambia |
| 18 | HLT | T1 `000` | `01` | IR_WE, PC_INC, RAM_OE | ROM0: `245 / 0xF5 / 11110101`<br>ROM1: `3 / 0x03 / 00000011`<br>ROM2: `65 / 0x41 / 01000001` | Opcode → IR; PC++ |
| 19 | HLT | T2 `001` | `11` | SYS_STEP | ROM0: `243 / 0xF3 / 11110011`<br>ROM1: `2 / 0x02 / 00000010`<br>ROM2: `9 / 0x09 / 00001001` | Arresto: µSTEP_EN=0, resta in 001 |

## Registri DOPO il fronte

MAR, IDX e R2..R7 non vengono modificati da questa prova. MDR resta **3 / 0x03 / 00000011** dopo
il secondo LDI; non contiene il risultato della somma. Il risultato è in RA.

| # | PC | IR | MDR | R0 | R1 | RA | RB | C Z N O |
|---|---|---|---|---|---|---|---|---|
| 1 | `1 / 0x0001 / 0000000000000001` | `32 / 0x20 / 00100000` | ? | ? | ? | ? | ? | ? ? ? ? |
| 2 | `2 / 0x0002 / 0000000000000010` | `32 / 0x20 / 00100000` | `5 / 0x05 / 00000101` | ? | ? | ? | ? | ? ? ? ? |
| 3 | `2 / 0x0002 / 0000000000000010` | `32 / 0x20 / 00100000` | `5 / 0x05 / 00000101` | `5 / 0x05 / 00000101` | ? | ? | ? | ? ? ? ? |
| 4 | `2 / 0x0002 / 0000000000000010` | `32 / 0x20 / 00100000` | `5 / 0x05 / 00000101` | `5 / 0x05 / 00000101` | ? | ? | ? | ? ? ? ? |
| 5 | `3 / 0x0003 / 0000000000000011` | `33 / 0x21 / 00100001` | `5 / 0x05 / 00000101` | `5 / 0x05 / 00000101` | ? | ? | ? | ? ? ? ? |
| 6 | `4 / 0x0004 / 0000000000000100` | `33 / 0x21 / 00100001` | `3 / 0x03 / 00000011` | `5 / 0x05 / 00000101` | ? | ? | ? | ? ? ? ? |
| 7 | `4 / 0x0004 / 0000000000000100` | `33 / 0x21 / 00100001` | `3 / 0x03 / 00000011` | `5 / 0x05 / 00000101` | `3 / 0x03 / 00000011` | ? | ? | ? ? ? ? |
| 8 | `4 / 0x0004 / 0000000000000100` | `33 / 0x21 / 00100001` | `3 / 0x03 / 00000011` | `5 / 0x05 / 00000101` | `3 / 0x03 / 00000011` | ? | ? | ? ? ? ? |
| 9 | `5 / 0x0005 / 0000000000000101` | `192 / 0xC0 / 11000000` | `3 / 0x03 / 00000011` | `5 / 0x05 / 00000101` | `3 / 0x03 / 00000011` | ? | ? | ? ? ? ? |
| 10 | `5 / 0x0005 / 0000000000000101` | `192 / 0xC0 / 11000000` | `3 / 0x03 / 00000011` | `5 / 0x05 / 00000101` | `3 / 0x03 / 00000011` | `5 / 0x05 / 00000101` | ? | ? ? ? ? |
| 11 | `5 / 0x0005 / 0000000000000101` | `192 / 0xC0 / 11000000` | `3 / 0x03 / 00000011` | `5 / 0x05 / 00000101` | `3 / 0x03 / 00000011` | `5 / 0x05 / 00000101` | ? | ? ? ? ? |
| 12 | `6 / 0x0006 / 0000000000000110` | `201 / 0xC9 / 11001001` | `3 / 0x03 / 00000011` | `5 / 0x05 / 00000101` | `3 / 0x03 / 00000011` | `5 / 0x05 / 00000101` | ? | ? ? ? ? |
| 13 | `6 / 0x0006 / 0000000000000110` | `201 / 0xC9 / 11001001` | `3 / 0x03 / 00000011` | `5 / 0x05 / 00000101` | `3 / 0x03 / 00000011` | `5 / 0x05 / 00000101` | `3 / 0x03 / 00000011` | ? ? ? ? |
| 14 | `6 / 0x0006 / 0000000000000110` | `201 / 0xC9 / 11001001` | `3 / 0x03 / 00000011` | `5 / 0x05 / 00000101` | `3 / 0x03 / 00000011` | `5 / 0x05 / 00000101` | `3 / 0x03 / 00000011` | ? ? ? ? |
| 15 | `7 / 0x0007 / 0000000000000111` | `103 / 0x67 / 01100111` | `3 / 0x03 / 00000011` | `5 / 0x05 / 00000101` | `3 / 0x03 / 00000011` | `5 / 0x05 / 00000101` | `3 / 0x03 / 00000011` | ? ? ? ? |
| 16 | `7 / 0x0007 / 0000000000000111` | `103 / 0x67 / 01100111` | `3 / 0x03 / 00000011` | `5 / 0x05 / 00000101` | `3 / 0x03 / 00000011` | `8 / 0x08 / 00001000` | `3 / 0x03 / 00000011` | `0 0 0 0` |
| 17 | `7 / 0x0007 / 0000000000000111` | `103 / 0x67 / 01100111` | `3 / 0x03 / 00000011` | `5 / 0x05 / 00000101` | `3 / 0x03 / 00000011` | `8 / 0x08 / 00001000` | `3 / 0x03 / 00000011` | `0 0 0 0` |
| 18 | `8 / 0x0008 / 0000000000001000` | `0 / 0x00 / 00000000` | `3 / 0x03 / 00000011` | `5 / 0x05 / 00000101` | `3 / 0x03 / 00000011` | `8 / 0x08 / 00001000` | `3 / 0x03 / 00000011` | `0 0 0 0` |
| 19 | `8 / 0x0008 / 0000000000001000` | `0 / 0x00 / 00000000` | `3 / 0x03 / 00000011` | `5 / 0x05 / 00000101` | `3 / 0x03 / 00000011` | `8 / 0x08 / 00001000` | `3 / 0x03 / 00000011` | `0 0 0 0` |

## Arresto e risultato

Dopo il fetch di HLT (riga 18), IR=**0 / 0x00 / 00000000**,
PC=**8 / 0x0008 / 0000000000001000** e il contatore entra in `001`.
Le uscite della riga 19 danno ROM2 D6=0; con IR2..IR0=000 la OR vale zero.
HLT non attende un altro impulso per rendere basso il consenso: entrando
in T2 il contatore è già inibito. La riga 19 indica lo stato fermo e il
comportamento con ulteriori impulsi, non un microstep che avanza.

Conseguentemente bastano **18 fronti utili RUN** per raggiungere l'arresto.
Altri impulsi devono lasciare microstep=`001` e i registri invariati:
PC=**8 / 0x0008 / 0000000000001000**, IR=**0 / 0x00 / 00000000**,
RA=**8 / 0x08 / 00001000**, RB=**3 / 0x03 / 00000011**.
Il clock principale può continuare se è inibito soltanto il contatore.

I LED su IR verificano questa sequenza:

| Istruzione | Decimale | Esadecimale | Binario IR[7:0] |
|---|---|---|---|
| LDI R0, 5 | 32 | 0x20 | `00100000` |
| LDI R1, 3 | 33 | 0x21 | `00100001` |
| MOV RA, R0 | 192 | 0xC0 | `11000000` |
| MOV RB, R1 | 201 | 0xC9 | `11001001` |
| ADD | 103 | 0x67 | `01100111` |
| HLT | 0 | 0x00 | `00000000` |

Per verificare anche i dati usa LED/probe o misure sui registri indicati:
IR da solo non dimostra che R0, R1 e RA contengano i risultati corretti.

Tabella confrontata con i bit delle tre immagini CU attuali; programma
assemblato e verificato anche nel simulatore funzionale. Questo programma
non prova scrittura RAM, salti, CMP, IDX o tutti i casi dei flag: serve come
prima prova breve per localizzare il primo passo divergente.
