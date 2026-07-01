# ALU: operazioni XOR e NOR

Negli articoli precedenti abbiamo iniziato a costruire l'ALU della nostra CPU a 8 bit partendo dalle prime operazioni logiche: AND e OR.

Abbiamo visto che ogni operazione viene realizzata come una rete a 8 bit: gli ingressi A e B vengono elaborati bit per bit, il risultato passa attraverso un buffer tri-state e infine viene portato sul bus dati solo quando il relativo segnale di enable è attivo.

In questo articolo aggiungiamo due nuove operazioni:

- XOR
- NOR

La XOR sarà molto importante anche più avanti, perché la ritroveremo nel circuito di somma e nel meccanismo che ci permetterà di passare dalla somma alla sottrazione. La NOR, invece, ci permette di introdurre in modo pratico il concetto di uscita negata rispetto a una porta OR.

## L'operazione XOR

XOR significa exclusive OR, cioè OR esclusivo.

È una porta logica a due ingressi. L'uscita vale 1 quando gli ingressi sono diversi tra loro. L'uscita vale 0 quando gli ingressi sono uguali.

La tabella di verità della XOR è:

|   A |   B | OUT |
| --: | --: | --: |
|   0 |   0 |   0 |
|   0 |   1 |   1 |
|   1 |   0 |   1 |
|   1 |   1 |   0 |

Possiamo quindi leggere la XOR come una porta che risponde alla domanda:

```text
A è diverso da B?
```

Se A e B sono diversi, l'uscita è 1.

Se A e B sono uguali, l'uscita è 0.

Questa caratteristica la rende molto utile in diversi circuiti digitali. Nel nostro progetto la useremo sia come operazione logica dell'ALU, sia all'interno del circuito di somma e sottrazione.

## XOR bit a bit

Come per AND e OR, anche la XOR verrà applicata bit per bit sulle variabili A e B.

Le due variabili sono larghe 8 bit:

```text
A7 A6 A5 A4 A3 A2 A1 A0
B7 B6 B5 B4 B3 B2 B1 B0
```

La rete XOR calcolerà:

```text
OUT0 = A0 XOR B0
OUT1 = A1 XOR B1
OUT2 = A2 XOR B2
OUT3 = A3 XOR B3
OUT4 = A4 XOR B4
OUT5 = A5 XOR B5
OUT6 = A6 XOR B6
OUT7 = A7 XOR B7
```

Il risultato sarà un valore a 8 bit.

Facciamo un esempio:

```text
A = 10101010
B = 11110000
```

La XOR bit a bit produce:

```text
A      10101010
B      11110000
XOR    01011010
```

In ogni colonna il risultato vale 1 solo se i due bit sono diversi.

## Il componente 7486

Per costruire la rete XOR useremo l'integrato 7486.

Il 7486 contiene quattro porte XOR a due ingressi. Poiché dobbiamo realizzare una rete a 8 bit, useremo due integrati 7486.

La piedinatura tipica del 7486 è simile a quella già vista per 7408 e 7432:

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

Come sempre, prima di montare il circuito è importante verificare il datasheet del componente specifico.

## Struttura della rete XOR a 8 bit

La rete XOR segue la stessa struttura modulare già vista:

```text
A0 ----\
       XOR ---- OUT0
B0 ----/

A1 ----\
       XOR ---- OUT1
B1 ----/

A2 ----\
       XOR ---- OUT2
B2 ----/

...

A7 ----\
       XOR ---- OUT7
B7 ----/
```

Le otto uscite della rete XOR vengono poi collegate agli ingressi di un buffer tri-state a 8 bit.

Il collegamento generale è:

```text
Switch A ----\
             7486 ---- risultato XOR ---- 74244 ---- bus dati ---- LED
Switch B ----/
```

Anche la rete XOR avrà un enable dedicato. Quando l'enable del buffer è attivo, il risultato della XOR viene trasferito sul bus dati. Quando l'enable non è attivo, la rete resta isolata dal bus.

## Test della rete XOR

Per testare la XOR possiamo partire dalla sua tabella di verità su un singolo bit:

|  A0 |  B0 | XOR |
| --: | --: | --: |
|   0 |   0 |   0 |
|   0 |   1 |   1 |
|   1 |   0 |   1 |
|   1 |   1 |   0 |

Il LED collegato al bit D0 del bus dati deve accendersi solo quando A0 e B0 sono diversi.

Poi possiamo testare l'intera rete a 8 bit.

Primo test:

```text
A = 00000000
B = 00000000
```

Risultato atteso:

```text
XOR = 00000000
```

Secondo test:

```text
A = 11111111
B = 00000000
```

Risultato atteso:

```text
XOR = 11111111
```

