# Complemento a due e numeri con segno

Nel precedente articolo abbiamo visto come funziona la somma binaria. Siamo partiti dalla somma di due bit, abbiamo introdotto il carry e siamo arrivati ai circuiti half adder e full adder.

Ora dobbiamo affrontare un passaggio fondamentale: come rappresentare i numeri negativi all'interno della nostra CPU a 8 bit.

Questo argomento è importante perché ci permetterà di usare lo stesso circuito sommatore anche per eseguire sottrazioni. Invece di costruire un circuito separato per sottrarre, trasformeremo la sottrazione in una somma usando il complemento a due.

## Il problema dei numeri negativi

Con 8 bit possiamo rappresentare 256 combinazioni diverse.

Se interpretiamo queste combinazioni come numeri senza segno, il range è:

```text
00000000 = 0
00000001 = 1
00000010 = 2
...
11111111 = 255
```

Quindi, senza segno, possiamo rappresentare i valori da 0 a 255.

Il problema è che una CPU deve spesso lavorare anche con numeri negativi. Dobbiamo quindi decidere come interpretare le stesse 256 combinazioni binarie per rappresentare sia numeri positivi sia numeri negativi.

Una delle rappresentazioni più usate è il complemento a due.

## Numeri senza segno e numeri con segno

Prendiamo un valore a 8 bit:

```text
11111111
```

Se lo interpretiamo come numero senza segno, vale 255:

```text
128 + 64 + 32 + 16 + 8 + 4 + 2 + 1 = 255
```

Ma se lo interpretiamo come numero con segno in complemento a due, lo stesso identico valore rappresenta -1.

Questo è un punto fondamentale: il valore elettrico presente sul bus dati è sempre lo stesso. Sono otto bit.

Il significato numerico dipende da come decidiamo di interpretarli.

La CPU lavora con bit. Siamo noi, tramite l'architettura e le regole scelte, a decidere se quei bit rappresentano un numero senza segno, un numero con segno, un carattere, un'istruzione o qualcos'altro.

## Il bit più significativo come bit di segno

Nel complemento a due, il bit più significativo ha un ruolo speciale.

In un numero a 8 bit, il bit più significativo è il bit 7:

```text
bit:   7   6   5   4   3   2   1   0
peso:128  64  32  16   8   4   2   1
```

Nel caso dei numeri senza segno, il bit 7 ha peso +128.

Nel caso dei numeri con segno in complemento a due, il bit 7 viene interpretato con peso -128:

```text
bit:    7   6   5   4   3   2   1   0
peso: -128 64  32  16   8   4   2   1
```

Quindi, se il bit più significativo è 0, il numero è positivo o zero.

Se il bit più significativo è 1, il numero è negativo.

## Range dei numeri a 8 bit con segno

Con 8 bit abbiamo sempre 256 combinazioni.

Nel caso senza segno, le usiamo per rappresentare:

```text
0 ... 255
```

Nel caso con segno in complemento a due, le usiamo per rappresentare:

```text
-128 ... +127
```

Quindi il range diventa:

```text
10000000 = -128
10000001 = -127
...
11111111 = -1
00000000 = 0
00000001 = 1
...
01111111 = 127
```

È importante notare che lo zero è uno solo:

```text
00000000 = 0
```

Questa è una delle ragioni per cui il complemento a due è molto usato: evita il problema del doppio zero che si avrebbe in altre rappresentazioni dei numeri negativi.

## Esempi di interpretazione

Vediamo alcuni esempi usando i pesi del complemento a due.

Primo esempio:

```text
00000101
```

Il bit più significativo è 0, quindi il numero è positivo.

I bit accesi hanno peso:

```text
4 + 1 = 5
```

Quindi:

```text
00000101 = +5
```

Secondo esempio:

```text
11111111
```

I pesi accesi sono:

```text
-128 + 64 + 32 + 16 + 8 + 4 + 2 + 1
```

Il risultato è:

```text
-1
```

Quindi:

```text
11111111 = -1
```

Terzo esempio:

```text
11111011
```

I pesi accesi sono:

```text
-128 + 64 + 32 + 16 + 8 + 2 + 1
```

Il risultato è:

```text
-5
```

Quindi:

```text
11111011 = -5
```

## Come ottenere il negativo di un numero

Il complemento a due ci dà una regola semplice per ottenere il negativo di un numero.

Per calcolare il complemento a due di un valore dobbiamo:

1. invertire tutti i bit
2. sommare 1

Questa operazione trasforma un numero nel suo opposto.

Ad esempio, partiamo da +5:

```text
+5 = 00000101
```

Primo passaggio: invertiamo tutti i bit.

```text
00000101 -> 11111010
```

