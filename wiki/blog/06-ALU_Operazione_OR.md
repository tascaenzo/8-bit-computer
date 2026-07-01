# ALU: operazione OR

Nel precedente articolo abbiamo approfondito il ruolo dei buffer tri-state e abbiamo visto perché sono fondamentali per collegare più reti logiche allo stesso bus dati senza creare conflitti.

Ora possiamo aggiungere una seconda operazione alla nostra ALU: l'OR.

La struttura sarà molto simile a quella già vista per l'operazione AND. Avremo due variabili in ingresso, A e B, una rete logica a 8 bit, un buffer tri-state e infine il collegamento al bus dati.

Cambierà soltanto il tipo di porta logica utilizzata: al posto delle porte AND useremo porte OR.

## Cos'è l'operazione OR

L'OR è una delle operazioni fondamentali dell'algebra booleana.

Lavora su due ingressi, che possiamo chiamare A e B, e produce una sola uscita. L'uscita vale 1 quando almeno uno dei due ingressi vale 1. L'uscita vale 0 solo quando entrambi gli ingressi valgono 0.

La tabella di verità della porta OR è la seguente:

|   A |   B | OUT |
| --: | --: | --: |
|   0 |   0 |   0 |
|   0 |   1 |   1 |
|   1 |   0 |   1 |
|   1 |   1 |   1 |

Quindi l'unica combinazione che produce 0 in uscita è:

```text
A = 0
B = 0
```

In tutti gli altri casi l'uscita vale 1.

L'espressione booleana dell'OR si può scrivere così:

```text
OUT = A + B
```

oppure:

```text
OUT = A OR B
```

Il simbolo `+` in algebra booleana non indica una somma aritmetica classica, ma l'operazione OR.

## OR bit a bit

Come per l'AND, anche l'operazione OR verrà applicata bit per bit sulle due variabili a 8 bit.

Le variabili A e B sono composte da otto bit ciascuna:

```text
A7 A6 A5 A4 A3 A2 A1 A0
B7 B6 B5 B4 B3 B2 B1 B0
```

La rete OR calcolerà:

```text
OUT0 = A0 OR B0
OUT1 = A1 OR B1
OUT2 = A2 OR B2
OUT3 = A3 OR B3
OUT4 = A4 OR B4
OUT5 = A5 OR B5
OUT6 = A6 OR B6
OUT7 = A7 OR B7
```

Il risultato sarà quindi un valore a 8 bit.

Facciamo un esempio:

```text
A = 10101010
B = 11110000
```

L'OR bit a bit produce:

```text
A     10101010
B     11110000
OR    11111010
```

Ogni colonna viene calcolata separatamente. Se almeno uno dei due bit vale 1, il risultato di quella colonna vale 1.

## Differenza tra AND e OR

AND e OR sembrano simili perché entrambe sono operazioni logiche a due ingressi, ma hanno un comportamento molto diverso.

L'AND è selettiva: produce 1 solo quando entrambi gli ingressi sono 1.

L'OR è inclusiva: produce 1 quando almeno uno degli ingressi è 1.

Possiamo confrontare le due tabelle:

|   A |   B | AND |  OR |
| --: | --: | --: | --: |
|   0 |   0 |   0 |   0 |
|   0 |   1 |   0 |   1 |
|   1 |   0 |   0 |   1 |
|   1 |   1 |   1 |   1 |

Questa differenza rende le due operazioni utili in contesti diversi.

L'AND può essere usata per mascherare bit e azzerare alcune parti di un valore. L'OR può essere usata per forzare alcuni bit a 1 lasciando invariati gli altri.

Ad esempio, se vogliamo forzare a 1 i quattro bit meno significativi di un valore, possiamo fare OR con la maschera `00001111`:

```text
A       10110000
MASK    00001111
OR      10111111
```

I bit corrispondenti agli 1 della maschera vengono forzati a 1. Gli altri restano uguali al valore originale.

## Il componente 7432

Per realizzare l'operazione OR useremo l'integrato 7432.

Il 7432 contiene quattro porte OR a due ingressi.

Ogni porta ha:

- ingresso A
- ingresso B
- uscita Y

