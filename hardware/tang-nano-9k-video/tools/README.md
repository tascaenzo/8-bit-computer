# Debug USB del bus CPU

Il bitstream video trasmette un campione ASCII circa ogni 100 ms sulla
USB-UART del debugger BL702 a bordo: **115200 baud, 8N1**, FPGA TX su pin
QN88 **17**. Non servono fili aggiuntivi; non invia comandi alla CPU.
Collegamento verificato nello [schema Sipeed](https://dl.sipeed.com/fileList/TANG/Nano%209K/2_Schematic/Tang_Nano_9k_3672_Schematic.pdf)
e nella [guida UART Sipeed](https://wiki.sipeed.com/hardware/zh/tang/Tang-Nano-9K/examples/lushaylabs/2_debugging_uart/debugging_uart.html).

## Prova a clock manuale

1. Caricare il nuovo bitstream, poi lasciare la USB-C collegata al computer.
2. Eseguire BOOT, passare a RUN e fermare la CPU nel punto da misurare.
3. Attendere almeno mezzo secondo e leggere il campione:

```sh
python3 hardware/tang-nano-9k-video/tools/debug_read.py --point 4
```

`--point` indica il numero **Punto** del PDF Hello World (1-372), non il
solo T1/T2/T3. Il punto 4 e la lettura STATUS: A=2018, /RD=0, /WR=1,
Y0=1, Y1=0, DIR=1, /OE=0, dato valido=01. Il punto 91 scrive H:
A=2000, /RD=1, /WR=0, DIR=0, /OE=0, dato=48.

La ricerca automatica prova le porte USB seriali e accetta solo righe con
prefisso CPU8v1. Per scegliere la porta o salvare dati leggibili:

```sh
python3 hardware/tang-nano-9k-video/tools/debug_read.py --port /dev/cu.usbserial-21201 --point 4 --json
python3 hardware/tang-nano-9k-video/tools/debug_read.py --seconds 10 --raw
```

Lo script apre la seriale senza alzare DTR/RTS, non scrive byte e non
reinizializza la CPU. I contatori ripartono da zero al reset FPGA, non
quando si apre la seriale o quando si cambia BOOT/RUN.

## Significato dei campi (numeri trasmessi in esadecimale)

### Registrazione continua di BOOT, RUN e accessi

```sh
python3 hardware/tang-nano-9k-video/tools/debug_monitor.py \
  --seconds 1800 --output output/debug/tang-session
```

Registra per 30 minuti senza inviare comandi e senza modificare FPGA o CPU.
Salva `samples.jsonl` (campioni e righe originali), `samples.csv` (valori
numerici in decimale), `events.log` (cambi e accessi, indirizzi/dati hex),
e `session.json`. Ogni campione include orario con fuso e tempo trascorso.
I file dei campioni vengono aggiornati durante la registrazione. Usare una
cartella nuova per ogni sessione. Non aprire contemporaneamente un altro
lettore seriale sulla stessa porta.

La frequenza è circa 10 Hz: non registra tutti i fronti né tutti i microstep
in esecuzione veloce. Quando il contatore avanza di più di uno, indica quanti
accessi intermedi non sono ricostruibili e conserva solo l'ultimo, come
consente il firmware. I contatori diminuiti indicano un possibile reset o wrap,
non la misura del pin RESET. RESET e PS/2 grezzi non sono nel protocollo
CPU8v1; durante reset FPGA la trasmissione si interrompe. I cambi del dato
pad non valido non vengono annunciati come attività CPU. Per osservare
ogni fase, procedere a clock manuale lasciando circa mezzo secondo per step.

| Campo | Significato |
| --- | --- |
| B | Ingresso BOOT_RUN: 1=BOOT, 0=RUN. |
| Y | Due bit Y0,Y1: 2=video, 1=tastiera, 0=nessuna, 3=selezione non valida. |
| RD, WR | Livelli fisici di /RD e /WR, attivi a zero. |
| A, M | Indirizzo e maschera dei bit conosciuti. |
| DI | Byte letto dai pad dati della FPGA; significativo solo con DV=1 e segnali stabili. |
| DV | 1 quando il traduttore dati e abilitato, 0 quando il dato non e affidabile. |
| DO | Risposta memorizzata nella FPGA; non implica che sia attualmente pilotata. |
| OE, DIR | /OE e DIR effettivamente richiesti al traduttore dati. |
| RDY, S | READY e registro VIDEO_STATUS. |
| P, C | Puntatore video e colore corrente. |
| W, R | Contatori a 32 bit di scritture e letture accettate dalla logica FPGA. |
| WA, WD | Indirizzo e byte dell'ultima scrittura accettata. |
| RA, RV | Indirizzo e risposta dell'ultima lettura accettata. |

A0-A2 non sono collegati alla FPGA. Quando e attiva una sola selezione,
lo script ricostruisce l'ID da Y0/Y1: M=FFFF; i bit bassi sono quindi
**dedotti**, non misurati direttamente. Altrimenti M=FFF8 e solo A15-A3
sono noti. Durante fetch/accessi RAM il traduttore dati e disabilitato:
DI non permette di osservare gli opcode o i dati del bus CPU.

I campi live attraversano un sincronizzatore e vengono congelati per
trasmettere una riga coerente. Per la diagnosi confrontare a CPU ferma;
una riga non e una registrazione di tutti i microstep a CPU in corsa.
Ultimi eventi e contatori provengono invece dagli impulsi reali di
accettazione della FSM, anche se l'accesso cade fra due campioni.

Le letture conteggiate indicano che la FPGA ha preparato una risposta:
non dimostrano che il MDR della CPU l'abbia catturata. Questo resta da
controllare sulla CPU. Misure elettriche e contese sul lato CPU non sono
rilevabili completamente dalla telemetria interna.

## Stato del primo collaudo USB (9 novembre 2026)

Il firmware completo si carica in SRAM con CRC riuscito. Le due porte
`usbserial-21200` e `usbserial-21201` sono presenti, ma nel primo collaudo
non e arrivato alcun pacchetto CPU8v1. Una prova separata a 27 MHz fa
lampeggiare il LED correttamente; anche il loopback UART isolato non ha
restituito la sequenza inviata sul canale seriale. Sono stati controllati
il driver seriale macOS e l'accesso diretto libftdi. Questo non identifica
ancora un guasto hardware o firmware del bridge.

Il bitstream completo conserva TX=17, come i vincoli dell'esempio Sipeed.
Le prove sono state solo in SRAM e non hanno cambiato la flash FPGA ne
il firmware BL702. Prossimo controllo: riconnessione USB, nuovo caricamento
in SRAM e nuova lettura, mantenendo inizialmente la CPU spenta.
Non iniziare il confronto dei microstep finche non si ricevono campioni reali.
