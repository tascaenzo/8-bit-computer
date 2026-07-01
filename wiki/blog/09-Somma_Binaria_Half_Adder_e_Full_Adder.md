# Somma binaria, half adder e full adder

Negli articoli precedenti abbiamo costruito il primo blocco logico della nostra ALU a 8 bit. Abbiamo implementato operazioni come AND, OR, XOR, NOR, NAND, XNOR e NOT, tutte collegate al bus dati tramite buffer tri-state.

Ora possiamo iniziare a ragionare sulla parte aritmetica della CPU.

La prima operazione aritmetica che vogliamo realizzare è la somma. Per costruirla dobbiamo capire come funziona la somma binaria, come viene gestito il riporto e come si possono combinare porte logiche per ottenere circuiti chiamati half adder e full adder.

In questo articolo resteremo sulla teoria del sommatore. Nel prossimo useremo questi concetti per parlare di numeri negativi e complemento a due.

## Numeri binari e sistema posizionale

La nostra CPU lavora con segnali digitali, quindi con valori che possono essere 0 oppure 1.

Un numero binario è un numero scritto in base 2. Questo significa che ogni cifra può assumere solo due valori:

```text
0
1
```

Come nel sistema decimale, anche il sistema binario è posizionale. Il valore di una cifra dipende dalla posizione in cui si trova.

Nel sistema decimale siamo abituati a ragionare con potenze di 10:

```text
unità      10^0 = 1
decine     10^1 = 10
centinaia  10^2 = 100
```

Nel sistema binario usiamo invece potenze di 2:

```text
2^0 = 1
2^1 = 2
2^2 = 4
2^3 = 8
2^4 = 16
2^5 = 32
2^6 = 64
2^7 = 128
```

In un numero a 8 bit, i pesi delle posizioni sono quindi:

```text
bit:   7   6   5   4   3   2   1   0
peso:128  64  32  16   8   4   2   1
```

Il bit 0 è il bit meno significativo, perché ha peso 1.

Il bit 7 è il bit più significativo, perché ha peso 128 se interpretiamo il numero come valore senza segno.

## Conversione da binario a decimale

Per convertire un numero binario in decimale dobbiamo sommare i pesi delle posizioni in cui compare un 1.

Ad esempio:

```text
00000001
```

Vale 1, perché è acceso solo il bit di peso 1.

Altro esempio:

```text
00000010
```

Vale 2, perché è acceso solo il bit di peso 2.

Altro esempio:

```text
00000101
```

Qui sono accesi i bit di peso 4 e 1:

```text
4 + 1 = 5
```

Quindi:

```text
00000101 = 5
```

Un esempio più grande:

```text
10110010
```

I bit accesi sono:

```text
128 + 32 + 16 + 2 = 178
```

Quindi:

```text
10110010 = 178
```

Questa interpretazione sarà importante quando testeremo i risultati prodotti dal sommatore.

## Somma di due bit

Per costruire un sommatore dobbiamo partire dal caso più semplice: sommare due bit.

Le combinazioni possibili sono quattro:

|   A |   B | Somma |
| --: | --: | ----: |
|   0 |   0 |     0 |
|   0 |   1 |     1 |
|   1 |   0 |     1 |
|   1 |   1 |    10 |

L'ultimo caso è il più interessante.

In binario:

```text
1 + 1 = 10
```

Questo significa che il risultato ha due parti:

- somma = 0
- riporto = 1

Esattamente come nel sistema decimale, quando una colonna supera il valore rappresentabile da una singola cifra, generiamo un riporto verso la colonna successiva.

Nel caso binario, una singola cifra può rappresentare solo 0 o 1. Quando facciamo 1 + 1 otteniamo 2, che in binario si scrive `10`.

## Somma e carry

Per descrivere correttamente la somma di due bit non basta una sola uscita.

Dobbiamo avere:

- S, cioè il bit di somma
- C, cioè il carry, o riporto

La tabella completa diventa:

|   A |   B |   S |   C |
| --: | --: | --: | --: |
|   0 |   0 |   0 |   0 |
|   0 |   1 |   1 |   0 |
|   1 |   0 |   1 |   0 |
|   1 |   1 |   0 |   1 |

Questa tabella è molto importante, perché ci permette di capire quali porte logiche servono per costruire un circuito sommatore.

Guardiamo la colonna S:

```text
0, 1, 1, 0
```

È esattamente la tabella di verità della XOR.

Guardiamo la colonna C:

```text
0, 0, 0, 1
```

È esattamente la tabella di verità della AND.

Quindi per sommare due bit possiamo usare:

```text
S = A XOR B
C = A AND B
```

Questo circuito prende il nome di half adder.

## Half adder

L'half adder è un circuito che somma due bit e produce due uscite:

- somma
- riporto

Ha due ingressi:

- A
- B

e due uscite:

- S
- C

Lo schema logico è:

```text
A ----\
       XOR ---- S
B ----/

A ----\
       AND ---- C
B ----/
```

La XOR produce il bit di somma.

La AND produce il riporto.

La tabella del circuito è:

|   A |   B |   S |   C |
| --: | --: | --: | --: |
|   0 |   0 |   0 |   0 |
|   0 |   1 |   1 |   0 |
|   1 |   0 |   1 |   0 |
|   1 |   1 |   0 |   1 |

Questo circuito funziona perfettamente per sommare due bit isolati.

Il suo limite è che non può ricevere un riporto proveniente da una colonna precedente.

Per costruire un sommatore multi-bit, abbiamo bisogno di qualcosa di più completo: il full adder.

## Perché l'half adder non basta

Quando sommiamo numeri con più bit, ogni colonna può ricevere un riporto dalla colonna precedente.

Facciamo un esempio:

```text
  0011
+ 0101
------
```

Partiamo dal bit meno significativo.

Nel primo bit facciamo:

```text
1 + 1 = 0 con riporto 1
```

Nel bit successivo non dobbiamo sommare solo A e B. Dobbiamo sommare anche il riporto precedente:

```text
1 + 0 + carry
```

Quindi, a partire dalla seconda colonna, il circuito deve avere tre ingressi:

- A
- B
- carry in

L'half adder ha solo due ingressi, quindi non basta.

Serve un full adder.

## Full adder

Il full adder è un circuito che somma tre bit:

- A
- B
- Cin, cioè carry in

Produce due uscite:

- S, cioè la somma
- Cout, cioè carry out

La tabella di verità è:

|   A |   B | Cin |   S | Cout |
| --: | --: | --: | --: | ---: |
|   0 |   0 |   0 |   0 |    0 |
|   0 |   0 |   1 |   1 |    0 |
|   0 |   1 |   0 |   1 |    0 |
|   0 |   1 |   1 |   0 |    1 |
|   1 |   0 |   0 |   1 |    0 |
|   1 |   0 |   1 |   0 |    1 |
|   1 |   1 |   0 |   0 |    1 |
|   1 |   1 |   1 |   1 |    1 |

Il full adder è il blocco fondamentale per costruire sommatori a più bit.

## Costruire un full adder con due half adder

Un full adder può essere costruito usando:

- due half adder
- una porta OR

Il primo half adder somma A e B:

```text
S1 = A XOR B
C1 = A AND B
```

Il secondo half adder somma S1 con Cin:

```text
S = S1 XOR Cin
C2 = S1 AND Cin
```

Il carry finale viene ottenuto facendo OR tra i due riporti:

```text
Cout = C1 OR C2
```

Lo schema concettuale è:

```text
A ----\
       Half Adder ---- S1 ----\
B ----/                         Half Adder ---- S
                         Cin --/

C1 --------------------\
                       OR ---- Cout
C2 --------------------/
```

In questo modo il full adder tiene conto sia dei due bit da sommare sia del riporto proveniente dalla colonna precedente.

## Sommatore multi-bit

Per sommare numeri a più bit possiamo collegare più full adder in cascata.

Ogni full adder si occupa di una colonna della somma.

Il carry out di un full adder diventa il carry in del full adder successivo.

Per un sommatore a 4 bit avremo:

```text
A0, B0, Cin0 -> Full Adder 0 -> S0, Cout0
A1, B1, Cout0 -> Full Adder 1 -> S1, Cout1
A2, B2, Cout1 -> Full Adder 2 -> S2, Cout2
A3, B3, Cout2 -> Full Adder 3 -> S3, Cout3
```

Nel primo full adder, il carry in iniziale normalmente vale 0 quando stiamo facendo una somma semplice.

Il risultato finale sarà:

```text
S3 S2 S1 S0
```

più un eventuale carry out finale.

## Sommatore a 8 bit

La nostra CPU lavora su 8 bit, quindi dovremo sommare due valori a 8 bit:

```text
A7 A6 A5 A4 A3 A2 A1 A0
B7 B6 B5 B4 B3 B2 B1 B0
```

