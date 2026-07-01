# Flip-flop SR: una cella di memoria

Nel precedente articolo abbiamo introdotto il segnale di clock, cioè il metronomo che permetterà alla CPU di aggiornare registri e circuiti sequenziali in modo ordinato.

Ora iniziamo a parlare di memoria digitale.

Una CPU non deve solo calcolare risultati con l'ALU. Deve anche conservare temporaneamente dati, istruzioni, indirizzi e stati interni. Per fare questo useremo dei registri, ma prima di costruire registri a 8 bit dobbiamo capire come si memorizza un singolo bit.

Il circuito più semplice per introdurre questo concetto è il flip-flop SR.

## Perché serve una memoria

Finora abbiamo costruito principalmente circuiti combinatori.

Un circuito combinatorio produce un'uscita che dipende solo dagli ingressi presenti in quel momento.

Ad esempio, una porta AND produce 1 solo se entrambi gli ingressi sono 1. Se cambiamo gli ingressi, cambia subito anche l'uscita.

Ma una CPU ha bisogno anche di circuiti capaci di ricordare.

Un registro, ad esempio, deve poter salvare un valore e mantenerlo anche se gli ingressi cambiano.

Per costruire un registro a 8 bit servono otto celle di memoria da un bit. Ogni cella memorizza un singolo valore logico:

```text
0 oppure 1
```

Il flip-flop SR è una prima forma di cella di memoria.

## Cos'è un flip-flop SR

SR significa:

```text
Set Reset
```

Un flip-flop SR ha due ingressi principali:

```text
S -> Set
R -> Reset
```

Ha poi almeno una uscita:

```text
Q
```

Spesso è presente anche l'uscita negata:

```text
/Q
```

L'uscita Q rappresenta il bit memorizzato.

Se Q vale 1, il flip-flop sta memorizzando 1.

Se Q vale 0, il flip-flop sta memorizzando 0.

L'ingresso Set serve a impostare Q a 1.

L'ingresso Reset serve a impostare Q a 0.

## Simbolo logico

Possiamo rappresentare il flip-flop SR come un blocco:

```text
       +--------+
S ---->|        |---- Q
R ---->|  SR    |---- /Q
       +--------+
```

Gli ingressi S e R controllano lo stato del circuito.

Le uscite Q e /Q rappresentano lo stato memorizzato e il suo complemento.

Idealmente, se Q vale 1, /Q vale 0.

Se Q vale 0, /Q vale 1.

## Tabella di verità del flip-flop SR

Il flip-flop SR può essere realizzato con due porte NOR incrociate.

In questa configurazione, la tabella di verità è:

|   S |   R | Q             |
| --: | --: | ------------- |
|   0 |   0 | memoria       |
|   0 |   1 | 0             |
|   1 |   0 | 1             |
|   1 |   1 | indeterminato |

Vediamo il significato delle varie righe.

Quando:

```text
S = 0
R = 0
```

il circuito mantiene il valore già memorizzato.

Quando:

```text
S = 1
R = 0
```

il flip-flop viene settato e Q diventa 1.

Quando:

```text
S = 0
R = 1
```

il flip-flop viene resettato e Q diventa 0.

Quando:

```text
S = 1
R = 1
```

si entra in una condizione non valida o indeterminata, che deve essere evitata.

## La condizione di memoria

La riga più interessante della tabella è:

```text
S = 0
R = 0
```

In questa condizione il flip-flop non riceve né un comando di set né un comando di reset.

Quindi mantiene il valore precedente.

Se prima Q valeva 1, continuerà a valere 1.

Se prima Q valeva 0, continuerà a valere 0.

Questa è la caratteristica fondamentale di una memoria: il circuito conserva uno stato.

## Set e Reset

L'ingresso Set imposta il bit memorizzato a 1.

```text
S = 1
R = 0
Q = 1
```

L'ingresso Reset imposta il bit memorizzato a 0.

```text
S = 0
R = 1
Q = 0
```

Dopo aver impostato il valore desiderato, possiamo tornare alla condizione:

```text
S = 0
R = 0
```

Il flip-flop manterrà il valore appena salvato.

## Condizione vietata

La combinazione:

```text
S = 1
R = 1
```

è una condizione da evitare.

Con un flip-flop SR costruito con porte NOR, questa condizione forza entrambe le uscite a 0. Il problema si presenta quando gli ingressi tornano poi a 0: lo stato finale può dipendere dai ritardi interni delle porte e non è prevedibile in modo affidabile.

Per questo motivo la condizione S = 1 e R = 1 viene considerata non valida.

Uno degli obiettivi dei circuiti più evoluti, come il flip-flop D, sarà proprio evitare questa condizione.

