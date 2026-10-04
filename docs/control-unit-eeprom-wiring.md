# Collegamenti EEPROM della Control Unit

Le tre EEPROM di controllo condividono lo stesso bus indirizzi. Il segnale
`BOOT_RUN` può utilizzare `A12` per selezionare due banchi di microcodice da
4096 byte: `0` per boot e `1` per run.

| Pin indirizzo | Segnale | Funzione |
| --- | --- | --- |
| `A0` | `µSTEP[2]` | Bit piu significativo del microstep nel cablaggio attuale. |
| `A1` | `µSTEP[1]` | Bit 1 del microstep. |
| `A2` | `µSTEP[0]` | Bit meno significativo del microstep; con `A0` e `A1` seleziona `T1..T8`. |
| `A3` | `IR[3]` | Primo dei cinque bit alti dell'opcode. |
| `A4` | `IR[4]` | Bit 4 dell'opcode. |
| `A5` | `IR[5]` | Bit 5 dell'opcode. |
| `A6` | `IR[6]` | Bit 6 dell'opcode. |
| `A7` | `IR[7]` | Bit piu significativo dell'opcode. |
| `A8` | `C` | Flag Carry/Borrow. |
| `A9` | `Z` | Flag Zero. |
| `A10` | `N` | Flag Negative. |
| `A11` | `O` | Flag Overflow. |
| `A12` | `BOOT_RUN` | Seleziona il banco boot (`0`) oppure run (`1`). |

| EEPROM | Uscite dati |
| --- | --- |
| Control ROM 0 | `ADDR_SEL_0`, `ADDR_SEL_1`, `PC_INC`, `MDR_WE`, `MDR_OE`, `RAM_WE`, `EPROM_OE`, `NEXT_FETCH` |
| Control ROM 1 | `IR_WE`, `PC_LOAD`, `MAR_L_WE`, `RF_EN`, `RF_RW`, `RA_EN`, `RA_RB_RW`, `RB_EN` |
| Control ROM 2 | `ALU_EN`, `FLAGS_WE`, `MAR_H_WE`, `RAM_OE`, `IDX_L_WE`, `IDX_H_WE`, `SYS_STEP_n`, una uscita riservata |

Il cablaggio riportato nel video 25 collega direttamente `IR[7:3]` alle cinque
linee `A3..A7`; `IR[2:0]` seleziona il registro generale e `IR[3:0]` raggiunge
il decoder ALU. Non e presente una EEPROM di dispatch nello schema mostrato.

> La ISA corrente assegna a `SUB`, `CMP` e a ciascun salto un gruppo distinto
> di `IR[7:3]`. Le tre Control ROM possono quindi produrre le sequenze e le
> condizioni sui flag senza una ROM di dispatch. L'immagine di dispatch che
> il tool genera resta **opzionale** e non va collegata nello schema attuale.
> I vecchi binari con `SUB=0x68` o `JZ..JO=0xA1..0xA7` vanno riassemblati.

> Il banco BOOT e definito: ROM 0 contiene tutti i segnali del trasferimento
> `EPROM[PC] -> bus dati -> RAM[PC]` in T1, seguito da disattivazione di `/WE_RAM`
> e incremento PC in T2 (EPROM resta abilitata), quindi
> reset del microstep in T3 con EPROM ancora abilitata. Il passaggio a RUN e il reset finale di PC
> restano azioni hardware esterne al microcodice.

Posizione e polarita elettrica delle uscite si configurano in
[`tools/cu-bytecode/config/control_signals.c`](../tools/cu-bytecode/config/control_signals.c).

## Reset all'accensione (schema proposto, da verificare sulla CPU)

Il reset iniziale **non puo essere affidato alla Control ROM**: prima che
alimentazione e indirizzi siano stabili, anche le sue uscite sono indeterminate.
Serve un generatore esterno di power-on reset a 5 V con uscita attiva bassa
`/POR`. Per tenere il reset attivo finche l'alimentazione non e stabile,
un supervisore di tensione come l'MCP809, nella
variante adatta alla soglia di alimentazione scelta, e una soluzione possibile.
Verificare piedinatura e soglia della **variante effettivamente acquistata**.

