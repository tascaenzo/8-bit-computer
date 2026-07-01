# Pull-up, pull-down e ingressi TTL

Nel precedente articolo abbiamo visto come organizzare il bus dati della CPU e perché è utile visualizzare le sue linee con dei LED. Prima di iniziare a collegare le prime reti logiche dell'ALU, dobbiamo però affrontare un problema molto importante: come fornire valori stabili agli ingressi degli integrati digitali.

Quando useremo degli switch per impostare manualmente le variabili A e B, ogni switch dovrà produrre un valore logico chiaro: 0 oppure 1. Non possiamo permetterci ingressi lasciati scollegati o indefiniti, perché un integrato digitale deve sempre ricevere un livello logico interpretabile.

Per risolvere questo problema useremo due circuiti fondamentali: il pull-down e il pull-up.

## Il problema degli ingressi flottanti

In un circuito digitale, un ingresso dovrebbe trovarsi sempre in uno stato definito:

- livello logico basso, cioè 0
- livello logico alto, cioè 1

Il problema nasce quando un ingresso viene lasciato scollegato. In questo caso si dice che l'ingresso è flottante.

Un ingresso flottante non è collegato né a massa né a una tensione positiva stabile. Di conseguenza può assumere valori imprevedibili, captare disturbi elettrici o comportarsi in modo diverso a seconda del circuito, della breadboard, dei fili o dell'ambiente circostante.

Questo è particolarmente importante quando lavoriamo con integrati logici della famiglia TTL o CMOS. Se lasciamo un ingresso libero, non possiamo essere sicuri che venga interpretato come 0 o come 1.

In una CPU costruita con molti integrati, un singolo ingresso instabile può causare risultati errati, LED che si accendono senza motivo, operazioni sbagliate o comportamenti difficili da diagnosticare.

Per questo motivo la regola è semplice: un ingresso digitale non deve mai essere lasciato flottante.

## Switch e livelli logici

Nel nostro progetto useremo degli switch per impostare manualmente alcuni segnali.

Ad esempio, nelle prime fasi useremo switch per rappresentare le variabili A e B in ingresso all'ALU. Ogni variabile sarà composta da 8 bit, quindi avremo otto switch per A e otto switch per B.

Ogni switch deve permetterci di scegliere se il bit corrispondente vale 0 oppure 1.

A prima vista potremmo pensare di collegare lo switch direttamente a +5 V. Quando lo switch è chiuso, l'ingresso riceve un livello alto. Ma quando lo switch è aperto, cosa succede?

Succede che l'ingresso resta scollegato. Quindi diventa flottante.

Per evitare questo problema dobbiamo fare in modo che anche quando lo switch è aperto l'ingresso abbia comunque un valore definito. Ed è qui che entrano in gioco pull-down e pull-up.

## Circuito di pull-down

Il circuito di pull-down serve a mantenere un ingresso normalmente a livello basso.

Lo schema concettuale è questo:

```text
+5 V ---- switch ---- nodo di uscita ---- ingresso logico
                         |
                         R
                         |
                        GND
```

La resistenza collega il nodo di uscita a massa. Per questo motivo, quando lo switch è aperto, il nodo viene “tirato giù” verso 0 V. L'ingresso logico legge quindi uno 0.

Quando invece chiudiamo lo switch, il nodo viene collegato a +5 V. In questo caso l'ingresso legge un 1.

Il comportamento è quindi:

| Stato switch | Valore letto dall'ingresso |
| ------------ | -------------------------- |
| Aperto       | 0                          |
| Chiuso       | 1                          |

La resistenza è fondamentale perché evita un cortocircuito diretto tra +5 V e massa quando lo switch viene chiuso.

Senza la resistenza, chiudere lo switch potrebbe collegare direttamente alimentazione e massa, causando una corrente troppo elevata. Con la resistenza, invece, la corrente viene limitata a un valore sicuro.

Nel progetto possiamo usare, ad esempio, resistenze da 4.7 kΩ.

## Circuito di pull-up

Il circuito di pull-up funziona in modo speculare rispetto al pull-down.

In questo caso la resistenza collega il nodo di uscita a +5 V, mentre lo switch collega il nodo a massa.

Lo schema concettuale è questo:

```text
+5 V
 |
 R
 |
nodo di uscita ---- ingresso logico
 |
switch
 |
GND
```

Quando lo switch è aperto, la resistenza tira il nodo verso +5 V. L'ingresso legge quindi un 1.

Quando invece chiudiamo lo switch, il nodo viene collegato direttamente a massa e l'ingresso legge uno 0.

