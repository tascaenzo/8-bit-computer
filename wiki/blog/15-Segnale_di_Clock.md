# Segnale di clock

Negli articoli precedenti abbiamo costruito la parte principale dell'ALU della nostra CPU a 8 bit. Abbiamo visto le operazioni logiche, il circuito di somma e sottrazione, i flag, le operazioni di confronto e il codice operazione.

Tutti questi circuiti appartengono principalmente alla logica combinatoria: dato un certo insieme di ingressi, producono un certo insieme di uscite.

Ora dobbiamo iniziare a ragionare sulla parte sequenziale della CPU.

Una CPU non deve solo calcolare risultati. Deve anche salvarli, spostarli tra registri, leggere istruzioni e procedere in modo ordinato da uno stato al successivo. Per fare questo serve un segnale che scandisca il tempo: il clock.

## Cos'è il clock

Il clock è un segnale periodico usato per sincronizzare le operazioni della CPU.

Possiamo immaginarlo come un metronomo. Ogni impulso scandisce un istante in cui i circuiti sequenziali possono aggiornare il proprio stato.

Senza clock, i vari blocchi della CPU cambierebbero stato appena cambiano gli ingressi, senza un ordine preciso. Con il clock, invece, possiamo stabilire quando un registro deve salvare un dato, quando un contatore deve avanzare o quando una certa fase dell'esecuzione deve iniziare.

Il clock non è il circuito che esegue le operazioni, ma è il segnale che coordina il momento in cui le operazioni vengono acquisite o propagate.

## Onda quadra

Il segnale di clock viene normalmente rappresentato come un'onda quadra.

Un'onda quadra alterna due livelli:

```text
livello basso -> 0
livello alto  -> 1
```

Graficamente possiamo immaginarla così:

```text
__----____----____----____----__
```

Il segnale resta per un certo tempo a 0, poi passa a 1, resta a 1 per un certo tempo, poi torna a 0, e così via.

Questa alternanza regolare permette ai circuiti della CPU di usare il clock come riferimento temporale.

## Periodo e frequenza

Il periodo è il tempo necessario al clock per completare un ciclo intero.

Un ciclo completo comprende:

- una fase a livello basso
- una fase a livello alto

Se indichiamo il periodo con T, la frequenza si calcola come:

```text
f = 1 / T
```

La frequenza indica quanti cicli il clock compie in un secondo e si misura in hertz.

Ad esempio:

```text
1 Hz = 1 ciclo al secondo
10 Hz = 10 cicli al secondo
1000 Hz = 1000 cicli al secondo
```

Nel nostro progetto non abbiamo bisogno di un clock molto veloce. Anzi, durante la fase di sviluppo è utile avere un clock relativamente lento, in modo da poter osservare il comportamento della CPU con LED e strumenti di misura.

## Duty cycle

Un altro parametro importante è il duty cycle.

Il duty cycle indica per quale percentuale del periodo il segnale resta a livello alto.

Se un clock ha duty cycle del 50%, significa che passa metà del tempo a 0 e metà del tempo a 1.

Esempio:

```text
livello alto: 50% del periodo
livello basso: 50% del periodo
```

In molti casi un duty cycle vicino al 50% è ideale, ma non sempre è strettamente necessario.

Nel nostro progetto useremo soprattutto i fronti del clock, cioè gli istanti in cui il segnale cambia stato. Per questo motivo il duty cycle non sarà il parametro più critico, almeno nelle prime fasi.

## Fronti di salita e discesa

Gli istanti più importanti di un segnale di clock sono i fronti.

Il fronte di salita è il momento in cui il clock passa da 0 a 1:

```text
0 -> 1
```

Il fronte di discesa è il momento in cui il clock passa da 1 a 0:

```text
1 -> 0
```

Molti circuiti sequenziali, come flip-flop e registri, aggiornano il proprio stato su uno specifico fronte del clock.

Nel nostro progetto ci concentreremo soprattutto sul fronte di salita.