Se si vogliono usare solo componenti discreti e porte logiche, una soluzione
pratica per un'alimentazione a 5 V che sale rapidamente e un **74HC14**
(inverter con ingresso Schmitt). Valori di partenza per il chip disponibile
sulla CPU: `R = 47 kohm`, `C = 4,7 µF`.

```text
+5 V ── 47 kohm ──o────────→ 74HC14 pin 1 (ingresso inverter 1)
                   ├── 4,7 µF ── GND
                   └── 1 kohm ── pulsante NO ── GND

74HC14 pin 2 ─────────────────────────→ pin 3 (ingresso inverter 2)
74HC14 pin 4 ─────────────────────────→ /POR
74HC14 pin 14 = +5 V; pin 7 = GND; 100 nF fra pin 14 e 7.
```

Se il condensatore e elettrolitico, il positivo va al nodo `o` e il negativo
a GND. All'accensione il nodo e inizialmente basso, quindi pin 4 (`/POR`) e
basso. Il condensatore si carica attraverso la resistenza; oltre la soglia
dell'ingresso Schmitt, pin 4 passa alto e rilascia il reset. Con questi valori
il ritardo atteso e nell'ordine di qualche decimo di secondo, ma non e
preciso: dipende dalla salita dei 5 V, dalla tolleranza e perdita del
condensatore e dalle soglie effettive del 74HC14. Prima di collegare i
contatori, misurare che `/POR` resti basso all'accensione e diventi alto
**una sola volta**. Un diodo di scarica in parallelo alla resistenza, con
anodo verso il nodo `o` e catodo verso i +5 V (per esempio `1N4148` con
`330 ohm` in serie per limitare la corrente), aiuta anche dopo spegnimenti
molto brevi.

Il pulsante **normalmente aperto** (NO) aggiunge il reset manuale: premendolo,
il condensatore si scarica verso GND attraverso `1 kohm`, il pin 1 scende a
zero e il pin 4 (`/POR`) torna basso. Rilasciandolo, il condensatore si
ricarica tramite `47 kohm` e il reset si disattiva dopo il normale ritardo.
La resistenza da `1 kohm` limita la corrente di scarica del condensatore.
Non collegare il pulsante direttamente al pin 4, che e un'uscita push-pull.
Per evitare ambiguita, la linea `/POR` qui indica sia il reset automatico sia
quello manuale; non cambia lo stato di `BOOT_RUN`.

Se invece si usa un **74LS14**, che ha una corrente d'ingresso molto maggiore,
i valori di partenza diventano `R = 1 kohm` e `C = 100 µF`: non scambiare i
valori delle due famiglie senza una nuova verifica.

Questo RC **non monitora la tensione** come un supervisore: con un'alimentazione
che sale lentamente o con cadute dei 5 V non garantisce un reset affidabile.
Non usare un normale inverter privo di ingresso Schmitt direttamente sul nodo
RC, perche la transizione lenta puo provocare commutazioni multiple.

Per il contatore 74161 del microstep, usare il caricamento **sincrono** a zero:

```text
/CLR_PC[0..3] = /POR                 (tutti i 74161 del PC)
/CLR_µSTEP   = /POR
/LOAD_µSTEP  = NEXT_FETCH_n          (Control ROM 0, D7)
D,C,B,A del contatore µSTEP = 0,0,0,0

NEXT_FETCH_n = Control ROM 0, D7 (attivo basso)
```

Con `/POR=0`, PC e microstep sono forzati a zero. Dopo il rilascio di `/POR`,
`NEXT_FETCH_n=0` carica `0000` nel **solo** contatore microstep al successivo
fronte di salita del clock. Il segnale resta attivo per l'intera fase di reset;
non si autoestingue in modo asincrono. Tenere `/POR` sul `/CLR` asincrono,
separato da D7 della EEPROM: sono due uscite che non vanno unite direttamente.
`NEXT_FETCH_n` non deve resettare il PC, altrimenti il BOOT ripartirebbe da
indirizzo zero a ogni byte.