Questo si chiama complemento a uno.

Secondo passaggio: sommiamo 1.

```text
11111010
+00000001
---------
11111011
```

Il risultato è:

```text
11111011
```

che, in complemento a due, rappresenta -5.

Quindi:

```text
+5 = 00000101
-5 = 11111011
```

## Verifica di -5

Verifichiamo che `11111011` rappresenti davvero -5.

Usiamo i pesi del complemento a due:

```text
bit:    7   6   5   4   3   2   1   0
peso: -128 64  32  16   8   4   2   1
val:    1   1   1   1   1   0   1   1
```

Sommiamo i pesi dei bit accesi:

```text
-128 + 64 + 32 + 16 + 8 + 2 + 1 = -5
```

Quindi il risultato è corretto.

## Perché il complemento a due è utile

Il grande vantaggio del complemento a due è che permette di usare lo stesso circuito per sommare e sottrarre.

In matematica sappiamo che:

```text
A - B = A + (-B)
```

Se riusciamo a trasformare B nel suo negativo, possiamo eseguire una sottrazione usando un normale sommatore.

Quindi, invece di costruire un circuito dedicato alla sottrazione, useremo il circuito sommatore già disponibile.

Per sottrarre B da A faremo:

```text
A + complemento_a_due(B)
```

Questo è il principio che useremo nella nostra ALU.

## Esempio: 7 - 5

Vogliamo calcolare:

```text
7 - 5
```

La trasformiamo in:

```text
7 + (-5)
```

Rappresentiamo +7:

```text
00000111
```

Abbiamo già calcolato -5:

```text
11111011
```

Ora sommiamo:

```text
  00000111
+ 11111011
----------
1 00000010
```

Il risultato produce 9 bit, ma la nostra CPU lavora a 8 bit. Consideriamo quindi solo gli 8 bit meno significativi:

```text
00000010
```

Questo valore è 2.

Quindi:

```text
7 - 5 = 2
```

Il bit extra a sinistra viene ignorato nel risultato a 8 bit.

## Esempio: 0 - 1

Consideriamo un altro caso importante:

```text
0 - 1
```

Lo riscriviamo come:

```text
0 + (-1)
```

Il valore +1 è:

```text
00000001
```

Per ottenere -1 facciamo il complemento a due.

Invertiamo i bit:

```text
00000001 -> 11111110
```

Sommiamo 1:

```text
11111110
+00000001
---------
11111111
```

Quindi:

```text
-1 = 11111111
```

Ora sommiamo:

```text
00000000
+11111111
--------
11111111
```

Il risultato è:

```text
11111111
```

Se lo interpretiamo senza segno, vale 255.

Se lo interpretiamo in complemento a due, vale -1.

Questo esempio mostra bene perché è fondamentale sapere quale rappresentazione stiamo usando.

## La stessa sequenza di bit può avere significati diversi

Il valore:

```text
11111111
```

può essere interpretato come:

```text
255   se usiamo numeri senza segno
-1    se usiamo numeri con segno in complemento a due
```

Il circuito non “sa” quale significato stiamo dando a quei bit. Il circuito somma sequenze binarie.

L'interpretazione dipende dal progetto della CPU e da come decidiamo di leggere i risultati.

Nel nostro caso, quando parleremo di flag e confronti, adotteremo il range con segno:

```text
-128 ... +127
```

Questo avrà conseguenze importanti sul modo in cui calcoleremo il flag di overflow.

## Sottrazione hardware con XOR e carry in

Ora dobbiamo capire come trasformare questa teoria in circuito.

Per calcolare:

```text
A - B
```

dobbiamo fare:

```text
A + complemento_a_due(B)
```

Il complemento a due di B si ottiene invertendo tutti i bit di B e sommando 1.

Quindi servono due operazioni:

1. invertire B
2. aggiungere 1 al sommatore

Possiamo controllare entrambe le operazioni con un unico segnale, che chiameremo K.

Se K vale 0, vogliamo fare una somma normale:

```text
A + B
```

Se K vale 1, vogliamo fare una sottrazione:

```text
A + NOT(B) + 1
```

Per invertire B solo quando K vale 1 possiamo usare porte XOR.

La XOR ha questa proprietà:

```text
B XOR 0 = B
B XOR 1 = NOT B
```

Quindi, se mandiamo ogni bit di B in XOR con K:

```text
B0 XOR K
B1 XOR K
B2 XOR K
...
B7 XOR K
```

otteniamo:

- se K = 0, B resta invariato
- se K = 1, B viene invertito

Poi colleghiamo K anche al carry in iniziale del sommatore.

In questo modo:

- K = 0 -> B non invertito e carry iniziale 0 -> somma
- K = 1 -> B invertito e carry iniziale 1 -> sottrazione

