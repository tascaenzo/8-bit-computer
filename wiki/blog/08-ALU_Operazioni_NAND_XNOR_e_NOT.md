# ALU: operazioni NAND, XNOR e NOT

Negli articoli precedenti abbiamo costruito le prime reti logiche della nostra ALU a 8 bit: AND, OR, XOR e NOR. Abbiamo visto che ogni rete segue la stessa struttura generale: riceve in ingresso le variabili A e B, calcola un risultato a 8 bit e lo invia al bus dati tramite un buffer tri-state.

In questo articolo completiamo il gruppo delle operazioni logiche di base aggiungendo:

- NAND
- XNOR
- NOT

Queste tre operazioni sono strettamente legate a quelle già viste. NAND è una AND negata, XNOR è una XOR negata, mentre NOT è l'operazione di negazione applicata a un singolo ingresso.

## Il concetto di negazione

Prima di analizzare le singole reti, è utile richiamare il concetto di negazione logica.

La negazione prende un valore logico e lo inverte:

| Ingresso | Uscita |
| -------: | -----: |
|        0 |      1 |
|        1 |      0 |

Quindi:

```text
NOT 0 = 1
NOT 1 = 0
```

Molte porte logiche possono essere viste come una porta già nota seguita da una negazione.

Ad esempio:

```text
NAND = NOT(AND)
NOR  = NOT(OR)
XNOR = NOT(XOR)
```

Nei simboli logici, la negazione viene spesso indicata con un piccolo cerchio sull'uscita della porta. Questo cerchio significa che il risultato è invertito.

## Operazione NAND

NAND significa NOT AND.

È una porta AND con l'uscita negata. Quindi produce il risultato opposto rispetto alla AND.

La tabella di verità della NAND è:

|   A |   B | AND | NAND |
| --: | --: | --: | ---: |
|   0 |   0 |   0 |    1 |
|   0 |   1 |   0 |    1 |
|   1 |   0 |   0 |    1 |
|   1 |   1 |   1 |    0 |

La NAND produce 0 solo quando entrambi gli ingressi sono 1.

In tutti gli altri casi produce 1.

L'espressione booleana può essere scritta come:

```text
OUT = NOT(A AND B)
```

oppure:

```text
OUT = ¬(A · B)
```

## NAND bit a bit

Come le altre operazioni dell'ALU, anche la NAND verrà applicata bit per bit sulle variabili A e B.

Le variabili sono:

```text
A7 A6 A5 A4 A3 A2 A1 A0
B7 B6 B5 B4 B3 B2 B1 B0
```

La rete NAND calcolerà:

```text
OUT0 = NAND(A0, B0)
OUT1 = NAND(A1, B1)
OUT2 = NAND(A2, B2)
OUT3 = NAND(A3, B3)
OUT4 = NAND(A4, B4)
OUT5 = NAND(A5, B5)
OUT6 = NAND(A6, B6)
OUT7 = NAND(A7, B7)
```

Facciamo un esempio:

```text
A = 10101010
B = 11110000
```

Prima calcoliamo l'AND:

```text
A      10101010
B      11110000
AND    10100000
```

Poi neghiamo il risultato:

```text
NAND   01011111
```

Quindi:

```text
10101010 NAND 11110000 = 01011111
```

## Il componente 7400

Per realizzare la rete NAND useremo l'integrato 7400.

Il 7400 contiene quattro porte NAND a due ingressi. Per una rete a 8 bit servono otto porte, quindi useremo due integrati 7400.

La piedinatura tipica del 7400 è simile a quella di altri integrati con quattro porte a due ingressi:

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

Come sempre, è importante controllare il datasheet del componente prima di procedere con il cablaggio.

## Struttura della rete NAND a 8 bit

La rete NAND segue lo stesso schema delle altre reti logiche:

```text
A0 ----\
       NAND ---- OUT0
B0 ----/

A1 ----\
       NAND ---- OUT1
B1 ----/

...

A7 ----\
       NAND ---- OUT7
B7 ----/
```