Se la scheda attuale collega D7 a `/CLR_µSTEP` tramite una porta AND con
`/POR`, la nuova sequenza RUN dedica comunque un microstep al solo reset:
la scrittura RAM e gli aggiornamenti dei registri terminano prima che D7
scenda a zero. Questa separazione **non garantisce** pero la durata del
reset asincrono autoestinguente ne l'assenza di glitch della EEPROM; per la
prova RUN finale resta raccomandato il collegamento a `/LOAD` sopra. Prima
di riprogrammare la ROM0 fisica, verificare quale cablaggio e presente.

### Arresto HLT esterno alla CU

`HLT=0x00` e `NOP=0x01` hanno entrambi `IR[7:3]=00000`. Control ROM 2
usa ora `D6` (pin DIP-28 **16**) per `SYS_STEP_n`, attivo basso:
`D6=0` solo se `BOOT_RUN=1`, `µSTEP[2:0]=001` (T2) e
`IR[7:3]=00000`. In tutti gli altri indirizzi, inclusi BOOT e T1, `D6=1`.
Le linee `IR[2:0]` restano esterne alle EEPROM. Per HLT basta una OR:

```text
µSTEP_EN = SYS_STEP_n OR IR2 OR IR1 OR IR0
```

Il risultato vale `0` solo per `HLT=0x00` in RUN/T2; collegarlo a una
**abilitazione al conteggio** del 74161 microstep (l'altra abilitazione
deve restare alta se non ha un'altra funzione). Non tagliare il clock.
`001` e T2 sui bit logici del contatore; sui pin EEPROM equivale a
`A2:A1:A0=100` con la mappatura attuale. In T2 le altre uscite CU sono
inattive e IR resta `0x00`, quindi il contatore resta fermo. Per NOP
(`IR[2:0]=001`) la OR vale `1` e il contatore raggiunge T3.
Se l'abilitazione del contatore e gia condizionata da altra logica,
combinare il risultato senza scavalcare tale condizione.

**Prima di collegare D6**, programmare e verificare la nuova immagine
`microcode-rom2.bin`: il precedente bit riservato non aveva un livello
garantito. Misurare D6 alto durante T1/BOOT e basso in RUN/T2 per il gruppo
di sistema; usare un clock che rispetti i tempi di propagazione della EEPROM
e di setup dell'ingresso enable del contatore.

Durante `/POR=0` va inoltre impedita la scrittura della RAM. Poiche T1 del
BOOT ha `/WE_RAM` attivo basso, aggiungere l'inibizione al circuito OR che
gia combina D5 con i bit alti del PC:

```text
H = PC15 OR PC14 OR PC13
/WE_RAM_fisico = ROM0_D5 OR H OR NOT(/POR)   (durante BOOT)
```

Quando `/POR=0`, `NOT(/POR)=1` e `/WE_RAM_fisico` resta alto; quando `/POR=1`,
la logica di scrittura torna quella normale. Usare un inverter e una porta OR
aggiuntiva (o una rete logicamente equivalente), non un collegamento diretto
di `/POR` al pin `/WE` della RAM. Tenere fermo anche il clock durante il reset
e consentire il primo fronte solo dopo il rilascio di `/POR` e l'assestamento
dei segnali. L'espressione con `PC15..PC13` descrive la protezione di BOOT;
in RUN la selezione RAM/VRAM deve usare l'indirizzo realmente presente sul bus.

Riferimenti hardware: [datasheet 74161/74LS161A di Texas Instruments](https://www.ti.com/lit/ds/symlink/sn74ls161a.pdf)
e [datasheet MCP809 di Microchip](https://ww1.microchip.com/downloads/en/devicedoc/11194c.pdf).
Per la variante RC: [datasheet 74HC14 di Texas Instruments](https://www.ti.com/lit/ds/symlink/sn74hc14.pdf)
e [datasheet 74LS14](https://www.ti.com/lit/ds/symlink/sn74ls14.pdf).
