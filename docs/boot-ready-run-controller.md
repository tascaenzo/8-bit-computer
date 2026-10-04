# Supervisore BOOT → READY → RUN

Proposta funzionale, 28 settembre 2026. Non ancora cablata né verificata
elettricamente. Mantiene le tre ROM CU e il boot a tre microstep attuale.
Assunzioni: copia di 8192 byte da 0x0000, oscillatore principale sempre attivo,
CPU che acquisisce sul fronte positivo. Prima del cablaggio servono schema
del clock reale, decoder memoria e famiglie degli integrati montati.

## Variante compatta proposta dopo la discussione

Per il solo controllo del passaggio BOOT/RUN si può usare un **secondo 74161**
e un **secondo 74138**, separati dal contatore e decoder dei microstep.
Questa variante riduce i registri necessari rispetto alla macchina a otto
stati descritta più avanti. Il contatore deve ricevere il master continuo
(invertito per aggiornare lo stato sul fronte di discesa), non CK_CPU.

| Q1:Q0 del supervisore | Stato interno | Funzione |
| --- | --- | --- |
| `00` | BOOT | La CPU copia. |
| `01` | SAFE | La copia è finita; CPU ferma, memorie isolate. |
| `10` | READY | `BOOT_RUN=1`, PC e microstep tenuti a zero; attende START. |
| `11` | RUN | Esegue il programma; il contatore supervisore resta fermo. |

Usare A=Q0 e B=Q1 del 74138 con C=0; `Y0..Y3` sono attivi bassi.
Q2/Q3 del 74161 restano a zero perché in `11` viene disabilitato il conteggio.
Tenere `/LOAD` del **contatore supervisore** inattivo e i dati di carico
definiti; non confonderlo con `/LOAD` del contatore microstep.

La condizione che abilita il conteggio del supervisore è:

```text
ADVANCE = (BOOT AND END_COPY) OR SAFE OR (READY AND START_VALID)
```

`END_COPY` è `PC=0x2000` quando il boot procede da PC=0 senza salti. Si
campiona sul fronte di discesa dopo il fronte che chiude T2 dell'ultimo byte:
il PC è 0x2000 e `/WE` è già inattivo. L'invariante permette anche di usare
PC13=1 come rivelatore del *primo* superamento di 0x1FFF; il confronto completo
è più adatto se si vogliono riconoscere stati iniziali inattesi.

Il 74138 **non deve pilotare direttamente** `/WE_RAM`, `/OE` o il clock CPU:
durante `01→10` cambiano due bit del contatore e il decoder può mostrare
brevi selezioni intermedie. Serve almeno un flip-flop `TRANSFER_LOCK`:

- parte a zero dopo reset globale, mentre `/POR` blocca comunque `/WE`;
- diventa uno al rilevamento END_COPY e resta alto durante SAFE e READY;
- dopo READY→RUN resta alto per un ulteriore periodo master;
- torna zero al successivo fronte di discesa, quando lo stato RUN è stabile.

Per esempio un 74HCT74 può registrarlo con:

```text
D_LOCK = (LOCK OR END_COPY) AND NOT(RUN_STABILE)
RUN_STABILE = (stato corrente == RUN)
```

Alla transizione READY→RUN, la logica D vede ancora READY prima del fronte
e conserva LOCK=1. Al fronte di discesa successivo vede RUN e lo azzera.
L'uscita LOCK inibisce `/WE`, `/OE` e CK_CPU nell'intervallo di cambio modo.

```text
BOOT_RUN = Q1
CPU_ALLOW = NOT(LOCK) AND (BOOT OR RUN)
CK_CPU = CK_MASTER AND CPU_ALLOW
/WE_RAM = /WE_esistente OR LOCK OR POR_ACTIVE
/OE_RAM = /OE_esistente OR LOCK OR POR_ACTIVE
/OE_EPROM = /OE_esistente OR LOCK OR POR_ACTIVE
RESET_CPU_ATTIVO = READY OR RESET_GLOBALE
```