Questo significa che un registro potrà salvare un dato proprio nell'istante in cui il clock passa da livello basso a livello alto.

## Perché usare il fronte del clock

Usare il fronte del clock è molto importante.

Se un registro salvasse dati per tutto il tempo in cui il clock è alto, potrebbe aggiornarsi mentre altri segnali stanno ancora cambiando. Questo renderebbe il comportamento più difficile da controllare.

Usando invece un fronte, il salvataggio avviene in un istante preciso.

Il circuito ha quindi una fase in cui i segnali si stabilizzano e un momento preciso in cui vengono acquisiti.

Questa idea è alla base del funzionamento delle macchine sequenziali sincrone.

## Clock automatico e clock manuale

Durante lo sviluppo della CPU è utile avere due modalità di clock:

- clock automatico
- clock manuale

Il clock automatico genera impulsi continuamente a una certa frequenza. È utile quando il circuito è già abbastanza stabile e vogliamo farlo funzionare in modo continuo.

Il clock manuale, invece, genera un singolo impulso quando premiamo un pulsante. È utilissimo durante il debug, perché ci permette di avanzare la CPU un passo alla volta.

In un progetto didattico, il clock manuale è quasi indispensabile.

Permette di osservare cosa succede dopo ogni impulso, controllare i LED, verificare i registri e capire meglio la sequenza delle operazioni.

## Generare un clock

Esistono molti modi per generare un'onda quadra.

Un circuito molto comune è basato sul timer 555, configurato come oscillatore astabile.

Nel nostro progetto, però, useremo un'altra soluzione: un trigger di Schmitt con una resistenza e un condensatore.

L'idea è sfruttare la carica e la scarica di un condensatore. Il condensatore produce un segnale analogico che sale e scende gradualmente. Il trigger di Schmitt trasforma questo segnale in un'onda quadra digitale.

## Trigger di Schmitt

Un trigger di Schmitt è un circuito con isteresi.

Questo significa che ha due soglie:

- una soglia alta
- una soglia bassa

Quando il segnale in ingresso supera la soglia alta, l'uscita cambia stato.

Quando il segnale in ingresso scende sotto la soglia bassa, l'uscita cambia di nuovo stato.

L'isteresi rende il circuito più stabile, perché evita continui cambiamenti di uscita quando il segnale in ingresso è vicino a una sola soglia.

Il trigger di Schmitt è quindi molto utile per trasformare segnali lenti o rumorosi in segnali digitali più netti.

## Il 7414 e il 74HC14

Per realizzare il trigger di Schmitt possiamo usare integrati come:

```text
7414
74HC14
```

Entrambi contengono inverter con ingresso a trigger di Schmitt.

La differenza principale è la famiglia logica.

Il 7414 appartiene alla famiglia TTL.

Il 74HC14 appartiene alla famiglia CMOS ad alta velocità.

Nel progetto può essere conveniente usare il 74HC14, perché produce livelli di uscita più vicini alla tensione di alimentazione e può risultare più adatto alla generazione di un clock stabile nel nostro circuito.

Come sempre, bisogna fare attenzione alle caratteristiche elettriche della famiglia logica usata, soprattutto per quanto riguarda correnti e valori delle resistenze.

## Oscillatore con trigger di Schmitt

Il circuito base per generare il clock è composto da:

- un inverter con trigger di Schmitt
- una resistenza di retroazione
- un condensatore verso massa

Lo schema concettuale è:

```text
          R
uscita ----/\/\/\---- ingresso
                         |
                         C
                         |
                        GND
```

L'uscita dell'inverter viene riportata all'ingresso tramite la resistenza.

Il condensatore è collegato tra ingresso e massa.

Il condensatore si carica e si scarica attraverso la resistenza. Quando la tensione sull'ingresso supera una soglia del trigger di Schmitt, l'uscita cambia stato. Questo cambiamento fa invertire il processo di carica/scarica, generando un'oscillazione continua.

Il risultato è un'onda quadra in uscita.

## Frequenza dell'oscillatore

La frequenza dipende dai valori di resistenza e capacità.

