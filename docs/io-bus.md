# Bus memoria e I/O con selezione tramite chip enable

> **Stato:** architettura concordata; cablaggio e periferiche da adeguare
> **Data:** 21 ottobre 2026
> **Ambito:** RAM da 8 KiB, CPU TTL, video e altre periferiche

## Scelta architetturale

RAM e periferiche condividono `A[15:0]`, `D[7:0]` e le richieste generali di
lettura e scrittura. La RAM usa 13 linee indirizzo (`A0–A12`). Il segnale
che rileva gli indirizzi esterni al suo intervallo viene riutilizzato per
il chip enable della RAM e per abilitare la selezione delle periferiche.

```text
FUORI_RAM = A15 OR A14 OR A13
/CE_RAM = FUORI_RAM
/OE_RAM = /RD
/WE_RAM = /WR
```

Queste sono le equazioni funzionali durante RUN, per una SRAM con chip
enable attivo basso e con gli eventuali altri enable nel livello richiesto.
Gli interblocchi di boot, reset e isolamento del bus vanno mantenuti.
Si impiegano i bit dell'indirizzo effettivamente presente sul bus, anche
quando la sorgente e MAR o IDX, non soltanto le uscite del PC.

| Indirizzi | `FUORI_RAM` | `/CE_RAM` | Destinazione |
| --- | ---: | ---: | --- |
| `0x0000–0x1FFF` | 0 | 0 | RAM selezionata: 8192 byte. |
| `0x2000–0xFFFF` | 1 | 1 | RAM esclusa; spazio disponibile per periferiche I/O. |

L'intero spazio esterno alla RAM e di 56 KiB. Non si usa il solo A13:
anche un indirizzo con A13=0 e A14 o A15=1 deve escludere la RAM.
Lo spazio disponibile non implica che ogni indirizzo debba avere una
periferica implementata.

Questa scelta sostituisce le proposte precedenti di `IO_ENABLE` su ROM2 D7,
direzione su A4 e sostituzione di A4 con un bit dell'opcode. **ROM2 D7
rimane riservato e libero.** A4 torna a essere un normale bit di indirizzo.
L'I/O e memory-mapped e usa le normali istruzioni di lettura e scrittura.
La VRAM resta interna alla scheda video, esposta attraverso la sua interfaccia.

## Riuso del circuito esistente

La [trascrizione del video 27](../wiki/videos/Costruiamo%20una%20CPU%20a%208%20bit%20-%2027%20-%20Dalla%20ROM%20alla%20RAM:%20il%20BOOT.txt)
descrive gia una OR sui tre bit alti, combinata con `/WE`, per impedire
scritture fuori dall'intervallo della RAM. La nuova scelta riutilizza il
risultato della OR dei soli indirizzi, prima della combinazione con `/WE`,
e lo applica al chip enable attivo basso.

La sola protezione di `/WE` non esclude l'uscita dati durante una lettura;
il chip enable esclude entrambe le operazioni. Occorre verificare il
cablaggio effettivo prima di spostare il collegamento. La versione del
video 18 descrive il chip select fisso a massa. Le trascrizioni sono grezze:
il video 18 menziona 15 linee e una sigla trascritta come HM6256A, mentre
il video 27 descrive la RAM da 13 linee. Questi riferimenti non identificano
con certezza il componente montato oggi.

## Perche disabilitare il chip non cancella la RAM

Il chip enable controlla l'accesso a una SRAM, non la sua alimentazione.
Con il chip disabilitato, la SRAM conserva le celle, non accetta scritture
e lascia le uscite dati in alta impedenza. Riabilitandola si possono
rileggere i byte precedentemente memorizzati. Non richiede refresh.

La conservazione richiede alimentazione entro i limiti previsti dal
componente. Togliere alimentazione a una SRAM ordinaria non garantisce
la conservazione; non e equivalente a disabilitarne il chip enable.

