# CU: avvio intermittente e sospetta corruzione RAM

Data: 12 novembre 2026. Analizzati il microcodice corrente e i tre binari CU
rigenerati in una cartella temporanea. Non e stata modificata o programmata
alcuna Control ROM. La verifica non legge i chip fisicamente montati.

## Esito e ordine degli interventi

1. **Protezione reset assente nel cablaggio, confermata dall'utente.** Il reset
   azzera solo PC e microstep. La CU non riceve il reset e non puo garantire
   da sola che il /WE fisico della RAM resti alto durante il reset.
2. **STA e STAI non conservano indirizzo e dato in una fase successiva alla
   disattivazione di /WR.** E un rischio strutturale dimostrabile nel codice;
   l'effettiva finestra di scrittura dipende dai ritardi del circuito.
3. **HLT stabile non richiede scritture.** Un bus dati libero in HLT produce
   letture non significative ma non cambia da solo le celle RAM. Un byte
   diverso letto sul bus dopo reset non dimostra ancora la corruzione se
   indirizzo effettivo, /CE, /OE e isolamento dei traduttori non sono verificati.
4. Gli enable provenienti direttamente dalle EEPROM possono disturbare clock
   locali e /WE durante le transizioni di indirizzo CU. Un clock manuale lento
   non elimina i fronti o impulsi brevi dentro una transizione.

## Verifiche riproducibili

```sh
make -C tools/cu-bytecode test
make -C tools/cu-bytecode all
mkdir -p tmp/cu-memory-audit-20261112
tools/cu-bytecode/build/cpu8microcode -o tmp/cu-memory-audit-20261112/microcode
python3 tools/cu-bytecode/audit_memory_safety.py \
  --prefix tmp/cu-memory-audit-20261112/microcode \
  --report tmp/cu-memory-audit-20261112/audit.json
```

- Test C: PASS.
- Audit indipendente: 8192 parole fisiche verificate.
- BOOT: 512 parole richiedono /WR basso, tutte e sole le righe T1.
- RUN: 32 parole richiedono /WR basso, tutte e sole STA/T5 e STAI/T3.
- HLT: nessuna scrittura nei suoi otto step, per tutte le 16 pagine flag.
- Fetch RUN: stessa parola di sola lettura per tutti i gruppi opcode e flag.
- Le tre immagini rigenerate coincidono con quelle presenti in build.

La numerazione T e logica; il cablaggio dei tre bit microstep verso A0-A2
EEPROM e invertito. T1..T8 corrispondono agli offset 0,4,2,6,1,5,3,7.
Il banco CU e BOOT con A12=0, RUN con A12=1. L'ingresso della Tang ha
invece la polarita richiesta dall'utente: 1=BOOT, 0=RUN.

## 1. BOOT e reset

In `tools/cu-bytecode/src/microcode.c:179`:

| Fase BOOT | Indirizzo | Dato sul bus | /WR | PC_INC | /NEXT_FETCH |
| --- | --- | --- | --- | --- | --- |
| T1 | PC | EPROM | 0 | 0 | 1 |
| T2 | PC | EPROM | 1 | 1 | 1 |
| T3 | PC | EPROM | 1 | 0 | 0 |

Le tre parole fisiche ROM0/1/2, a flag zero, sono rispettivamente
`91 02 49`, `B5 02 49`, `31 02 49`.

Questa sequenza conserva i bus in T2 e T3: non c'e una scrittura logica
nel medesimo passo in cui PC viene incrementato. Non emerge un errore
nominale per cui BOOT debba sempre copiare byte sbagliati.

Resta pero fondamentale che T1 abilita la scrittura **come livello**, anche
con clock fermo. Se durante BOOT/reset gli indirizzi PC cambiano mentre
la RAM ha /WE basso e chip enable attivo, possono esserci scritture non
volute. La CU non ha un ingresso RESET fra i suoi 13 indirizzi: azzerare
PC e microstep non equivale a disabilitare il /WE fisico della memoria.

Durante un reset in RUN non e prevista alcuna scrittura nelle parole stabili
HLT/T2 e fetch/T1. L'assenza della protezione lascia pero passare un eventuale
transitorio o una selezione involontaria del banco BOOT. Non e dimostrato
che tale transitorio si sia effettivamente verificato sul circuito.

### Inibizione necessaria sul circuito

Con /RESET_CPU attivo basso, /WR_CU attivo basso e mantenendo gli altri
interblocchi gia presenti, la funzione richiesta e:

```text
RESET_ACTIVE = NOT(/RESET_CPU)
/WE_RAM_fisico = /WR_CU OR RESET_ACTIVE OR altri_blocchi_attivi
```

Durante reset il /WE RAM deve restare alto indipendentemente dalla ROM.
E una funzione da realizzare con logica appropriata, non collegando insieme
uscite push-pull. L'inibizione deve essere efficace prima delle variazioni
di indirizzo e rimanere fino all'assestamento; servono pin e polarita dei
componenti reali per definire il cablaggio e i ritardi. Vanno considerate
anche /CE e gli enable locali dei registri. La stessa condizione di reset
va rispettata nelle richieste alle periferiche.

Questo requisito era gia indicato in `docs/control-unit-eeprom-wiring.md`,
ma la conferma dell'utente dice che non e implementato nel circuito attuale.

## 2. Fine scrittura STA/STAI: possibile ritorno da I/O a RAM

In `src/microcode.c:263` e `:327`:

| Istruzione | Fase | Indirizzo | Dato | /WR |
| --- | --- | --- | --- | --- |
| STA | T5 | MAR | MDR | 0 |
| STA | T6 | Nessuna sorgente | Nessuna sorgente | 1 |
| STAI | T3 | IDX | MDR | 0 |
| STAI | T4 | Nessuna sorgente | Nessuna sorgente | 1 |

