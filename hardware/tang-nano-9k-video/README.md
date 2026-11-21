# Video HDMI e tastiera PS/2 sulla Tang Nano 9K

Il video usa l'ID I/O `000` (Y0 del 74238) e la tastiera l'ID `001` (Y1).
La Tang riceve A3–A15; A0–A2 sono decodificati dal 74238.
I registri della stessa periferica distano 8 indirizzi, senza alias di A3.
La RAM CPU rimane a 8 KiB e le periferiche usano le richieste condivise `/RD`
e `/WR`. Il bitstream implementa la [mappa I/O corrente](../../docs/io-bus.md).

- HDMI in modalità video DVI, 640 × 480 a 60 Hz, senza audio.
- Testo a 16 colori di primo piano e 16 di sfondo, 80 × 60 caratteri da 8 × 8 pixel.
  VRAM: 16 KiB caratteri + 16 KiB attributi, passo di riga 128.
- Cursore lampeggiante, cancellazione, ritorno a capo e scorrimento automatici.
  La posizione è `riga * 128 + colonna`.
- Video e ricezione PS/2 funzionano con il clock FPGA anche a CPU ferma.
- Tastiera PS/2 Set 2 con mappa US QWERTY, Shift, Caps Lock, frecce, un evento
  in attesa e flag di errore. Il timer resta da implementare.

| Selezione | Indirizzo CPU | Accesso | Funzione |
| --- | --- | --- | --- |
| Y0 | `0x2000` | W | VIDEO_DATA: scrive carattere e colore, con avanzamento configurabile |
| Y0 | `0x2018` | R | VIDEO_STATUS: bit 0 READY, bit 1 BUSY |
| Y0 | `0x2020` | W | VIDEO_CMD: clear, home, newline, scroll, carriage return |
| Y0 | `0x2028` | R/W | VIDEO_COLOR: sfondo alto / testo basso, 4 bit ciascuno |
| Y0 | `0x2030` | R/W | VIDEO_CURSOR_X: colonna 0–79 |
| Y0 | `0x2038` | R/W | VIDEO_CURSOR_Y: riga 0–59 |
| Y0 | `0x2040` | R/W | VIDEO_CONTROL: cursore, blink, avanzamento, wrap, scroll |
| Y1 | `0x2001` | R | KEY_DATA: legge un evento o zero se vuoto |
| Y1 | `0x2009` | R | KEY_STATUS: pronto, trabocco, parità e frame |
| Y1 | `0x2011` | W | KEY_CTRL: bit 0 cancella il trabocco, bit 1 gli errori di ricezione |

La posizione si imposta solo con CURSOR_X/Y. Gli indirizzi `0x2008` e
`0x2010` sono riservati: scritture ignorate, letture in alta impedenza.
Gli altri indirizzi restano invariati. I vecchi programmi che usavano PTR_L/H
vanno aggiornati e il bitstream va rigenerato e caricato sulla Tang.

L'ingresso BOOT_RUN della Tang è **1 in BOOT e 0 in RUN**.
Questa polarità non modifica la selezione dei banchi delle EEPROM della CU. Durante BOOT lo schermo mostra «Enzo Tasca», «8 BIT COMPUTER»
e «BOOTING...» in un pannello a colori con indicatore animato, senza limite di tempo. In RUN l'overlay scompare e viene
mostrata la VRAM della CPU. Non esiste più il timer di avvio di tre secondi.
L'overlay non modifica la VRAM. In BOOT la FPGA isola il bus CPU e mantiene
READY basso; in RUN READY indica che la VRAM è inizializzata.

BOOT_RUN entra su J6-2 / GPIO 86, **banca 1,8 V**: CPU → U4 B2 (pin 20),
U4 A2 (pin 4) → resistenza 3,3 kΩ → GPIO 86, con 3,9 kΩ dal GPIO a GND.
Usare resistenze all'1%. Seguire il [cablaggio dettagliato](../../docs/cablaggio-tang-video-ps2.md#ingresso-bootrun-e-schermata-di-avvio).
La [specifica dei registri video](../../docs/video-registers.md) descrive comandi,
colori, controlli e gestione BUSY. Vedi la [specifica PS/2](../../docs/io-ps2-timer.md)
per i codici evento.

## Reset condiviso con la CPU

