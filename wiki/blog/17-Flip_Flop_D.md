# Flip-flop D e salvataggio sul fronte di clock

Nel precedente articolo abbiamo introdotto il flip-flop SR, una cella di memoria capace di memorizzare un singolo bit usando due porte NOR collegate in retroazione.

Il flip-flop SR è molto utile per capire il concetto di memoria digitale, ma ha un limite importante: la combinazione S = 1 e R = 1 porta a una condizione non valida. Inoltre, per costruire registri comodi da usare nella CPU, vogliamo un circuito con un solo ingresso dati e un controllo più preciso sul momento in cui il valore viene salvato.

Il passo successivo è quindi il flip-flop D.

## Dal flip-flop SR al flip-flop D

Il flip-flop D può essere visto come un'evoluzione del flip-flop SR.

L'obiettivo è avere un solo ingresso dati:

```text
D
```

Il valore presente su D deve essere copiato in uscita Q solo quando il circuito riceve un comando di salvataggio.

In pratica vogliamo un comportamento di questo tipo:

```text
quando salvo -> Q diventa uguale a D
quando non salvo -> Q mantiene il valore precedente
```

Questo comportamento è molto più adatto alla costruzione dei registri della CPU.

## Il problema del flip-flop SR

Ricordiamo la tabella del flip-flop SR costruito con porte NOR:

|   S |   R | Q          |
| --: | --: | ---------- |
|   0 |   0 | memoria    |
|   0 |   1 | 0          |
|   1 |   0 | 1          |
|   1 |   1 | non valido |

Il problema è l'ultima riga.

Se S e R vengono portati entrambi a 1, il circuito entra in una condizione non valida o comunque non utilizzabile in modo affidabile.

Per evitare questo problema possiamo fare in modo che S e R non siano mai entrambi a 1.

Un modo semplice è ricavare S e R da un unico segnale D:

```text
S = D
R = NOT D
```

In questo modo, se D vale 1:

```text
S = 1
R = 0
```

Se D vale 0:

```text
S = 0
R = 1
```

La combinazione S = 1 e R = 1 diventa impossibile.

## Primo circuito: D collegato a SR

Partiamo da questa idea semplice:

```text
D -------> S
D -> NOT -> R
```

Se D vale 1, il flip-flop viene settato:

```text
Q = 1
```

Se D vale 0, il flip-flop viene resettato:

```text
Q = 0
```

La tabella diventa:

|   D |   Q |
| --: | --: |
|   0 |   0 |
|   1 |   1 |

Questo elimina la condizione non valida, ma non è ancora una vera memoria controllabile.

Infatti, appena D cambia, cambia anche Q.

Non abbiamo ancora un segnale che dica quando salvare il valore e quando mantenerlo.

## Aggiungere un enable

Per rendere il circuito utile, dobbiamo aggiungere un segnale di enable.

L'enable decide se il flip-flop deve aggiornarsi oppure mantenere il valore precedente.

Vogliamo questa tabella:

| Enable |   D | Q       |
| -----: | --: | ------- |
|      0 |   0 | memoria |
|      0 |   1 | memoria |
|      1 |   0 | 0       |
|      1 |   1 | 1       |

Quando Enable vale 0, il circuito mantiene il valore precedente.

Quando Enable vale 1, il valore di D viene copiato in Q.

Per ottenere questo comportamento possiamo usare due porte AND prima degli ingressi del flip-flop SR.

## D latch con enable

Il circuito risultante è spesso chiamato D latch.

Lo schema concettuale è:

```text
D --------------------\
                       AND ---- S
Enable ---------------/

D ---- NOT -----------\
                       AND ---- R
Enable ---------------/
```

Gli ingressi S e R del flip-flop SR vengono generati così:

```text
S = D AND Enable
R = NOT(D) AND Enable
```

Vediamo cosa succede.

Se Enable vale 0:

```text
S = D AND 0 = 0
R = NOT(D) AND 0 = 0
```

Quindi il flip-flop SR riceve:

```text
S = 0
R = 0
```

e mantiene memoria.

Se Enable vale 1:

```text
S = D
R = NOT(D)
```

Il flip-flop si aggiorna copiando D in Q.

## Tabella del D latch

La tabella di funzionamento è:

| Enable |   D |   S |   R | Q       |
| -----: | --: | --: | --: | ------- |
|      0 |   0 |   0 |   0 | memoria |
|      0 |   1 |   0 |   0 | memoria |
|      1 |   0 |   0 |   1 | 0       |
|      1 |   1 |   1 |   0 | 1       |

Questa tabella mostra chiaramente il vantaggio del D latch.

Quando Enable è basso, il circuito conserva lo stato.

Quando Enable è alto, il circuito segue il valore di D.

Il problema è che, se Enable resta alto per un certo tempo, ogni variazione di D può propagarsi a Q.

Per costruire registri sincronizzati al clock, vogliamo invece salvare il valore in un istante preciso.

## Dal livello al fronte

Un latch controllato da enable è sensibile al livello.

