# Codice operazione dell'ALU

Negli articoli precedenti abbiamo costruito molte parti della nostra ALU a 8 bit. Abbiamo implementato operazioni logiche come AND, OR, XOR, NOR, NAND, XNOR e NOT. Abbiamo poi aggiunto il circuito di somma e sottrazione, i flag e le operazioni di confronto.

Finora, però, abbiamo considerato le varie reti come circuiti separati, da abilitare manualmente tramite i rispettivi segnali di enable.

Ora dobbiamo fare un passo in avanti: vogliamo selezionare automaticamente quale operazione deve essere eseguita dall'ALU usando un codice operazione.

Il codice operazione, spesso abbreviato in opcode, è un insieme di bit che indica all'ALU quale funzione deve essere attiva in un determinato momento.

## Perché serve un codice operazione

La nostra ALU contiene diverse reti operative.

Ad esempio:

```text
AND
OR
XOR
NOR
NAND
XNOR
NOT
ADD
SUB
COMPARE
```

Tutte queste reti possono ricevere gli stessi ingressi A e B. Molte di esse calcolano continuamente un risultato interno.

Il problema è decidere quale risultato deve essere portato sul bus dati.

Non possiamo abilitare più reti contemporaneamente, perché tutte condividono lo stesso bus dati. Se due buffer tri-state fossero attivi nello stesso momento, due circuiti potrebbero tentare di pilotare la stessa linea del bus con valori diversi.

Abbiamo quindi bisogno di un sistema di selezione.

Il codice operazione risolve questo problema: associamo a ogni combinazione di bit una specifica operazione dell'ALU.

Ad esempio:

```text
0000 -> AND
0001 -> OR
0010 -> XOR
0011 -> NOR
```

Quando l'opcode vale `0000`, abilitiamo solo la rete AND.

Quando vale `0001`, abilitiamo solo la rete OR.

E così via.

## Opcode a 4 bit

Nel nostro progetto useremo un codice operazione a 4 bit.

Lo indicheremo così:

```text
OP3 OP2 OP1 OP0
```

Con 4 bit possiamo rappresentare:

```text
2^4 = 16
```

combinazioni diverse.

Questo significa che possiamo selezionare fino a 16 operazioni.

Nel progetto attuale non useremo necessariamente tutte le 16 combinazioni, ma avere spazio libero è utile. Ci permette di aggiungere operazioni in futuro oppure di lasciare alcuni codici non utilizzati.

Una possibile tabella delle operazioni è:

| Opcode | Operazione |
| ------ | ---------- |
| 0000   | AND        |
| 0001   | OR         |
| 0010   | XOR        |
| 0011   | NOR        |
| 0100   | NAND       |
| 0101   | XNOR       |
| 0110   | NOT        |
| 0111   | ADD        |
| 1000   | SUB        |
| 1001   | COMPARE    |
| 1010   | non usato  |
| 1011   | non usato  |
| 1100   | non usato  |
| 1101   | non usato  |
| 1110   | non usato  |
| 1111   | non usato  |

Questa tabella non è l'unica possibile, ma è coerente con la struttura costruita finora.

## Dall'opcode agli enable

Ogni rete dell'ALU ha un buffer tri-state verso il bus dati.

Ogni buffer ha un segnale di enable.

Quindi, per selezionare un'operazione, dobbiamo trasformare l'opcode in una serie di segnali di enable.

Ad esempio:

```text
opcode = 0000 -> enable AND attivo
opcode = 0001 -> enable OR attivo
opcode = 0010 -> enable XOR attivo
```

Tutti gli altri enable devono restare disattivati.

Questa trasformazione prende il nome di decodifica.

Un decoder prende in ingresso un numero binario e attiva una sola uscita corrispondente a quel numero.

Nel nostro caso useremo il decoder 74138.

## Il componente 74138

Il 74138 è un decoder/demultiplexer 3-to-8.

Questo significa che prende in ingresso 3 bit di selezione e può attivare una tra 8 uscite.

Gli ingressi di selezione sono:

```text
A0
A1
A2
```

Le uscite sono:

```text
Y0
Y1
Y2
Y3
Y4
Y5
Y6
Y7
```

Con 3 bit abbiamo 8 combinazioni:

```text
000 -> Y0
001 -> Y1
010 -> Y2
011 -> Y3
100 -> Y4
101 -> Y5
110 -> Y6
111 -> Y7
```

Una caratteristica importante del 74138 è che le sue uscite sono attive basse.

Questo significa che l'uscita selezionata va a 0, mentre tutte le altre restano a 1.

