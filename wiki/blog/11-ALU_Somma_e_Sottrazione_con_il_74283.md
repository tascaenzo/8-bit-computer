# ALU: somma e sottrazione con il 74283

Negli articoli precedenti abbiamo introdotto la parte aritmetica della nostra ALU. Abbiamo visto come funziona la somma binaria, come si costruiscono half adder e full adder, e come il complemento a due permetta di trasformare una sottrazione in una somma.

Ora possiamo passare alla parte pratica: costruire nella nostra ALU un circuito capace di eseguire sia la somma sia la sottrazione tra due valori a 8 bit.

Per farlo useremo:

- due sommatori 74283
- due integrati 7486 per le porte XOR
- un buffer tri-state a 8 bit
- un segnale di controllo K per scegliere tra somma e sottrazione

Il risultato finale verrà inviato al bus dati, come per le altre operazioni dell'ALU.

## Obiettivo del circuito

Vogliamo costruire un modulo dell'ALU capace di eseguire due operazioni:

```text
A + B
A - B
```

Le variabili A e B sono entrambe larghe 8 bit:

```text
A7 A6 A5 A4 A3 A2 A1 A0
B7 B6 B5 B4 B3 B2 B1 B0
```

Il risultato sarà anch'esso un valore a 8 bit:

```text
S7 S6 S5 S4 S3 S2 S1 S0
```

Per selezionare l'operazione useremo un segnale chiamato K:

```text
K = 0 -> somma
K = 1 -> sottrazione
```

Il circuito userà sempre un sommatore. La differenza tra somma e sottrazione sarà ottenuta modificando l'ingresso B e il carry iniziale.

## Richiamo: sottrazione con complemento a due

Nel complemento a due possiamo scrivere:

```text
A - B = A + complemento_a_due(B)
```

Il complemento a due di B si ottiene con due passaggi:

1. invertire tutti i bit di B
2. sommare 1

Quindi:

```text
A - B = A + NOT(B) + 1
```

L'idea del circuito è sfruttare questa proprietà.

Quando vogliamo fare una somma, B deve entrare nel sommatore senza modifiche e il carry iniziale deve essere 0.

Quando vogliamo fare una sottrazione, B deve essere invertito e il carry iniziale deve essere 1.

Queste due condizioni saranno controllate dallo stesso segnale K.

## Il ruolo del segnale K

Il segnale K decide se il circuito lavora in modalità somma o in modalità sottrazione.

La tabella è:

|   K | Operazione  | B verso il sommatore | Carry iniziale |
| --: | ----------- | -------------------- | -------------: |
|   0 | Somma       | B                    |              0 |
|   1 | Sottrazione | NOT B                |              1 |

Per ottenere questo comportamento useremo la XOR.

La XOR ha una proprietà molto utile:

```text
B XOR 0 = B
B XOR 1 = NOT B
```

Quindi, se colleghiamo ogni bit di B a una porta XOR insieme al segnale K, otteniamo:

```text
B0' = B0 XOR K
B1' = B1 XOR K
B2' = B2 XOR K
B3' = B3 XOR K
B4' = B4 XOR K
B5' = B5 XOR K
B6' = B6 XOR K
B7' = B7 XOR K
```

Dove B' è il valore che entrerà nel sommatore.

Se K vale 0, B' è uguale a B.

Se K vale 1, B' è uguale a NOT B.

Poi colleghiamo K anche al carry in del primo sommatore.

In questo modo, con un solo segnale, otteniamo sia l'inversione di B sia il +1 necessario al complemento a due.

## Il componente 74283

Per costruire il sommatore useremo il 74283.

Il 74283 è un sommatore binario a 4 bit. Prende in ingresso due numeri a 4 bit, un carry in, e produce una somma a 4 bit più un carry out.

In forma logica possiamo rappresentarlo così:

```text
A3 A2 A1 A0
B3 B2 B1 B0
Cin
 |
 v
74283 -> S3 S2 S1 S0, Cout
```