Poiché la nostra ALU lavora su 8 bit, avremo bisogno di otto porte OR. Useremo quindi due integrati 7432.

La piedinatura tipica del 7432 è molto simile a quella del 7408 usato per l'AND:

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

Come sempre, prima di cablare un integrato è buona pratica controllare il datasheet del componente specifico.

## Struttura della rete OR a 8 bit

La rete OR è composta da otto porte OR indipendenti, una per ogni coppia di bit A/B.

Lo schema logico è:

```text
A0 ----\
       OR ---- OUT0
B0 ----/

A1 ----\
       OR ---- OUT1
B1 ----/

A2 ----\
       OR ---- OUT2
B2 ----/

...

A7 ----\
       OR ---- OUT7
B7 ----/
```

Ogni uscita OUT rappresenta il risultato dell'OR tra i due bit corrispondenti.

Come per l'AND, le uscite delle porte OR non verranno collegate direttamente al bus dati. Passeranno prima attraverso un buffer tri-state.

## Collegamento al bus dati

Il collegamento generale della rete OR sarà:

```text
Switch A ----\
             7432 ---- risultato OR ---- 74244 ---- bus dati ---- LED
Switch B ----/
```

In pratica:

1. gli switch della variabile A forniscono i bit A0-A7
2. gli switch della variabile B forniscono i bit B0-B7
3. ogni coppia Ai/Bi entra in una porta OR del 7432
4. le otto uscite delle porte OR entrano nel buffer tri-state
5. le uscite del buffer vanno alle otto linee del bus dati
6. i LED collegati al bus mostrano il risultato
7. il segnale di enable decide se la rete OR può scrivere sul bus

La rete OR avrà quindi un proprio buffer, separato da quello della rete AND.

Questo è importante: ogni rete dell'ALU deve poter essere isolata individualmente dal bus dati.

## Enable della rete OR

Il buffer della rete OR avrà un segnale di enable dedicato.

Se l'enable è attivo basso, avremo:

```text
enable OR = 0 -> rete OR collegata al bus
enable OR = 1 -> rete OR isolata dal bus
```

Durante i test manuali potremo collegare l'enable a massa per abilitare la rete OR, oppure a +5 V per disabilitarla.

Quando più avanti costruiremo il circuito del codice operazione, questo enable non sarà più controllato manualmente. Verrà pilotato automaticamente da un decoder.

Ad esempio:

```text
opcode 0000 -> abilita AND
opcode 0001 -> abilita OR
```

Per ora, però, ci interessa verificare che la rete OR funzioni correttamente e che il buffer riesca a collegarla e scollegarla dal bus.

## Convivenza con la rete AND

A questo punto sulla nostra ALU iniziano a esserci almeno due reti:

```text
A, B -> rete AND -> buffer AND -> bus dati
A, B -> rete OR  -> buffer OR  -> bus dati
```

Entrambe le reti ricevono gli stessi ingressi A e B.

Questo significa che, quando cambiamo gli switch delle variabili A e B, sia la rete AND sia la rete OR calcolano il proprio risultato.

La differenza è che solo una delle due deve essere collegata al bus dati.

Se vogliamo testare l'AND:

```text
enable AND = 0
enable OR  = 1
```

Se vogliamo testare l'OR:

```text
enable AND = 1
enable OR  = 0
```

Non dobbiamo mai abilitare entrambe le reti contemporaneamente, perché potremmo creare un conflitto sul bus.

## Test su un singolo bit

Prima di verificare l'intera rete, possiamo testare un solo bit.

Colleghiamo A0 e B0 alla prima porta OR e osserviamo il LED collegato a D0, con il buffer OR abilitato.

La tabella attesa è:

|  A0 |  B0 |  OR |
| --: | --: | --: |
|   0 |   0 |   0 |
|   0 |   1 |   1 |
|   1 |   0 |   1 |
|   1 |   1 |   1 |

Il LED dovrà rimanere spento solo nel caso `0 OR 0`.

In tutti gli altri casi dovrà accendersi.

Questo test è semplice ma molto utile, perché ci permette di verificare sia la porta OR sia il collegamento verso il buffer.

## Test della rete a 8 bit

Una volta verificato il singolo bit, possiamo testare tutta la rete OR.

