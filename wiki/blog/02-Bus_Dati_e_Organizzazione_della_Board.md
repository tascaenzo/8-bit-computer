# Bus dati e organizzazione della board

Nel primo articolo abbiamo visto una panoramica generale del progetto: l'obiettivo è costruire una CPU a 8 bit partendo dai blocchi fondamentali dell'elettronica digitale. Prima di entrare nel dettaglio dell'ALU, dei registri, del clock e dell'unità di controllo, è utile preparare la base fisica su cui questi blocchi verranno collegati.

Uno degli elementi più importanti di questa base è il bus dati.

Il bus dati può essere immaginato come una strada condivisa sulla quale viaggiano i valori elaborati dai vari moduli della CPU. Nel nostro progetto sarà un bus a 8 bit, quindi formato da otto linee elettriche parallele. Ogni linea rappresenta un singolo bit: potrà trovarsi a livello logico basso, cioè 0, oppure a livello logico alto, cioè 1.

Costruire e rendere visibile il bus dati fin dall'inizio è molto utile, perché ci permette di osservare cosa sta succedendo all'interno della CPU durante i test. Per questo motivo collegheremo ogni linea del bus a un LED, in modo da visualizzare direttamente il valore binario presente sul bus.

## Cos'è un bus dati

In una CPU diversi moduli devono scambiarsi informazioni.

L'ALU deve poter scrivere il risultato di un'operazione. I registri devono poter leggere o scrivere valori. In futuro, anche altri blocchi potranno usare le stesse linee per trasferire dati.

Sarebbe poco pratico collegare ogni modulo direttamente a tutti gli altri con collegamenti separati. Il bus dati risolve questo problema creando un canale condiviso: tutti i blocchi principali possono essere collegati allo stesso insieme di linee, ma solo uno alla volta deve essere autorizzato a scrivere sul bus.

Nel nostro caso il bus dati è composto da 8 linee:

- D0, il bit meno significativo
- D1
- D2
- D3
- D4
- D5
- D6
- D7, il bit più significativo

Il bit D0 ha peso 1, D1 ha peso 2, D2 ha peso 4 e così via fino a D7, che ha peso 128 se interpretiamo il valore come numero senza segno.

Quando leggeremo un valore sul bus, dovremo quindi interpretare lo stato degli 8 bit come un numero binario.

Ad esempio:

```text
D7 D6 D5 D4 D3 D2 D1 D0
 0  0  0  0  0  0  0  1  = 1
 0  0  0  0  0  0  1  0  = 2
 0  0  0  0  0  1  0  1  = 5
 1  1  1  1  1  1  1  1  = 255, se interpretato senza segno
```

Più avanti, quando parleremo di numeri con segno e complemento a due, vedremo che lo stesso valore binario può essere interpretato anche in modo diverso. Per ora ci interessa soprattutto capire che il bus è il luogo in cui vedremo transitare i risultati prodotti dai circuiti.

## Perché visualizzare il bus con i LED

Durante la costruzione di una CPU fatta con integrati logici e collegamenti fisici, il debug è fondamentale.

Quando qualcosa non funziona, dobbiamo poter capire se il problema si trova negli ingressi, nelle uscite, nel cablaggio, nel segnale di enable o nel circuito logico vero e proprio.

Collegare un LED a ogni linea del bus dati ci permette di avere una visualizzazione immediata del valore presente sul bus:

- LED spento: bit a 0
- LED acceso: bit a 1

In questo modo possiamo leggere a colpo d'occhio il valore binario prodotto da una rete logica.

Ad esempio, se stiamo testando una rete AND e ci aspettiamo che il risultato sia `00000001`, dovremo vedere acceso solo il LED collegato al bit meno significativo. Se invece ci aspettiamo `11111111`, dovranno accendersi tutti gli 8 LED.

Questa visualizzazione sarà molto utile in tutti gli articoli successivi, perché ogni nuova rete dell'ALU verrà collegata al bus dati e potremo verificarne il comportamento osservando direttamente i LED.