Le uscite delle porte NAND entrano poi in un buffer tri-state a 8 bit, che collega la rete al bus dati solo quando l'enable è attivo.

Lo schema generale è:

```text
Switch A ----\
             7400 ---- risultato NAND ---- 74244 ---- bus dati ---- LED
Switch B ----/
```

Anche la NAND avrà un proprio segnale di enable dedicato.

## Test della rete NAND

Per un singolo bit, la tabella attesa è:

|  A0 |  B0 | NAND |
| --: | --: | ---: |
|   0 |   0 |    1 |
|   0 |   1 |    1 |
|   1 |   0 |    1 |
|   1 |   1 |    0 |

Il LED collegato a D0 deve spegnersi solo quando A0 e B0 sono entrambi a 1.

Per la rete a 8 bit possiamo fare alcuni test:

```text
A = 00000000
B = 00000000
NAND = 11111111
```

```text
A = 11111111
B = 11111111
NAND = 00000000
```

```text
A = 11111111
B = 00000000
NAND = 11111111
```

```text
A = 10101010
B = 11110000
NAND = 01011111
```

Questi test confermano che la NAND è effettivamente l'inversione dell'AND.

## Operazione XNOR

XNOR significa NOT XOR.

È una porta XOR con uscita negata.

La XOR produce 1 quando gli ingressi sono diversi. La XNOR produce 1 quando gli ingressi sono uguali.

La tabella di verità è:

|   A |   B | XOR | XNOR |
| --: | --: | --: | ---: |
|   0 |   0 |   0 |    1 |
|   0 |   1 |   1 |    0 |
|   1 |   0 |   1 |    0 |
|   1 |   1 |   0 |    1 |

Quindi possiamo leggere la XNOR come una porta che risponde alla domanda:

```text
A è uguale a B?
```

Se A e B sono uguali, l'uscita è 1.

Se A e B sono diversi, l'uscita è 0.

Questa caratteristica rende la XNOR utile nei circuiti di confronto, anche se nel nostro progetto le operazioni di confronto principali verranno ricavate dai flag generati dalla sottrazione.

## XNOR bit a bit

Anche la XNOR viene applicata bit per bit:

```text
OUT0 = XNOR(A0, B0)
OUT1 = XNOR(A1, B1)
OUT2 = XNOR(A2, B2)
OUT3 = XNOR(A3, B3)
OUT4 = XNOR(A4, B4)
OUT5 = XNOR(A5, B5)
OUT6 = XNOR(A6, B6)
OUT7 = XNOR(A7, B7)
```

Esempio:

```text
A = 10101010
B = 11110000
```

Prima calcoliamo la XOR:

```text
A      10101010
B      11110000
XOR    01011010
```

Poi neghiamo:

```text
XNOR   10100101
```

Quindi:

```text
10101010 XNOR 11110000 = 10100101
```

## Come realizzare la XNOR

Per realizzare una rete XNOR potremmo usare un integrato dedicato che contiene porte XNOR.

Nel nostro progetto, però, possiamo costruire la XNOR partendo dalla rete XOR già disponibile e aggiungendo una negazione in uscita.

Lo schema concettuale è:

```text
A ----\
       XOR ---- NOT ---- XNOR
B ----/
```

A livello a 8 bit, questo significa che prendiamo le otto uscite della rete XOR, le facciamo passare attraverso otto porte NOT e poi inviamo il risultato a un buffer tri-state dedicato.

Questa soluzione è utile perché ci permette di riutilizzare concetti e componenti già presenti nel progetto.

Per realizzare le porte NOT useremo integrati 7404.

## Il componente 7404

Il 7404 contiene sei porte NOT.

Ogni porta NOT ha un ingresso e un'uscita:

```text
ingresso 0 -> uscita 1
ingresso 1 -> uscita 0
```

Poiché per invertire 8 bit servono otto porte NOT, avremo bisogno di due integrati 7404. Ogni 7404 contiene sei inverter, quindi in totale avremo dodici porte NOT disponibili, ma ne useremo otto per la rete XNOR o per altre funzioni.