Durante BOOT mantenere anche la protezione PC13..15 già documentata per
impedire scritture oltre 0x1FFF. I segnali per periferiche memory-mapped
vanno protetti allo stesso modo. In READY tenere azzerati PC e microstep;
quando si entra in RUN il reset si rilascia mentre LOCK tiene ancora CPU e
memorie ferme. Il primo clock RUN arriva solo dopo il rilascio di LOCK.

START deve essere antirimbalzato e sincronizzato al master. Se resta premuto
dall'accensione, un piccolo bit `START_ARMED` deve ignorarlo finché READY non
ha osservato il pulsante rilasciato, poi accetta la nuova pressione.

Componenti principali della variante: **1 × 74161, 1 × 74HCT138,
1 × 74HCT74 per LOCK e consenso START, 1 × 74HCT14 per clock invertito e
pulsante**, più le porte necessarie a ADVANCE, isolamento e reset. Un secondo
74HCT74 può sincronizzare START su due stadi; considerare anche il rilascio
sincronizzato di `/POR`. Il conteggio esatto delle porte dipende dal decoder
e dal generatore di clock già sulla board.

La variante è un progetto logico: i percorsi `CK_MASTER → inverter → 74161`
e `74161/74HCT74 → porte → CK_CPU` richiedono verifica di setup, propagazione
e assenza di impulsi corti sul circuito reale. Il modello a otto stati sotto
resta un'alternativa più esplicita; non costruire entrambe le versioni.

## Obiettivo e interfaccia

All'accensione copia EPROM → RAM; alla fine prepara PC=0 e T1 del banco RUN,
accende READY e aspetta una nuova pressione di START. La pressione durante
BOOT non viene accodata. START tenuto premuto non avvia automaticamente RUN.
RESET globale annulla l'esecuzione e ricomincia la copia; non è un pulsante
di pausa. La RAM non viene cancellata dal reset dei contatori.

Il supervisore riceve CK_MASTER prima del blocco del clock CPU. Fermare
l'oscillatore renderebbe impossibili le transizioni automatiche successive.

Ingressi:

- CK_MASTER: clock continuo, con fronti puliti.
- /POR: reset generale; rilascio sincronizzato nel supervisore.
- START: pulsante con antirimbalzo, poi sincronizzato.
- PC[15:0] e microstep[2:0]: uscite dei contatori CPU.

Uscite registrate (non semplici decodifiche combinatorie dello stato):

- CLOCK_ALLOW: consente gli impulsi del clock CPU.
- MODE_RUN: a A12 delle tre EEPROM CU; sostituisce lo switch diretto.
- WRITE_BLOCK: forza inattive le scritture di RAM e periferiche.
- MEM_ISOLATE: forza inattivi i buffer memoria EPROM/RAM/periferiche.
- RESET_ACTIVE: azzera PC e microstep. Non azzera il supervisore.

READY e BOOT_DONE sono indicazioni di stato; BOOT_DONE rimane memorizzato
anche durante il reset del PC, fino a /POR.

## Fine copia

Si campiona sul fronte di discesa del master la condizione:

```text
END_COPY = (stato == COPY) AND (PC == 0x2000) AND (microstep == 010)
```

`010` è T3 sui bit logici del contatore, non sui pin EEPROM invertiti.
Il fronte positivo precedente ha chiuso T2 dell'ultima cella e incrementato
PC da 0x1FFF a 0x2000. /WE era già alto durante T2: l'ultimo byte è concluso.
Questa scelta evita di bloccare la CPU mentre /WE è basso.

Il confronto completo evita di confondere un indirizzo arbitrario con la
fine copia. La semplificazione al solo PC13 è possibile solo con l'invariante
di partenza da zero, avanzamento sequenziale e arresto al primo superamento.
Non collegare un bit del PC direttamente ad A12 o al clock.

## Clock e fasi

```text
CK_CPU = CK_MASTER AND CLOCK_ALLOW
```

