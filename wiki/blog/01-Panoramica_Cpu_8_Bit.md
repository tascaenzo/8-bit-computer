# Costruiamo una CPU a 8 bit da zero: panoramica del progetto

Costruire una CPU può sembrare qualcosa di estremamente complesso, quasi irraggiungibile. Siamo abituati a pensare ai processori come a componenti minuscoli, potentissimi, realizzati con tecnologie industriali avanzate e miliardi di transistor.

In questa serie, però, proveremo a fare un percorso diverso: costruiremo una CPU a 8 bit partendo dai blocchi fondamentali dell'elettronica digitale. Non useremo un microcontrollore già pronto e non programmeremo una scheda per “simulare” una CPU. L'obiettivo sarà capire come funziona davvero un processore, costruendolo passo dopo passo con porte logiche, integrati, registri, bus dati, clock e unità di controllo.

Questa non vuole essere soltanto una guida pratica, ma anche un percorso didattico. Ogni circuito che costruiremo avrà uno scopo preciso all'interno della CPU e cercheremo di capire non solo come collegarlo, ma soprattutto perché serve.

## Perché costruire una CPU a 8 bit

Una CPU a 8 bit è un ottimo punto di partenza per studiare l'architettura dei processori.

Da un lato è abbastanza semplice da poter essere costruita e compresa con componenti discreti o integrati logici della famiglia TTL/CMOS. Dall'altro, è sufficientemente completa da contenere tutti i concetti fondamentali presenti anche nei processori più complessi: operazioni aritmetiche e logiche, registri, segnali di controllo, clock, bus dati e istruzioni.

Il fatto che sia a 8 bit significa che la CPU lavorerà principalmente con dati larghi 8 bit. In altre parole, il bus dati, i registri principali e l'uscita dell'ALU saranno progettati per gestire valori composti da 8 linee digitali.

Con 8 bit possiamo rappresentare 256 combinazioni diverse. Se interpretiamo i valori come numeri senza segno, possiamo rappresentare i numeri da 0 a 255. Se invece decidiamo di usare una rappresentazione con segno, ad esempio il complemento a due, possiamo rappresentare valori da -128 a +127.

Queste scelte diventeranno importanti quando inizieremo a parlare di somme, sottrazioni, overflow e flag di stato.

## Cosa fa una CPU

Una CPU, in modo molto semplificato, è un circuito capace di eseguire una sequenza di operazioni.

Queste operazioni possono essere di vario tipo: sommare due numeri, confrontare due valori, spostare un dato da un registro a un altro, leggere un'istruzione dalla memoria o decidere se eseguire un salto condizionale.

Per fare tutto questo, una CPU è composta da diversi blocchi che collaborano tra loro. Ogni blocco ha un ruolo specifico. Alcuni blocchi elaborano i dati, altri li memorizzano temporaneamente, altri ancora generano i segnali di controllo necessari per coordinare il funzionamento dell'intero circuito.

Nel nostro progetto costruiremo questi blocchi uno alla volta, partendo dai più semplici fino ad arrivare a una struttura sempre più vicina a una CPU completa.

## I blocchi principali del progetto

La CPU che costruiremo sarà composta da diversi moduli fondamentali.

Il primo blocco importante sarà l'ALU, cioè l'unità aritmetico-logica. È il circuito incaricato di eseguire operazioni sui dati: AND, OR, XOR, NOT, somma, sottrazione e confronto.

Poi avremo il bus dati, cioè l'insieme di linee elettriche su cui viaggeranno le informazioni all'interno della CPU. Nel nostro caso sarà un bus a 8 bit, quindi formato da otto linee parallele.

Avremo poi i registri, che serviranno a memorizzare temporaneamente i dati. Possiamo immaginarli come piccole celle di memoria interne alla CPU, usate per conservare valori durante l'esecuzione delle istruzioni.

Un altro blocco fondamentale sarà il clock. Il clock è il segnale che sincronizza le operazioni della CPU. Possiamo immaginarlo come un metronomo: ogni impulso scandisce un istante in cui qualcosa può essere letto, scritto o aggiornato.

Infine arriveremo all'unità di controllo, cioè il circuito che decide quali segnali attivare in base all'istruzione da eseguire. È la parte che coordina tutti gli altri blocchi e permette alla CPU di eseguire una sequenza ordinata di operazioni.

## Il ruolo dell'ALU

Nel nostro percorso inizieremo proprio dall'ALU.

L'ALU, acronimo di Arithmetic Logic Unit, è il blocco che esegue le operazioni aritmetiche e logiche. Avrà due ingressi principali, che chiameremo A e B, e un'uscita collegata al bus dati.

Oltre agli ingressi A e B, l'ALU riceverà anche un codice operazione. Questo codice servirà a selezionare quale operazione eseguire. Ad esempio, un codice potrà indicare l'operazione AND, un altro l'operazione OR, un altro ancora la somma o la sottrazione.

L'idea generale è questa: gli ingressi A e B contengono i dati da elaborare, il codice operazione dice all'ALU cosa fare, e l'uscita contiene il risultato.