## Costruire un flip-flop SR con porte NOR

Un flip-flop SR può essere costruito usando due porte NOR collegate in retroazione.

Lo schema concettuale è:

```text
        +-----+
R ----->| NOR |---- Q
   +--->|     |
   |    +-----+
   |
   |    +-----+
   +----| NOR |<---- S
        |     |
        +-----+
             |
            /Q
```

Più chiaramente, le due uscite vengono incrociate:

- l'uscita della prima NOR rientra in ingresso alla seconda
- l'uscita della seconda NOR rientra in ingresso alla prima

Questa retroazione è ciò che permette al circuito di mantenere uno stato.

## Richiamo: porta NOR

La porta NOR è una OR negata.

La sua tabella di verità è:

|   A |   B | NOR |
| --: | --: | --: |
|   0 |   0 |   1 |
|   0 |   1 |   0 |
|   1 |   0 |   0 |
|   1 |   1 |   0 |

L'unica combinazione che produce 1 in uscita è:

```text
A = 0
B = 0
```

Questo comportamento è alla base del flip-flop SR.

## Come mantiene memoria

Vediamo intuitivamente come il circuito mantiene memoria.

Supponiamo di essere nella condizione:

```text
S = 0
R = 0
Q = 1
/Q = 0
```

L'uscita Q = 1 viene riportata all'ingresso della porta che genera /Q.

Poiché una NOR con almeno un ingresso a 1 produce 0, /Q resta a 0.

A sua volta, /Q = 0 viene riportato all'altra porta NOR. Con R = 0 e /Q = 0, la NOR produce 1, quindi Q resta a 1.

Il circuito si sostiene da solo in questo stato.

Ora supponiamo invece:

```text
S = 0
R = 0
Q = 0
/Q = 1
```

Il ragionamento è simmetrico. La retroazione mantiene Q a 0 e /Q a 1.

Quindi, con S e R entrambi a 0, il circuito può mantenere due stati stabili:

```text
Q = 0
Q = 1
```

Questa è la memoria di un bit.

## Esempio: impostare Q a 1

Supponiamo che il flip-flop stia memorizzando 0:

```text
Q = 0
/Q = 1
```

Vogliamo impostarlo a 1.

Applichiamo:

```text
S = 1
R = 0
```

Il comando Set forza il circuito a portare Q a 1.

Una volta che Q è diventato 1, possiamo tornare a:

```text
S = 0
R = 0
```

Il flip-flop manterrà Q = 1.

## Esempio: impostare Q a 0

Supponiamo che il flip-flop stia memorizzando 1:

```text
Q = 1
/Q = 0
```

Vogliamo resettarlo.

Applichiamo:

```text
S = 0
R = 1
```

Il comando Reset forza Q a 0.

Poi possiamo tornare alla condizione di memoria:

```text
S = 0
R = 0
```

Il flip-flop manterrà Q = 0.

## Il componente 7402

Per costruire il flip-flop SR useremo il 7402.

Il 7402 contiene quattro porte NOR a due ingressi.

Per un flip-flop SR bastano due porte NOR, quindi un singolo 7402 permette teoricamente di costruire due flip-flop SR.

La piedinatura del 7402 va controllata con attenzione perché, come già visto nella rete NOR dell'ALU, non segue sempre lo stesso ordine di altri integrati come 7408 o 7432.

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

## Collegamento degli ingressi S e R

Per testare il flip-flop possiamo controllare gli ingressi S e R con due switch.

Come sempre, gli ingressi non devono mai essere lasciati flottanti.

Useremo quindi resistenze di pull-up o pull-down per garantire che S e R abbiano sempre un livello logico definito.

Una configurazione semplice è usare switch che permettano di portare gli ingressi a 1 o a 0 in modo controllato.

Durante i test dobbiamo assicurarci di non impostare contemporaneamente:

```text
S = 1
R = 1
```

perché questa è la condizione non valida del flip-flop SR.

## Visualizzare l'uscita con un LED

Per vedere lo stato memorizzato possiamo collegare l'uscita Q a un LED tramite una resistenza.

Quando Q vale 1, il LED si accende.

Quando Q vale 0, il LED si spegne.

In questo modo possiamo osservare direttamente il bit memorizzato.

Schema concettuale:

```text
Q ---- resistenza ---- LED ---- GND
```

Il LED non è parte essenziale del flip-flop, ma è molto utile durante i test.

## Test pratico: Set

Partiamo da una condizione qualunque e applichiamo il comando Set:

```text
S = 1
R = 0
```

Il risultato atteso è:

```text
Q = 1
```

Il LED collegato a Q deve accendersi.

Ora torniamo alla condizione di memoria:

```text
S = 0
R = 0
```

