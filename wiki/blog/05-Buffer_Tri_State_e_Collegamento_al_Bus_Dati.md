# Buffer tri-state e collegamento al bus dati

Nel precedente articolo abbiamo costruito la prima rete logica della nostra ALU: l'operazione AND a 8 bit. Abbiamo visto che le uscite delle porte AND non vengono collegate direttamente al bus dati, ma passano prima attraverso un buffer tri-state.

In questo articolo approfondiamo proprio questo componente.

Il buffer tri-state è uno degli elementi più importanti del progetto, perché ci permette di collegare più circuiti allo stesso bus dati senza creare conflitti elettrici. Senza questo meccanismo, l'ALU non potrebbe avere più reti operative collegate contemporaneamente al bus.

## Il problema del bus condiviso

Il bus dati è condiviso da diversi moduli della CPU.

Nel caso dell'ALU, avremo molte reti capaci di produrre un risultato a 8 bit:

- rete AND
- rete OR
- rete XOR
- rete NOR
- rete NAND
- rete XNOR
- rete NOT
- circuito di somma
- circuito di sottrazione
- operazione di confronto

Tutte queste reti devono poter inviare il proprio risultato sul bus dati, ma non possono farlo contemporaneamente.

Immaginiamo una singola linea del bus, ad esempio D0. Se la rete AND cerca di portare D0 a 1 e nello stesso momento la rete OR cerca di portare D0 a 0, abbiamo un conflitto. Due uscite stanno cercando di imporre due livelli logici diversi sulla stessa linea.

Questo può causare:

- valori logici imprevedibili
- correnti indesiderate
- surriscaldamento dei componenti
- possibile danneggiamento degli integrati

Per evitare tutto questo, dobbiamo fare in modo che solo una rete alla volta sia collegata elettricamente al bus.

## Uscita normale e uscita tri-state

Una normale uscita digitale può assumere due stati:

- 0, livello logico basso
- 1, livello logico alto

Un'uscita tri-state, invece, può assumere tre stati:

- 0, livello logico basso
- 1, livello logico alto
- Z, alta impedenza

Il terzo stato, indicato spesso con la lettera `Z`, è la caratteristica fondamentale dei buffer tri-state.

Quando un'uscita è in alta impedenza, si comporta come se fosse scollegata dal circuito. Non forza la linea né a 0 né a 1. In pratica lascia che sia un altro circuito a pilotare il bus.

Questo stato è ciò che ci permette di collegare più uscite allo stesso bus, purché una sola alla volta sia effettivamente abilitata.

## Cos'è un buffer

Un buffer è un circuito che prende un segnale in ingresso e lo ripropone in uscita.

Nel caso più semplice:

```text
Ingresso = 0 -> Uscita = 0
Ingresso = 1 -> Uscita = 1
```

A prima vista può sembrare inutile, perché l'uscita è uguale all'ingresso. In realtà un buffer serve a separare elettricamente due parti del circuito, aumentare la capacità di pilotaggio o, nel caso dei buffer tri-state, controllare se un segnale deve essere collegato o isolato.

Nel nostro progetto useremo i buffer soprattutto per questo ultimo motivo: decidere quando una rete logica può scrivere sul bus dati.

## Il segnale di enable

Un buffer tri-state ha almeno tre elementi fondamentali:

- ingresso dati
- uscita dati
- segnale di enable

Il segnale di enable decide se il buffer deve trasferire il valore dall'ingresso all'uscita oppure se deve mettere l'uscita in alta impedenza.

Nel caso di molti integrati della famiglia 74xx, l'enable è attivo basso. Questo significa che il buffer è abilitato quando l'enable vale 0.

La tabella di funzionamento è quindi:

| Enable | Ingresso | Uscita |
| -----: | -------: | -----: |
|      0 |        0 |      0 |
|      0 |        1 |      1 |
|      1 |        0 |      Z |
|      1 |        1 |      Z |

Quando enable vale 0, l'uscita segue l'ingresso.

Quando enable vale 1, l'uscita va in alta impedenza, indipendentemente dal valore dell'ingresso.

Questa logica attiva bassa è molto importante, perché la ritroveremo anche quando useremo i decoder per selezionare l'operazione dell'ALU.

## Alta impedenza nella pratica

Dire che un'uscita è in alta impedenza significa dire che non sta pilotando attivamente la linea.

Non è un 0.

Non è un 1.

È come se l'uscita fosse scollegata.

Questo concetto è fondamentale perché spesso, quando si inizia con l'elettronica digitale, si pensa che ogni uscita debba per forza essere 0 o 1. Nei bus condivisi, invece, è necessario avere anche uno stato in cui un circuito “si fa da parte”.

Nel nostro caso, quando la rete AND non è selezionata, il suo buffer deve essere in alta impedenza. La rete AND può anche continuare a calcolare internamente il risultato tra A e B, ma quel risultato non deve arrivare al bus.