Il medesimo cambio di parola disattiva la scrittura e rilascia i bus.
Non e garantito quale azione arrivi prima ai pin della memoria.

Esempio coerente con il test della H, **ipotesi da verificare**:

1. Durante STA a 2000, /WR=0 ma la RAM e esclusa da /CE: scrive la Tang.
2. In uscita da STA, il MAR puo smettere di pilotare il bus prima che /WR
   fisico torni alto.
3. Se il bus non pilotato presenta temporaneamente A15=A14=A13=0, la OR
   esterna seleziona la RAM mentre /WR e ancora basso.
4. Si crea una possibile finestra di scrittura nella RAM. Il dato e l'indirizzo
   possono essere non validi; non e garantito che la cella colpita sia 0000.

Questo spiega perche un programma che intende scrivere solo sul video non
esclude, da solo, un danno involontario alla RAM nella transizione elettrica.
Non prova che sia gia successo. Il risultato dipende dai ritardi, dalla
sigla SRAM e dal circuito concreto di /CE e /WE.

L'audit enumera sei ordinamenti delle tre disattivazioni: quattro ammettono
una finestra con /WR ancora basso e almeno un bus gia rilasciato. E solo un
controesempio strutturale, **non una probabilita di guasto o una simulazione
analogica**.

Una sequenza candidata separa le fasi:

| Fase | STA | STAI | Indirizzo e dato |
| --- | --- | --- | --- |
| Prepara | T5 | T3 | MAR/IDX e MDR validi, /WR=1 |
| Scrivi | T6 | T4 | Stessi bus, /WR=0 |
| Mantieni | T7 | T5 | Stessi bus, /WR=1 |
| Ritorna | T8 | T6 | Bus rilasciati, /NEXT_FETCH=0 |

Rientra negli otto microstep, ma non elimina i transitori delle uscite ROM:
serve anche una finestra di scrittura/registrazione dei controlli con tempi
validati. Non e stata applicata: cambierebbe tempi e numerazione dei PDF
attualmente usati sul banco.

## 3. HLT

Con IR=00, RUN e T2, la parola fisica e `F3 02 09`:

- /WR=1, /RD=1, /EPROM_OE=1, /MDR_OE=1;
- nessuna sorgente del bus indirizzi e nessuna sorgente dati attiva;
- PC_INC=0, /PC_LOAD=1;
- SYS_STEP_n=0; la logica esterna deve bloccare il contatore microstep.

Il bus puo fluttuare in questo stato. La cella RAM non deve cambiare per
questo motivo. Se la CPU non resta in T2, va verificata la logica esterna
`microstep_enable = SYS_STEP_n OR IR2 OR IR1 OR IR0`.

Una modifica osservata soltanto dopo HLT puo essere avvenuta all'ultima
scrittura, al passaggio BOOT/RUN, durante reset o puo essere un errore di
lettura. Serve individuare il primo momento in cui il byte cambia.

## Prima prova sul banco

Con il test attuale `video_one_char.asm`, i primi sei byte RAM devono essere
`20 48 48 00 20 00`, quindi RAM[0000] deve essere **20**, non 40 come nel
precedente Hello World completo.

1. Verificare 0000 in un fetch valido prima di eseguire la STA; non confondere
   le Q del PC con l'indirizzo effettivo del bus.
2. In HLT, controllare prima lo stato dei controlli: /WR deve essere alto,
   /RD alto e microstep T2. Una lettura del bus in HLT non verifica la cella 0000.
3. Per osservare la RAM in HLT occorre un accesso di lettura valido con
   indirizzo pilotato e una sola sorgente dati, senza introdurre un reset
   che potrebbe esso stesso alterarla. Non forzare i pin contro altre uscite.
4. Verificare il /WE **fisico della RAM**, non solo ROM0 D5, mentre reset
   e attivo. Il livello alto stabile non esclude impulsi brevi: un tester
   non puo dimostrare l'assenza di transitori.
5. Collegare l'inibizione di reset prima di rifare prove di riavvio; poi
   confrontare prima/dopo STA e prima/dopo reset.

Per stabilire piedinatura, logica e tempi della soluzione serve la sigla della
RAM montata e lo schema effettivo di reset, /CE e /WE.

## Riferimenti tecnici

- [Microchip AT28C64B, lettura asincrona e tempi di accesso](https://ww1.microchip.com/downloads/en/DeviceDoc/doc0270.pdf).
- [Alliance AS6C6264, write cycle e condizioni /CE-/WE](https://www.alliancememory.com/wp-content/uploads/Alliance-Memory_64K_AS6C6264v2.0July2017.pdf).

La AS6C6264 e solo un riferimento della classe SRAM: la RAM fisica dell'utente
non e ancora identificata e i suoi valori numerici non sono assunti qui.

### Prova discriminante possibile con il test della H

`video_one_char.asm` legge istruzioni dalla RAM ma scrive soltanto all'I/O
2000. Per questa sola prova, dopo BOOT la RAM puo restare in sola lettura
senza impedire la stampa. Un'inibizione hardware del **solo /WE RAM**
durante RUN permetterebbe di distinguere scritture accidentali da errori di
lettura; la richiesta /WR verso la Tang deve continuare a funzionare.

E una configurazione diagnostica da definire sul circuito, non una modifica
permanente della CPU: in futuro le normali STA in RAM devono funzionare.
Non forzare un livello alto contro l'uscita di una porta/EEPROM. Serve una
porta di qualificazione o un isolamento esplicito e la piedinatura reale
della memoria prima di indicare collegamenti fisici.
