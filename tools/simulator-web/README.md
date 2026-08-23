# Simulatore web della CPU 8-bit

Applicazione statica, senza installazione o fase di build, per eseguire
programmi assembly della ISA v0.1 istruzione per istruzione.

## Avvio

Apri `index.html` nel browser oppure servi la cartella con un piccolo server
HTTP:

```sh
cd tools/simulator-web
python3 -m http.server 8080
```

Poi visita `http://localhost:8080`.

## Cosa simula

- assembler nel browser: label, `.equ`, `.code`, `.data`, `.byte`;
- istruzioni documentate nell'ISA v0.1;
- registri `R0`–`R7`, `RA`, `RB`, `PC`, `MAR`, `MDR`, `IR` e flag;
- esecuzione a istruzioni (`Step`) o continua;
- avanzamento didattico nei microcicli `T1`–`T7`, con fetch, decode ed execute
  evidenziati su uno schema interattivo dei blocchi della CPU;
- RAM da 64 KiB, memoria video da `0x4000` a `0x7FFF` e semplice anteprima
  testuale;
- una porta di input e una di output per `IN` e `OUT`.

Il simulatore esegue lo stato architetturale al termine di ogni istruzione. La
vista `T1`–`T7` è invece un modello didattico di microcodice, utile per
progettare la Control Unit: i segnali e il numero preciso di clock per
istruzione devono ancora essere confermati dall’hardware reale. `IX` non è
incluso perché è un’estensione futura dell’ISA, discussa ma non ancora definita
nei documenti del progetto.

## Struttura del codice

Il browser carica `js/app.js`, che coordina moduli piccoli e con responsabilità
separate:

- `isa.js`: opcode, formati e mappa video;
- `assembler.js`: parsing e generazione dei byte macchina;
- `cpu.js`: stato e semantica eseguibile della CPU;
- `microcode.js`: modello didattico delle fasi `T1`–`T7`;
- `view.js`: rendering della UI e anteprima dei valori nei microcicli;
- `diagram.js`: schema del datapath, porte e collegamenti ortogonali;
- `programs.js`: programmi demo;
- `utils.js`: conversioni condivise, come esadecimale e parsing dei numeri.

Lo schema usa AntV X6, distribuita con licenza MIT. Il bundle è incluso in
`vendor/`, quindi il simulatore resta utilizzabile offline e non richiede `npm`,
`package.json` o download all’avvio.

Questa separazione permette di estendere, ad esempio, `IX` modificando prima
`isa.js` e `cpu.js`, e solo poi assembler, microcicli e visualizzazione.
