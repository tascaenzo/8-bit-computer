# ALU: operazione AND

Nei precedenti articoli abbiamo preparato le basi del progetto: abbiamo introdotto il bus dati, visto come organizzare la board e capito perché gli ingressi digitali devono essere sempre collegati a un livello logico stabile tramite circuiti di pull-up o pull-down.

A questo punto possiamo iniziare a costruire il primo vero blocco operativo della nostra CPU: l'ALU.

L'ALU, cioè Arithmetic Logic Unit, è l'unità aritmetico-logica della CPU. Il suo compito è eseguire operazioni sui dati. Alcune operazioni saranno logiche, come AND, OR, XOR, NOT. Altre saranno aritmetiche, come somma e sottrazione.

In questo articolo partiremo dall'operazione più semplice: l'AND bit a bit tra due variabili a 8 bit.

## Cos'è l'operazione AND

L'AND è una delle operazioni fondamentali dell'algebra booleana.

Lavora su due ingressi, che possiamo chiamare A e B, e produce una sola uscita. L'uscita vale 1 soltanto quando entrambi gli ingressi valgono 1. In tutti gli altri casi l'uscita vale 0.

La tabella di verità della porta AND è la seguente:

|   A |   B | OUT |
| --: | --: | --: |
|   0 |   0 |   0 |
|   0 |   1 |   0 |
|   1 |   0 |   0 |
|   1 |   1 |   1 |

Questa tabella ci dice che la combinazione `1 AND 1` è l'unica che produce un livello logico alto in uscita.

L'espressione booleana dell'AND si può scrivere così:

```text
OUT = A · B
```

oppure, in forma più vicina alla programmazione:

```text
OUT = A AND B
```

Nel nostro progetto non useremo una sola porta AND, ma una rete di porte AND in parallelo, una per ogni bit delle variabili A e B.

## AND bit a bit

La nostra CPU lavora con dati a 8 bit. Questo significa che le variabili A e B saranno composte da otto linee ciascuna:

```text
A7 A6 A5 A4 A3 A2 A1 A0
B7 B6 B5 B4 B3 B2 B1 B0
```

L'operazione AND verrà eseguita bit per bit:

```text
OUT0 = A0 AND B0
OUT1 = A1 AND B1
OUT2 = A2 AND B2
OUT3 = A3 AND B3
OUT4 = A4 AND B4
OUT5 = A5 AND B5
OUT6 = A6 AND B6
OUT7 = A7 AND B7
```

Il risultato sarà quindi un altro valore a 8 bit:

```text
OUT7 OUT6 OUT5 OUT4 OUT3 OUT2 OUT1 OUT0
```

Facciamo un esempio.

Supponiamo di avere:

```text
A = 10101010
B = 11110000
```

L'AND bit a bit produce:

```text
A      10101010
B      11110000
AND    10100000
```

Ogni colonna viene calcolata separatamente. Dove entrambi i bit sono 1, il risultato è 1. In tutti gli altri casi il risultato è 0.

## Il ruolo dell'AND nella CPU

L'AND può sembrare un'operazione semplice, ma è molto utile all'interno di una CPU.

Viene spesso usata per mascherare bit, cioè per mantenere solo alcune parti di un valore e azzerarne altre.

Ad esempio, se vogliamo conservare solo i quattro bit meno significativi di un valore, possiamo fare l'AND con la maschera `00001111`:

```text
A       10110110
MASK    00001111
AND     00000110
```

I bit corrispondenti agli 1 della maschera vengono mantenuti, mentre quelli corrispondenti agli 0 vengono azzerati.

Nel nostro progetto, però, la cosa più importante non è ancora l'uso software dell'AND, ma la sua implementazione hardware. Costruendo questa prima rete capiremo il modello che useremo anche per molte altre operazioni dell'ALU.

## Il componente 7408

Per realizzare l'operazione AND useremo l'integrato 7408.

Il 7408 contiene quattro porte AND a due ingressi. Ogni porta ha:

- ingresso A
- ingresso B
- uscita Y

Poiché a noi servono otto porte AND, una per ogni bit, useremo due integrati 7408.

In questo modo avremo:

- primo 7408: quattro porte AND per i bit 0, 1, 2, 3
- secondo 7408: quattro porte AND per i bit 4, 5, 6, 7

La piedinatura tipica del 7408 è organizzata in questo modo:

| Porta | Ingresso A | Ingresso B | Uscita |
| ----- | ---------: | ---------: | -----: |
| 1     |      pin 1 |      pin 2 |  pin 3 |
| 2     |      pin 4 |      pin 5 |  pin 6 |
| 3     |      pin 9 |     pin 10 |  pin 8 |
| 4     |     pin 12 |     pin 13 | pin 11 |