Questa caratteristica è molto utile nel nostro progetto, perché anche gli enable dei buffer tri-state sono attivi bassi.

Quindi possiamo collegare direttamente un'uscita del 74138 all'enable di un buffer.

## Uscite attive basse

Vediamo un esempio.

Supponiamo che gli ingressi del 74138 siano:

```text
A2 A1 A0 = 000
```

L'uscita selezionata sarà Y0.

Dato che le uscite sono attive basse, avremo:

```text
Y0 = 0
Y1 = 1
Y2 = 1
Y3 = 1
Y4 = 1
Y5 = 1
Y6 = 1
Y7 = 1
```

Se colleghiamo Y0 all'enable del buffer AND, la rete AND sarà abilitata.

Tutte le altre reti resteranno disabilitate.

Questo si adatta perfettamente al funzionamento dei buffer:

```text
enable = 0 -> buffer attivo
enable = 1 -> buffer in alta impedenza
```

## Perché servono due 74138

Un singolo 74138 usa 3 bit di selezione e genera 8 uscite.

La nostra ALU, però, usa un opcode a 4 bit e può quindi avere fino a 16 operazioni.

Per questo motivo useremo due 74138.

L'idea è questa:

- i primi 3 bit dell'opcode selezionano una delle 8 uscite
- il quarto bit decide quale dei due 74138 deve essere abilitato

Quindi:

```text
OP0, OP1, OP2 -> ingressi di selezione di entrambi i 74138
OP3 -> selezione del decoder basso o alto
```

Quando OP3 vale 0, abilitiamo il primo 74138.

Quando OP3 vale 1, abilitiamo il secondo 74138.

In questo modo otteniamo 16 uscite totali:

```text
decoder 0 -> operazioni 0000 ... 0111
decoder 1 -> operazioni 1000 ... 1111
```

## Abilitazione dei due decoder

Il 74138 ha anche ingressi di enable.

Questi ingressi permettono di accendere o spegnere l'intero decoder.

Nel nostro progetto possiamo collegare gli enable in modo che solo uno dei due 74138 sia attivo alla volta.

Il bit OP3, cioè il bit più significativo dell'opcode, decide quale decoder usare.

Schema concettuale:

```text
OP3 = 0 -> decoder 0 attivo, decoder 1 spento
OP3 = 1 -> decoder 0 spento, decoder 1 attivo
```

Per ottenere questo comportamento serve anche una negazione di OP3.

Infatti un decoder dovrà ricevere OP3 direttamente, mentre l'altro dovrà ricevere OP3 negato, in modo che i due siano sempre in stati opposti.

La negazione può essere ottenuta con una porta NOT. In alcuni casi, se abbiamo porte XOR libere, possiamo usare una XOR come NOT collegando uno degli ingressi a 1:

```text
A XOR 1 = NOT A
```

Questo trucco può essere utile per risparmiare integrati o semplificare il cablaggio.

## Mappatura delle operazioni

Una volta ottenute 16 uscite, possiamo assegnare ogni uscita a una rete dell'ALU.

Una possibile mappatura è:

| Opcode | Uscita decoder | Operazione | Segnale generato      |
| ------ | -------------- | ---------- | --------------------- |
| 0000   | Y0 decoder 0   | AND        | enable AND            |
| 0001   | Y1 decoder 0   | OR         | enable OR             |
| 0010   | Y2 decoder 0   | XOR        | enable XOR            |
| 0011   | Y3 decoder 0   | NOR        | enable NOR            |
| 0100   | Y4 decoder 0   | NAND       | enable NAND           |
| 0101   | Y5 decoder 0   | XNOR       | enable XNOR           |
| 0110   | Y6 decoder 0   | NOT        | enable NOT            |
| 0111   | Y7 decoder 0   | ADD        | enable ADD/SUB, K = 0 |
| 1000   | Y0 decoder 1   | SUB        | enable ADD/SUB, K = 1 |
| 1001   | Y1 decoder 1   | COMPARE    | K = 1, flag confronto |

Le uscite rimanenti possono restare inutilizzate o essere assegnate a future operazioni.

## Operazioni logiche semplici

Per le operazioni logiche il collegamento è diretto.

Ad esempio:

```text
Y0 decoder 0 -> enable buffer AND
Y1 decoder 0 -> enable buffer OR
Y2 decoder 0 -> enable buffer XOR
Y3 decoder 0 -> enable buffer NOR
```

Dato che le uscite del 74138 sono attive basse e gli enable dei buffer sono attivi bassi, l'uscita selezionata abilita direttamente il buffer corretto.

Quando l'opcode vale `0000`, Y0 va a 0 e abilita AND.

