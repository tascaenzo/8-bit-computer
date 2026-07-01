# Operazioni di confronto: A uguale B, A minore di B, A maggiore di B

Nel precedente articolo abbiamo introdotto i flag principali della nostra CPU a 8 bit: Carry/Borrow, Negative, Zero e Overflow. Abbiamo visto che questi bit descrivono lo stato del risultato prodotto dall'ALU e possono essere usati per prendere decisioni.

In questo articolo useremo proprio i flag per implementare le operazioni di confronto.

L'obiettivo è capire se, dati due valori A e B, vale una di queste condizioni:

```text
A = B
A < B
A > B
```

Una soluzione possibile sarebbe usare un comparatore dedicato. Tuttavia, nel nostro progetto useremo un approccio più interessante: riutilizzeremo il circuito di sottrazione e i flag già disponibili.

## Perché confrontare due numeri

Le operazioni di confronto sono fondamentali in una CPU.

Un programma deve spesso prendere decisioni in base al valore di due dati. Ad esempio:

```text
se A è uguale a B, esegui una certa istruzione
se A è minore di B, salta a un'altra parte del programma
se A è maggiore di B, continua in un certo modo
```

Queste condizioni sono alla base dei salti condizionati, dei cicli, delle istruzioni di confronto e di molte strutture di controllo.

Anche se nel nostro progetto non abbiamo ancora implementato l'unità di controllo completa, è utile preparare l'ALU per generare queste informazioni.

## L'idea di base: confrontare sottraendo

Per confrontare due numeri possiamo usare una sottrazione.

L'operazione chiave è:

```text
A - B
```

Il risultato di questa sottrazione ci dà molte informazioni:

- se il risultato è 0, allora A = B
- se il risultato è negativo, allora A < B
- se il risultato è positivo e non zero, allora A > B

Questa idea funziona, ma quando lavoriamo con numeri con segno e complemento a due dobbiamo tenere conto anche dell'overflow.

Per questo motivo useremo i flag generati dall'ALU:

```text
Z -> Zero
N -> Negative
V -> Overflow
```

Il flag C/Borrow può essere utile in altri contesti, ma per i confronti con segno useremo soprattutto Z, N e V.

## Perché non usare un comparatore dedicato

Esistono integrati dedicati al confronto tra numeri, come il 7485, che è un comparatore a 4 bit.

Un comparatore prende in ingresso due valori e produce uscite che indicano condizioni come:

```text
A = B
A < B
A > B
```

Questa sarebbe una soluzione diretta.

Tuttavia, nel nostro progetto abbiamo già costruito un circuito capace di fare sottrazioni e abbiamo già introdotto i flag. Quindi possiamo evitare di aggiungere un comparatore dedicato e riutilizzare ciò che abbiamo.

Questo rende il progetto più coerente con il funzionamento di molte CPU reali, dove le operazioni di confronto sono spesso implementate come sottrazioni che aggiornano i flag.

## Confronto di uguaglianza: A = B

Il caso più semplice è l'uguaglianza.

Se facciamo:

```text
A - B
```

allora:

```text
A = B  se e solo se  A - B = 0
```

Quindi possiamo usare direttamente il flag Zero.

La regola è:

```text
A = B -> Z = 1
```

oppure:

```text
EQ = Z
```

Dove EQ è il flag di uguaglianza.

Esempi:

```text
5 - 5 = 0  -> Z = 1 -> A = B
7 - 3 = 4  -> Z = 0 -> A != B
3 - 7 = -4 -> Z = 0 -> A != B
```

Questa condizione non richiede nessuna rete logica aggiuntiva. È sufficiente leggere il flag Z prodotto dalla sottrazione.

## Confronto A < B

Per capire se A è minore di B, potremmo pensare di guardare semplicemente il flag Negative dopo la sottrazione:

```text
A - B < 0 -> A < B
```

Quindi sembrerebbe sufficiente:

```text
LT = N
```

Dove LT significa less than, cioè minore di.

Il problema è che, con i numeri con segno, l'overflow può rendere il bit di segno non affidabile.

Per questo motivo dobbiamo combinare il flag Negative con il flag Overflow.

La regola corretta è:

```text
A < B -> N XOR V
```

Quindi:

```text
LT = N XOR V
```

Se N e V sono diversi, allora A è minore di B.

## Perché usare N XOR V

Il flag N indica il segno del risultato.

Il flag V indica se c'è stato overflow.

Se non c'è overflow, il bit di segno è affidabile. Quindi:

```text
V = 0 -> LT = N
```

Infatti:

```text
N XOR 0 = N
```