Poiché la nostra ALU lavora a 8 bit, useremo due 74283 collegati in cascata:

- il primo per i 4 bit meno significativi
- il secondo per i 4 bit più significativi

Il carry out del primo 74283 verrà collegato al carry in del secondo.

## Sommatore a 8 bit con due 74283

Dividiamo le variabili A e B in due gruppi:

```text
bit bassi: A0 A1 A2 A3, B0 B1 B2 B3
bit alti:  A4 A5 A6 A7, B4 B5 B6 B7
```

Il primo 74283 somma i bit bassi:

```text
A0-A3
B0'-B3'
Cin = K
```

Produce:

```text
S0-S3
Cout basso
```

Il secondo 74283 somma i bit alti:

```text
A4-A7
B4'-B7'
Cin = Cout del primo 74283
```

Produce:

```text
S4-S7
Cout finale
```

Il risultato complessivo è:

```text
S7 S6 S5 S4 S3 S2 S1 S0
```

Il carry out finale verrà usato più avanti per costruire i flag.

## Schema generale del circuito

Lo schema concettuale del modulo somma/sottrazione è:

```text
B0-B7 ---- XOR con K ----\
                          \
A0-A7 ---------------------> 74283 + 74283 ---- risultato ---- buffer ---- bus dati

K -------------------------> carry in iniziale
```

Più in dettaglio:

```text
B0 ---- XOR ---- B0' ----\
B1 ---- XOR ---- B1' -----\
B2 ---- XOR ---- B2' ------> primo 74283
B3 ---- XOR ---- B3' -----/

A0 -----------------------\
A1 ------------------------> primo 74283
A2 -----------------------/
A3 ----------------------/

K -----------------------> Cin primo 74283
```

Il carry out del primo passa al secondo:

```text
Cout primo 74283 -> Cin secondo 74283
```

Il secondo 74283 gestisce i bit 4-7.

## Componenti necessari

Per realizzare il circuito servono:

| Componente | Quantità | Funzione                              |
| ---------- | -------: | ------------------------------------- |
| 74283      |        2 | sommatori a 4 bit                     |
| 7486       |        2 | XOR per invertire condizionatamente B |
| 74244      |        1 | buffer tri-state verso il bus dati    |
| switch A   |  8 linee | variabile A                           |
| switch B   |  8 linee | variabile B                           |
| segnale K  |  1 linea | selezione somma/sottrazione           |
| LED bus    |        8 | visualizzazione del risultato         |

I due 7486 forniscono otto porte XOR, una per ogni bit di B.

I due 74283 realizzano il sommatore a 8 bit.

Il 74244 collega il risultato al bus dati solo quando il modulo somma/sottrazione è selezionato.

## Collegamento degli ingressi A

I bit della variabile A entrano direttamente nei sommatori.

Non vengono modificati.

Quindi:

```text
A0 -> ingresso A del primo 74283
A1 -> ingresso A del primo 74283
A2 -> ingresso A del primo 74283
A3 -> ingresso A del primo 74283
A4 -> ingresso A del secondo 74283
A5 -> ingresso A del secondo 74283
A6 -> ingresso A del secondo 74283
A7 -> ingresso A del secondo 74283
```

A rappresenta sempre il primo operando dell'operazione.

Nel caso di somma:

```text
A + B
```

Nel caso di sottrazione:

```text
A - B
```

## Collegamento degli ingressi B

I bit della variabile B non entrano direttamente nei sommatori.

Prima passano attraverso una rete di XOR controllata da K.

Quindi:

```text
B0 -> XOR con K -> B0'
B1 -> XOR con K -> B1'
B2 -> XOR con K -> B2'
B3 -> XOR con K -> B3'
B4 -> XOR con K -> B4'
B5 -> XOR con K -> B5'
B6 -> XOR con K -> B6'
B7 -> XOR con K -> B7'
```

Le uscite B0'-B7' entrano nei due 74283.

Se K = 0:

```text
B' = B
```

Se K = 1:

```text
B' = NOT B
```

