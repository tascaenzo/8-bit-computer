# Verifica ISA, microsequenze e timing della CU

Data: 28 settembre 2026. Verificata la copia di lavoro corrente, incluse le
modifiche locali già presenti. Nessuna modifica al microcodice di produzione.

## Esito

**Le parole stabili delle ROM corrispondono alle microsequenze ISA documentate.
Il timing fisico non è ancora validato per il collegamento definitivo.**

Ci sono due rischi prioritari: clock dei registri generati da enable ROM che
possono cambiare durante il livello alto del clock, e rilascio di indirizzo/dato
contemporaneo alla fine della scrittura RAM. Inoltre `CMP` richiede di accertare
dove sono prelevati i flag rispetto all'abilitazione dell'ALU.

Questi problemi possono manifestarsi anche a clock manuale: aumentare la durata
del microstep non elimina un fronte spurio o inverte l'ordine di due transizioni.

## Verifiche eseguite

| Verifica | Risultato | Limite |
| --- | --- | --- |
| `make -B test` in `tools/cu-bytecode` | PASS | Controlla parole logiche e immagini, non i ritardi. |
| `make -B test` in `tools/assembler` | PASS | Codifica ed errori di assembly. |
| `npm test` in `tools/simulator-web` | 21/21 PASS | Simulazione funzionale. |
| Audit indipendente dei tre binari | PASS su 8192 parole fisiche | Assenza di contese negli stati assestati. |
| Sequenze dei binari confrontate con tabella ISA indipendente | 86 opcode × 16 flag = 1376 sequenze PASS | Tutti gli otto step, incluse le fasi inattive; non è una simulazione analogica. |
| BOOT e decoder HLT | PASS per tutti gli opcode, flag e step | La OR esterna e il collegamento al contatore devono esistere davvero. |
| Fine scrittura STA/STAI | RISCHIO rilevato in entrambe | Nessuna fase di mantenimento dei bus dopo `/WE`. |

L'audit decodifica direttamente i bit fisici dei file, con una mappa fissata
alla revisione attuale, senza chiamare le funzioni del generatore C. Verifica
anche sorgente presente per ogni destinazione, indirizzo valido per memoria,
assenza di `PC_INC` e `PC_LOAD` contemporanei e fetch comune a tutti i gruppi.
La verifica delle sequenze non prova che il cablaggio dell'ALU implementi le
formule matematiche dell'ISA.

Il simulatore web non esegue i binari CU: `app.js`, nella funzione `microStep`,
mostra il piano dei microstep e invoca `runInstruction()` al passo di esecuzione.
`cpu.js` aggiorna lo stato a livello di istruzione. Quindi il suo PASS non
dimostra l'assenza di errori fra i fronti di clock.

### Sequenze attuali controllate

`T1` comune: PC → memoria → IR, incremento PC alla chiusura del passo.

| Famiglia | Esecuzione dopo T1 | Ritorno |
| --- | --- | --- |
| LDI | T2 immediato → MDR e PC++; T3 MDR → Rn | T4 |
| LDA | T2/T3 indirizzo low/high → MAR e PC++; T4 memoria → MDR; T5 MDR → Rn | T6 |
| STA | T2/T3 indirizzo → MAR e PC++; T4 Rn → MDR; T5 MDR → memoria | T6 |
| LDX | T2/T3 indirizzo low/high → IDX e PC++ | T4 |
| LDAI | T2 memoria[IDX] → MDR; T3 MDR → Rn | T4 |
| STAI | T2 Rn → MDR; T3 MDR → memoria[IDX] | T4 |
| ALU | T2 risultato → RA e flag | T3 |
| CMP | T2 solo flag, RA/RB conservati | T3 |
| MOV | T2 trasferimento fra Rn e RA/RB previsto dall'opcode | T3 |
| Salti | T2/T3 indirizzo → MAR e PC++; T4 eventuale MAR → PC | T5 |
| NOP / HLT | T2 inattivo; HLT blocca qui il contatore con la OR esterna | T3 per NOP |