Terzo test:

```text
A = 11111111
B = 11111111
```

Risultato atteso:

```text
XOR = 00000000
```

Quarto test:

```text
A = 10101010
B = 01010101
```

Risultato atteso:

```text
XOR = 11111111
```

Quinto test:

```text
A = 10101010
B = 11110000
```

Risultato atteso:

```text
XOR = 01011010
```

Questi test permettono di verificare sia il comportamento logico sia l'ordine corretto dei bit sul bus.

## L'operazione NOR

Dopo la XOR possiamo aggiungere la NOR.

NOR significa NOT OR. In altre parole, è una porta OR con uscita negata.

La porta OR produce 1 quando almeno uno dei due ingressi vale 1. La porta NOR produce il risultato opposto: vale 1 solo quando entrambi gli ingressi valgono 0.

La tabella di verità della NOR è:

|   A |   B |  OR | NOR |
| --: | --: | --: | --: |
|   0 |   0 |   0 |   1 |
|   0 |   1 |   1 |   0 |
|   1 |   0 |   1 |   0 |
|   1 |   1 |   1 |   0 |

Quindi la NOR è alta solo nel caso:

```text
A = 0
B = 0
```

L'espressione booleana può essere scritta come:

```text
OUT = NOT(A OR B)
```

oppure:

```text
OUT = ¬(A + B)
```

Il piccolo cerchio che spesso si vede sul simbolo della porta NOR indica proprio la negazione dell'uscita.

## NOR come OR negata

È utile confrontare OR e NOR.

La OR ha questa tabella:

|   A |   B |  OR |
| --: | --: | --: |
|   0 |   0 |   0 |
|   0 |   1 |   1 |
|   1 |   0 |   1 |
|   1 |   1 |   1 |

La NOR è semplicemente il contrario dell'uscita OR:

|   A |   B | NOR |
| --: | --: | --: |
|   0 |   0 |   1 |
|   0 |   1 |   0 |
|   1 |   0 |   0 |
|   1 |   1 |   0 |

Quindi potremmo costruire una NOR anche usando una porta OR seguita da una porta NOT:

```text
A ----\
       OR ---- NOT ---- NOR
B ----/
```

Nel progetto, però, useremo direttamente un integrato che contiene porte NOR.

## Il componente 7402

Per realizzare la rete NOR useremo il 7402.

Il 7402 contiene quattro porte NOR a due ingressi. Per ottenere una rete a 8 bit useremo quindi due integrati 7402.

A differenza di 7408, 7432 e 7486, la piedinatura del 7402 è organizzata in modo diverso. Questo è un dettaglio importante da non sottovalutare.

Una piedinatura tipica è:

| Porta | Ingressi       | Uscita |
| ----- | -------------- | -----: |
| 1     | pin 2, pin 3   |  pin 1 |
| 2     | pin 5, pin 6   |  pin 4 |
| 3     | pin 8, pin 9   | pin 10 |
| 4     | pin 11, pin 12 | pin 13 |

Inoltre:

| Pin | Collegamento |
| --: | ------------ |
|  14 | +5 V         |
|   7 | GND          |

Proprio perché la disposizione delle porte è diversa, è importante controllare con attenzione i collegamenti prima di alimentare il circuito.

## Struttura della rete NOR a 8 bit

La rete NOR a 8 bit segue lo stesso principio delle altre reti logiche:

```text
A0 ----\
       NOR ---- OUT0
B0 ----/

A1 ----\
       NOR ---- OUT1
B1 ----/

A2 ----\
       NOR ---- OUT2
B2 ----/

...

A7 ----\
       NOR ---- OUT7
B7 ----/
```

Le uscite OUT0-OUT7 entrano in un buffer tri-state.

Il collegamento generale è:

```text
Switch A ----\
             7402 ---- risultato NOR ---- 74244 ---- bus dati ---- LED
Switch B ----/
```

Anche in questo caso il buffer avrà un enable dedicato, che permetterà alla rete NOR di scrivere sul bus solo quando selezionata.

## Test della rete NOR

Partiamo dal test su un singolo bit:

|  A0 |  B0 | NOR |
| --: | --: | --: |
|   0 |   0 |   1 |
|   0 |   1 |   0 |
|   1 |   0 |   0 |
|   1 |   1 |   0 |

Il LED collegato a D0 deve accendersi solo quando A0 e B0 sono entrambi a 0.

Poi possiamo testare l'intera rete a 8 bit.

Primo test:

```text
A = 00000000
B = 00000000
```

Risultato atteso:

```text
NOR = 11111111
```

Tutti i LED del bus devono accendersi.

Secondo test:

```text
A = 11111111
B = 00000000
```

Risultato atteso:

```text
NOR = 00000000
```

Terzo test:

```text
A = 00000000
B = 11111111
```

Risultato atteso:

```text
NOR = 00000000
```

Quarto test:

```text
A = 10101010
B = 01010101
```

Risultato atteso:

```text
NOR = 00000000
```

Quinto test:

```text
A = 00001111
B = 00110000
```

Prima calcoliamo l'OR:

```text
OR = 00111111
```

Poi neghiamo il risultato:

```text
NOR = 11000000
```

Questo tipo di test è utile perché ci obbliga a ragionare sulla NOR come OR negata.

## Confronto tra OR e NOR

Una prova interessante consiste nell'usare gli stessi ingressi A e B e osservare prima il risultato della OR, poi quello della NOR.

Ad esempio:

```text
A = 00000000
B = 00000000
```

La OR produce:

```text
OR = 00000000
```

La NOR produce:

```text
NOR = 11111111
```

Altro esempio:

```text
A = 11111111
B = 00000000
```

La OR produce:

```text
OR = 11111111
```

La NOR produce:

```text
NOR = 00000000
```

Questo confronto rende evidente che la NOR è l'inversione dell'OR.

Naturalmente, per fare questo test sulla board, bisogna ricordarsi di abilitare una sola rete alla volta:

```text
enable OR  = 0, enable NOR = 1 -> vediamo OR
enable OR  = 1, enable NOR = 0 -> vediamo NOR
```

Non dobbiamo mai abilitare entrambe contemporaneamente.

## Convivenza delle reti nell'ALU

A questo punto la nostra ALU contiene quattro reti logiche:

```text
AND
OR
XOR
NOR
```

Tutte ricevono gli stessi ingressi A e B.

Tutte calcolano continuamente il proprio risultato.

Tutte hanno un buffer tri-state dedicato.

Solo la rete selezionata deve poter scrivere sul bus dati.

La struttura complessiva può essere vista così:

```text
          rete AND ---- buffer AND ----\
          rete OR  ---- buffer OR  -----\
A, B ---> rete XOR ---- buffer XOR ------ bus dati
          rete NOR ---- buffer NOR -----/
```

Questa organizzazione modulare ci permette di continuare ad aggiungere operazioni senza cambiare il principio generale della ALU.

## Importanza della XOR nei prossimi circuiti

Tra le due operazioni viste in questo articolo, la XOR avrà un ruolo particolarmente importante.

Nel circuito di somma binaria, la XOR verrà usata per calcolare il bit di somma tra due ingressi.

Inoltre, quando costruiremo il circuito di somma e sottrazione, useremo una rete di XOR per invertire condizionatamente i bit della variabile B. Questo ci permetterà di trasformare una somma in una sottrazione usando il complemento a due.

Quindi la XOR non è solo una delle operazioni disponibili nell'ALU, ma anche un componente interno fondamentale per costruire funzioni più complesse.

## Errori comuni

Durante il montaggio di XOR e NOR ci sono alcuni errori da evitare.

Il primo è confondere la XOR con la OR. La OR produce 1 anche quando entrambi gli ingressi sono 1. La XOR invece, nel caso 1 e 1, produce 0.

Il secondo è dimenticare che la NOR è una OR negata. Se l'OR produce 1, la NOR produce 0. Se l'OR produce 0, la NOR produce 1.

Il terzo è usare la piedinatura sbagliata per il 7402. A differenza di altri integrati, nel 7402 alcune uscite si trovano prima degli ingressi nella disposizione dei pin.

Il quarto è lasciare attivi più buffer contemporaneamente. Ogni rete deve avere il proprio enable e durante i test bisogna abilitarne una sola.

Il quinto è non verificare l'ordine dei bit. Come sempre, OUT0 deve finire su D0, OUT1 su D1 e così via.

## Conclusione

In questo articolo abbiamo aggiunto due nuove operazioni alla nostra ALU a 8 bit: XOR e NOR.

Abbiamo visto che la XOR produce 1 quando i due ingressi sono diversi, mentre la NOR è una OR con uscita negata. Abbiamo analizzato i componenti 7486 e 7402, costruendo reti a 8 bit con due integrati per ciascuna operazione.

Abbiamo poi collegato entrambe le reti al bus dati tramite buffer tri-state dedicati, mantenendo la stessa architettura modulare già usata per AND e OR.

A questo punto la nostra ALU dispone delle operazioni:

```text
AND
OR
XOR
NOR
```

Nel prossimo articolo completeremo il gruppo delle operazioni logiche di base aggiungendo NAND, XNOR e NOT.

Queste operazioni ci permetteranno di consolidare il concetto di uscita negata e di vedere come alcune funzioni possono essere costruite combinando porte già disponibili.