Il comportamento è quindi:

| Stato switch | Valore letto dall'ingresso |
| ------------ | -------------------------- |
| Aperto       | 1                          |
| Chiuso       | 0                          |

Anche in questo caso la resistenza è indispensabile. Quando lo switch viene chiuso, la resistenza impedisce che +5 V e massa siano collegati direttamente senza limitazione di corrente.

## Pull-down e pull-up a confronto

Entrambi i circuiti servono allo stesso scopo: garantire che un ingresso abbia sempre un valore definito.

La differenza principale è il valore predefinito dell'ingresso:

| Circuito  | Valore con switch aperto | Valore con switch chiuso |
| --------- | -----------------------: | -----------------------: |
| Pull-down |                        0 |                        1 |
| Pull-up   |                        1 |                        0 |

Nel pull-down lo stato di riposo è 0.

Nel pull-up lo stato di riposo è 1.

La scelta tra i due dipende dal comportamento che vogliamo ottenere e dal tipo di logica che stiamo usando.

Nel nostro progetto, inizialmente possiamo ragionare con entrambi gli schemi. Tuttavia, lavorando con integrati TTL, il pull-up può risultare più stabile in alcune situazioni pratiche. Per questo motivo, sugli switch usati per impostare le variabili della CPU, può essere conveniente usare una configurazione di pull-up.

## Perché gli ingressi TTL richiedono attenzione

Gli integrati TTL hanno caratteristiche elettriche specifiche.

Un livello logico basso non è semplicemente “qualsiasi tensione vicina a 0”, e un livello logico alto non è “qualsiasi tensione vicina a 5 V”. Ogni famiglia logica ha soglie precise entro cui interpreta un segnale come 0 o come 1.

Inoltre, gli ingressi TTL non si comportano esattamente come ingressi ideali. Per questo motivo è importante pilotarli con segnali ben definiti e non lasciarli mai scollegati.

Quando usiamo uno switch, il contatto meccanico apre o chiude un collegamento. Ma se non aggiungiamo una resistenza di pull-up o pull-down, almeno una delle due posizioni dello switch lascia l'ingresso senza riferimento.

Questo può portare a comportamenti casuali.

Ad esempio, una porta AND potrebbe leggere un 1 anche se pensiamo di aver lasciato l'ingresso a 0. Oppure una linea del bus potrebbe cambiare stato apparentemente senza motivo.

La stabilità degli ingressi è quindi una condizione necessaria per costruire circuiti affidabili.

## Applicazione alle variabili A e B

Nelle prime reti dell'ALU useremo due variabili principali:

- A
- B

Ogni variabile sarà larga 8 bit. Avremo quindi:

```text
A7 A6 A5 A4 A3 A2 A1 A0
B7 B6 B5 B4 B3 B2 B1 B0
```

Ogni bit verrà impostato tramite uno switch.

Questi switch dovranno essere collegati agli ingressi delle reti logiche dell'ALU: AND, OR, XOR, NOR e così via.

Per ogni linea dovremo quindi garantire un livello stabile. Se usiamo un pull-up, ogni ingresso sarà normalmente a 1 quando lo switch è aperto e passerà a 0 quando lo switch viene chiuso. Se usiamo un pull-down, il comportamento sarà opposto.

L'importante è mantenere coerenza tra il cablaggio fisico e il modo in cui leggiamo gli switch.

Se il pull-up ci dà logica invertita rispetto a ciò che ci aspettiamo visivamente dallo switch, possiamo compensare organizzando la posizione degli switch o etichettando chiaramente quale posizione corrisponde a 0 e quale a 1.

## Resistenza di pull-up o pull-down

Il valore della resistenza deve essere scelto in modo da garantire un livello logico stabile senza far circolare troppa corrente.

Un valore tipico per questi esperimenti è 4.7 kΩ.

Con una resistenza di questo tipo otteniamo un buon compromesso:

- il nodo viene portato stabilmente a 0 o a 1
- la corrente resta limitata
- lo switch può forzare facilmente il valore opposto

Valori troppo bassi farebbero circolare più corrente del necessario. Valori troppo alti potrebbero rendere il nodo più sensibile ai disturbi.

Per il nostro progetto, l'obiettivo non è ottimizzare ogni singolo parametro elettrico, ma costruire un circuito stabile, comprensibile e facile da testare.

## Esempio pratico con un bit

Immaginiamo di voler impostare il bit A0 usando un circuito di pull-down.