Sono coerenti little-endian, consumo degli operandi anche per salti non presi,
separazione SUB `0x78` / CMP `0x69`, selezione diretta di Rn da IR[2:0] e nove
condizioni di salto distinte. La mappa fisica degli step è invertita:
T1..T8 corrispondono agli offset EEPROM `0,4,2,6,1,5,3,7`.

## 1. Priorità alta: enable ROM usati per generare i clock

Le trascrizioni dei video 14 e 23 descrivono porte AND fra clock ed enable
per RA/RB, IDX e flag. Il video 24 descrive il contatore microstep 74161.
Se il cablaggio è ancora questo e microstep e registri usano lo stesso fronte
di salita, si presenta il seguente rischio:

1. Il clock sale e il contatore cambia microstep.
2. Dopo i ritardi di propagazione, le ROM producono gli enable del nuovo passo.
3. Il clock è ancora alto: un enable che passa da 0 a 1 genera un nuovo fronte
   di salita all'uscita della AND, senza un nuovo impulso del clock principale.
4. Un registro può acquisire mentre indirizzo, dato o ALU stanno cambiando.

Esempio: entrando nel T2 di ADD, `RA_EN`, `RA_RB_RW` e `FLAGS_WE` diventano
attivi. Il clock locale può scattare all'ingresso di T2, invece che soltanto
alla sua chiusura. Un'acquisizione anticipata di RA modifica subito l'ingresso
dell'ALU; un'acquisizione successiva può sommare RB una seconda volta.

Anche IR e flag sono indirizzi delle ROM: la loro variazione può disturbare
le uscite durante il livello alto. Parole uguali nelle pagine dei flag non
costituiscono una garanzia elettrica di assenza di transitori.

**Intervento richiesto:** definire uno schema di clock nel quale gli enable
dei clock locali restino stabili per l'intera fase alta. Una soluzione da
progettare è registrare la microistruzione dopo l'assestamento delle ROM e
prima del fronte di esecuzione, mantenendola durante quel fronte. Un'altra
possibilità è una gestione delle fasi con enable trattenuti correttamente.
Spostare soltanto il contatore sul fronte opposto non risolve automaticamente
le variazioni di IR/flag né le scritture asincrone RAM.