CLOCK_ALLOW è l'uscita di un flip-flop aggiornato al fronte di discesa di
CK_MASTER, tramite clock invertito. Non è il pulsante e non è una decodifica
diretta del PC. Rimane invariato per l'intera fase alta del master.
Anche le altre quattro uscite di controllo sono aggiornate sul fronte di
discesa. Il master alla AND deve essere già basso prima del cambio di Q:
verificare skew e ritardi minimi del percorso inverter + flip-flop.

Il clock CPU così ottenuto deve raggiungere PC, microstep e tutte le AND dei
clock locali: nessun registro CPU deve continuare a ricevere CK_MASTER.
Il supervisore e il sincronizzatore START usano invece il master.

Il fronte positivo del master serve all'esecuzione CPU. Il successivo fronte
negativo osserva PC/microstep assestati e cambia lo stato del supervisore.
Ogni fase intermedia dura almeno un periodo master. Deve superare i tempi
peggiori di propagazione dei circuiti coinvolti.

## Tabella degli stati e delle uscite registrate

Le uscite sono caricate insieme allo stato di destinazione. Questa tabella
non autorizza a pilotare segnali sensibili con le uscite grezze di un decoder.

| Stato | CLOCK_ALLOW | MODE_RUN | WRITE_BLOCK | MEM_ISOLATE | RESET_ACTIVE | Uscita dallo stato |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| RESET | 0 | 0 | 1 | 1 | 1 | Dopo rilascio sincronizzato /POR → BOOT_PREP |
| BOOT_PREP | 0 | 0 | 1 | 0 | 0 | Un periodo → COPY |
| COPY | 1 | 0 | 0 | 0 | 0 | END_COPY → ISOLATE, salva BOOT_DONE=1 |
| ISOLATE | 0 | 0 | 1 | 1 | 0 | Un periodo → MODE_RESET |
| MODE_RESET | 0 | 1 | 1 | 1 | 1 | Un periodo → READY |
| READY | 0 | 1 | 1 | 1 | 0 | START valido → ARM |
| ARM | 0 | 1 | 1 | 0 | 0 | Un periodo → RUN |
| RUN | 1 | 1 | 0 | 0 | 0 | Solo RESET globale ricomincia il boot |

BOOT_PREP presenta EPROM[0] con /WE inibito prima di consentire la prima
scrittura. ISOLATE chiude il clock dopo un impulso completo e disconnette
le memorie; soltanto nel periodo successivo si azzerano i contatori e si
cambia il banco CU. READY può durare indefinitamente. ARM riabilita la
lettura del primo opcode prima che parta il primo clock RUN.

HLT resta gestito dalla OR prevista per l'enable del microstep. Non serve
fermare CK_MASTER; START in RUN è ignorato e non scavalca HLT.

## Collegamenti di protezione memoria e reset

Le seguenti sono equazioni funzionali, da integrare nel decoder esistente:

```text
/WE_RAM = /WE_RAM_esistente OR WRITE_BLOCK OR POR_ACTIVE
/OE_RAM = /OE_RAM_esistente OR MEM_ISOLATE OR POR_ACTIVE
/OE_EPROM = /OE_EPROM_esistente OR MEM_ISOLATE OR POR_ACTIVE
/CLR_PC = /POR AND NOT(RESET_ACTIVE)
/CLR_MICROSTEP = /POR AND NOT(RESET_ACTIVE)
```

Usare porte logiche: non unire uscite fra loro. Applicare WRITE_BLOCK anche
agli strobe di scrittura di eventuali periferiche e MEM_ISOLATE ai loro
buffer di lettura. Il termine "esistente" comprende la selezione del chip.
La protezione di boot con PC15 OR PC14 OR PC13 deve essere limitata a BOOT;
in RUN il decoder deve usare l'indirizzo sul bus (PC/MAR/IDX).

NEXT_FETCH resta collegato al /LOAD sincrono del microstep, dati paralleli
0000. RESET_ACTIVE agisce su /CLR e non va combinato elettricamente con
l'uscita ROM NEXT_FETCH. Le abilitazioni del 74161 non bloccano /LOAD.

