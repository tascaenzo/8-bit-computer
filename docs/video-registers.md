# Video a colori della Tang Nano 9K

Interfaccia corrente: A0–A2 = `000`, uscita Y0 del 74238. A3–A15
selezionano il registro, D0–D7 trasportano il byte, /RD e /WR richiedono
lettura e scrittura. La RAM occupa 0x0000–0x1FFF. Gli indirizzi video
sotto non coincidono con quelli della tastiera, che hanno ID `001`.
Il cablaggio fisico non cambia con questa estensione.

## Registri

| Indirizzo CPU | Nome | Accesso | Funzione |
| --- | --- | --- | --- |
| `0x2000` | VIDEO_DATA | W | Scrive carattere e colore corrente nella cella puntata. |
| `0x2018` | VIDEO_STATUS | R | Bit 0 READY, bit 1 BUSY; gli altri bit sono zero. |
| `0x2020` | VIDEO_CMD | W | Esegue il comando descritto sotto. |
| `0x2028` | VIDEO_COLOR | R/W | Bit 7–4 sfondo, bit 3–0 testo; reset `0x0F`. |
| `0x2030` | VIDEO_CURSOR_X | R/W | Colonna del puntatore, 0–79; scritture fuori intervallo ignorate. |
| `0x2038` | VIDEO_CURSOR_Y | R/W | Riga del puntatore, 0–59; scritture fuori intervallo ignorate. |
| `0x2040` | VIDEO_CONTROL | R/W | Controlli del cursore e avanzamento, reset `0x1C`. |

Il puntatore è anche la posizione del cursore. Le scritture a CURSOR_X/Y
modificano rispettivamente i bit bassi 6–0 e alti 13–7 del puntatore.
Una cella visibile si trova a `riga * 128 + colonna`. Ci sono 80 colonne
visibili, con 48 celle di padding per riga. La posizione si imposta tramite CURSOR_X/Y; il puntatore a 14 bit resta interno
alla FPGA. Gli indirizzi rimossi `0x2008` e `0x2010` sono riservati:
le scritture vengono ignorate e le letture lasciano il bus in alta impedenza.

Ogni posizione conserva un carattere ASCII e un attributo colore separati:
16 KiB per i caratteri e 16 KiB per gli attributi. Cambiare VIDEO_COLOR
influenza le scritture successive, non ricolora il testo già presente.
Il font comprende ASCII 0x20–0x7E; gli altri codici producono una cella vuota.
VIDEO_DATA non interpreta automaticamente CR/LF: usare VIDEO_CMD.

## Comandi VIDEO_CMD

| Byte scritto | Comando | Effetto |
| --- | --- | --- |
| `1` | CLEAR | Riempie di spazi le 60 righe, incluso padding, con il colore corrente. Porta il puntatore a 0. |
| `2` | HOME | Porta il puntatore alla prima cella; conserva i contenuti. |
| `3` | NEWLINE | Colonna 0 della riga successiva. In fondo scorre se AUTO_SCROLL è attivo, altrimenti resta sulla riga. |
| `4` | SCROLL_UP | Scorre di una riga verso l'alto, conserva i colori, svuota l'ultima riga col colore corrente e porta il puntatore a riga 59, colonna 0. |
| `5` | CARRIAGE_RETURN | Colonna 0 della riga attuale. |
| altri | Nessuna operazione | Byte riservati a future estensioni. |

CLEAR e SCROLL_UP lavorano in background: durante l'operazione READY=0
e BUSY=1. La CPU deve leggere VIDEO_STATUS e attendere READY=1 prima di
scrivere un altro registro video. Le scritture video ricevute mentre BUSY=1
sono ignorate, non accodate. Gli accessi alla tastiera continuano a funzionare.
Con clock 25,2 MHz CLEAR richiede circa 0,31 ms e lo scorrimento circa 0,92 ms,
oltre al tempo di acquisizione della richiesta.

## VIDEO_CONTROL

| Bit | Nome | Quando vale 1 |
| --- | --- | --- |
| 0 | CURSOR_ENABLE | Mostra il cursore come cella con colori invertiti. |
| 1 | CURSOR_BLINK | Il cursore lampeggia, circa 0,5 s acceso / 0,5 s spento. |
| 2 | AUTO_INCREMENT | Avanza il puntatore dopo VIDEO_DATA. |
| 3 | AUTO_WRAP | Con AUTO_INCREMENT, dopo colonna 79 passa a colonna 0 della riga seguente. |
| 4 | AUTO_SCROLL | Scorre quando AUTO_WRAP o NEWLINE raggiungono il fondo dello schermo. |
| 7–5 | Riservati | Ignorati in scrittura, zero in lettura. |

Reset `0x1C`: avanzamento, ritorno a capo e scorrimento automatici attivi,
cursore nascosto. Scrivere `0x1F` per attivare anche il cursore lampeggiante.
Con AUTO_WRAP disattivo, AUTO_INCREMENT avanza linearmente modulo 16384.
Con AUTO_WRAP attivo e AUTO_SCROLL disattivo, al fondo si torna a colonna 0
della stessa ultima riga. Il cursore è una sovrapposizione: non modifica VRAM.

## Palette a 16 colori

| Indice | Colore RGB | Indice | Colore RGB |
| --- | --- | --- | --- |
| 0 | `000000` nero | 8 | `526177` grigio ardesia |
| 1 | `18243B` blu scuro | 9 | `5B8DEF` azzurro |
| 2 | `238636` verde | A | `68D391` verde chiaro |
| 3 | `168AAD` blu petrolio | B | `38D9CF` turchese |
| 4 | `B93838` rosso | C | `FF7B72` corallo |
| 5 | `9146B5` viola | D | `D99BFF` lilla |
| 6 | `AD762D` ocra | E | `FFD166` oro |
| 7 | `B8C4D4` grigio chiaro | F | `FFFFFF` bianco |

Esempio: `0x1E` significa testo oro su sfondo blu scuro.
La palette è fissa in questa versione; grafica a pixel, sprite e font
caricabili non sono implementati. Gli aggiornamenti non sono sincronizzati
al vertical blank: durante una scrittura o uno scorrimento può vedersi
una transizione parziale nel fotogramma corrente.

## BOOT/RUN

BOOT_RUN=1 mostra il pannello «Enzo Tasca / 8 BIT COMPUTER / BOOTING...»
con indicatore animato di attività e testo «COPYING PROGRAM TO RAM».
L'indicatore non misura la percentuale di copia. La schermata non modifica
la VRAM; in BOOT il bus CPU è isolato. Passando a RUN (BOOT_RUN=0) viene mostrata la VRAM
quando inizializzata. Un'operazione video già avviata continua internamente
anche se la CPU torna in BOOT. Il reset FPGA reinizializza memoria e controlli.

[Cablaggio BOOT/RUN](cablaggio-tang-video-ps2.md#ingresso-bootrun-e-schermata-di-avvio)
· [Esempio assembly](../examples/assembly/video_color_demo.asm)
· [Anteprima BOOT](../output/preview/tang-boot-screen.png)