**/CPU_RESET su GPIO 85, J6-3: 0 = RESET, 1 = normale.** Passa per U4 B3
(pin 19) → A3 (pin 5), poi un partitore 3,3 kΩ / 3,9 kΩ verso GND, come
BOOT_RUN: il GPIO lavora a **1,8 V**. Rimuovere il vecchio filo U4 B3 → GND.
Vedi il [cablaggio completo](../../docs/cablaggio-tang-video-ps2.md#reset-della-cpu-condiviso-con-la-fpga).

Reset esterno, pulsante a bordo e perdita di lock PLL azzerano lo stesso core.
Il bus si isola subito; il rilascio è sincronizzato a quattro cicli pixel.
Si ripristinano VRAM vuota, attributi 0F, cursore/puntatore, registri video ed
eventi/errori PS/2. La cancellazione VRAM richiede circa 0,65 ms: attendere
almeno 1 ms o READY prima del primo accesso video CPU. BOOT_RUN continua a
selezionare la schermata BOOTING: il reset da solo non cambia modalità.
Il bitstream deve essere caricato sulla Tang per attivare questo nuovo ingresso.

## Build e test

Dalla radice del repository:

```sh
make -C hardware/tang-nano-9k-video test
make -C hardware/tang-nano-9k-video bitstream
make -C hardware/tang-nano-9k-video preview
```

Strumenti richiesti: `iverilog`, `vvp`, `yosys`, `nextpnr-himbaechel` con backend
Gowin e `gowin_pack` (Apicula), presenti in OSS CAD Suite.

`vendor/hdmi/` contiene la PLL, il divisore di clock, l'encoder TMDS e
l'header incluso dall'encoder. I file provengono dall'[esempio HDMI Sipeed
al commit c3b7957](https://github.com/sipeed/TangNano-9K-example/tree/c3b795799f23de91982be52db4273a8eea100cdb/hdmi)
e mantengono le intestazioni originali.

File generato: **`build/cpu8_video.fs`**. Log: `build/synth.log`, `build/pnr.log`;
report di timing: `build/timing.json`. Device: `GW1NR-LV9QN88PC6/I5`, family
`GW1N-9C`. Non usare i vecchi `video_text.fs` presenti in build: appartengono
al precedente smoke test e non contengono questa interfaccia CPU.

`video.gprj` e' incluso per Gowin IDE, top module `top_video`, con
`constraints/video-gowin.cst`. Il percorso di build effettivamente verificato
qui e' OSS CAD Suite, che usa `constraints/video.cst`. Le due varianti
hanno lo stesso pinout e differiscono nella dichiarazione delle coppie HDMI.
Il pin 55 e' usato come GPIO: disabilitare SSPI anche nelle opzioni Gowin IDE.
La build Makefile passa i flag `sspi_as_gpio` a nextpnr e al packer.

## Pinout e contratto del bus

Seguire il [cablaggio filo per filo](../../docs/cablaggio-tang-video-ps2.md).
J5-5 e J5-6 sono Y0 e Y1, J5-7 e J5-8 sono PS/2 CLK e DATA. A4–A15 sono
su J5-9…J5-20; A3 entra su J6-21 (GPIO 31) tramite U4.
Usare quattro NH245: U1/U2/U4 per gli ingressi, U3 per i dati. Il pulsante di reset e LED1 a bordo usano GPIO a 1,8 V;
LED1 acceso indica che il video è pronto per la CPU. Il bus CPU e i segnali PS/2 adattati usano
GPIO a 3,3 V. Tenere liberi i connettori microSD e display che condividono GPIO.

La FPGA accetta un ciclo quando esattamente una selezione e uno strobe
sono attivi e l'indirizzo del registro è valido. Per il primo collaudo usare
una finestra di almeno 1 µs con indirizzo e selezione stabili, oltre al dato
stabile in scrittura. Mantenere il dato scritto e l'indirizzo fino al termine
dello strobe. Campionare il dato letto dopo almeno 1 µs dall'inizio del ciclo
selezionato. Fra due accessi lasciare almeno 1 µs senza richiesta valida per
la Tang. Una fase con entrambi i select bassi conta come inattiva anche
quando /RD è basso per un accesso alla RAM.

Il decoder aspetta otto cicli dopo aver acquisito la richiesta. In lettura
prepara il dato per un ciclo prima di abilitare il traduttore verso la CPU.
La disabilitazione fisica dipende dai segnali di bus effettivi, dal reset e
dal lock della PLL. Verificare sul banco i ritardi dei traduttori e il tempo
di rilascio prima che un altro dispositivo inizi a pilotare D7–D0.

## Primo collaudo

Caricare in SRAM con CPU scollegata e monitor sulla porta HDMI:

```sh
openFPGALoader -b tangnano9k hardware/tang-nano-9k-video/build/cpu8_video.fs
```

Con i traduttori abilitati e BOOT_RUN a 1, verificare la schermata BOOTING.
Passare a RUN (BOOT_RUN=0): lo schermo mostra la VRAM e LED1 si accende
quando il video è pronto. Eseguire sulla CPU:

```asm
.code 0x0000
LDX 0x2000
LDI R0, 0x43
STAI R0
LDI R0, 0x49
STAI R0
HLT
```

Il video deve mostrare CI dall'angolo in alto a sinistra dopo un reset
FPGA. Per la tastiera, leggere KEY_STATUS (0x2009) dopo aver premuto un
tasto e poi KEY_DATA (0x2001). Una seconda lettura di KEY_DATA restituisce
zero se non è arrivato un nuovo evento.

I test simulano il bus con ritardo del traduttore, accessi video, eventi
PS/2, colori per cella, cursore, clear/scroll, isolamento durante BUSY e rilascio del bus. Il renderer e TMDS hanno test separati.
Il file generato va ancora caricato e collaudato sulla scheda fisica.

## Prova di compatibilità TV

`make bitstream-720p-hdmi` genera `build/cpu8_video_720p_hdmi.fs`.
Usa 1280 × 720 a 60 Hz con un AVI InfoFrame per fotogramma (VIC 4).
La schermata di avvio segue BOOT_RUN anche in questa modalità. Per il collaudo caricare il file
in SRAM con openFPGALoader, come per il bitstream base.

## Debug del bus via USB

La build include telemetria USB-UART a 115200 baud, circa 10 campioni/s,
con livelli di bus, ultimo evento accettato e puntatore video.
A CPU ferma posso confrontare il campione con un punto del PDF Hello World:

```sh
python3 hardware/tang-nano-9k-video/tools/debug_read.py --point 4
```

Vedi la [guida al debug USB](tools/README.md). Il canale usa il pin interno 17
verso BL702 e non richiede modifiche al cablaggio CPU.