Questa è la parte del circuito che ci permette di passare dalla somma alla sottrazione.

## Collegamento del carry iniziale

Il carry in del primo 74283 viene collegato al segnale K.

Questo significa:

```text
K = 0 -> carry iniziale = 0
K = 1 -> carry iniziale = 1
```

Quando facciamo una somma normale, il carry iniziale deve essere 0.

Quando facciamo una sottrazione, dobbiamo sommare 1 dopo aver invertito B, quindi il carry iniziale deve essere 1.

Collegare K al carry in iniziale risolve questo problema in modo semplice ed elegante.

## Collegamento del risultato al bus dati

Le uscite dei due 74283 formano il risultato a 8 bit:

```text
S0 S1 S2 S3 S4 S5 S6 S7
```

Queste uscite non vengono collegate direttamente al bus dati.

Come per tutte le altre reti dell'ALU, passano prima attraverso un buffer tri-state.

Il collegamento è:

```text
S0 -> buffer -> D0
S1 -> buffer -> D1
S2 -> buffer -> D2
S3 -> buffer -> D3
S4 -> buffer -> D4
S5 -> buffer -> D5
S6 -> buffer -> D6
S7 -> buffer -> D7
```

Il buffer avrà un enable dedicato.

Quando l'enable del modulo somma/sottrazione è attivo, il risultato viene mostrato sul bus dati.

Quando l'enable non è attivo, il modulo resta isolato dal bus.

## Test della somma

Per testare la somma impostiamo:

```text
K = 0
```

In questo modo:

```text
B XOR K = B
carry iniziale = 0
```

Il circuito calcola:

```text
A + B
```

Primo test:

```text
A = 00000001   1
B = 00000001   1
```

Risultato atteso:

```text
00000010   2
```

Secondo test:

```text
A = 00000010   2
B = 00000011   3
```

Risultato atteso:

```text
00000101   5
```

Terzo test:

```text
A = 00000101   5
B = 00000001   1
```

Risultato atteso:

```text
00000110   6
```

Quarto test:

```text
A = 00000111   7
B = 00000001   1
```

Risultato atteso:

```text
00001000   8
```

Questi test verificano che il carry si propaghi correttamente tra i bit.

## Test della somma con carry finale

Un test interessante è:

```text
A = 11111111   255 senza segno
B = 00000001   1
K = 0
```

La somma reale è:

```text
255 + 1 = 256
```

Ma 256 richiede 9 bit:

```text
1 00000000
```

Sul bus dati a 8 bit vedremo:

```text
00000000
```

Il carry out finale sarà 1.

Questo carry ci segnala che, interpretando i numeri come senza segno, il risultato è uscito dal range rappresentabile con 8 bit.

Più avanti vedremo che, per i numeri con segno, il flag di overflow dovrà essere calcolato in modo diverso.

## Test della sottrazione

Per testare la sottrazione impostiamo:

```text
K = 1
```

In questo modo:

```text
B XOR K = NOT B
carry iniziale = 1
```

Il circuito calcola:

```text
A + NOT(B) + 1
```

cioè:

```text
A - B
```

Primo test:

```text
A = 00000101   5
B = 00000001   1
```

Risultato atteso:

```text
00000100   4
```

Secondo test:

```text
A = 00000110   6
B = 00000011   3
```

Risultato atteso:

```text
00000011   3
```

Terzo test:

```text
A = 00001101   13
B = 00000001   1
```

Risultato atteso:

```text
00001100   12
```

Questi test confermano che il circuito sta eseguendo correttamente la sottrazione tramite complemento a due.

## Test: 0 - 1

Un test molto utile è:

```text
A = 00000000   0
B = 00000001   1
K = 1
```

Il circuito calcola:

```text
0 - 1
```

Il risultato sul bus sarà:

```text
11111111
```

Se interpretiamo questo valore senza segno, vale 255.

Se lo interpretiamo in complemento a due, vale -1.

Questo test mostra ancora una volta che la stessa sequenza di bit può avere significati diversi a seconda della rappresentazione scelta.