Lo stesso vale per tutte le altre reti dell'ALU.

## Esempio con due reti logiche

Immaginiamo di avere solo due reti nell'ALU:

- rete AND
- rete OR

Entrambe ricevono gli stessi ingressi A e B. Entrambe calcolano sempre il proprio risultato.

Tuttavia, solo una delle due deve poter scrivere sul bus.

Possiamo rappresentare la situazione così:

```text
        rete AND ---- buffer AND ----\
A, B ->                           bus dati
        rete OR  ---- buffer OR  ----/
```

Se vogliamo eseguire l'AND, abilitiamo il buffer della rete AND e disabilitiamo il buffer della rete OR.

```text
buffer AND: attivo
buffer OR:  alta impedenza
```

Se invece vogliamo eseguire l'OR, facciamo l'opposto:

```text
buffer AND: alta impedenza
buffer OR:  attivo
```

In questo modo il bus riceve sempre un solo valore alla volta.

## Il 74244

Nel progetto useremo buffer tri-state a 8 bit, come il 74244.

Questo integrato contiene otto buffer, quindi è perfetto per collegare una rete a 8 bit al bus dati.

Ogni operazione dell'ALU produrrà infatti un risultato largo 8 bit. Il 74244 permette di abilitare o isolare contemporaneamente tutte le otto linee.

Il collegamento concettuale è:

```text
OUT0 -> buffer -> D0
OUT1 -> buffer -> D1
OUT2 -> buffer -> D2
OUT3 -> buffer -> D3
OUT4 -> buffer -> D4
OUT5 -> buffer -> D5
OUT6 -> buffer -> D6
OUT7 -> buffer -> D7
```

Dove OUT0-OUT7 sono le uscite della rete logica e D0-D7 sono le linee del bus dati.

Il 74244 è spesso diviso internamente in due gruppi da quattro buffer, ciascuno con il proprio segnale di enable. Nel nostro progetto, quando vogliamo controllare tutti gli 8 bit insieme, possiamo collegare in parallelo i due enable, in modo da ottenere un unico segnale di abilitazione per tutta la rete.

## Enable attivo basso

Uno degli aspetti da tenere sempre presente è che l'enable del buffer è attivo basso.

Questo significa che, per abilitare il trasferimento dei dati verso il bus, dobbiamo portare l'enable a massa.

```text
enable = 0 -> rete collegata al bus
enable = 1 -> rete isolata dal bus
```

Questa scelta può sembrare poco intuitiva, ma è molto comune negli integrati digitali.

Per renderla chiara nei nostri schemi, possiamo indicare l'enable con una barra sopra il nome oppure con un piccolo pallino sul simbolo logico. Entrambi i simboli indicano che il segnale è attivo quando vale 0.

Ad esempio:

```text
/ENABLE
```

oppure:

```text
ENABLE attivo basso
```

Quando più avanti useremo il codice operazione dell'ALU, questa caratteristica diventerà molto comoda, perché il decoder che useremo produrrà uscite attive basse.

## Collegamento con la rete AND

Riprendiamo la rete AND costruita nell'articolo precedente.

La struttura era:

```text
A, B -> 7408 -> risultato AND -> 74244 -> bus dati
```

Le porte AND calcolano continuamente il risultato. Se cambiamo A o B, anche l'uscita delle porte AND cambia.

Tuttavia, questo risultato raggiunge il bus solo quando il 74244 è abilitato.

Quindi abbiamo due livelli di funzionamento:

1. calcolo interno della rete AND
2. trasferimento del risultato sul bus tramite buffer

Questa distinzione è importante.

Una rete può essere attiva internamente, ma non collegata al bus. In una CPU reale succede spesso: molti circuiti producono segnali, ma solo quelli selezionati vengono effettivamente usati in un determinato momento.

## Test pratico del buffer

Per testare il buffer possiamo usare la rete AND.

Impostiamo gli ingressi in modo che il risultato dell'AND sia sicuramente diverso da zero. Ad esempio:

```text
A = 11111111
B = 11111111
```

Il risultato interno della rete AND sarà:

```text
AND = 11111111
```

Ora portiamo l'enable del 74244 a 0.

Il bus dati dovrebbe mostrare tutti i LED accesi:

```text
D = 11111111
```

Poi portiamo l'enable a 1.

La rete AND viene isolata dal bus. I LED del bus non sono più pilotati da quella rete.

Questo test dimostra che il buffer non serve a calcolare il risultato, ma a decidere se quel risultato può raggiungere il bus.

## Cosa succede se due buffer sono attivi

Una situazione da evitare assolutamente è abilitare contemporaneamente due buffer collegati allo stesso bus.

Supponiamo che la rete AND stia producendo:

```text
AND = 00000000
```

mentre la rete OR stia producendo:

```text
OR = 11111111
```