Questo significa che, mentre Enable vale 1, il dato può passare da D a Q.

In una CPU, spesso vogliamo un comportamento diverso:

```text
salva D solo sul fronte di salita del clock
mantieni il valore in tutti gli altri momenti
```

Il fronte di salita è l'istante in cui il clock passa da 0 a 1:

```text
0 -> 1
```

Questo comportamento rende il circuito molto più controllabile.

I segnali possono stabilizzarsi durante il ciclo di clock e il registro salva il valore solo in un momento preciso.

## Flip-flop D edge-triggered

Un flip-flop D sincronizzato sul fronte di clock ha questa idea di base:

```text
fronte di salita del clock -> Q prende il valore di D
altri momenti -> Q mantiene il valore precedente
```

La tabella si può scrivere così:

| Clock            |   D | Q       |
| ---------------- | --: | ------- |
| nessun fronte    |   0 | memoria |
| nessun fronte    |   1 | memoria |
| fronte di salita |   0 | 0       |
| fronte di salita |   1 | 1       |

Spesso il fronte di salita viene indicato con una freccia:

```text
↑
```

Quindi:

| Clock |   D |   Q |
| ----- | --: | --: |
| ↑     |   0 |   0 |
| ↑     |   1 |   1 |

Negli altri momenti, Q non cambia.

## Generare un impulso dal clock

Per trasformare un latch in un circuito che salva solo sul fronte, possiamo generare un impulso molto breve quando il clock passa da 0 a 1.

Questo impulso diventa l'enable del D latch.

L'idea è:

```text
clock normale -> generatore di impulso -> enable breve
```

Durante quell'impulso, il latch copia D in Q.

Subito dopo, l'enable torna a 0 e il valore resta memorizzato.

## Generatore di impulso con NOT e AND

Un modo didattico per generare un impulso è usare:

- una porta NOT
- una porta AND

Lo schema concettuale è:

```text
Clock ----------------------\
                             AND ---- impulso
Clock ---- NOT -------------/
```

A prima vista sembra che questo circuito debba produrre sempre 0, perché stiamo facendo:

```text
Clock AND NOT(Clock)
```

che logicamente è sempre falso.

Però nella realtà le porte logiche hanno un piccolo ritardo di propagazione.

Quando il clock passa da 0 a 1, il ramo diretto arriva subito alla porta AND, mentre il ramo che passa dalla NOT cambia con un piccolo ritardo.

Per un brevissimo istante, entrambi gli ingressi della AND possono trovarsi a 1.

In quell'istante l'uscita della AND produce un impulso.

## Ritardo di propagazione

Ogni porta logica reale non cambia uscita istantaneamente.

Quando un ingresso cambia, l'uscita cambia dopo un piccolo tempo chiamato ritardo di propagazione.

Nel generatore di impulso, sfruttiamo proprio questo ritardo.

Quando il clock sale:

```text
Clock diretto = 1
Clock negato = ancora 1 per un brevissimo tempo
```

Quindi la AND vede temporaneamente:

```text
1 AND 1 = 1
```

Poi la NOT aggiorna la sua uscita:

```text
Clock negato = 0
```

e la AND torna a:

```text
1 AND 0 = 0
```

Il risultato è un impulso molto breve.

## Limiti di questa soluzione

Il generatore di impulso basato sul ritardo di una porta NOT è utile per capire il concetto, ma non è una soluzione robusta.

Il ritardo di propagazione può variare in base a:

- tipo di integrato
- temperatura
- tensione di alimentazione
- carico collegato
- tolleranze del componente

Questo significa che l'impulso generato può essere troppo breve, troppo instabile o non adatto a un circuito più grande.

Per questo motivo, in una CPU reale o in un progetto più affidabile, è meglio usare flip-flop D già integrati, progettati per lavorare correttamente sul fronte di clock.

Nel nostro caso, però, costruire questo circuito ha un grande valore didattico: mostra come si passa da un latch sensibile al livello a un comportamento controllato dal fronte.

## Circuito completo del flip-flop D didattico

Il circuito didattico completo è composto da:

1. un flip-flop SR costruito con due porte NOR
2. una porta NOT per ottenere NOT(D)
3. due porte AND per generare S e R
4. un generatore di impulso dal clock

Il segnale D viene usato come dato da salvare.

Il clock viene trasformato in un impulso breve.

L'impulso abilita il latch solo per un istante.

Durante quell'istante:

```text
Q = D
```

Poi il circuito torna in memoria.

## Uso del 7408, 7402 e porte NOT

Per costruire il circuito possiamo usare:

- 7402 per le porte NOR del flip-flop SR
- 7408 per le porte AND
- 7404 per le porte NOT

Se vogliamo evitare di aggiungere un integrato solo per una NOT, possiamo anche ricavare una negazione usando porte disponibili, a seconda di ciò che abbiamo sulla board.

Ad esempio, una porta NOR con un ingresso fissato a 0 può comportarsi come una NOT:

```text
A NOR 0 = NOT A
```

