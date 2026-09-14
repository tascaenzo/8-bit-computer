# Simulatore web della CPU 8-bit

Applicazione statica, senza installazione o fase di build, per eseguire
programmi assembly della ISA v0.1 istruzione per istruzione.

## Avvio

Apri `index.html` nel browser oppure servi la cartella con un piccolo server
HTTP:

```sh
cd tools/simulator-web
python3 -m http.server 8081
```

Poi visita `http://localhost:8081`.

## Verifica automatica

La suite controlla assembler, semantica delle istruzioni, flag, salti,
allineamento tra stato interno e microsegnali, assenza di contese sui bus e
corrispondenza tra percorsi del microcodice e collegamenti del datapath:

```sh
cd tools/simulator-web
npm test
```

## Cosa simula

- assembler nel browser: label, `.equ`, `.code`, `.data`, `.byte`;
- istruzioni documentate nell'ISA v0.1;
- registri `R0`–`R7`, `RA`, `RB`, `PC`, `MAR`, `IDX`, `MDR`, `IR` e flag;
- selettore a 2 bit del bus indirizzi: `00=IDX`, `01=PC`, `10=MAR`,
  `11=nessuna sorgente`;
- esecuzione a istruzioni (`Step`) o continua;
- avanzamento didattico nei microcicli funzionali, con numero di fasi variabile
  per istruzione e segnali allineati alla specifica della Control Unit;
- RAM da 64 KiB, memoria video da `0x4000` a `0x7FFF` e semplice anteprima
  testuale;
- una porta di input e una di output per `IN` e `OUT`.

Il simulatore esegue lo stato architetturale al termine di ogni istruzione. La
vista microcodice mostra invece le fasi funzionali definite in
[`docs/control-unit-microcode.md`](../../docs/control-unit-microcode.md):
`ADDR_SEL_1:0`, `MEM_RD`, `MEM_WR`, `MDR_WE`, `RF_WR`, `ALU_OE`, `FLAGS_WE`
e segnali di sequencer. Il numero preciso di clock e il wiring TTL restano da
verificare sulla board reale. `IDX` è presente nello stato e nel datapath, ma
rimane a zero perché le relative istruzioni non hanno ancora una codifica
definitiva nella ISA. La vista usa il banco RUN (`BOOT_RUN=1`); il
microprogramma di boot non è ancora definito.

## Struttura del codice

Il browser carica `js/app.js`, che coordina moduli piccoli e con responsabilità
separate:

- `isa.js`: opcode, formati e mappa video;
- `assembler.js`: parsing e generazione dei byte macchina;
- `cpu.js`: stato e semantica eseguibile della CPU;
- `microcode.js`: microsequenze funzionali e segnali della Control Unit;
- `view.js`: rendering della UI e anteprima dei valori nei microcicli;
- `diagram.js`: schema del datapath, porte e collegamenti ortogonali;
- `programs.js`: programmi demo;
- `utils.js`: conversioni condivise, come esadecimale e parsing dei numeri.

Lo schema usa AntV X6, distribuita con licenza MIT. Il bundle è incluso in
`vendor/`, quindi il simulatore resta utilizzabile offline e non richiede `npm`,
download o una fase di build all’avvio. Node.js serve soltanto per eseguire la
suite opzionale con `npm test`.

Questa separazione permette di estendere, ad esempio, `IDX` modificando prima
`isa.js` e `cpu.js`, e solo poi assembler, microcicli e visualizzazione.