Inoltre:

| Pin | Collegamento |
| --: | ------------ |
|  14 | +5 V         |
|   7 | GND          |

Prima di collegare un integrato è sempre importante verificare il datasheet del componente specifico che si sta usando, soprattutto se si utilizzano varianti diverse della famiglia logica.

## Struttura della rete AND a 8 bit

La rete AND a 8 bit segue una struttura molto semplice.

Ogni bit della variabile A viene collegato a un ingresso di una porta AND. Il bit corrispondente della variabile B viene collegato all'altro ingresso della stessa porta.

L'uscita della porta AND rappresenta il risultato per quel bit.

Lo schema logico può essere rappresentato così:

```text
A0 ----\
       AND ---- OUT0
B0 ----/

A1 ----\
       AND ---- OUT1
B1 ----/

A2 ----\
       AND ---- OUT2
B2 ----/

...

A7 ----\
       AND ---- OUT7
B7 ----/
```

Le uscite OUT0-OUT7, però, non devono essere collegate direttamente al bus dati.

Prima devono passare attraverso un buffer tri-state.

## Perché serve un buffer verso il bus dati

Il bus dati è condiviso da più circuiti.

Oggi stiamo costruendo la rete AND, ma più avanti aggiungeremo la rete OR, la rete XOR, il sommatore, la sottrazione e altre operazioni. Tutte queste reti avranno un risultato a 8 bit e tutte dovranno poterlo mandare sul bus dati.

Se collegassimo direttamente tutte le uscite al bus, avremmo un problema: più reti potrebbero tentare di pilotare contemporaneamente le stesse linee.

Ad esempio, una rete potrebbe cercare di portare D0 a 1 mentre un'altra cerca di portarlo a 0. Questo creerebbe un conflitto elettrico.

Per evitarlo, ogni rete dell'ALU verrà collegata al bus attraverso un buffer tri-state.

Quando il buffer della rete AND è abilitato, il risultato dell'AND arriva sul bus dati.

Quando il buffer è disabilitato, le uscite della rete AND sono isolate dal bus e si trovano in alta impedenza.

Questo ci permette di avere molte reti collegate fisicamente allo stesso bus, ma una sola rete attiva alla volta.

## Il buffer 74244

Per collegare il risultato della rete AND al bus dati useremo un buffer tri-state a 8 bit, come il 74244.

Il 74244 contiene otto buffer. Ogni buffer prende un ingresso e lo riporta su un'uscita quando il segnale di enable è attivo.

Nel nostro caso collegheremo:

```text
OUT0 della rete AND -> ingresso buffer 0 -> D0 bus dati
OUT1 della rete AND -> ingresso buffer 1 -> D1 bus dati
OUT2 della rete AND -> ingresso buffer 2 -> D2 bus dati
...
OUT7 della rete AND -> ingresso buffer 7 -> D7 bus dati
```

Il segnale di enable controllerà l'intera rete.

In molti buffer della famiglia 74xx l'enable è attivo basso. Questo significa che:

| Enable | Stato buffer   |
| -----: | -------------- |
|      0 | buffer attivo  |
|      1 | alta impedenza |

Quindi, per abilitare la rete AND e vedere il risultato sul bus, dovremo portare l'enable a 0, cioè a massa.

Per disabilitare la rete, dovremo portare l'enable a 1, cioè a +5 V.

Questa logica attiva bassa è molto comune nei circuiti digitali, e la incontreremo spesso anche nei prossimi articoli.

## Collegamento generale della rete

Il collegamento complessivo della rete AND sarà quindi:

```text
Switch A ----\
             7408 ---- risultato AND ---- 74244 ---- bus dati ---- LED
Switch B ----/
```

Più precisamente:

1. gli switch della variabile A forniscono gli 8 bit A0-A7
2. gli switch della variabile B forniscono gli 8 bit B0-B7
3. ogni coppia Ai/Bi entra in una porta AND del 7408
4. le otto uscite delle porte AND entrano nel buffer 74244
5. le uscite del 74244 vanno alle otto linee del bus dati
6. i LED collegati al bus mostrano il risultato
7. il segnale di enable decide se la rete AND può scrivere sul bus

Questa struttura diventerà lo schema base per molte reti dell'ALU.

Cambierà la porta logica, ma resterà lo stesso principio:

```text
Ingressi A/B -> rete logica -> buffer tri-state -> bus dati
```

## Prima prova: un solo bit

Prima di testare l'intera rete a 8 bit, conviene ragionare su un solo bit.

Supponiamo di collegare A0 e B0 alla prima porta AND.

Facciamo le quattro prove possibili:

|  A0 |  B0 | Risultato atteso |
| --: | --: | ---------------: |
|   0 |   0 |                0 |
|   0 |   1 |                0 |
|   1 |   0 |                0 |
|   1 |   1 |                1 |

Se il buffer è abilitato, il LED collegato a D0 dovrà accendersi solo nell'ultimo caso.

Se invece il buffer è disabilitato, il LED del bus non dovrà essere pilotato dalla rete AND, indipendentemente dal valore prodotto dalle porte AND.

Questo test ci permette di verificare due cose:

- la porta AND funziona correttamente
- il buffer abilita e disabilita correttamente il collegamento al bus

## Test della rete a 8 bit

Una volta verificato un singolo bit, possiamo testare l'intera rete.

Un primo test semplice consiste nel mettere tutti i bit di A a 1 e tutti i bit di B a 1:

```text
A = 11111111
B = 11111111
```

Il risultato atteso è:

```text
OUT = 11111111
```

Tutti i LED del bus dati dovrebbero accendersi.

Se invece mettiamo A a 11111111 e B a 00000000:

```text
A = 11111111
B = 00000000
```

il risultato atteso è:

```text
OUT = 00000000
```

Tutti i LED dovrebbero essere spenti.

Un altro test utile è usare valori alternati:

```text
A = 10101010
B = 11110000
```

Risultato atteso:

```text
OUT = 10100000
```

Questi test ci aiutano a verificare che ogni bit sia collegato correttamente e che non ci siano inversioni o scambi tra le linee.

## Test del segnale di enable

Oltre a testare l'operazione AND, dobbiamo verificare anche il comportamento del buffer.

Con il risultato dell'AND diverso da zero, ad esempio:

```text
A = 11111111
B = 11111111
```

portiamo l'enable del buffer a massa.

Il bus dati dovrebbe mostrare:

```text
11111111
```

A questo punto portiamo l'enable a +5 V.

La rete AND deve essere isolata dal bus. Il risultato prodotto dalle porte AND continua a esistere all'uscita del 7408, ma non viene più trasferito al bus dati.

Questo comportamento è fondamentale, perché in futuro il codice operazione dell'ALU controllerà proprio questi enable per decidere quale rete deve scrivere sul bus.

## Problemi comuni durante il montaggio

Durante il montaggio della rete AND possono comparire alcuni problemi tipici.

Uno dei più comuni è invertire l'ordine dei bit. Ad esempio, potremmo collegare A0 alla porta che poi finisce su D7 invece che su D0. In questo caso il risultato logico sarebbe corretto, ma apparirebbe nella posizione sbagliata sul bus.

Un altro problema possibile è dimenticare l'alimentazione di uno degli integrati. Il 7408 e il 74244 devono essere entrambi alimentati correttamente con +5 V e GND.

Bisogna poi fare attenzione agli enable del buffer. Se l'enable è attivo basso e lo lasciamo a +5 V, la rete resterà disabilitata e sul bus non vedremo il risultato, anche se le porte AND stanno funzionando.

Infine, è importante controllare che gli ingressi A e B non siano flottanti. Gli switch devono essere collegati tramite pull-up o pull-down, come visto nell'articolo precedente.

## Perché partire dall'AND

L'operazione AND è un ottimo punto di partenza per costruire l'ALU.

È semplice da capire, usa componenti comuni e ci permette di introdurre subito la struttura fondamentale che useremo per tutte le operazioni logiche:

```text
porta logica -> buffer -> bus dati
```

Una volta costruita e testata la rete AND, aggiungere altre operazioni diventa più semplice.

La rete OR, ad esempio, avrà una struttura quasi identica. Cambierà solo il tipo di porta logica: useremo il 7432 al posto del 7408.

Lo stesso discorso varrà per XOR, NOR, NAND, XNOR e NOT.

## Conclusione

In questo articolo abbiamo costruito il primo blocco operativo dell'ALU: la rete AND a 8 bit.

Abbiamo visto la tabella di verità della porta AND, il concetto di operazione bit a bit e l'uso del componente 7408. Abbiamo poi collegato le uscite della rete a un buffer tri-state, in modo da poter trasferire il risultato sul bus dati solo quando il segnale di enable lo permette.

Questo primo circuito introduce il modello base dell'intera ALU: ogni operazione produrrà un risultato a 8 bit, ma solo l'operazione selezionata verrà collegata al bus.

Nel prossimo articolo approfondiremo proprio il ruolo dei buffer tri-state e dell'alta impedenza.

Capire bene questo meccanismo è fondamentale, perché sarà alla base della selezione delle operazioni dell'ALU e, più avanti, della comunicazione tra i vari blocchi della CPU.
