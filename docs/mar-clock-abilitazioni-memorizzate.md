# Clock dei MAR con 74HC377 e abilitazioni memorizzate

Revisione 15 novembre 2026 per il componente indicato dall'utente: **74HC377**.
Sostituisce la proposta con 74HCT74. Schema da collaudare sulla CPU, non ancora montato.

![Schema attuale](../output/schemi/mar-clock-74hc377.png)

[Versione SVG ingrandibile](../output/schemi/mar-clock-74hc377.svg).
U1/U2/U3 sono riferimenti locali a questo disegno, non i traduttori della Tang.

## Componenti e funzione

- U1: 74HC377, DIP-20, alimentato a 5 V; due degli otto canali memorizzano gli enable MAR.
- U2: 74HCT14, DIP-14, 5 V; un inverter genera /CK e quattro inverter (due per linea) adattano i livelli degli enable EEPROM senza invertirne la polarità.
- U3: 74HCT08, DIP-14, 5 V; due AND mascherano gli enable durante reset, due qualificano il clock dei MAR.

Il 74HC377 ha ingressi CMOS: il livello alto minimo garantito dalla AT28C64B
(2,4 V nelle condizioni specificate) non soddisfa la soglia HC a 4,5 V (3,15 V).
Gli ingressi HCT di U2 accettano TTL e le sue uscite forniscono livelli CMOS.
**U2 deve essere HCT14, non HC14.**

## Fili: pin fisici, visti dall'alto

### Clock e inizializzazione

| Sorgente | Destinazione |
| --- | --- |
| CK CPU, disponibile anche con reset premuto | U2 pin 1; U3 pin 5 e 13 |
| U2 pin 2, /CK_CPU | U1 pin 11 (CLK) |
| /RESET_CPU, 0 durante reset | U3 pin 2 e 10 |
| GND | U1 pin 1 (/G), abilitazione di acquisizione sempre attiva |

### MAR basso

| Sorgente | Destinazione |
| --- | --- |
| CU1 D2, pin 13 (MAR_L_WE) | U2 pin 3 |
| U2 pin 4 | U2 pin 5 |
| U2 pin 6 | U1 pin 3 (primo D) |
| U1 pin 2 (primo Q) | U3 pin 1 |
| U3 pin 3 (Q AND /RESET) | U3 pin 4 |
| U3 pin 6 | CK del MAR basso |

### MAR alto

| Sorgente | Destinazione |
| --- | --- |
| CU2 D2, pin 13 (MAR_H_WE) | U2 pin 9 |
| U2 pin 8 | U2 pin 11 |
| U2 pin 10 | U1 pin 4 (secondo D) |
| U1 pin 5 (secondo Q) | U3 pin 9 |
| U3 pin 8 (Q AND /RESET) | U3 pin 12 |
| U3 pin 11 | CK del MAR alto |

Se il MAR è HC574/HCT574 DIP-20, il suo CK è il pin 11; confermare la sigla
reale del registro. Scollegare le uscite delle vecchie AND dai clock dei MAR:
le nuove uscite le sostituiscono. Non mettere in parallelo due uscite.

### Alimentazione e pin inutilizzati

| Chip | Collegamento |
| --- | --- |
| U1 HC377 | VCC pin 20 a +5 V; GND pin 10 a massa |
| U2 HCT14 e U3 HCT08 | VCC pin 14 a +5 V; GND pin 7 a massa |
| Tutti | 100 nF tra VCC e GND, vicino al chip; massa comune CPU |
| U1 ingressi D inutilizzati | Pin 7, 8, 13, 14, 17, 18 a GND |
| U1 uscite Q inutilizzate | Pin 6, 9, 12, 15, 16, 19 scollegati |
| U2 inverter inutilizzato | Pin 13 a GND; pin 12 scollegato |
| U3 | Tutte e quattro le porte sono usate |

## Reset: sequenza necessaria per questa variante

**Il 377 non ha clear; /G non è un reset.** Le AND di reset bloccano i clock
MAR durante reset, ma non azzerano le uscite di U1. Serve inizializzarle.

1. Fermare il clock CPU basso e mantenere /RESET_CPU basso. PC e microstep devono restare azzerati per tutta la sequenza.
2. Attendere l'assestamento CU in T1 e verificare MAR_L_WE=MAR_H_WE=0. T1 non richiede caricamenti MAR, sia in BOOT sia in RUN.
3. Con RESET ancora premuto, dare un impulso completo basso-alto-basso al CK CPU. Il 377 riceve la discesa tramite U2 e copia gli enable a zero. Le AND con /RESET basso impediscono impulsi ai MAR anche se U1 era inizialmente indeterminato.
4. Tenere CK basso, rilasciare RESET e iniziare il normale ciclo CPU.

**Non rilasciare RESET con CK alto.** La stessa procedura va ripetuta dopo ogni
reset. Se il clock viene bloccato a monte mentre RESET è premuto, questo schema
non può inizializzare U1: il punto di prelievo deve consentire il suo impulso.

Prima dell'impulso sotto reset deve essere presente anche l'inibizione della
scrittura RAM durante reset già discussa per la CPU. Questa scheda protegge
solo i clock MAR, non /WE RAM e non gli altri clock locali. Se l'inibizione
/WE non è ancora montata, completarla prima di usare questa sequenza.

## Sequenza normale e collaudo

Ipotesi: microstep aggiornato alla salita del CK CPU. Durante la fase alta,
CU e due inverter di ingresso si assestano sul passo nuovo; alla discesa U1
campiona le abilitazioni. Le mantiene ferme durante la salita successiva.
Il clock effettivo MAR attraversa una sola AND dopo il CK principale: la
maschera reset è sulla linea enable, non aggiunge uno stadio al percorso CK.

Per il programma della singola H: STA/T2 acquisisce 00 nel MAR basso;
STA/T3 acquisisce 20 nel MAR alto; a STA/T5 il bus indirizzi deve essere 2000.
Durante T4 il dato 48 deve andare in MDR senza un nuovo fronte sul CK MAR alto.

Verificare sul banco che i Q del 377 cambino a clock locale già basso, e che
le durate degli impulsi e i setup/hold dei dati siano rispettati. Il ritardo
relativo tra incremento PC, cambiamento del dato RAM e CK locale MAR resta
un percorso da misurare se il problema persiste. Questo schema non è una
verifica elettrica completa della CPU e non corregge gli altri clock locali.

Nessuna riprogrammazione delle EEPROM CU o della Tang è necessaria.
La vecchia proposta è conservata in `output/schemi/archive/mar-clock-74hct74.svg`.

## Fonti primarie

- [TI SN74HC377](https://www.ti.com/lit/ds/symlink/sn74hc377.pdf): funzione, pinout DIP-20, /G e assenza di clear.
- [TI SN74HCT14](https://www.ti.com/lit/ds/symlink/sn74hct14.pdf): inverter Schmitt, livelli TTL in ingresso e CMOS in uscita, pinout.
- [TI SN74HCT08](https://www.ti.com/lit/ds/symlink/sn74hct08.pdf): AND e pinout DIP-14.
- [Microchip AT28C64B](https://ww1.microchip.com/downloads/en/DeviceDoc/doc0270.pdf): livelli di uscita delle EEPROM della CU.
- [TI SN74HC574](https://www.ti.com/lit/ds/symlink/sn74hc574.pdf): pin CK del MAR e requisiti di acquisizione, se questo è il componente montato.