## Collegamento dei LED al bus dati

Per collegare i LED al bus dati dobbiamo usare una resistenza in serie a ciascun LED, in modo da limitare la corrente.

Una configurazione semplice consiste nel collegare ogni linea del bus a un LED tramite una resistenza, ad esempio da 220 ohm. Quando la linea del bus si trova a livello logico alto, il LED si accende. Quando la linea è a livello logico basso, il LED rimane spento.

Lo schema concettuale di una singola linea è il seguente:

```text
Linea bus dati ---- resistenza ---- LED ---- massa
```

Oppure, a seconda di come si sceglie di cablare i LED, il collegamento può essere invertito. L'importante è che ogni LED abbia sempre una resistenza di limitazione della corrente.

Ripetendo questo schema per tutte le otto linee otteniamo una piccola barra di visualizzazione binaria.

Questa barra LED non è necessaria al funzionamento logico della CPU, ma è estremamente utile durante la costruzione e il collaudo. In un progetto didattico come questo, vedere fisicamente i bit che cambiano stato aiuta molto a capire cosa sta succedendo.

## Organizzazione fisica della board

Prima di iniziare a montare le singole reti logiche, conviene organizzare la board in modo chiaro.

Nel progetto useremo una superficie composta da più basette millefori, o comunque da un'area abbastanza grande da ospitare i vari integrati. L'idea è dividere fisicamente la CPU in zone funzionali.

Una possibile organizzazione è questa:

- una zona per l'alimentazione
- una zona per il bus dati
- una zona per l'ALU
- una zona per i flag
- una zona per il clock
- una zona futura per registri e controllo

Separare le aree aiuta a mantenere i collegamenti più ordinati e a rendere il circuito più facile da leggere.

All'inizio il progetto può sembrare semplice, ma con il passare degli articoli il numero di fili aumenta rapidamente. Avere una disposizione chiara fin da subito evita molta confusione nelle fasi successive.

## Alimentazione del circuito

La maggior parte degli integrati logici che useremo lavora con una tensione di alimentazione di 5 V.

Per questo motivo è utile predisporre una linea di alimentazione comune, con:

- +5 V
- massa, o GND

Queste due linee dovranno essere distribuite a tutti gli integrati presenti sulla board.

Ogni integrato avrà un pin di alimentazione e un pin di massa. È importante controllare sempre il datasheet del componente, perché la piedinatura può cambiare da integrato a integrato.

Ad esempio, molti integrati della serie 74xx a 14 pin hanno:

- pin 14 collegato a +5 V
- pin 7 collegato a massa

Altri integrati, come alcuni buffer a 20 pin, hanno invece alimentazione e massa su pin diversi.

Prima di alimentare il circuito è buona pratica controllare attentamente tutti i collegamenti. Un errore sull'alimentazione può impedire il funzionamento del circuito o, nei casi peggiori, danneggiare un integrato.

## Il bus come riferimento comune

Il bus dati diventerà un punto di riferimento per tutta la CPU.

Ogni volta che costruiremo una nuova rete logica, il risultato verrà portato verso il bus. Tuttavia, non potremo collegare direttamente tutte le uscite al bus dati, perché più circuiti potrebbero tentare di pilotare contemporaneamente le stesse linee.

Per questo motivo, tra le uscite delle reti logiche e il bus dati inseriremo dei buffer tri-state. Questi componenti permettono di abilitare una sola rete alla volta e di isolare tutte le altre.

Il bus, quindi, sarà condiviso, ma controllato.

Questa è una delle idee fondamentali del progetto: molti moduli possono essere fisicamente collegati allo stesso bus, ma solo il modulo selezionato deve poter scrivere un valore sulle linee dati.

Negli articoli successivi vedremo questo concetto in pratica quando collegheremo la prima rete logica dell'ALU, cioè l'operazione AND.