Il reset richiesto dopo BOOT non deve azzerare BOOT_DONE né MODE_RUN: il
supervisore ha un proprio /POR, distinto dal reset locale dei contatori.

All'accensione /POR forza CLOCK_ALLOW=0, MODE_RUN=0, WRITE_BLOCK=1,
MEM_ISOLATE=1, RESET_ACTIVE=1. Con 74HCT74 usare opportunamente /CLR e /PRE,
mai attivarli insieme; gli ingressi asincroni inutilizzati restano inattivi.
Un reset globale durante RUN è un'interruzione distruttiva dell'esecuzione,
può troncare un impulso o una scrittura; la successiva copia ripristina gli
8 KiB del programma. Non promette di conservare RAM dati fuori da quell'area.

## START

Pulsante → antirimbalzo → due flip-flop di sincronizzazione su CK_MASTER.
Una rete RC con Schmitt può realizzare l'antirimbalzo; valori e soglie vanno
dimensionati sulla famiglia effettiva e verificati, non basta il solo Schmitt.
Il supervisore legge soltanto il secondo stadio sincronizzato.

Un bit START_ARMED parte da zero e viene azzerato fuori da READY. In READY
diventa uno soltanto dopo aver osservato START rilasciato. Con START_ARMED=1,
una pressione passa ad ARM; una pressione mantenuta dall'accensione non può
quindi avviare il programma. START non pilota mai direttamente un clock.

## Realizzazione con 74xx

Una realizzazione tutta a integrati DIP può partire da questa assegnazione.
La quantità di porte di combinazione è ancora da chiudere in schema prima
di acquistare le confezioni definitive.

| Funzione | Componenti candidati | Note |
| --- | --- | --- |
| Stato, controlli e START | **2 × CD74HCT174** | 12 flip-flop totali, clock comune e clear asincrono. |
| Rilascio sincronizzato di /POR | **1 × 74HCT74** | Due stadi; /POR azzera direttamente anche le uscite di sicurezza. |
| PC=0x2000 | **2 × CD74HCT688** | Confrontano PC[7:0] con 00 e PC[15:8] con 20; le uscite di uguaglianza sono attive basse. |
| Decodifica 8 stati | **1 × 74HCT138** | Ingresso dai tre bit di stato; uscite attive basse. |
| Clock e pulsante | **1 × 74HCT14**, pulsante START, RC di antirimbalzo | Un inverter genera il clock dei flip-flop del supervisore dal master; gli altri ingressi condizionano il pulsante. |
| Porte di controllo | 74HCT08, 74HCT32 e 74HCT00/74HCT04 secondo sintesi | AND del clock CPU, isolamento /OE e /WE, combinazioni del prossimo stato. |
| Indicazione | LED READY con resistenza | Pilotare secondo la corrente disponibile sull'uscita scelta. |

Distribuzione esatta dei 12 flip-flop dei due HCT174:

```text
3  stato binario: RESET=000, BOOT_PREP=001, COPY=010,
   ISOLATE=011, MODE_RESET=100, READY=101, ARM=110, RUN=111
5  CLOCK_ALLOW, MODE_RUN, WRITE_PERMIT, MEM_PERMIT, RESET_RELEASE
2  START_SYNC_1, START_SYNC_2
1  START_ARMED
1  BOOT_DONE
--
12 flip-flop
```

Le quattro uscite di permesso/abilitazione e RESET_RELEASE partono tutte a
zero grazie al clear dei 174. Le equazioni fisiche diventano:

```text
CK_CPU = CK_MASTER AND CLOCK_ALLOW
/WE_RAM = /WE_RAM_esistente OR NOT(WRITE_PERMIT) OR NOT(POR_OK)
/OE_RAM = /OE_RAM_esistente OR NOT(MEM_PERMIT) OR NOT(POR_OK)
/OE_EPROM = /OE_EPROM_esistente OR NOT(MEM_PERMIT) OR NOT(POR_OK)
/CLR_PC = POR_OK AND RESET_RELEASE
/CLR_MICROSTEP = POR_OK AND RESET_RELEASE
```