Oppure una XOR con un ingresso fissato a 1 può invertire il segnale:

```text
A XOR 1 = NOT A
```

Questi trucchi sono utili quando si lavora fisicamente con integrati e cablaggi.

## Test del flip-flop D

Per testare il flip-flop D possiamo usare:

- uno switch o un filo per impostare D a 0 o 1
- un pulsante o un clock manuale per generare l'impulso
- un LED collegato a Q per visualizzare il valore memorizzato

Primo test:

```text
D = 1
```

Prima del clock, Q non deve cambiare.

Quando arriva l'impulso di clock, Q deve diventare 1.

Il LED si accende.

Secondo test:

```text
D = 0
```

Prima del clock, Q deve restare al valore precedente.

Quando arriva un nuovo impulso, Q deve diventare 0.

Il LED si spegne.

La sequenza attesa è:

```text
D = 1, clock -> Q = 1
D = 0, nessun clock -> Q resta 1
D = 0, clock -> Q = 0
D = 1, nessun clock -> Q resta 0
D = 1, clock -> Q = 1
```

Questo dimostra che il circuito salva il valore solo quando riceve il clock.

## Differenza tra latch e flip-flop

È utile distinguere tra latch e flip-flop.

Un latch è sensibile al livello del segnale di enable.

Se Enable è alto, il valore può passare da D a Q.

Un flip-flop edge-triggered, invece, è sensibile al fronte del clock.

Aggiorna Q solo in un istante specifico, ad esempio sul fronte di salita.

In forma semplificata:

```text
latch      -> controllato da un livello
flip-flop  -> controllato da un fronte
```

Questa distinzione sarà importante quando parleremo di registri.

## Perché il flip-flop D è utile per i registri

Un registro a 8 bit può essere costruito usando otto flip-flop D in parallelo.

Ogni flip-flop memorizza un bit:

```text
D0 -> Q0
D1 -> Q1
D2 -> Q2
D3 -> Q3
D4 -> Q4
D5 -> Q5
D6 -> Q6
D7 -> Q7
```

Tutti i flip-flop ricevono lo stesso segnale di clock.

Quando arriva il fronte di clock, tutti salvano contemporaneamente il rispettivo bit.

In questo modo possiamo memorizzare un valore a 8 bit.

Questo è il principio alla base dei registri della CPU.

## Memoria e clock nella CPU

Con il flip-flop D iniziamo a vedere come la CPU può conservare dati nel tempo.

L'ALU produce risultati.

Il bus dati trasporta valori.

I registri salvano questi valori quando arriva il clock.

Questa collaborazione tra logica combinatoria e logica sequenziale è alla base dell'intera CPU.

La logica combinatoria risponde agli ingressi.

La logica sequenziale memorizza stati.

Il clock coordina il momento in cui gli stati vengono aggiornati.

## Errori comuni

Quando si studia o si costruisce un flip-flop D ci sono alcuni errori frequenti.

Il primo è confondere un latch con un flip-flop edge-triggered. Se il circuito è sensibile al livello, non salva solo sul fronte.

Il secondo è aspettarsi che il generatore di impulso con NOT e AND sia perfetto. È un circuito didattico, ma non è la soluzione più stabile.

Il terzo è dimenticare che D deve essere stabile nel momento del fronte di clock. Se D cambia proprio durante il salvataggio, il comportamento può diventare imprevedibile.

Il quarto è lasciare flottante l'ingresso D o il clock. Anche questi segnali devono avere livelli logici definiti.

Il quinto è dimenticare che il flip-flop conserva memoria solo finché è alimentato.

Il sesto è non distinguere tra il valore presente su D e il valore memorizzato in Q. D può cambiare, ma Q cambia solo quando il circuito salva.

## Riepilogo

Il flip-flop D ha un ingresso dati:

```text
D
```

e un'uscita:

```text
Q
```

Il suo comportamento ideale è:

```text
fronte di clock -> Q prende il valore di D
nessun fronte -> Q mantiene il valore precedente
```

Può essere visto come un'evoluzione del flip-flop SR, con una logica che evita la condizione non valida.

Un registro a 8 bit può essere costruito usando otto flip-flop D in parallelo.

## Conclusione

In questo articolo abbiamo introdotto il flip-flop D, una cella di memoria più adatta alla costruzione dei registri della CPU.

Siamo partiti dal flip-flop SR e abbiamo visto come eliminare la condizione non valida usando un solo ingresso dati D. Abbiamo poi aggiunto un enable, ottenendo un latch controllabile, e infine abbiamo introdotto l'idea del salvataggio sul fronte di clock.

Abbiamo anche visto un generatore di impulso didattico basato su una porta NOT e una porta AND, utile per capire il concetto ma non ideale per un progetto definitivo.

Il flip-flop D è il ponte tra il singolo bit di memoria e i registri a 8 bit che useremo nella CPU.

Con questo articolo chiudiamo la prima parte del percorso: abbiamo costruito le basi dell'ALU, il bus dati, il clock e le prime celle di memoria.