Nel nostro progetto, quando lavoreremo con numeri con segno, interpreteremo:

```text
11111111 = -1
```

## Carry out e flag futuri

Il carry out finale del secondo 74283 è un segnale importante.

Nel caso della somma senza segno può indicare che il risultato ha superato il range a 8 bit.

Nel caso della sottrazione, però, il suo significato cambia e va interpretato con più attenzione. In molte architetture si parla di borrow, cioè prestito, quando si analizza una sottrazione.

Per questo motivo non ci limiteremo a usare direttamente il carry out come unico indicatore di errore.

Nei prossimi articoli costruiremo una rete di flag più completa, capace di generare:

```text
Carry / Borrow
Negative
Zero
Overflow
```

Questi flag permetteranno alla CPU di capire meglio lo stato del risultato prodotto dall'ALU.

## Enable del modulo somma/sottrazione

Come per le altre reti dell'ALU, anche il modulo somma/sottrazione deve avere un buffer tri-state verso il bus dati.

Questo significa che il risultato del sommatore non deve essere sempre visibile sul bus.

Il modulo sarà collegato al bus solo quando il suo enable sarà attivo.

Durante i test manuali possiamo controllare questo enable direttamente.

Più avanti, quando implementeremo il codice operazione dell'ALU, l'enable del modulo aritmetico verrà generato automaticamente.

In quel momento dovremo distinguere tra:

```text
ADD -> K = 0, enable sommatore attivo
SUB -> K = 1, enable sommatore attivo
COMPARE -> K = 1, sommatore usato per generare flag
```

Il circuito sommatore sarà quindi riutilizzato anche per le operazioni di confronto.

## Riepilogo del funzionamento

Il modulo somma/sottrazione funziona così:

```text
K = 0
B XOR K = B
carry in = 0
risultato = A + B
```

```text
K = 1
B XOR K = NOT B
carry in = 1
risultato = A + NOT(B) + 1
risultato = A - B
```

Le uscite dei 74283 producono il risultato a 8 bit.

Il buffer tri-state decide se questo risultato può essere trasferito al bus dati.

Il carry out finale verrà usato per costruire i flag.

## Errori comuni

Durante il montaggio del modulo somma/sottrazione ci sono diversi errori possibili.

Il primo è non collegare K a tutte le porte XOR. Ogni bit di B deve essere XORato con lo stesso segnale K.

Il secondo è dimenticare di collegare K al carry in iniziale del primo 74283. Senza questo collegamento, la sottrazione non esegue il +1 del complemento a due.

Il terzo è invertire l'ordine dei bit tra i due 74283. Bisogna distinguere chiaramente i quattro bit meno significativi dai quattro bit più significativi.

Il quarto è non collegare il carry out del primo 74283 al carry in del secondo. Senza questo collegamento, il sommatore a 8 bit non funziona correttamente.

Il quinto è collegare direttamente le uscite del sommatore al bus dati senza buffer tri-state.

Il sesto è interpretare sempre il risultato come numero senza segno. Dopo l'introduzione del complemento a due, alcuni risultati devono essere letti come numeri con segno.

## Conclusione

In questo articolo abbiamo costruito il modulo aritmetico principale della nostra ALU: il circuito di somma e sottrazione a 8 bit.

Abbiamo usato due 74283 per ottenere un sommatore a 8 bit, una rete di XOR per modificare l'ingresso B in base al segnale K, e lo stesso K come carry iniziale.

In questo modo, con un unico circuito, possiamo eseguire sia:

```text
A + B
```

sia:

```text
A - B
```

Il risultato viene poi collegato al bus dati tramite un buffer tri-state, rispettando la stessa architettura modulare già usata per le operazioni logiche.

Nel prossimo articolo introdurremo i flag della CPU.

Vedremo come ricavare informazioni importanti dal risultato dell'ALU: se è zero, se è negativo, se ha generato un carry o borrow, e se è uscito dal range rappresentabile con 8 bit con segno.