`POR_OK` è prodotto dai due flip-flop del 74HCT74: /POR basso li azzera,
poi un 1 attraversa i due stadi sul clock invertito. Solo dopo POR_OK=1
si libera il clear dei due HCT174. Le porte sopra mantengono memoria e
contatori in stato sicuro durante questa attesa. Il reset di /POR del
supervisore resta separato dal RESET_RELEASE dei contatori CPU.

Le uscite registrate sono il decoder Moore del **prossimo** stato. Esempio:
`D_CLOCK_ALLOW = 1` se il prossimo stato è COPY o RUN; `D_MODE_RUN = 1`
se il prossimo stato è MODE_RESET, READY, ARM o RUN. I restanti tre D si
ottengono dalla tabella delle uscite. Il 74HCT138 decodifica lo stato
corrente per scegliere lo stato seguente, secondo la tabella sopra. Il
combinatore deve rispettare il setup del 174 al fronte di discesa del master.

Per la prima prova su breadboard conviene montare e misurare tre blocchi in
ordine: i due comparatori del PC, poi stato/LED, poi le uscite di permesso.
Collegare il clock CPU e /WE fisico solo dopo aver osservato la sequenza
RESET → BOOT_PREP → COPY → ISOLATE → MODE_RESET → READY e la permanenza
in READY senza START. Usare sonde direttamente sui pin RAM.

Questa è una scelta concreta di famiglie e conteggi dei flip-flop, ma non
ancora una netlist pin-per-pin. Prima di montare occorre completare le porte
del prossimo stato, verificare fan-out/ritardi e il decoder RAM/EPROM esistente.
Nessuna modifica alle immagini CU è necessaria per questa proposta.

## Verifica

Il modello `tools/cu-bytecode/tests/test_boot_supervisor.py` verifica:
8192 copie ordinate, arresto dopo l'ultimo byte, preparazione PC/T1, attesa
READY, pulsante già premuto, nuovo START, ritorno a boot dopo reset.
Non modella metastabilità, rimbalzi analogici, ritardi o transitori EEPROM.

Prima del collegamento verificare all'oscilloscopio CK_MASTER/CK_CPU,
WRITE_BLOCK, /WE fisico e MODE_RUN. MODE_RUN deve cambiare solo dopo
l'isolamento e senza clock CPU; il primo clock RUN deve avvenire dopo
azzeramento, rilascio reset e preparazione della lettura. Verificare anche
l'isolamento dei buffer durante il cambio modo.

Questo supervisore risolve l'ordine del passaggio BOOT/RUN. Non sostituisce
la correzione dei clock locali pilotati da EEPROM grezze discussa nell'audit.
Se vengono aggiunti i registri di controllo, occorre prevederne il caricamento
durante BOOT_PREP/ARM usando un clock disponibile anche con CK_CPU fermo.

Riferimenti dei produttori:

- [TI 74HCT74](https://www.ti.com/lit/ds/symlink/sn74hct74.pdf): flip-flop
  con preset/clear asincroni e ingressi TTL; rispettare setup/hold e reset.
- [TI CD74HCT174](https://www.ti.com/product/CD74HCT174): sei flip-flop con
  clear comune e ingressi compatibili TTL.
- [TI CD74HCT688](https://www.ti.com/product/CD74HCT688): comparatore a
  otto bit, disponibile anche DIP.
- [TI 74HCT138](https://www.ti.com/lit/ds/symlink/sn74hct138.pdf): decoder
  da tre a otto, uscite attive basse.
- [TI 74HCT14](https://www.ti.com/lit/ds/symlink/sn74hct14.pdf): inverter Schmitt.
- [TI 74LS161A](https://www.ti.com/lit/ds/symlink/sn74ls161a.pdf): contatori CPU.
