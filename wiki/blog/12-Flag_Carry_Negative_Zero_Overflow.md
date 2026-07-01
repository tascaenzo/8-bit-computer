# Flag della CPU: Carry, Negative, Zero e Overflow

Negli articoli precedenti abbiamo costruito il modulo aritmetico principale della nostra ALU: un circuito capace di eseguire somma e sottrazione a 8 bit usando due 74283, una rete di XOR e il complemento a due.

Ora dobbiamo aggiungere un altro elemento fondamentale: i flag.

I flag sono bit di stato generati a partire dal risultato di un'operazione. Servono alla CPU per capire qualcosa in più sul valore prodotto dall'ALU. Ad esempio, il risultato è zero? È negativo? C'è stato un riporto? Il risultato è uscito dal range rappresentabile?

Queste informazioni saranno molto importanti quando, più avanti, costruiremo operazioni di confronto e quando l'unità di controllo dovrà decidere se eseguire o meno determinate azioni.

## Cosa sono i flag

Un flag è un singolo bit che rappresenta una condizione.

Può valere:

```text
0 -> condizione falsa
1 -> condizione vera
```

Nel nostro progetto implementeremo quattro flag principali:

```text
C -> Carry / Borrow
N -> Negative
Z -> Zero
V -> Overflow
```

Questi flag vengono generati dopo un'operazione aritmetico-logica eseguita dall'ALU.

Ad esempio, dopo una somma, il flag Z ci dirà se il risultato è zero. Il flag N ci dirà se il risultato è negativo. Il flag V ci dirà se il risultato non è rappresentabile correttamente nel range scelto.

## Perché i flag sono importanti

L'ALU produce un risultato, ma spesso alla CPU non basta conoscere solo quel risultato.

Facciamo un esempio.

Se eseguiamo:

```text
A - B
```

possiamo usare il risultato per capire se A e B sono uguali. Infatti, se:

```text
A - B = 0
```

allora A è uguale a B.

In questo caso non serve necessariamente leggere tutto il risultato a 8 bit: basta sapere se il flag Zero è attivo.

Un altro esempio riguarda i salti condizionati. Una CPU può decidere di saltare a una certa istruzione solo se il risultato precedente era zero, negativo o se una certa condizione è vera.

I flag permettono quindi alla CPU di prendere decisioni.

Per questo motivo vengono anche chiamati flag di stato.

## Il range scelto per la nostra CPU

Prima di calcolare correttamente i flag, dobbiamo stabilire come interpretiamo i valori a 8 bit.

Nel nostro progetto useremo la rappresentazione con segno in complemento a due.

Il range sarà:

```text
-128 ... +127
```

Il bit più significativo, cioè il bit 7, sarà il bit di segno:

```text
0 -> numero positivo o zero
1 -> numero negativo
```

Questa scelta è importante soprattutto per i flag Negative e Overflow.

## Flag Zero

Il flag Zero indica se il risultato dell'ALU è uguale a zero.

Lo indicheremo con:

```text
Z
```

La regola è:

```text
Z = 1 se OUT = 00000000
Z = 0 in tutti gli altri casi
```

Quindi, se tutti gli 8 bit del risultato sono 0, il flag Zero si accende.

Se anche un solo bit del risultato vale 1, il flag Zero resta spento.

## Come calcolare il flag Zero

Per calcolare Z dobbiamo verificare se tutti i bit dell'uscita sono a 0.

Possiamo farlo in due passaggi:

1. facciamo l'OR di tutti i bit del risultato
2. neghiamo il risultato finale

Se almeno un bit è 1, l'OR totale vale 1.

Se tutti i bit sono 0, l'OR totale vale 0.

Negando il risultato otteniamo il flag Zero.

Schema concettuale:

```text
OUT0 ----\
OUT1 ----- OR ----\
OUT2 ----/         \
                   OR ---- NOT ---- Z
OUT3 ----\         /
OUT4 ----- OR ----/
...
OUT7 --------------
```

In forma logica:

```text
Z = NOT(OUT0 OR OUT1 OR OUT2 OR OUT3 OR OUT4 OR OUT5 OR OUT6 OR OUT7)
```

Esempi:

```text
OUT = 00000000 -> OR totale = 0 -> Z = 1
OUT = 00000001 -> OR totale = 1 -> Z = 0
OUT = 10000000 -> OR totale = 1 -> Z = 0
```

Il flag Zero sarà molto utile nelle operazioni di confronto.

## Flag Negative

Il flag Negative indica se il risultato deve essere interpretato come numero negativo.

Lo indicheremo con:

```text
N
```

Nel complemento a due, un numero è negativo quando il bit più significativo vale 1.

Nel nostro bus dati a 8 bit, il bit più significativo è:

```text
OUT7
```

Quindi il flag Negative può essere ottenuto direttamente dal bit 7 del risultato:

```text
N = OUT7
```

Esempi:

```text
OUT = 00000101 -> N = 0 -> +5
OUT = 11111111 -> N = 1 -> -1
OUT = 10000000 -> N = 1 -> -128
OUT = 01111111 -> N = 0 -> +127
```