## Ordinare i collegamenti

In un progetto digitale costruito fisicamente, l'ordine dei collegamenti è importante quasi quanto lo schema logico.

Conviene usare colori diversi per distinguere i vari tipi di segnale. Ad esempio:

- rosso per +5 V
- nero o blu scuro per la massa
- giallo per le uscite verso il bus dati
- colori diversi per le variabili A e B
- un colore dedicato per i segnali di enable

Non è obbligatorio usare esattamente questi colori, ma è importante mantenere una convenzione coerente.

Quando i circuiti aumentano, avere fili colorati in modo ordinato permette di seguire più facilmente il percorso dei segnali. Anche etichettare i gruppi di cavi o gli integrati può essere molto utile.

Nel progetto, ad esempio, sarà utile distinguere chiaramente:

- gli ingressi A
- gli ingressi B
- le uscite delle porte logiche
- le uscite dei buffer verso il bus
- i segnali di enable
- i segnali di controllo

Questa attenzione all'ordine non serve solo per l'estetica. Serve soprattutto per ridurre gli errori e rendere più semplice la manutenzione del circuito.

## Primo test del bus dati

Prima di collegare l'ALU, possiamo fare un test molto semplice.

Prendiamo una delle linee del bus, ad esempio D0, e portiamola manualmente a +5 V. Il LED corrispondente dovrebbe accendersi. Riportando la linea a massa, il LED dovrebbe spegnersi.

Ripetendo il test sulle altre linee possiamo verificare che tutti gli 8 LED funzionino correttamente.

Questo test iniziale è importante perché ci permette di assicurarci che la visualizzazione del bus sia affidabile. Se in seguito una rete logica produrrà un risultato inatteso, sapremo che il problema non è nei LED del bus, ma probabilmente nella rete o nei collegamenti che la precedono.

Possiamo anche provare a simulare manualmente alcuni valori binari:

```text
00000001  -> solo D0 acceso
00000010  -> solo D1 acceso
00000101  -> D2 e D0 accesi
11111111  -> tutti i LED accesi
00000000  -> tutti i LED spenti
```

Questi test semplici aiutano a prendere confidenza con la lettura visiva del bus.

## Perché partire dal bus

Potremmo essere tentati di iniziare subito dalle porte logiche o dall'ALU, ma partire dal bus dati ha un vantaggio importante: ci permette di costruire fin da subito uno strumento di osservazione.

Ogni circuito successivo verrà verificato guardando cosa appare sul bus. Senza una visualizzazione chiara, ogni test sarebbe più complicato e richiederebbe continuamente l'uso di strumenti esterni.

Il bus dati con i LED diventa quindi una sorta di pannello di controllo minimale della CPU.

Non è ancora un vero registro, non è ancora memoria e non esegue nessuna operazione. Però ci mostra lo stato delle linee su cui viaggeranno i risultati prodotti dai vari blocchi.

Per questo motivo è uno dei primi elementi da preparare.

## Conclusione

In questo articolo abbiamo preparato la base del progetto.

Abbiamo visto cos'è un bus dati, perché nel nostro caso sarà largo 8 bit e perché è utile collegare ogni linea a un LED di debug. Abbiamo anche introdotto l'importanza dell'organizzazione fisica della board, dell'alimentazione a 5 V e della separazione ordinata dei vari segnali.

Il bus dati sarà il punto di incontro tra i diversi moduli della CPU. Su di esso vedremo comparire i risultati dell'ALU, i valori letti dai registri e, più avanti, i dati coinvolti nell'esecuzione delle istruzioni.

Nel prossimo articolo vedremo un altro aspetto fondamentale prima di collegare gli ingressi delle reti logiche: i circuiti di pull-up e pull-down.

Capiremo perché un ingresso digitale non deve mai essere lasciato flottante e come possiamo usare resistenze e switch per fornire valori logici stabili agli integrati della CPU.