Se invece c'è overflow, il segno del risultato è invertito rispetto a quello che ci aspetteremmo. In quel caso dobbiamo correggere l'informazione usando V.

Infatti:

```text
N XOR 1 = NOT N
```

Quindi la formula:

```text
LT = N XOR V
```

funziona sia quando non c'è overflow sia quando c'è overflow.

Questa è una relazione molto importante nei confronti tra numeri con segno.

## Esempi di A < B

Prendiamo un caso semplice:

```text
A = 3
B = 7
```

Facciamo:

```text
A - B = 3 - 7 = -4
```

Il risultato è negativo e non c'è overflow.

Quindi:

```text
N = 1
V = 0
LT = N XOR V = 1 XOR 0 = 1
```

Il flag A < B si accende.

Altro caso:

```text
A = 10
B = 5
```

Facciamo:

```text
A - B = 5
```

Il risultato è positivo.

```text
N = 0
V = 0
LT = 0 XOR 0 = 0
```

Quindi A non è minore di B.

## Confronto A > B

Per determinare se A è maggiore di B possiamo ragionare in modo logico.

Se A non è uguale a B e A non è minore di B, allora A deve essere maggiore di B.

Quindi:

```text
A > B = NOT(A = B) AND NOT(A < B)
```

Usando i flag:

```text
GT = NOT(Z) AND NOT(LT)
```

Dove:

```text
LT = N XOR V
```

Quindi possiamo scrivere:

```text
GT = NOT(Z) AND NOT(N XOR V)
```

Questa formula ci permette di ricavare il flag A > B senza un comparatore dedicato.

## Perché la formula di A > B funziona

Tra due numeri A e B, se stiamo considerando un confronto ordinato, ci sono solo tre possibilità:

```text
A = B
A < B
A > B
```

Se sappiamo che A non è uguale a B e sappiamo anche che A non è minore di B, allora l'unica possibilità rimasta è:

```text
A > B
```

Quindi la formula:

```text
GT = NOT(Z) AND NOT(LT)
```

è una conseguenza diretta della logica del confronto.

## Rete logica per i confronti

Le tre condizioni possono essere generate così:

```text
EQ = Z
LT = N XOR V
GT = NOT(Z) AND NOT(LT)
```

A livello di porte logiche servono:

- una XOR per calcolare LT
- una NOT per negare LT
- una NOT per negare Z, oppure il segnale Z negato già disponibile
- una AND per calcolare GT

In forma schematica:

```text
N ----\
      XOR ---- LT ---- NOT ----\
V ----/                         AND ---- GT
                       NOT Z --/

Z ---------------------------- EQ
```

Se nella rete del flag Zero abbiamo già disponibile il segnale prima della NOT, possiamo riutilizzarlo come NOT Z. Questo riduce il numero di porte necessarie.

## Visualizzazione con LED

Per rendere il comportamento dell'ALU più leggibile, possiamo aggiungere tre LED dedicati alle condizioni di confronto:

```text
A = B
A < B
A > B
```

Questi LED non sono necessariamente parte obbligatoria della CPU finale, ma sono molto utili nella fase didattica.

Permettono di vedere immediatamente il risultato del confronto dopo aver impostato A, B e l'operazione di sottrazione.

In una CPU completa, questi segnali potrebbero essere usati dall'unità di controllo per decidere se eseguire un salto condizionato.

## Test: A = B

Primo test:

```text
A = 0
B = 0
```

Facciamo:

```text
A - B = 0 - 0 = 0
```

Il flag Zero si accende:

```text
Z = 1
```

Quindi:

```text
EQ = 1
LT = 0
GT = 0
```

Secondo test:

```text
A = 1
B = 1
```

Facciamo:

```text
1 - 1 = 0
```

Anche qui:

```text
EQ = 1
```

Il LED A = B deve accendersi.

## Test: A > B

Consideriamo:

```text
A = 1
B = 0
```

Facciamo:

```text
1 - 0 = 1
```

Il risultato è positivo e diverso da zero.

Quindi:

```text
Z = 0
N = 0
V = 0
LT = N XOR V = 0
GT = NOT(Z) AND NOT(LT)
GT = 1 AND 1 = 1
```

Il LED A > B deve accendersi.

Altro esempio:

```text
A = 10
B = 5
```

```text
10 - 5 = 5
```

Risultato positivo e non nullo:

```text
A > B
```

## Test: A < B

Consideriamo:

```text
A = 1
B = 2
```

Facciamo:

```text
1 - 2 = -1
```

In complemento a due:

```text
-1 = 11111111
```