Un sommatore a 8 bit può essere costruito collegando otto full adder in cascata:

```text
FA0 -> FA1 -> FA2 -> FA3 -> FA4 -> FA5 -> FA6 -> FA7
```

Ogni full adder produce un bit del risultato:

```text
S0, S1, S2, S3, S4, S5, S6, S7
```

Il carry si propaga dal bit meno significativo verso il bit più significativo.

Questa struttura prende spesso il nome di ripple carry adder, perché il riporto si propaga da uno stadio al successivo.

Il vantaggio è che è semplice da capire e costruire.

Lo svantaggio è che il risultato finale è disponibile solo dopo che il carry ha attraversato tutti gli stadi. In una CPU molto veloce questo ritardo sarebbe un problema, ma per il nostro progetto didattico non è un limite significativo.

## Esempio di somma binaria

Sommiamo:

```text
00000101 = 5
00000011 = 3
```

La somma è:

```text
  00000101
+ 00000011
----------
  00001000
```

Il risultato è:

```text
00001000 = 8
```

Vediamo cosa succede nei bit meno significativi:

```text
bit 0: 1 + 1 = 0 con carry 1
bit 1: 0 + 1 + carry 1 = 0 con carry 1
bit 2: 1 + 0 + carry 1 = 0 con carry 1
bit 3: 0 + 0 + carry 1 = 1 con carry 0
```

Gli altri bit restano a 0.

Il risultato finale è quindi `00001000`.

## Overflow e carry finale

Quando sommiamo due numeri a 8 bit, il risultato potrebbe richiedere più di 8 bit per essere rappresentato.

Ad esempio:

```text
11111111 = 255
00000001 = 1
```

La somma è:

```text
1 00000000
```

Il risultato richiede 9 bit.

Se consideriamo solo gli 8 bit meno significativi, otteniamo:

```text
00000000
```

ma c'è un carry finale pari a 1.

Questo carry finale ci segnala che il risultato ha superato il range rappresentabile con 8 bit senza segno.

Più avanti vedremo che, quando useremo numeri con segno in complemento a due, il concetto di overflow dovrà essere trattato con più attenzione. Non basterà guardare semplicemente il carry finale.

Per ora ci basta capire che il sommatore può produrre un riporto finale oltre gli 8 bit del risultato.

## Il componente 74283

Nel progetto non costruiremo ogni full adder partendo manualmente da porte XOR, AND e OR.

Useremo invece un integrato dedicato: il 74283.

Il 74283 è un sommatore binario a 4 bit. Contiene già al suo interno la logica necessaria per sommare due numeri a 4 bit con un carry in e un carry out.

Per costruire un sommatore a 8 bit useremo due 74283 collegati in cascata:

- il primo somma i 4 bit meno significativi
- il secondo somma i 4 bit più significativi
- il carry out del primo entra come carry in del secondo

In questo articolo ci interessa soprattutto il principio. Nel prossimo articolo pratico dedicato alla somma e sottrazione vedremo più nel dettaglio come collegare il 74283 all'interno dell'ALU.

## Perché la XOR è così importante

Negli articoli precedenti abbiamo già costruito la rete XOR come operazione logica dell'ALU.

Ora vediamo che la XOR compare anche nel cuore della somma binaria.

Nel caso dell'half adder:

```text
S = A XOR B
C = A AND B
```

La XOR è quindi la porta che calcola il bit di somma tra due ingressi.

Questo è uno dei motivi per cui la XOR è una porta molto importante nei circuiti aritmetici.

Inoltre, nel circuito di sottrazione, la useremo anche per invertire condizionatamente i bit della variabile B.

## Conclusione

In questo articolo abbiamo iniziato la parte aritmetica della nostra ALU.

Siamo partiti dal sistema binario e dal concetto di numero posizionale. Abbiamo poi visto come sommare due bit, introducendo il concetto di carry o riporto.

Da qui siamo arrivati all'half adder, costruito con una porta XOR e una porta AND, e poi al full adder, che aggiunge un ingresso di carry in e può essere realizzato con due half adder e una porta OR.

Infine abbiamo visto come collegare più full adder in cascata per ottenere un sommatore multi-bit e abbiamo introdotto il 74283, un sommatore a 4 bit che useremo nella nostra ALU.

Nel prossimo articolo parleremo di numeri negativi e complemento a due.

Questo passaggio è fondamentale perché ci permetterà di usare lo stesso circuito sommatore anche per eseguire sottrazioni.