Se abilitiamo entrambi i buffer, la rete AND proverà a portare tutte le linee a 0, mentre la rete OR proverà a portarle tutte a 1.

Questo crea un conflitto sul bus.

Per questo motivo, quando costruiremo il sistema di selezione dell'operazione, dovremo garantire che venga abilitata una sola rete alla volta.

Il codice operazione dell'ALU avrà proprio questo compito: scegliere quale risultato deve essere collegato al bus.

## Bus spento o bus non pilotato

Quando tutti i buffer sono disabilitati, nessuna rete sta pilotando il bus.

In questa condizione il bus potrebbe non avere un valore definito, a meno che non siano presenti resistenze di pull-up, pull-down o altri circuiti che stabiliscono uno stato di default.

È importante distinguere tra:

```text
bus = 00000000
```

e:

```text
bus non pilotato
```

Nel primo caso qualcuno sta effettivamente portando tutte le linee a 0.

Nel secondo caso nessun circuito sta imponendo un valore. Le linee potrebbero apparire a 0, a 1 o assumere stati instabili a seconda del circuito.

Durante i test bisogna quindi fare attenzione a non interpretare automaticamente un LED spento come un valore logico 0 valido. Potrebbe semplicemente significare che nessun modulo sta pilotando quella linea.

Nel nostro progetto, quando vorremo osservare un risultato, ci assicureremo sempre che il buffer corretto sia abilitato.

## Buffer e codice operazione

Per ora abilitiamo manualmente il buffer della rete che vogliamo testare.

Ad esempio, per testare l'AND portiamo manualmente a massa il suo enable.

Più avanti, però, non lo faremo più manualmente. Useremo un codice operazione, cioè un insieme di bit che indicherà all'ALU quale operazione eseguire.

Questo codice verrà decodificato da un circuito apposito, che attiverà il buffer corretto.

Ad esempio:

```text
opcode 0000 -> abilita AND
opcode 0001 -> abilita OR
opcode 0010 -> abilita XOR
opcode 0011 -> abilita NOR
```

In questo modo, cambiando il codice operazione, cambierà automaticamente la rete autorizzata a scrivere sul bus.

Il buffer tri-state è quindi il punto di collegamento tra il risultato delle reti logiche e il sistema di controllo dell'ALU.

## Perché il buffer è più di un dettaglio

All'inizio può sembrare che il buffer sia solo un componente aggiunto tra la porta logica e il bus.

In realtà è uno degli elementi che rendono possibile l'architettura della CPU.

Senza buffer tri-state dovremmo costruire circuiti molto più complessi per selezionare i risultati, oppure dovremmo evitare di condividere il bus tra più moduli.

Grazie ai buffer, invece, possiamo progettare la CPU in modo modulare:

- ogni rete calcola il proprio risultato
- ogni rete ha il proprio buffer
- il bus è condiviso
- il controllo decide quale buffer abilitare

Questa struttura verrà usata più volte, non solo nell'ALU ma anche quando inizieremo a ragionare sui registri e sul trasferimento dei dati.

## Errori comuni

Quando si lavora con buffer tri-state ci sono alcuni errori frequenti.

Il primo errore è dimenticare che l'enable è attivo basso. Se pensiamo che 1 significhi “abilitato”, potremmo lasciare il buffer spento senza capirne il motivo.

Il secondo errore è lasciare l'enable flottante. Anche l'enable è un ingresso digitale e deve sempre essere collegato a un valore stabile: 0 o 1.

Il terzo errore è abilitare due buffer contemporaneamente sullo stesso bus.

Il quarto errore è confondere alta impedenza con 0. Un'uscita in alta impedenza non sta scrivendo uno 0: non sta scrivendo nulla.

Il quinto errore è invertire ingressi e uscite del buffer. Prima di cablare il componente è sempre necessario controllare il datasheet e verificare la piedinatura.

## Conclusione

In questo articolo abbiamo approfondito il ruolo dei buffer tri-state nel collegamento delle reti logiche al bus dati.

Abbiamo visto che un'uscita tri-state può assumere tre stati: 0, 1 e alta impedenza. Proprio l'alta impedenza permette di collegare più circuiti allo stesso bus senza che tutti lo pilotino contemporaneamente.

Abbiamo anche visto che il segnale di enable, spesso attivo basso, decide quando il risultato di una rete può raggiungere il bus dati.

Questo concetto sarà fondamentale per tutta l'ALU. Ogni operazione avrà la propria rete logica e il proprio buffer. Il codice operazione selezionerà quale buffer abilitare, permettendo a una sola rete alla volta di scrivere sul bus.

Nel prossimo articolo aggiungeremo una nuova operazione alla nostra ALU: l'OR.

La struttura sarà molto simile a quella dell'AND: cambierà la porta logica, ma resterà lo stesso schema generale con ingressi A e B, rete logica, buffer tri-state e uscita sul bus dati.