Una piedinatura tipica del 7404 è:

| Porta | Ingresso | Uscita |
| ----- | -------: | -----: |
| 1     |    pin 1 |  pin 2 |
| 2     |    pin 3 |  pin 4 |
| 3     |    pin 5 |  pin 6 |
| 4     |    pin 9 |  pin 8 |
| 5     |   pin 11 | pin 10 |
| 6     |   pin 13 | pin 12 |

Inoltre:

| Pin | Collegamento |
| --: | ------------ |
|  14 | +5 V         |
|   7 | GND          |

## Struttura della rete XNOR a 8 bit

La rete XNOR può quindi essere costruita così:

```text
A0 ----\
       XOR ---- NOT ---- OUT0
B0 ----/

A1 ----\
       XOR ---- NOT ---- OUT1
B1 ----/

...

A7 ----\
       XOR ---- NOT ---- OUT7
B7 ----/
```

Le uscite OUT0-OUT7 entrano in un buffer tri-state, che le collega al bus dati solo quando l'enable della rete XNOR è attivo.

Lo schema generale è:

```text
Switch A ----\
             7486 ---- 7404 ---- risultato XNOR ---- 74244 ---- bus dati
Switch B ----/
```

## Test della rete XNOR

Per un singolo bit, la tabella attesa è:

|  A0 |  B0 | XNOR |
| --: | --: | ---: |
|   0 |   0 |    1 |
|   0 |   1 |    0 |
|   1 |   0 |    0 |
|   1 |   1 |    1 |

Il LED collegato a D0 deve accendersi quando A0 e B0 sono uguali.

Test a 8 bit:

```text
A = 00000000
B = 00000000
XNOR = 11111111
```

```text
A = 11111111
B = 11111111
XNOR = 11111111
```

```text
A = 11111111
B = 00000000
XNOR = 00000000
```

```text
A = 10101010
B = 01010101
XNOR = 00000000
```

```text
A = 10101010
B = 11110000
XNOR = 10100101
```

Questi test confermano che la XNOR è l'inversione della XOR.

## Operazione NOT

L'ultima operazione logica che aggiungiamo in questo articolo è la NOT.

A differenza di AND, OR, XOR, NOR, NAND e XNOR, la NOT lavora su un solo ingresso.

Nel nostro progetto applicheremo la NOT alla variabile A.

La tabella di verità della NOT è:

|   A | OUT |
| --: | --: |
|   0 |   1 |
|   1 |   0 |

Quindi:

```text
OUT = NOT A
```

A livello a 8 bit, ogni bit di A viene invertito:

```text
OUT0 = NOT A0
OUT1 = NOT A1
OUT2 = NOT A2
OUT3 = NOT A3
OUT4 = NOT A4
OUT5 = NOT A5
OUT6 = NOT A6
OUT7 = NOT A7
```

## NOT bit a bit

Facciamo un esempio:

```text
A = 10101010
```

Applicando la NOT otteniamo:

```text
NOT A = 01010101
```

Ogni 1 diventa 0 e ogni 0 diventa 1.

Un altro esempio:

```text
A = 11110000
NOT A = 00001111
```

La variabile B non viene usata in questa operazione.

Questo è un punto importante: non tutte le operazioni dell'ALU devono necessariamente usare entrambi gli ingressi A e B. Alcune operazioni, come NOT, possono lavorare su una sola variabile.

## Struttura della rete NOT a 8 bit

Per costruire la rete NOT useremo due integrati 7404, in modo da avere almeno otto inverter.

Lo schema logico è:

```text
A0 ---- NOT ---- OUT0
A1 ---- NOT ---- OUT1
A2 ---- NOT ---- OUT2
A3 ---- NOT ---- OUT3
A4 ---- NOT ---- OUT4
A5 ---- NOT ---- OUT5
A6 ---- NOT ---- OUT6
A7 ---- NOT ---- OUT7
```

