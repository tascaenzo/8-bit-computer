# Specifica I/O, tastiera PS/2 e timer — Tang Nano 9K

> **Stato:** baseline implementabile
> **Versione:** 1.0
> **Data:** 3 settembre 2026

## 1. Scopo e regole comuni

La Tang Nano 9K acquisisce una tastiera PS/2, espone eventi di tastiera e un
timer alla CPU tramite registri memory-mapped. Il programma usa `LDA` per
leggere e `STA` per scrivere; `IN` e `OUT` non sono coinvolte.

La FPGA guida `D[7:0]` solo quando `/RD=0` e l'indirizzo e' compreso fra
`0xFF00` e `0xFF0F`. Durante `/WR=0` cattura i dati ma non guida mai il bus.
Gli stessi requisiti elettrici e di durata dello strobe definiti nell'[indice
FPGA](io-video-ps2-timer.md#vincoli-elettrici-comuni) valgono anche qui.

## 2. Mappa dei registri

| Nome | Indirizzo | Accesso | Reset | Semantica |
| --- | ---: | --- | ---: | --- |
| `KEY_DATA` | `0xFF00` | R | `0x00` | Evento tastiera; la lettura consuma l'evento. |
| `KEY_STATUS` | `0xFF01` | R | `0x00` | Stato della tastiera e flag di errore. |
| `KEY_CTRL` | `0xFF02` | W | — | Cancella flag di errore. |
| — | `0xFF03` | R/W | — | Riservato: lettura `0x00`, scrittura ignorata. |
| `TIME_LO` | `0xFF04` | R | `0x00` | Byte basso del timer; acquisisce il byte alto. |
| `TIME_HI` | `0xFF05` | R | `0x00` | Byte alto acquisito dall'ultima lettura di `TIME_LO`. |
| `TIME_STATUS` | `0xFF06` | R | `0x01` | Bit 0 `ACTIVE`; gli altri bit sono zero. |
| — | `0xFF07-0xFF0F` | R/W | — | Riservato: lettura `0x00`, scrittura ignorata. |

## 3. Tastiera

### 3.1 Protocollo fisico

La FPGA riceve il protocollo PS/2 Set 2: un frame contiene start a zero, otto
bit LSB-first, parita' dispari e stop a uno. `CLK` e `DATA` sono linee
open-collector. La tastiera e' alimentata a 5 V, ma i pull-up di `CLK` e
`DATA` sul lato FPGA devono andare a 3,3 V; non applicare mai 5 V ai pin FPGA.
In prima revisione la CPU non invia comandi alla tastiera.

Il ricevitore campiona `DATA` sul fronte di discesa di `CLK`, valida start,
stop e parita' e riconosce i prefissi `E0` (esteso) e `F0` (break). Gli errori
di frame e parita' scartano il frame corrente, impostano il relativo flag
sticky e resettano il parser al prossimo start valido.

### 3.2 Codice evento interno

Il software non riceve scan-code PS/2 grezzi: riceve un byte evento.

| Intervallo/valore | Evento |
| --- | --- |
| `0x20-0x7E` | carattere ASCII stampabile |
| `0x08` | Backspace |
| `0x09` | Tab |
| `0x0D` | Enter |
| `0x1B` | Esc |
| `0x80` / `0x81` | freccia su / giu' |
| `0x82` / `0x83` | freccia sinistra / destra |
| `0x00` | nessun evento (non viene mai accodato) |

La mappa iniziale e' **US QWERTY, PS/2 Set 2**. `Shift` sinistro o destro e
`Caps Lock` sono stati interni: non producono un evento, ma trasformano le
lettere. `Shift` trasforma anche cifre e punteggiatura secondo la tastiera US.
Un make-code ripetuto dalla tastiera produce eventi ripetuti; un break-code
aggiorna lo stato dei modificatori ma non produce eventi.

| Tasti | Make-code Set 2 |
| --- | --- |
| `A-Z` | `1C 32 21 23 24 2B 34 33 43 3B 42 4B 3A 31 44 4D 15 2D 1B 2C 3C 2A 1D 22 35 1A` |
| `1-0` | `16 1E 26 25 2E 36 3D 3E 46 45` |
| spazio | `29` |
| `- = [ ] \\ ; ' , . / \`` | `4E 55 54 5B 5D 4C 52 41 49 4A 0D` |
| Backspace, Tab, Enter, Esc | `66 0D 5A 76` |
| Shift sinistro, Shift destro, Caps Lock | `12 59 58` |
| frecce su, giu', sinistra, destra | `E0 75`, `E0 72`, `E0 6B`, `E0 74` |

Le lettere sono minuscole quando `Shift XOR CapsLock = 0` e maiuscole quando
vale uno. La localizzazione italiana non e' implicita: sara' una mappa
alternativa selezionabile in una revisione futura, senza cambiare i registri.

### 3.3 Buffer e registri di tastiera

La prima revisione usa una coda di profondita' uno.

| Registro | Bit | Definizione |
| --- | --- | --- |
| `KEY_DATA` | `7:0` | Se `READY=1`, restituisce il byte pendente e azzera `READY`; altrimenti restituisce `0x00`. |
| `KEY_STATUS` | 0 | `READY`: esiste un evento non letto. |
|  | 1 | `OVERRUN`: e' arrivato un evento quando `READY=1`; il byte gia' presente viene conservato e il nuovo viene scartato. |
|  | 2 | `PARITY_ERROR`: errore sticky di parita'. |
|  | 3 | `FRAME_ERROR`: errore sticky di start/stop. |
|  | `7:4` | Sempre zero. |
| `KEY_CTRL` | 0 | Scrivere uno cancella `OVERRUN`. |
|  | 1 | Scrivere uno cancella `PARITY_ERROR` e `FRAME_ERROR`. |
|  | `7:2` | Ignorati. |

La lettura di `KEY_STATUS` non modifica alcuno stato. Una lettura di
`KEY_DATA` e' distruttiva solo quando un evento e' pendente.

## 4. Timer

Il timer e' un contatore modulo `2^16` inizializzato a zero dal reset FPGA. Con
`CLK_CPU` nominale di 1 kHz, incrementa ogni dieci fronti, cioe' a **100 Hz**
(un tick = 10 ms). `TIME_STATUS.ACTIVE` resta a uno dopo il reset finche' la
FPGA e' operativa.

Per ottenere una lettura atomica, il firmware deve leggere `TIME_LO` e subito
dopo `TIME_HI`: la lettura di `TIME_LO` restituisce il byte basso corrente e
salva nello stesso istante il byte alto nel latch; `TIME_HI` restituisce quel
latch. Il rollover completo dura 655,36 secondi.

```asm
.equ TIME_LO, 0xFF04
.equ TIME_HI, 0xFF05

LDA R0, TIME_LO     ; acquisisce anche l'alto
LDA R1, TIME_HI     ; alto coerente con R0
```

Le differenze temporali si calcolano modulo `2^16` e sono corrette per
intervalli inferiori al rollover. Se in futuro il timer dovra' avanzare a CPU
ferma, richiedera' un clock FPGA indipendente e un handshake separato: non e'
parte della versione 1.

## 5. Criteri di accettazione

1. Senza tasti, `LDA` da `KEY_DATA` restituisce `0x00` e `READY=0`.
2. Premere `A` accoda `0x61`; con Shift o Caps Lock accoda `0x41`.
3. Una seconda pressione prima della lettura conserva il primo evento e pone
   `OVERRUN=1`.
4. Leggere `KEY_DATA` consegna una volta sola l'evento e azzera `READY`.
5. Due letture `TIME_LO`, `TIME_HI` consecutive restituiscono un valore a 16
   bit coerente, anche al passaggio da `0x00FF` a `0x0100`.