Il risultato ha bit di segno a 1 e non c'è overflow.

Quindi:

```text
N = 1
V = 0
LT = N XOR V = 1
```

Il LED A < B deve accendersi.

Altro esempio:

```text
A = 5
B = 10
```

```text
5 - 10 = -5
```

Anche qui:

```text
A < B
```

## Caso con overflow

La formula `LT = N XOR V` diventa davvero importante nei casi in cui il risultato della sottrazione produce overflow.

Consideriamo valori con segno a 8 bit.

Supponiamo:

```text
A = 127
B = -1
```

Vogliamo confrontare:

```text
127 < -1 ?
```

La risposta corretta è no.

La sottrazione è:

```text
127 - (-1) = 128
```

Ma +128 non è rappresentabile in 8 bit con segno. Il risultato binario sarà:

```text
10000000
```

Questo ha bit di segno a 1, quindi N = 1, ma il risultato è in overflow, quindi V = 1.

Se guardassimo solo N, penseremmo erroneamente che A < B.

Usando invece:

```text
LT = N XOR V
LT = 1 XOR 1 = 0
```

otteniamo il risultato corretto: A non è minore di B.

Questo esempio mostra perché il flag Overflow è indispensabile nei confronti con segno.

## Operazione Compare

Nel nostro progetto possiamo trattare il confronto come una vera e propria operazione dell'ALU.

Questa operazione può essere chiamata:

```text
COMPARE
```

Durante una compare, l'ALU esegue internamente:

```text
A - B
```

Il risultato della sottrazione può anche non essere usato direttamente sul bus dati. Ciò che ci interessa davvero sono i flag generati:

```text
Z, N, V
```

Da questi flag ricaviamo:

```text
A = B
A < B
A > B
```

Quindi la compare non richiede necessariamente un nuovo circuito aritmetico. Riutilizza il circuito di sottrazione già presente.

## Relazione con il codice operazione

Più avanti, quando implementeremo il codice operazione dell'ALU, avremo un codice dedicato alla compare.

Quando verrà selezionata l'operazione COMPARE, il circuito dovrà comportarsi come una sottrazione:

```text
K = 1
```

perché deve calcolare:

```text
A - B
```

La differenza rispetto alla SUB sarà nel modo in cui il risultato viene usato.

Nella sottrazione, il risultato può essere portato sul bus dati.

Nella compare, invece, potrebbero interessarci solo i flag e i segnali di confronto.

Questa distinzione diventerà importante quando parleremo del codice operazione dell'ALU.

## Errori comuni

Quando si implementano i confronti con i flag, ci sono alcuni errori frequenti.

Il primo è usare solo il flag Negative per determinare A < B. Questo funziona solo se non c'è overflow. Per i numeri con segno bisogna usare N XOR V.

Il secondo è dimenticare che A = B si ottiene dalla sottrazione A - B, non confrontando direttamente i singoli bit.

Il terzo è confondere GT con NOT(LT). Se A non è minore di B, potrebbe essere uguale a B. Per questo GT richiede anche NOT(Z).

Il quarto è usare il confronto senza aver impostato il circuito in modalità sottrazione. La compare richiede K = 1.

Il quinto è interpretare questi confronti come confronti senza segno. Le formule basate su N e V sono pensate per numeri con segno in complemento a due.

## Riepilogo

Le condizioni di confronto si ottengono così:

```text
EQ = Z
LT = N XOR V
GT = NOT(Z) AND NOT(LT)
```

Dove:

```text
Z = flag Zero
N = flag Negative
V = flag Overflow
```

L'operazione di base è sempre:

```text
A - B
```

Quindi il confronto riutilizza il circuito di sottrazione già costruito nell'ALU.

## Conclusione

In questo articolo abbiamo visto come implementare le operazioni di confronto nella nostra CPU a 8 bit senza usare un comparatore dedicato.

Abbiamo usato il circuito di sottrazione e i flag generati dall'ALU per ricavare tre condizioni:

```text
A = B
A < B
A > B
```

L'uguaglianza si ottiene direttamente dal flag Zero. La condizione A < B si ottiene combinando Negative e Overflow con una XOR. La condizione A > B si ottiene verificando che A non sia uguale a B e non sia minore di B.

Questa soluzione rende l'ALU più coerente e riutilizza circuiti già presenti, invece di aggiungere un comparatore separato.

Nel prossimo articolo passeremo al codice operazione dell'ALU.

Vedremo come usare un decoder per selezionare quale rete deve scrivere sul bus dati e come associare a ogni combinazione di bit un'operazione diversa.