In modo semplificato possiamo dire che la frequenza è legata al prodotto:

```text
R · C
```

Aumentando R o C, il condensatore impiega più tempo a caricarsi e scaricarsi, quindi la frequenza diminuisce.

Diminuendo R o C, il ciclo diventa più rapido e la frequenza aumenta.

Una formula approssimata spesso usata è:

```text
f ≈ 1 / (R · C)
```

Questa formula non tiene conto di tutti i dettagli reali del circuito, delle soglie del trigger e delle tolleranze dei componenti, ma è utile per avere un ordine di grandezza.

Nella pratica, il valore misurato può essere diverso da quello calcolato.

## Scelta dei componenti

Se usiamo un 74HC14, dobbiamo scegliere valori di resistenza e condensatore compatibili con la logica CMOS.

Una possibile scelta è:

```text
R = 200 kΩ
C = 10 nF
```

Questi valori generano un clock nell'ordine di alcune centinaia di hertz, adatto a un progetto didattico.

L'obiettivo non è ottenere una frequenza precisa, ma generare un segnale abbastanza stabile da poter essere usato dalla CPU.

Per verificare il risultato, possiamo collegare l'uscita del circuito a un oscilloscopio e misurare:

- frequenza
- ampiezza
- forma dell'onda
- duty cycle

## Clock manuale con pulsante

Oltre al clock automatico vogliamo anche un clock manuale.

Il clock manuale deve generare un impulso quando premiamo un pulsante.

L'idea è collegare un pulsante a un ingresso con pull-up o pull-down, far passare il segnale attraverso un trigger di Schmitt e ottenere un impulso pulito.

Un possibile schema concettuale è:

```text
+5 V
 |
 R
 |
nodo ---- ingresso trigger di Schmitt ---- uscita clock manuale
 |
pulsante
 |
GND
```

Quando il pulsante non è premuto, il nodo è mantenuto a +5 V dalla resistenza di pull-up.

Quando premiamo il pulsante, il nodo viene portato a massa.

Il trigger di Schmitt aiuta a trasformare la transizione in un segnale digitale più pulito.

## Il problema del rimbalzo dei pulsanti

I pulsanti meccanici non cambiano stato in modo perfetto.

Quando premiamo un pulsante, i contatti interni possono rimbalzare per un breve tempo. Questo fenomeno si chiama bounce o rimbalzo.

Dal punto di vista del circuito digitale, invece di un solo impulso potremmo ottenere più transizioni rapide.

Per una CPU questo è un problema: premendo una sola volta il pulsante potremmo generare più impulsi di clock.

Per ridurre il problema possiamo usare un condensatore di debounce.

Il condensatore filtra le variazioni rapide e rende il segnale più stabile prima dell'ingresso del trigger di Schmitt.

## Selettore del clock

Poiché vogliamo avere sia il clock automatico sia il clock manuale, possiamo usare un selettore.

Ad esempio, un interruttore a tre posizioni può permettere di scegliere tra:

```text
clock automatico
clock manuale
clock disattivato
```

L'uscita del selettore sarà il clock effettivo della CPU.

Schema concettuale:

```text
clock automatico ----\
                     selettore ---- clock CPU
clock manuale -------/
```

Questa soluzione rende il progetto molto più comodo da testare.

Durante il debug possiamo avanzare manualmente.

Quando il circuito funziona, possiamo passare al clock automatico.

## Livelli logici del clock

Il clock deve produrre livelli logici compatibili con gli integrati della CPU.

Se alimentiamo il circuito a 5 V, idealmente vorremmo che il clock oscillasse tra:

```text
0 V
5 V
```

Nella pratica, alcuni integrati potrebbero produrre un livello alto inferiore a 5 V.

È importante verificare che il livello alto sia comunque riconosciuto come 1 dagli integrati successivi.

Usando un 74HC14 possiamo ottenere un livello alto molto vicino alla tensione di alimentazione, ad esempio intorno a 4.7 V, rendendo il segnale più netto.

## Verifica con oscilloscopio