Questo flag non ci dice se il risultato è corretto o meno. Ci dice solo che il bit di segno è 1.

Se c'è overflow, il risultato potrebbe avere un segno apparentemente valido ma essere numericamente sbagliato.

## Flag Carry / Borrow

Il flag Carry è legato al riporto prodotto dal sommatore.

Lo indicheremo con:

```text
C
```

Nel caso della somma, il carry out finale del sommatore indica che il risultato ha generato un riporto oltre gli 8 bit.

Ad esempio, interpretando i valori come senza segno:

```text
11111111 + 00000001 = 1 00000000
```

Gli 8 bit del risultato sono:

```text
00000000
```

ma c'è un carry finale pari a 1.

Nel caso della sottrazione, però, il significato del carry cambia. Quando usiamo il complemento a due, il carry out va interpretato in relazione all'operazione di sottrazione e può essere trasformato in un'indicazione di borrow, cioè prestito.

Nel nostro progetto useremo una rete che combina il carry out del 74283 con il segnale K.

Ricordiamo:

```text
K = 0 -> somma
K = 1 -> sottrazione
```

Per ottenere un flag coerente tra somma e sottrazione possiamo usare:

```text
C = CarryOut XOR K
```

Quando K = 0, quindi in somma:

```text
C = CarryOut XOR 0 = CarryOut
```

Quando K = 1, quindi in sottrazione:

```text
C = CarryOut XOR 1 = NOT CarryOut
```

In questo modo il flag C può essere letto come Carry nelle somme e come Borrow nelle sottrazioni.

## Flag Overflow

Il flag Overflow indica che il risultato prodotto non è rappresentabile nel range scelto.

Lo indicheremo con:

```text
V
```

Nel nostro caso il range è:

```text
-128 ... +127
```

Quindi, se una somma o una sottrazione produce un valore fuori da questo intervallo, il flag Overflow deve accendersi.

È importante non confondere Carry e Overflow.

Il carry finale è legato al riporto oltre il bit più significativo.

L'overflow, invece, riguarda la validità del risultato quando interpretiamo i numeri come valori con segno in complemento a due.

## Esempio di overflow positivo

Consideriamo:

```text
127 + 1
```

In binario con complemento a due:

```text
127 = 01111111
1   = 00000001
```

Sommiamo:

```text
  01111111
+ 00000001
----------
  10000000
```

Il risultato binario è:

```text
10000000
```

Ma in complemento a due questo valore rappresenta -128, non +128.

Il risultato reale, +128, non è rappresentabile con 8 bit con segno.

Quindi:

```text
V = 1
```

Il flag Negative sarà anch'esso 1, perché OUT7 vale 1, ma il risultato non è valido come +128.

## Esempio di overflow negativo

Consideriamo:

```text
-128 - 1
```

Il valore -128 è:

```text
10000000
```

Sottrarre 1 significa ottenere -129, ma -129 non è rappresentabile con 8 bit in complemento a due.

Il risultato andrà fuori dal range.

Anche in questo caso:

```text
V = 1
```

Il flag Overflow serve proprio a intercettare queste situazioni.

## Come calcolare l'overflow

L'overflow può essere calcolato analizzando i segni degli operandi e del risultato.

Per la somma tra numeri con segno, c'è overflow quando sommiamo due numeri dello stesso segno e otteniamo un risultato di segno opposto.

Esempi:

```text
positivo + positivo = negativo -> overflow
negativo + negativo = positivo -> overflow
```

Nel nostro circuito dobbiamo tenere conto anche del segnale K, perché K decide se stiamo facendo una somma o una sottrazione.

Gli ingressi utili sono:

```text
A7 -> bit di segno di A
B7 -> bit di segno di B
K  -> selezione somma/sottrazione
OUT7 -> bit di segno del risultato
```

La rete logica dell'overflow userà questi segnali per determinare se il risultato è uscito dal range rappresentabile.

In forma concettuale, il flag Overflow deve accendersi quando il segno del risultato non è coerente con i segni degli operandi e con l'operazione eseguita.

## Rete dei flag sulla board

Nel progetto possiamo visualizzare i flag usando dei LED dedicati.

Avremo quindi una piccola sezione della board con quattro LED:

```text
C -> Carry / Borrow
N -> Negative
Z -> Zero
V -> Overflow
```

Ogni LED sarà collegato al rispettivo segnale tramite una resistenza di limitazione della corrente.

Questi LED non sono strettamente necessari al funzionamento finale della CPU, ma sono molto utili durante lo sviluppo. Permettono di vedere immediatamente lo stato dell'ALU dopo ogni operazione.

Quando più avanti introdurremo i registri di stato, questi flag potranno essere salvati e usati dall'unità di controllo.

## Test del flag Zero

Un primo test semplice è:

```text
A = 00000000
B = 00000000
operazione: A - B
```

Il risultato è:

```text
00000000
```

Quindi:

```text
Z = 1
```

Altro test:

```text
A = 00000001
B = 00000001
operazione: A - B
```

Anche qui:

```text
1 - 1 = 0
```

Risultato:

```text
00000000
```

Quindi:

```text
Z = 1
```

Se invece facciamo:

```text
A = 00000010
B = 00000001
A - B = 1
```

Il risultato è diverso da zero:

```text
Z = 0
```

## Test del flag Negative

Un test semplice è:

```text
A = 00000101   5
B = 00001010   10
operazione: A - B
```

Il risultato è:

```text
5 - 10 = -5
```

In complemento a due, -5 è:

```text
11111011
```

Il bit più significativo è 1, quindi:

```text
N = 1
```

Se invece facciamo:

```text
10 - 5 = 5
```

Il risultato è positivo:

```text
00000101
```

Quindi:

```text
N = 0
```

## Test del flag Carry / Borrow

Consideriamo una sottrazione:

```text
A = 00000101   5
B = 00001010   10
operazione: A - B
```

Stiamo sottraendo un numero più grande da uno più piccolo.

Il risultato è negativo:

```text
5 - 10 = -5
```

In questa situazione si genera una condizione di borrow.

Nel nostro circuito, il flag C viene calcolato come:

```text
C = CarryOut XOR K
```

Poiché siamo in sottrazione, K vale 1. Il flag C diventa quindi l'indicazione di borrow.

## Test del flag Overflow

Testiamo una somma che produce overflow:

```text
A = 01111111   127
B = 00000001   1
operazione: A + B
```

Il risultato binario è:

```text
10000000
```

Letto in complemento a due, questo valore rappresenta -128.

Ma il risultato matematico atteso è:

```text
128
```

che non è rappresentabile nel range -128/+127.

Quindi:

```text
V = 1
```

Altro test:

```text
A = 10000000   -128
B = 00000001   1
operazione: A - B
```

Il risultato matematico sarebbe:

```text
-129
```

Anche questo valore non è rappresentabile a 8 bit con segno.

Quindi:

```text
V = 1
```

## Flag e operazioni non aritmetiche

Un aspetto importante è che alcuni flag, nel nostro circuito attuale, possono cambiare anche quando sul bus dati transitano risultati prodotti da operazioni non aritmetiche.

Ad esempio, il flag Zero può essere calcolato direttamente osservando il bus dati. Se una rete logica produce `00000000`, il flag Zero può accendersi anche se non è stata eseguita una somma o una sottrazione.

Questo non è necessariamente un problema.

In una CPU completa, l'unità di controllo decide quando i flag devono essere salvati in un registro di stato. Quindi non tutti i cambiamenti momentanei dei segnali devono per forza diventare uno stato ufficiale della CPU.

Per ora, nella fase didattica, visualizzare i flag con LED ci aiuta a capire come reagiscono i circuiti.

## Riepilogo dei flag

Possiamo riassumere i quattro flag così:

| Flag | Nome           | Significato                                |
| ---- | -------------- | ------------------------------------------ |
| C    | Carry / Borrow | riporto in somma o prestito in sottrazione |
| N    | Negative       | il risultato ha bit di segno a 1           |
| Z    | Zero           | il risultato è uguale a zero               |
| V    | Overflow       | il risultato è fuori dal range con segno   |

E le formule principali sono:

```text
Z = NOT(OUT0 OR OUT1 OR OUT2 OR OUT3 OR OUT4 OR OUT5 OR OUT6 OR OUT7)
N = OUT7
C = CarryOut XOR K
```

Per V serve una rete logica dedicata che considera:

```text
A7, B7, K, OUT7
```

## Errori comuni

Quando si lavora con i flag, ci sono alcuni errori frequenti.

Il primo è confondere Carry e Overflow. Il carry riguarda il riporto, mentre l'overflow riguarda la validità del risultato nel range con segno.

Il secondo è pensare che il flag Negative garantisca che il risultato sia corretto. In realtà N indica solo il valore del bit di segno. Se V è attivo, il risultato non va interpretato come valido.

Il terzo è dimenticare che Zero richiede che tutti gli 8 bit siano a 0. Non basta controllare un solo bit.

Il quarto è interpretare il carry out della sottrazione nello stesso modo della somma. Per questo usiamo la combinazione con K.

Il quinto è dimenticare che i flag, in una CPU completa, devono essere salvati solo quando l'unità di controllo lo richiede.

## Conclusione

In questo articolo abbiamo introdotto i flag principali della nostra CPU a 8 bit.

Abbiamo visto che i flag sono bit di stato generati a partire dal risultato dell'ALU e che forniscono informazioni importanti alla CPU.

Abbiamo analizzato quattro flag:

```text
Carry / Borrow
Negative
Zero
Overflow
```

Il flag Zero ci dice se il risultato è nullo. Il flag Negative coincide con il bit di segno del risultato. Il flag Carry/Borrow deriva dal carry out del sommatore combinato con il segnale K. Il flag Overflow indica che il risultato non è rappresentabile nel range -128/+127.

Nel prossimo articolo useremo questi flag per costruire le operazioni di confronto.

Vedremo come ricavare le condizioni:

```text
A = B
A < B
A > B
```

senza usare un comparatore dedicato, ma riutilizzando il circuito di sottrazione e i flag appena introdotti.
