# Specifica I/O, tastiera PS/2 e timer — Tang Nano 9K

**Stato:** specifica della tastiera per la nuova mappa I/O, implementata in RTL sulla Tang Nano 9K, da collaudare su scheda. Il timer resta un'estensione futura senza ID assegnato.

## 1. Selezione e bus condiviso

La tastiera usa **ID `001` su A2–A0**, quindi l'uscita **Y1 del 74238**. Il video usa Y0. Entrambe le uscite raggiungono la stessa Tang tramite adattamento di livello. La Tang condivide `A15–A3`, `D7–D0`, `/RD` e `/WR` fra video e tastiera. Il [decoder I/O](io-bus.md) seleziona lo spazio fuori RAM tramite la OR dei bit alti. A3 è il bit meno significativo del registro interno. Gli accessi validi richiedono gli interblocchi RUN della CPU.

Durante una lettura valida, la FPGA restituisce il byte del registro selezionato attraverso il traduttore dati bidirezionale. Durante una scrittura valida è la CPU a pilotare il bus. Se manca la selezione o il registro non esiste, la FPGA lascia il bus libero. Per un ciclo valido si attiva uno solo fra `/RD` e `/WR`.

Il software usa le normali istruzioni `LDA` e `STA`, oppure `LDAI` e `STAI` tramite IDX. La CU usa il microcodice di lettura e scrittura già previsto.

## 2. Mappa dei registri

| Nome | Indirizzo | Accesso | Reset | Funzione |
| --- | ---: | --- | ---: | --- |
| `KEY_DATA` | `0x2001` | R | `0x00` | Legge e consuma un evento. Restituisce zero quando il buffer è vuoto. |
| `KEY_STATUS` | `0x2009` | R | `0x00` | Bit 0 `READY` e flag di errore. La lettura lascia il buffer intatto. |
| `KEY_CTRL` | `0x2011` | W | — | Cancella i flag selezionati dal byte scritto. |

La FPGA decodifica tutti i bit `A15–A3` insieme a Y1. I registri distano 8 indirizzi e non hanno alias dovuti ad A3. Una lettura di `KEY_DATA` consegna al massimo un evento per transazione, anche se `/RD` rimane basso per molti cicli FPGA. La CPU può leggere periodicamente `KEY_STATUS` e controllare `READY` in software, oppure leggere direttamente `KEY_DATA` e usare `0x00` come indicazione di buffer vuoto.

## 3. Tastiera

### 3.1 Protocollo fisico

La FPGA riceve il protocollo PS/2 Set 2: un frame contiene start a zero, otto
bit LSB-first, parita' dispari e stop a uno. `CLK` e `DATA` sono linee
open-collector. Alimentare la tastiera a 5 V con massa comune. Portare `CLK`
e `DATA` ai GPIO a 3,3 V tramite due canali di adattamento adatti a segnali
open-collector, con pull-up al livello del rispettivo lato. La ricezione usa
il clock interno della FPGA per sincronizzare le due linee e continua a
funzionare a CPU ferma. La prima revisione riceve gli eventi senza inviare
comandi alla tastiera.

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
| `- = [ ] \\ ; ' , . / \`` | `4E 55 54 5B 5D 4C 52 41 49 4A 0E` |
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

Il timer è previsto come contatore a 16 bit. L'ID e gli indirizzi dei suoi
registri restano da assegnare. Nella proposta precedente, con `CLK_CPU`
nominale di 1 kHz, il timer incrementa ogni dieci fronti a 100 Hz. Il rollover
completo dura 655,36 secondi.

Per una lettura coerente, `TIME_LO` restituisce il byte basso e salva nello
stesso istante il byte alto. `TIME_HI` restituisce il byte alto salvato.
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
5. Una lettura del video su Y0 lascia intatti stato ed evento della tastiera.
6. Quando sarà implementato il timer, due letture `TIME_LO`, `TIME_HI` consecutive restituiscono un valore a 16
   bit coerente, anche al passaggio da `0x00FF` a `0x0100`.