L'oscilloscopio è lo strumento ideale per verificare il segnale di clock.

Con l'oscilloscopio possiamo osservare:

- se il segnale oscilla correttamente
- la frequenza effettiva
- il duty cycle
- il valore massimo e minimo della tensione
- eventuali disturbi o rimbalzi

Ad esempio, potremmo misurare un clock intorno a 700 Hz.

Anche se il valore teorico era leggermente diverso, questo non è un problema: le tolleranze di resistenze, condensatori e soglie interne del trigger possono modificare la frequenza reale.

Per il nostro progetto conta soprattutto avere un segnale stabile e leggibile dagli altri circuiti.

## Clock e registri

Il clock diventerà fondamentale quando inizieremo a costruire registri.

Un registro deve salvare un dato in un momento preciso.

Ad esempio, potremmo voler salvare nel registro A il valore presente sul bus dati.

Non vogliamo che il registro cambi continuamente mentre il bus cambia. Vogliamo che acquisisca il valore solo quando arriva un fronte di clock.

Il comportamento desiderato sarà:

```text
fronte di salita del clock -> salva il dato
altri momenti -> mantieni il valore precedente
```

Questo sarà possibile usando flip-flop e registri sincronizzati.

## Clock e macchina sequenziale

Con l'introduzione del clock, la CPU inizia a diventare una macchina sequenziale.

La logica combinatoria produce risultati in base agli ingressi.

La logica sequenziale salva stati in base al clock.

Una CPU ha bisogno di entrambe:

- logica combinatoria per calcolare
- logica sequenziale per ricordare e procedere nel tempo

L'ALU che abbiamo costruito finora produce risultati.

I registri che costruiremo più avanti conserveranno quei risultati.

Il clock coordinerà il momento in cui i dati verranno salvati.

## Errori comuni

Quando si costruisce un circuito di clock ci sono alcuni errori frequenti.

Il primo è usare valori di resistenza troppo bassi con integrati CMOS, facendo circolare correnti non adatte alla famiglia logica.

Il secondo è non gestire il rimbalzo del pulsante manuale, ottenendo più impulsi invece di uno solo.

Il terzo è pensare che il duty cycle debba essere sempre perfettamente al 50%. In molti casi conta soprattutto avere fronti chiari e livelli logici validi.

Il quarto è non controllare l'ampiezza del segnale. Un'onda quadra troppo bassa potrebbe non essere interpretata correttamente dagli altri integrati.

Il quinto è collegare direttamente più sorgenti di clock senza un selettore o un isolamento adeguato.

Il sesto è dimenticare che il clock sarà uno dei segnali più importanti e distribuiti della CPU: deve essere stabile e ben cablato.

## Riepilogo

Il clock è il segnale che sincronizza la CPU.

È normalmente rappresentato come un'onda quadra.

I suoi parametri principali sono:

```text
periodo
frequenza
duty cycle
fronte di salita
fronte di discesa
```

Nel progetto useremo:

```text
clock automatico -> generato con trigger di Schmitt, resistenza e condensatore
clock manuale    -> generato con pulsante e debounce
selettore        -> per scegliere la sorgente del clock
```

Il clock sarà usato soprattutto per aggiornare registri e flip-flop sul fronte di salita.

## Conclusione

In questo articolo abbiamo introdotto il segnale di clock della nostra CPU a 8 bit.

Abbiamo visto che il clock funziona come un metronomo, scandendo gli istanti in cui i circuiti sequenziali possono aggiornarsi. Abbiamo analizzato onda quadra, frequenza, periodo, duty cycle e fronti di salita e discesa.

Abbiamo poi visto come generare un clock automatico usando un trigger di Schmitt, una resistenza e un condensatore, e come affiancare a questo un clock manuale utile per il debug.

Con il clock siamo pronti a entrare nel mondo della memoria digitale.

Nel prossimo articolo introdurremo il flip-flop SR, una delle celle di memoria più semplici, e vedremo come sia possibile memorizzare un singolo bit usando porte logiche.