Quando l'opcode vale `0001`, Y1 va a 0 e abilita OR.

Tutti gli altri buffer restano disabilitati.

Questo è il caso più semplice.

## Gestione di ADD, SUB e COMPARE

Le operazioni ADD, SUB e COMPARE richiedono un ragionamento leggermente diverso.

Infatti tutte e tre usano lo stesso circuito aritmetico basato sui 74283.

La differenza è:

```text
ADD     -> K = 0
SUB     -> K = 1
COMPARE -> K = 1
```

ADD deve abilitare il buffer del sommatore e portare il risultato sul bus.

SUB deve abilitare lo stesso buffer, ma con K = 1, così il circuito esegue A - B.

COMPARE deve usare il circuito come sottrattore, quindi K = 1, ma il risultato potrebbe non dover essere usato come dato principale sul bus. Quello che ci interessa davvero sono i flag e i segnali di confronto.

Quindi dobbiamo generare due tipi di segnali:

- enable del buffer del sommatore
- valore del segnale K

## Enable del modulo aritmetico

Il buffer del modulo somma/sottrazione deve essere abilitato quando l'operazione selezionata è ADD o SUB.

A seconda della scelta progettuale, possiamo decidere se abilitarlo anche durante COMPARE.

Se vogliamo che COMPARE produca solo flag e non scriva sul bus, allora il buffer può restare disabilitato durante COMPARE.

Se invece vogliamo visualizzare comunque il risultato della sottrazione sul bus durante i test, possiamo abilitarlo anche in COMPARE.

Nel progetto didattico può essere comodo vedere il risultato, ma dal punto di vista concettuale la compare usa soprattutto i flag.

Una possibile scelta è:

```text
ADD o SUB -> enable sommatore attivo
COMPARE -> sommatore usato internamente per i flag
```

## Generazione del segnale K

Il segnale K deve valere:

```text
K = 0 per ADD
K = 1 per SUB
K = 1 per COMPARE
```

Questo significa che K deve attivarsi quando viene selezionata SUB oppure COMPARE.

Dato che le uscite del 74138 sono attive basse, bisogna fare attenzione alla logica.

Se le uscite SUB e COMPARE vanno a 0 quando selezionate, possiamo combinarle con porte logiche e inversioni per ottenere un K attivo alto.

Concettualmente vogliamo:

```text
K = SUB OR COMPARE
```

Dove SUB e COMPARE sono intesi come segnali logici attivi alti.

Se invece partiamo da segnali attivi bassi, dobbiamo prima considerarne la polarità.

In pratica, la rete di generazione di K serve a trasformare le uscite attive basse del decoder in un segnale che valga 1 quando il circuito deve lavorare in sottrazione.

## Uso delle porte disponibili

Durante la costruzione della ALU può capitare di avere porte logiche libere in integrati già presenti.

Ad esempio:

- porte AND inutilizzate in un 7408
- porte XOR inutilizzate in un 7486
- inverter liberi in un 7404

Invece di aggiungere nuovi integrati, possiamo riutilizzare queste porte per generare segnali di controllo come K o per invertire OP3.

Un esempio utile è usare una XOR come NOT:

```text
A XOR 1 = NOT A
```

Quindi, se abbiamo una porta XOR libera, possiamo collegare un ingresso a +5 V e usare l'altro come ingresso del segnale da negare.

Questa soluzione non cambia la logica del progetto, ma può rendere il cablaggio più compatto.

## LED per visualizzare l'operazione selezionata

Oltre a collegare le uscite del decoder agli enable delle reti, possiamo portarle anche a dei LED.

Ogni LED rappresenta un'operazione:

```text
AND
OR
XOR
NOR
NAND
XNOR
NOT
ADD
SUB
COMPARE
```

Quando selezioniamo un opcode, il LED corrispondente si accende.

Questa visualizzazione è molto utile durante i test, perché permette di verificare immediatamente quale operazione è stata selezionata.

In un progetto didattico, vedere l'opcode tradotto in un LED di operazione rende il comportamento dell'ALU molto più leggibile.

## Test del codice operazione

Per testare il circuito del codice operazione possiamo impostare manualmente i 4 bit dell'opcode e osservare quale rete viene abilitata.

Primo test:

```text
opcode = 0000
```

Operazione attesa:

```text
AND
```

Il LED AND deve accendersi e il bus deve mostrare il risultato dell'AND tra A e B.

Secondo test:

```text
opcode = 0001
```

Operazione attesa:

```text
OR
```

Il LED OR deve accendersi e il bus deve mostrare il risultato della OR.

Terzo test:

```text
opcode = 0010
```

Operazione attesa:

```text
XOR
```

Quarto test:

```text
opcode = 0011
```

Operazione attesa:

```text
NOR
```

Possiamo continuare con tutte le operazioni implementate.

## Test di ADD e SUB

Per testare ADD:

```text
opcode = 0111
K = 0
```

Impostiamo, ad esempio:

```text
A = 00000001
B = 00000001
```

Risultato atteso:

```text
00000010
```

Per testare SUB:

```text
opcode = 1000
K = 1
```

Con:

```text
A = 00000011
B = 00000001
```

Risultato atteso:

```text
00000010
```

Questi test verificano che il codice operazione non solo abiliti il buffer corretto, ma imposti anche correttamente il segnale K.

## Test di COMPARE

Per testare COMPARE:

```text
opcode = 1001
```

Il circuito deve eseguire internamente:

```text
A - B
```

quindi K deve valere 1.

Se impostiamo:

```text
A = 00000001
B = 00000000
```

ci aspettiamo:

```text
A > B
```

Se impostiamo:

```text
A = 00000001
B = 00000001
```

ci aspettiamo:

```text
A = B
```

Se impostiamo:

```text
A = 00000001
B = 00000010
```

ci aspettiamo:

```text
A < B
```

Questi test verificano che COMPARE usi correttamente il circuito di sottrazione e aggiorni i segnali di confronto.

## Codici non usati

Con 4 bit abbiamo 16 combinazioni disponibili, ma al momento ne usiamo solo alcune.

I codici non usati possono essere lasciati inattivi.

Questo significa che nessun buffer dell'ALU viene abilitato e il bus dati non viene pilotato dall'ALU.

In futuro potremo assegnare questi codici a nuove operazioni, ad esempio shift, incrementi, decrementi o altre funzioni.

Per ora è importante che i codici non usati non attivino accidentalmente più reti o segnali non desiderati.

## Errori comuni

Quando si costruisce il circuito del codice operazione ci sono diversi errori possibili.

Il primo è dimenticare che le uscite del 74138 sono attive basse. L'uscita selezionata va a 0, non a 1.

Il secondo è dimenticare che anche gli enable dei buffer sono attivi bassi. In questo caso la caratteristica del 74138 è un vantaggio, ma bisogna leggerla correttamente.

Il terzo è abilitare entrambi i 74138 contemporaneamente. Se succede, potremmo attivare due operazioni diverse nello stesso momento.

Il quarto è invertire l'ordine dei bit dell'opcode. Se OP0, OP1 e OP2 vengono collegati in ordine sbagliato, la tabella delle operazioni non corrisponderà ai codici previsti.

Il quinto è generare K con polarità sbagliata. Se K vale 1 durante ADD o 0 durante SUB, il circuito aritmetico farà l'operazione opposta.

Il sesto è lasciare codici non usati in condizioni ambigue. Anche i segnali non utilizzati devono portare il circuito in uno stato sicuro.

## Riepilogo

Il codice operazione serve a selezionare quale operazione dell'ALU deve essere attiva.

Nel nostro progetto usiamo un opcode a 4 bit:

```text
OP3 OP2 OP1 OP0
```

Con 4 bit possiamo selezionare fino a 16 operazioni.

Per decodificare l'opcode usiamo due 74138:

```text
OP0, OP1, OP2 -> selezione dell'uscita
OP3 -> scelta del decoder
```

Le uscite del 74138 sono attive basse, quindi possono pilotare direttamente gli enable attivi bassi dei buffer tri-state.

Le operazioni ADD, SUB e COMPARE richiedono anche la generazione del segnale K, che decide se il circuito aritmetico lavora in somma o sottrazione.

## Conclusione

In questo articolo abbiamo aggiunto all'ALU il codice operazione.

Abbiamo visto come un opcode a 4 bit possa selezionare fino a 16 operazioni e come usare due decoder 74138 per trasformare quel codice in segnali di enable.

Questo passaggio è fondamentale perché rende l'ALU controllabile: non dobbiamo più abilitare manualmente le singole reti, ma possiamo selezionare l'operazione impostando un codice binario.

Abbiamo anche visto che le uscite attive basse del 74138 si adattano molto bene agli enable attivi bassi dei buffer tri-state.

A questo punto la parte combinatoria principale dell'ALU è completa: abbiamo reti logiche, circuito aritmetico, flag, confronti e selezione tramite opcode.

Nel prossimo articolo inizieremo a spostarci verso la parte sequenziale della CPU introducendo il segnale di clock.

Il clock sarà il metronomo che permetterà ai registri e agli altri blocchi della CPU di aggiornarsi in modo ordinato nel tempo.