Il LED deve rimanere acceso.

Questo dimostra che il flip-flop ha memorizzato il valore 1.

## Test pratico: Reset

Ora applichiamo il comando Reset:

```text
S = 0
R = 1
```

Il risultato atteso è:

```text
Q = 0
```

Il LED deve spegnersi.

Torniamo poi a:

```text
S = 0
R = 0
```

Il LED deve rimanere spento.

Questo dimostra che il flip-flop ha memorizzato il valore 0.

## Test della memoria

Il test più importante è verificare che il circuito mantenga lo stato.

Sequenza:

```text
1. S = 1, R = 0 -> Q diventa 1
2. S = 0, R = 0 -> Q resta 1
3. S = 0, R = 1 -> Q diventa 0
4. S = 0, R = 0 -> Q resta 0
```

Se il LED segue questa sequenza, il flip-flop sta funzionando correttamente.

## Memoria volatile

Il flip-flop SR memorizza un bit, ma questa memoria è volatile.

Questo significa che il valore viene mantenuto solo finché il circuito è alimentato.

Se togliamo alimentazione, il flip-flop perde lo stato memorizzato.

Quando ridiamo alimentazione, lo stato iniziale può non essere prevedibile.

Questo è normale per questo tipo di memoria.

Anche i registri interni di una CPU sono memorie volatili: conservano i valori solo mentre il circuito è alimentato.

## Limiti del flip-flop SR

Il flip-flop SR è molto utile per capire il concetto di memoria, ma ha alcuni limiti.

Il limite principale è la condizione non valida:

```text
S = 1
R = 1
```

In un circuito più complesso, vogliamo evitare che una combinazione di ingressi possa portare a uno stato indeterminato.

Inoltre, il flip-flop SR non è ancora sincronizzato con il clock nel modo che ci servirà per costruire registri della CPU.

Per i registri vogliamo un comportamento più controllato:

```text
salva il valore solo quando arriva il fronte di clock
mantieni il valore negli altri momenti
```

Per questo motivo, nel prossimo articolo passeremo al flip-flop D.

## Dal flip-flop SR al flip-flop D

Il flip-flop D può essere visto come un'evoluzione del flip-flop SR.

L'idea è evitare la condizione non valida e avere un solo ingresso dati:

```text
D
```

Il valore presente su D verrà salvato nel flip-flop in un momento controllato, ad esempio quando arriva un impulso di clock.

Questa struttura è molto più adatta alla costruzione dei registri.

Il flip-flop SR resta però fondamentale dal punto di vista didattico, perché mostra come due porte logiche con retroazione possano memorizzare un bit.

## Errori comuni

Quando si costruisce un flip-flop SR ci sono alcuni errori frequenti.

Il primo è lasciare flottanti gli ingressi S e R. Anche qui vale la stessa regola vista per gli altri circuiti digitali: ogni ingresso deve avere sempre un livello definito.

Il secondo è entrare accidentalmente nella condizione S = 1 e R = 1.

Il terzo è collegare male la retroazione tra le due porte NOR. Senza le uscite incrociate, il circuito non può mantenere memoria.

Il quarto è invertire Q e /Q durante il cablaggio o la lettura del LED.

Il quinto è dimenticare la resistenza in serie al LED.

Il sesto è aspettarsi che il flip-flop mantenga memoria anche senza alimentazione. Il circuito è volatile.

## Riepilogo

Il flip-flop SR è una cella di memoria da un bit.

Ha due ingressi:

```text
S -> Set
R -> Reset
```

Ha un'uscita principale:

```text
Q -> bit memorizzato
```

La tabella di funzionamento è:

|   S |   R | Q          |
| --: | --: | ---------- |
|   0 |   0 | memoria    |
|   0 |   1 | 0          |
|   1 |   0 | 1          |
|   1 |   1 | non valido |

Può essere costruito con due porte NOR incrociate.

La condizione S = 0 e R = 0 permette al circuito di mantenere il valore precedente.

## Conclusione

In questo articolo abbiamo introdotto il flip-flop SR, una delle celle di memoria più semplici.

Abbiamo visto che, usando due porte NOR collegate in retroazione, è possibile costruire un circuito capace di memorizzare un singolo bit.

Abbiamo analizzato gli ingressi Set e Reset, la condizione di memoria, la condizione non valida e il comportamento dell'uscita Q.

Abbiamo anche visto come testare il circuito usando switch e un LED, e perché questa memoria è volatile.

Nel prossimo articolo passeremo al flip-flop D.

Vedremo come partire dal concetto di flip-flop SR per ottenere una cella di memoria più controllabile, con un ingresso dati e un segnale di clock, adatta alla costruzione dei registri della CPU.