Le uscite OUT0-OUT7 vengono poi collegate a un buffer tri-state dedicato.

Lo schema generale è:

```text
Switch A ---- 7404 ---- risultato NOT ---- 74244 ---- bus dati ---- LED
```

La variabile B non entra in questa rete.

## Test della rete NOT

Per testare la rete NOT possiamo usare alcuni valori semplici.

Primo test:

```text
A = 00000000
NOT A = 11111111
```

Tutti i LED del bus devono accendersi.

Secondo test:

```text
A = 11111111
NOT A = 00000000
```

Tutti i LED devono spegnersi.

Terzo test:

```text
A = 10101010
NOT A = 01010101
```

Quarto test:

```text
A = 11110000
NOT A = 00001111
```

Durante questi test bisogna abilitare solo il buffer della rete NOT e disabilitare tutti gli altri buffer dell'ALU.

## Reti logiche presenti nell'ALU

A questo punto la nostra ALU dispone di un insieme abbastanza completo di operazioni logiche:

```text
AND
OR
XOR
NOR
NAND
XNOR
NOT
```

Tutte queste reti seguono lo stesso principio generale:

```text
ingressi -> rete logica -> buffer tri-state -> bus dati
```

Per le operazioni a due ingressi, usiamo A e B.

Per la NOT, usiamo solo A.

Ogni rete ha il proprio buffer e il proprio segnale di enable. In futuro, questi enable verranno collegati al circuito del codice operazione, così sarà possibile selezionare automaticamente quale operazione eseguire.

## Confronto tra operazioni e negazioni

Possiamo riassumere le relazioni tra le operazioni logiche viste finora in questo modo:

| Operazione base | Operazione negata |
| --------------- | ----------------- |
| AND             | NAND              |
| OR              | NOR               |
| XOR             | XNOR              |

La NOT, invece, è la negazione diretta di un singolo valore.

Queste relazioni sono molto utili perché permettono di ragionare sulle porte logiche non come componenti isolati, ma come combinazioni di funzioni elementari.

Ad esempio:

```text
NAND = AND + NOT
NOR  = OR  + NOT
XNOR = XOR + NOT
```

Questa idea tornerà utile più avanti, quando useremo porte già disponibili per costruire circuiti più complessi.

## Errori comuni

Durante il montaggio di NAND, XNOR e NOT ci sono alcuni errori da evitare.

Il primo è dimenticare che NAND e XNOR sono operazioni negate. Se il risultato sembra l'opposto di quello atteso, potrebbe semplicemente essere stata letta la tabella di verità sbagliata.

Il secondo è usare la variabile B nella rete NOT. Nel nostro progetto la NOT viene applicata solo ad A.

Il terzo è non considerare che il 7404 contiene sei inverter, non otto. Per una rete NOT a 8 bit servono quindi due integrati.

Il quarto è abilitare più buffer contemporaneamente. Anche in questo articolo vale la stessa regola: una sola rete alla volta deve poter scrivere sul bus dati.

Il quinto è non verificare l'ordine dei bit. Soprattutto nelle reti che passano attraverso più integrati, come la XNOR costruita con XOR più NOT, è facile scambiare alcune linee.

## Conclusione

In questo articolo abbiamo completato le operazioni logiche di base della nostra ALU a 8 bit.

Abbiamo aggiunto la rete NAND usando il 7400, la rete XNOR costruita come XOR seguita da NOT, e la rete NOT applicata alla variabile A usando il 7404.

Abbiamo visto che NAND, NOR e XNOR sono versioni negate di AND, OR e XOR, mentre NOT è la negazione diretta di un singolo ingresso.

La nostra ALU ora contiene un primo blocco logico abbastanza completo:

```text
AND
OR
XOR
NOR
NAND
XNOR
NOT
```

Nel prossimo articolo inizieremo a entrare nella parte aritmetica della CPU.

Vedremo come funziona la somma binaria, come si costruiscono half adder e full adder, e perché una semplice combinazione di porte XOR, AND e OR può diventare la base per realizzare un sommatore.