## Schema concettuale

Il circuito può essere rappresentato così:

```text
A -----------------------> sommatore ---- risultato

B ---- XOR con K --------> sommatore

K -----------------------> carry in iniziale
```

Quando K vale 0:

```text
B XOR 0 = B
carry in = 0
risultato = A + B
```

Quando K vale 1:

```text
B XOR 1 = NOT B
carry in = 1
risultato = A + NOT(B) + 1
risultato = A - B
```

Questo è uno dei passaggi più eleganti del progetto: usando XOR e un sommatore possiamo ottenere sia la somma sia la sottrazione.

## Esempio con K

Supponiamo di voler calcolare:

```text
5 + 3
```

Impostiamo:

```text
A = 00000101
B = 00000011
K = 0
```

Con K = 0:

```text
B XOR K = B
carry in = 0
```

Il sommatore calcola:

```text
00000101 + 00000011 = 00001000
```

Risultato:

```text
8
```

Ora vogliamo calcolare:

```text
5 - 3
```

Impostiamo:

```text
A = 00000101
B = 00000011
K = 1
```

Con K = 1:

```text
B XOR K = NOT B
carry in = 1
```

Il sommatore calcola:

```text
A + NOT(B) + 1
```

cioè:

```text
A + complemento_a_due(B)
```

Il risultato sarà:

```text
00000010
```

cioè 2.

## Complemento a due e overflow

Il complemento a due semplifica molto la sottrazione, ma introduce anche la necessità di gestire correttamente l'overflow.

Con 8 bit con segno possiamo rappresentare solo valori da -128 a +127.

Quindi alcune operazioni producono risultati non rappresentabili.

Ad esempio:

```text
127 + 1 = 128
```

Ma +128 non è rappresentabile in 8 bit con segno.

Il valore binario ottenuto sarà:

```text
10000000
```

che in complemento a due rappresenta -128, non +128.

Quindi il risultato, se letto senza controllare i flag, sarebbe fuorviante.

Per questo motivo più avanti introdurremo il flag di overflow, che servirà a indicare quando il risultato prodotto dall'ALU non è valido nel range scelto.

## Riepilogo delle regole principali

Le regole più importanti da ricordare sono:

```text
con 8 bit senza segno: 0 ... 255
con 8 bit con segno:  -128 ... +127
```

Il bit più significativo indica il segno:

```text
0 -> numero positivo o zero
1 -> numero negativo
```

Per ottenere il negativo di un numero:

```text
inverti tutti i bit
somma 1
```

Per trasformare una sottrazione in somma:

```text
A - B = A + complemento_a_due(B)
```

Per implementare somma e sottrazione con lo stesso circuito:

```text
K = 0 -> somma
K = 1 -> sottrazione
```

con:

```text
B XOR K
carry in = K
```

## Errori comuni

Quando si studia il complemento a due ci sono alcuni errori molto frequenti.

Il primo è confondere numeri con segno e numeri senza segno. La sequenza `11111111` non ha un significato unico: può essere 255 oppure -1, a seconda dell'interpretazione.

Il secondo è dimenticare il `+1` dopo l'inversione dei bit. Invertire i bit produce il complemento a uno, non il complemento a due.

Il terzo è interpretare il carry finale come overflow in ogni situazione. Per i numeri con segno, l'overflow richiede un ragionamento più preciso.

Il quarto è dimenticare che il range positivo arriva solo a +127, mentre il valore -128 è rappresentabile.

Il quinto è pensare che il circuito cambi tra sommatore e sottrattore. In realtà il cuore del circuito resta un sommatore: ciò che cambia è il modo in cui prepariamo l'ingresso B e il carry iniziale.

## Conclusione

In questo articolo abbiamo introdotto i numeri con segno e il complemento a due.

Abbiamo visto che con 8 bit possiamo rappresentare 256 combinazioni, interpretandole come valori senza segno da 0 a 255 oppure come valori con segno da -128 a +127.

Abbiamo imparato a ottenere il negativo di un numero invertendo tutti i bit e sommando 1. Abbiamo poi visto che una sottrazione può essere trasformata in una somma:

```text
A - B = A + (-B)
```

Nel caso della CPU, questo significa che possiamo usare lo stesso circuito sommatore sia per la somma sia per la sottrazione.

Il trucco sarà usare una rete di porte XOR controllata dal segnale K e collegare lo stesso K al carry in iniziale del sommatore.

Nel prossimo articolo passeremo dalla teoria alla pratica.

Vedremo come costruire nella ALU il circuito di somma e sottrazione usando il 74283, le porte XOR e un buffer tri-state collegato al bus dati.