Primo test:

```text
A = 00000000
B = 00000000
```

Risultato atteso:

```text
OR = 00000000
```

Tutti i LED del bus devono essere spenti.

Secondo test:

```text
A = 11111111
B = 00000000
```

Risultato atteso:

```text
OR = 11111111
```

Tutti i LED devono essere accesi.

Terzo test:

```text
A = 00000000
B = 11111111
```

Risultato atteso:

```text
OR = 11111111
```

Anche in questo caso tutti i LED devono essere accesi.

Quarto test:

```text
A = 10101010
B = 01010101
```

Risultato atteso:

```text
OR = 11111111
```

Perché in ogni posizione almeno uno dei due bit vale 1.

Quinto test:

```text
A = 10100000
B = 00001111
```

Risultato atteso:

```text
OR = 10101111
```

Questi test permettono di verificare che tutti i bit siano collegati nell'ordine corretto.

## Test dell'enable

Come per la rete AND, dobbiamo testare anche il segnale di enable del buffer OR.

Impostiamo un caso in cui il risultato dell'OR sia evidente:

```text
A = 11111111
B = 00000000
```

Con l'enable OR a 0, il bus deve mostrare:

```text
11111111
```

Con l'enable OR a 1, la rete OR deve essere isolata dal bus.

Questo test è fondamentale perché conferma che la rete non sta sempre pilotando il bus, ma solo quando viene selezionata.

## Errori comuni

Durante il montaggio della rete OR possono comparire errori simili a quelli già visti per l'AND.

Il primo è invertire l'ordine dei bit. Se OUT0 finisce su D7 invece che su D0, il risultato sarà specchiato o comunque nella posizione sbagliata.

Il secondo è dimenticare di disabilitare la rete AND mentre si testa la rete OR. Se entrambi i buffer sono attivi, il risultato sul bus potrebbe essere errato o instabile.

Il terzo è lasciare flottante l'enable del buffer. Anche l'enable deve essere sempre collegato a un valore definito.

Il quarto è confondere la piedinatura del 7432 con quella di un altro integrato. Anche se molti integrati della serie 74xx hanno pin simili, non bisogna mai dare per scontato che siano identici.

Il quinto è non alimentare correttamente entrambi i 7432. Poiché servono due integrati per ottenere otto porte OR, entrambi devono avere +5 V e GND collegati.

## Una struttura modulare

Con la rete OR iniziamo a vedere meglio il metodo di costruzione dell'ALU.

Ogni operazione viene realizzata come un modulo separato:

```text
modulo AND
modulo OR
modulo XOR
modulo NOR
...
```

Tutti i moduli ricevono gli stessi ingressi A e B, ma ognuno produce un risultato diverso.

Il bus dati resta condiviso.

I buffer tri-state decidono quale modulo può scrivere sul bus.

Questa organizzazione è molto utile perché ci permette di aggiungere nuove operazioni senza modificare completamente ciò che abbiamo già costruito.

Per aggiungere una nuova operazione dobbiamo:

1. costruire la rete logica corrispondente
2. collegare gli ingressi A e B
3. portare le uscite a un buffer tri-state
4. collegare il buffer al bus dati
5. aggiungere un segnale di enable dedicato

Più avanti, tutti questi enable verranno controllati dal codice operazione.

## Conclusione

In questo articolo abbiamo aggiunto all'ALU l'operazione OR a 8 bit.

Abbiamo visto la tabella di verità della porta OR, il concetto di OR bit a bit e il componente 7432, che contiene quattro porte OR a due ingressi. Usando due integrati 7432 possiamo costruire una rete OR completa a 8 bit.

Abbiamo poi collegato il risultato della rete a un buffer tri-state, in modo da poter trasferire il valore sul bus dati solo quando la rete OR viene abilitata.

A questo punto la nostra ALU contiene già due operazioni logiche: AND e OR.

Nel prossimo articolo continueremo ad espandere l'ALU aggiungendo due nuove operazioni: XOR e NOR.

La XOR sarà molto importante anche più avanti, perché verrà usata nella costruzione del circuito di somma e sottrazione. La NOR, invece, ci permetterà di introdurre il concetto di uscita negata rispetto all'OR.