Quando lo switch è aperto, A0 viene collegato a massa tramite la resistenza. Quindi A0 vale 0.

Quando chiudiamo lo switch, A0 viene collegato a +5 V. Quindi A0 vale 1.

Questo bit può essere collegato, ad esempio, all'ingresso di una porta AND.

Se facciamo la stessa cosa anche per B0, possiamo testare la tabella di verità della porta AND sul bit meno significativo:

|  A0 |  B0 | AND |
| --: | --: | --: |
|   0 |   0 |   0 |
|   0 |   1 |   0 |
|   1 |   0 |   0 |
|   1 |   1 |   1 |

La cosa importante è che A0 e B0 non siano mai flottanti. In ogni momento devono essere collegati, direttamente o tramite resistenza, a un livello logico valido.

## Pull-up e logica invertita

Nel caso del pull-up bisogna ricordare che il comportamento dello switch è invertito rispetto al pull-down.

Con pull-up:

- switch aperto → ingresso a 1
- switch chiuso → ingresso a 0

Questo può sembrare meno intuitivo all'inizio, perché spesso immaginiamo lo switch chiuso come “acceso” e quindi associato a 1.

In realtà non è un problema, purché il cablaggio sia chiaro e coerente.

Molti circuiti digitali usano segnali attivi bassi, cioè segnali che si attivano quando sono a 0. Anche nel nostro progetto incontreremo spesso questa logica, ad esempio con gli enable dei buffer tri-state o con alcune uscite dei decoder.

Abituarsi a leggere segnali attivi bassi è quindi molto utile.

## Errori comuni da evitare

Quando si cablano switch e ingressi digitali, ci sono alcuni errori molto comuni.

Il primo errore è collegare lo switch a +5 V senza una resistenza verso massa. In questo caso, quando lo switch è aperto, l'ingresso resta flottante.

Il secondo errore è collegare direttamente +5 V e massa tramite lo switch, senza una resistenza di limitazione. In questo caso, chiudendo lo switch si crea un cortocircuito.

Il terzo errore è usare valori di resistenza non adatti o dimenticare che la logica può essere invertita nel caso del pull-up.

Il quarto errore è non mantenere una convenzione chiara tra bit, switch e fili. Quando avremo 8 bit per A e 8 bit per B, più i segnali di enable e le uscite verso il bus, l'ordine dei collegamenti diventerà fondamentale.

## Test degli ingressi

Prima di collegare gli switch alle reti logiche, conviene testarli uno alla volta.

Possiamo collegare temporaneamente l'uscita di uno switch a un LED, oppure leggerla con un multimetro.

Nel caso di pull-down ci aspettiamo:

```text
switch aperto  -> circa 0 V
switch chiuso  -> circa 5 V
```

Nel caso di pull-up ci aspettiamo:

```text
switch aperto  -> circa 5 V
switch chiuso  -> circa 0 V
```

Questo test semplice ci permette di verificare che ogni bit produca il livello logico corretto prima di collegarlo agli ingressi dell'ALU.

È molto meglio individuare un problema in questa fase che scoprirlo più avanti, quando il segnale sarà già collegato a più integrati.

## Perché questo passaggio è fondamentale

Pull-up e pull-down sembrano dettagli secondari, ma in realtà sono fondamentali per il funzionamento di tutta la CPU.

Una CPU è un sistema digitale composto da molti segnali. Se anche solo alcuni di questi segnali non sono ben definiti, l'intero circuito può comportarsi in modo instabile.

Prima di progettare operazioni complesse, dobbiamo quindi assicurarci che gli ingressi siano affidabili.

Questo articolo serve proprio a fissare questa regola di base: ogni ingresso deve sempre avere un valore noto.

## Conclusione

In questo articolo abbiamo visto perché gli ingressi digitali non devono mai essere lasciati flottanti.

Abbiamo introdotto i circuiti di pull-down e pull-up, analizzando il loro comportamento con uno switch. Abbiamo visto che il pull-down mantiene l'ingresso normalmente a 0, mentre il pull-up lo mantiene normalmente a 1.

Abbiamo anche discusso perché, usando integrati TTL, è importante fornire segnali stabili e ben definiti agli ingressi delle porte logiche.

Nel prossimo articolo inizieremo finalmente a costruire il primo blocco operativo dell'ALU: la rete AND a 8 bit.

Vedremo la tabella di verità della porta AND, il componente 7408, il collegamento degli ingressi A e B e il modo in cui il risultato verrà portato verso il bus dati tramite un buffer tri-state.