Per rendere il progetto modulare, realizzeremo inizialmente le varie operazioni come reti separate. Avremo quindi una rete per l'AND, una per l'OR, una per lo XOR, una per la somma e così via. Ogni rete produrrà un risultato, ma solo una alla volta sarà autorizzata a scrivere sul bus dati.

Questo ci porterà a introdurre un concetto molto importante: i buffer tri-state.

## Il bus dati e i buffer

Il bus dati è una delle parti più importanti del progetto.

Tutti i moduli della CPU devono poter comunicare tra loro, ma non possono farlo in modo disordinato. Se due circuiti provassero a scrivere contemporaneamente sullo stesso bus, potremmo avere conflitti elettrici e risultati imprevedibili.

Per evitare questo problema useremo dei buffer tri-state. Questi componenti permettono di collegare o scollegare l'uscita di un circuito dal bus dati tramite un segnale di enable.

Quando il buffer è abilitato, il risultato prodotto da una rete logica può raggiungere il bus. Quando invece il buffer è disabilitato, l'uscita viene messa in alta impedenza, comportandosi come se fosse fisicamente scollegata dal bus.

Questo meccanismo sarà fondamentale per tutta la CPU. Ci permetterà di avere molti moduli collegati allo stesso bus, ma di abilitarne uno solo alla volta.

Nel progetto useremo anche dei LED collegati alle linee del bus dati. Questo ci permetterà di vedere visivamente quali bit sono a 1 e quali sono a 0, rendendo il debug molto più semplice.

## Clock, registri e memoria

Dopo aver costruito la parte combinatoria della CPU, cioè i circuiti che producono un risultato in base agli ingressi, dovremo introdurre la memoria.

Una CPU non deve solo calcolare risultati: deve anche conservarli, spostarli e usarli in momenti successivi. Per questo serviranno i registri.

I registri saranno costruiti a partire da circuiti capaci di memorizzare un singolo bit, come i flip-flop. Prima studieremo il flip-flop SR, poi passeremo al flip-flop D, che è più adatto a essere usato nei registri sincronizzati dal clock.

Il clock diventerà quindi fondamentale. Sarà il segnale che stabilirà quando un registro deve salvare un dato. In molti casi useremo il fronte di salita del clock, cioè l'istante in cui il segnale passa da livello basso a livello alto.

In questo modo la CPU non sarà più un insieme di circuiti che cambiano stato in modo continuo e indipendente, ma diventerà una macchina sequenziale, capace di eseguire operazioni ordinate nel tempo.

## Componenti e filosofia del progetto

Per costruire la CPU useremo integrati logici abbastanza comuni, come porte AND, OR, XOR, NOR, NAND, NOT, buffer, decoder, sommatori e flip-flop.

Alcuni esempi di componenti che incontreremo durante la serie sono:

- 7408 per le porte AND
- 7432 per le porte OR
- 7486 per le porte XOR
- 7402 per le porte NOR
- 7400 per le porte NAND
- 7404 per le porte NOT
- 74244 per i buffer tri-state
- 74283 per i sommatori a 4 bit
- 74138 per la decodifica del codice operazione
- 74HC14 per la generazione del clock con trigger di Schmitt

L'obiettivo non sarà usare il minor numero possibile di componenti, ma costruire una CPU comprensibile. Per questo motivo in alcune parti del progetto useremo LED, etichette e circuiti leggermente più espliciti, anche quando esisterebbero soluzioni più compatte.

Questo approccio rende il circuito più facile da seguire, testare e spiegare.

## Come sarà organizzata la serie

La serie sarà organizzata in modo progressivo.

Inizieremo dalle basi: bus dati, ingressi digitali stabili, pull-up e pull-down. Poi passeremo alla costruzione delle prime reti logiche dell'ALU, partendo dall'AND e aggiungendo progressivamente OR, XOR, NOR, NAND, XNOR e NOT.

Successivamente entreremo nella parte aritmetica, studiando la somma binaria, il complemento a due e la costruzione del circuito di somma e sottrazione con i sommatori 74283.

A quel punto introdurremo i flag di stato: Carry, Zero, Negative e Overflow. Questi bit saranno fondamentali per capire se il risultato di un'operazione è zero, negativo, fuori range o se ha generato un riporto.

Useremo poi questi flag anche per implementare le operazioni di confronto tra due numeri, come A = B, A < B e A > B.

Dopo aver completato l'ALU, passeremo al codice operazione, cioè al sistema che permette di selezionare quale operazione eseguire. Useremo dei decoder per trasformare un codice binario in segnali di enable destinati alle varie reti dell'ALU.

Infine inizieremo la parte sequenziale della CPU: clock, flip-flop, registri e, successivamente, unità di controllo.

## Cosa costruiremo nel prossimo articolo

Nel prossimo articolo partiremo da uno degli elementi più semplici ma più importanti del progetto: il bus dati.

Vedremo cos'è un bus, perché nel nostro caso sarà largo 8 bit e come possiamo usare dei LED per osservare i valori che transitano all'interno della CPU.

Prima di costruire operazioni complesse, dobbiamo infatti preparare la “strada” su cui viaggeranno i dati. Una volta pronto il bus, potremo iniziare a collegare i primi blocchi logici della nostra ALU.

Questo sarà il primo vero passo pratico nella costruzione della nostra CPU a 8 bit.