Non basta inserire una AND aggiuntiva o rallentare il clock. Vanno verificati
anche durata degli impulsi, setup/hold e ritardo relativo fra clock locali.
I 574 acquisiscono sul fronte positivo e richiedono dati stabili attorno al
fronte; vedere il [datasheet TI SN74HCT574](https://www.ti.com/lit/ds/symlink/sn74hct574.pdf).
La famiglia e il suffisso realmente montati determinano i tempi da usare.

## 2. Priorità alta: scrittura RAM senza mantenimento dei bus

In `src/microcode.c`, STA T5 abilita `ADDR_SEL=MAR`, `MDR_OE`, `RAM_WE`.
T6 seleziona invece nessun indirizzo, disabilita MDR e disattiva RAM_WE.
STAI fa lo stesso nel passaggio T3 → T4, con IDX.

Non esiste una garanzia che `/WE_RAM` salga prima che il dato diventi alta
impedenza o l'indirizzo cambi. I tre comandi partono dalla stessa parola ROM,
ma seguono percorsi fisici diversi. Anche un hold nominale di zero richiede
che il dato resti valido **fino** alla fine della scrittura.

All'ingresso del passo di scrittura manca inoltre una fase esplicita di
preparazione: selettore indirizzi, MDR_OE e RAM_WE cambiano insieme. Il rischio
dipende dai ritardi del selettore, dei buffer e del decoder di memoria.

Una sequenza proposta, non ancora applicata, è:

| Fase | STA diretto | STAI | Segnali |
| --- | --- | --- | --- |
| Preparazione | T5 | T3 | MAR/IDX selezionato, MDR_OE, RAM_WE inattivo |
| Scrittura | T6 | T4 | stesso indirizzo e dato, RAM_WE attivo |
| Chiusura con mantenimento | T7 | T5 | stesso indirizzo e dato, RAM_WE inattivo |
| Ritorno | T8 | T6 | NEXT_FETCH, bus rilasciati |

Rientra negli otto microstep disponibili. Separare queste fasi rende espliciti
setup e mantenimento, ma **non elimina i glitch delle uscite ROM grezze**.
Occorre anche impedire che `/WE` produca impulsi durante l'assestamento della
CU: registrazione dei controlli e/o una finestra di scrittura qualificata,
con apertura dopo dati/indirizzo validi e chiusura prima del loro rilascio.
Anche `/CS` può terminare una scrittura: va incluso nella verifica.

I diagrammi SRAM distinguono durata dell'impulso, dato prima della fine della
scrittura e mantenimento successivo. Come riferimento di metodo vedere la
[tabella del produttore Alliance Memory](https://www.alliancememory.com/wp-content/uploads/181204_256Kb-LP-Sram-comparison-between-CY62256NLL-55-and-AS6C62256-55_SOP-TSOP-sTSOP-1.pdf).
Non trasferire i suoi valori numerici alla RAM Hitachi descritta nel video 18:
serve la sigla completa del componente realmente montato.

## 3. Da accertare: CMP con ALU_EN inattivo

CMP T2 attiva solo FLAGS_WE. È corretto **se i flag sono generati sul risultato
interno dell'ALU anche quando il buffer verso il bus CPU è disabilitato**.
Nei video 7 e 8 Z/N sono descritti come derivati dal bus del risultato; il
testo da solo non distingue con certezza un bus interno dal bus CPU attuale.

Se ALU_EN disabilita anche il decoder interno che seleziona il risultato,
oppure Z/N sono prelevati a valle del buffer disabilitato, CMP campiona flag
non validi. In quel cablaggio occorre abilitare il percorso ALU durante CMP
senza abilitare la scrittura di RA, oppure prelevare i flag a monte.

Provare RA=RB (Z=1), RA=0/RB=1 (C=1,N=1), RA=0x80/RB=1 (O=1,N=0),
con RA e RB invariati dopo CMP. Controllare anche C=borrow per SUB/CMP e
C=O=0 nelle operazioni logiche: la CU salva i flag, non ne corregge i valori.

## 4. BOOT, reset, fetch e ritorno

- BOOT è meglio separato delle STA: T2 alza `/WE` conservando PC selezionato
  ed EPROM abilitata; PC incrementa alla chiusura di T2. T3 lascia assestare
  il nuovo byte prima della successiva copia. Rimane necessaria la protezione
  dai transitori ROM, specialmente durante l'incremento PC e il reset.
- NEXT_FETCH su `/LOAD` sincrono del 74161, ingressi paralleli zero: corretto.
  Il video 27 riporta già il malfunzionamento usando `/CLR` asincrono e il
  passaggio a `/LOAD`. Il passo dedicato al ritorno da solo non protegge un
  `/CLR` collegato direttamente alla ROM. Riferimento:
  [TI SN74LS161A](https://www.ti.com/lit/ds/symlink/sn74ls161a.pdf).
- Fetch con IR_WE e PC_INC simultanei è valido nel modello a fronte comune:
  IR legge il vecchio indirizzo, PC poi avanza. Sulla scheda verificare che
  il clock locale di IR non arrivi dopo il cambio di dato causato dal PC.
  Lo stesso vale per immediati, MAR e IDX. L'hold dipende dai ritardi minimi,
  non dalla lunghezza dell'intero periodo.
- ALU e flag possono essere acquisiti nello stesso microstep se entrambi
  campionano il risultato dei vecchi RA/RB. Verificare che il clock dei flag
  non arrivi tanto tardi da vedere il risultato ricalcolato dopo il cambio RA.
- Reset deve inibire scritture RAM **e clock di scrittura locali** durante
  l'assestamento. Tenere il clock basso, selezionare BOOT/RUN, azzerare PC e
  sequencer, attendere controlli validi e soltanto poi avviare l'esecuzione.
  Se si aggiunge un registro di controllo, definirne anche l'inizializzazione.

## 5. Misure necessarie prima della prova completa

1. Acquisire clock principale, Q del microstep, enable ROM e clock locale
   di RA/flag: un solo fronte utile per acquisizione prevista, nessuno spurio.
2. Per STA/STAI osservare `/WE` e `/CS` sul chip, selezione indirizzi e dato
   ai pin della RAM. Misurare setup, durata, fine scrittura e hold. Provare
   indirizzi con molti bit diversi e dati `00`, `FF`, `55`, `AA`.
3. Provare fetch e operandi attraversando `0x00FF → 0x0100`: controllare
   il dato ai registri rispetto ai loro clock locali, non soltanto ai LED.
4. Provare ADD `FF+01` (RA=00,C=1,Z=1), SUB `00-01` (RA=FF,C=1,N=1),
   ADD `7F+01` (RA=80,O=1,N=1), CMP e tutti i salti presi/non presi.
5. Verificare HLT fermo in T2 anche con altri impulsi, NOP che prosegue,
   reset e passaggio BOOT/RUN. Eseguire poi `examples/assembly/cu_isa_smoke.asm`.

Per il setup serve un budget del percorso peggiore: uscita dei registri di
indirizzo CU → EEPROM → decodifica/buffer → memoria o ALU → ingresso registro,
più setup e margine per lo skew dei clock. Per l'hold serve invece il percorso
minimo di cambiamento del dato confrontato con il clock locale di cattura.
Con fasi separate usare il tempo della fase disponibile, non l'intero periodo.

La AT28C64B documenta tempi di accesso fino a 150 ns nella versione citata:
non è una frequenza massima della CPU e non promette uscite utilizzabili
durante il cambio indirizzo. Vedere [datasheet Microchip](https://ww1.microchip.com/downloads/en/DeviceDoc/doc0270.pdf).
Non è possibile assegnare una frequenza garantita senza suffissi dei chip,
schema dei clock e misure/carichi reali.

## Riproduzione e identificazione immagini

Da root del repository, con Python 3 e compilatore C:

```sh
make -B -C tools/cu-bytecode test all
mkdir -p /tmp/cpu8-audit-20260928
tools/cu-bytecode/build/cpu8microcode -o /tmp/cpu8-audit-20260928/microcode
python3 tools/cu-bytecode/tests/audit_rom_timing.py /tmp/cpu8-audit-20260928/microcode
make -B -C tools/assembler test
npm --prefix tools/simulator-web test
```

Lo script termina con zero quando i controlli logici passano; i messaggi
`RISCHIO` restano motivi per non considerare validato il timing fisico.
I binari di audit sono stati generati in `/tmp`, senza sovrascrivere quelli
destinati al programmatore. Hash SHA-256 della revisione esaminata:

```text
ROM0 bcd68d8330227aaab5fe3195cb19cef1b6a31963cf08d59ad3ec47118bd2fff3
ROM1 b470cbf7c58c6d2d8d3b7f43623e389aa7fa3c99beaf14f3ae15967f4281ee88
ROM2 f0748d039591f55060a6eab2e96dd69f5fdd4f9bc5aef1a25f6c2ea12115c01d
```

Fuori dall'ISA fisica verificata: IN/OUT, implementati soltanto da
assembler/simulatore. Gli opcode riservati non hanno necessariamente un trap
hardware: le ROM vedono IR[7:3], quindi condividono il comportamento del gruppo.
Non usare vecchi binari SUB/salti o assumere che un opcode invalido fermi la CPU.