Come riferimento verificabile, il
[datasheet Alliance Memory AS6C6264](https://www.alliancememory.com/wp-content/uploads/Alliance-Memory_64K_AS6C6264v2.0July2017.pdf)
descrive una SRAM 8K x 8: la tabella a pagina 2 associa CE# alto a standby
con uscite High-Z, indipendentemente da OE# e WE#. La pagina 7 descrive
la conservazione dei dati. Questo e un esempio documentato della classe
di memoria, **non l'identificazione del chip montato sulla CPU**.

Per il cablaggio definitivo vanno confermati sigla completa, polarita e pin
del chip enable, eventuale secondo enable, tensione e tempi del componente.

## Segnali generali di lettura e scrittura

Le uscite CU gia chiamate `RAM_OE` e `RAM_WE` assumono il ruolo generale:

| Nome nel generatore attuale | Nome funzionale sul bus | Funzione |
| --- | --- | --- |
| `RAM_OE` (attivo basso) | `/RD` | Richiesta di lettura al dispositivo selezionato. |
| `RAM_WE` (attivo basso) | `/WR` | Richiesta di scrittura al dispositivo selezionato. |

Non cambiano assegnazioni dei bit EEPROM per effetto di questa scelta.
I nomi del generatore restano quelli esistenti finche non saranno rinominati.
RAM e periferiche possono ricevere entrambe le richieste; soltanto il
dispositivo selezionato deve rispondere. Per le periferiche le condizioni
logiche sono, con selezione positiva:

```text
SELECT_i = ACCESS_OK AND FUORI_RAM AND NOT A3 AND (DEVICE_ID == i)
READ_i = SELECT_i AND NOT(/RD)
WRITE_i = SELECT_i AND NOT(/WR)
```

`ACCESS_OK` rappresenta il permesso di accesso in RUN, con reset e isolamento
inattivi; non e un nuovo bit EEPROM. Va ottenuto dai segnali di sistema
effettivamente disponibili. Durante il boot l'EPROM puo pilotare i dati
mentre `/WR` copia nella RAM: non deve attivare periferiche accidentalmente.

Il decoder della periferica deve usare `FUORI_RAM`, non semplicemente il
livello finale di `/WE_RAM`: quest'ultimo include anche la richiesta di
scrittura e non identifica da solo lo spazio di indirizzi.

## Selezione delle periferiche e indirizzi

Si riserva il nibble basso `A3–A0` alla selezione I/O: `A2–A0` selezionano
**8 periferiche**, mentre `A3` e riservato e deve valere zero. Il decoder
deve includere questa condizione nell'abilitazione: con `A3=1` nessuna
periferica risponde. Ignorare A3 produrrebbe invece indirizzi duplicati.
Questa scelta non cambia il principio di selezione della RAM: A3 e un
normale bit di indirizzo durante gli accessi alla RAM.

La mappa concordata e:

| Segnali | Funzione |
| --- | --- |
| `A15–A13` | OR per distinguere RAM e spazio I/O. |
| `A2–A0` | ID della periferica, da 0 a 7. |
| `A3` | Riservato a zero nello spazio I/O; con A3=1 nessuna periferica selezionata. |
| `A15–A4` | Indirizzo interno ricevuto dalla periferica, con vincolo di essere fuori RAM. |
| `D7–D0` | Byte completo trasferito. |
| `/RD`, `/WR` | Direzione e richiesta di accesso. |

La periferica puo decodificare le linee superiori per registri o banchi;
la sua mappa interna resta da definire. Ignorare linee superiori crea alias,
cioe indirizzi diversi che selezionano la stessa posizione.

Nel primo intervallo I/O `0x2000–0x3FFF`, la convenzione di indirizzamento e:

```text
indirizzo = 0x2000 + (offset << 4) + device_id
```

Qui `offset=0..511`, `device_id=0..7`. Posizioni consecutive della stessa
periferica distano 16 (`0x10`); lettura e scrittura usano esattamente lo stesso indirizzo.
Per esempio, ID 2 ha i primi tre offset a `0x2002`, `0x2012` e `0x2022`.
La convenzione non assegna ID o registri effettivi ai dispositivi.

## Assembly e uso di IDX

Si usano `LDA`/`STA` per indirizzi diretti e `LDAI`/`STAI` tramite IDX.
La CPU conosce la direzione dall'istruzione e la comunica con `/RD` o `/WR`.
Non si carica un bit di direzione in IDX e non servono `IN`/`OUT` per questa
interfaccia. La definizione storica di tali opcode resta separata.

Esempio per una periferica illustrativa ID 2 con registro 0 rileggibile:

```asm
.code 0x0000
LDX 0x2002       ; I/O, periferica 2, offset 0
LDI R0, 0x41
STAI R0          ; R0 -> registro della periferica tramite /WR
LDAI R1          ; registro della periferica -> R1 tramite /RD
HLT
```

Se il registro conserva e restituisce il valore scritto, alla fine R1 vale
`0x41`. IDX non cambia. La sintassi e le istruzioni sono gia previste, ma la
risposta della periferica richiede il nuovo cablaggio e la sua implementazione;
il simulatore attuale non e una verifica della nuova mappa I/O.

## Timing e integrita dei dati

Disabilitare una SRAM alimentata non cancella le celle. La sicurezza delle
transazioni richiede comunque il rispetto dei suoi tempi elettrici:

- Cambiare indirizzo con `/WR` inattivo, poi lasciare assestare la selezione
  prima di iniziare la scrittura. La OR dei bit alti puo avere transitori
  mentre cambia l'indirizzo; non deve trasformarli in accessi validi.
- Terminare la scrittura mantenendo indirizzo e dato per il tempo richiesto.
  Anche la disattivazione di `/CE` puo terminare una scrittura: non assumere
  che spostare la selezione risolva automaticamente il timing esistente.
- In lettura rispettare i ritardi da indirizzo, chip enable e output enable.
  Prima che un altro dispositivo piloti i dati, attendere il rilascio High-Z.
- Tenere `/RD` e `/WR` inattivi durante reset e nelle fasi senza trasferimento;
  evitare che RAM e periferiche pilotino insieme il bus.

Le periferiche devono eseguire una sola acquisizione per transazione, anche
se hanno un clock interno piu veloce. Il fronte di acquisizione e i tempi
vanno definiti nel loro protocollo. Non si introduce uno step separato per
codificare la direzione. I rischi descritti nell'[audit CU](control-unit-timing-audit.md)
restano da verificare sul circuito; la scelta architetturale non e un collaudo.

## Conseguenze per video e stato della migrazione

La precedente finestra video `0x4000–0x7FFF` e i registri `0xFF00–0xFF0F`
non vanno considerati la nuova mappa definitiva. Lo spazio fuori RAM rimane
disponibile per il decoder delle periferiche. Il video puo esporre registri
di comando, puntatore e dati, mantenendo la VRAM da 16 KiB interna alla FPGA;
protocollo, ID e mappa registri restano da definire. Il rendering HDMI puo
continuare indipendentemente dagli accessi CPU.

| Parte | Stato al 21 ottobre 2026 |
| --- | --- |
| OR `A15 OR A14 OR A13` e selezione tramite `/CE_RAM` | Scelta concordata; collegamenti da verificare sul chip reale. |
| `RAM_OE` e `RAM_WE` come `/RD` e `/WR` generali | Scelta concordata; nessun nuovo bit EEPROM. |
| ROM2 D7 | Rimane libero e riservato. |
| Istruzioni di accesso | `LDA`/`STA`, `LDAI`/`STAI` gia previste. |
| Numero di periferiche | Concordato: 8 ID su A0–A2; A3 riservato a zero e controllato dal decoder. |
| Decoder, timing e cablaggio periferiche | Da definire e verificare. |
| RTL video, pinout e bitstream | Implementazione precedente, da adeguare alla nuova selezione e mappa. |
| Simulatore ed esempi precedenti | Da adeguare alle periferiche e alla nuova mappa. |

Riferimenti precedenti: [video](video-hdmi.md), [tastiera e timer](io-ps2-timer.md)
e [README FPGA](../hardware/tang-nano-9k-video/README.md).
