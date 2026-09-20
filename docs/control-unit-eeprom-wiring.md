# Collegamenti EEPROM della Control Unit

Le tre EEPROM di controllo condividono lo stesso bus indirizzi. Il segnale
`BOOT_RUN` può utilizzare `A12` per selezionare due banchi di microcodice da
4096 byte: `0` per boot e `1` per run.

| Pin indirizzo | Segnale | Funzione |
| --- | --- | --- |
| `A0` | `µSTEP[0]` | Bit 0 del microstep. |
| `A1` | `µSTEP[1]` | Bit 1 del microstep. |
| `A2` | `µSTEP[2]` | Bit 2 del microstep; con `A0` e `A1` seleziona `T1..T8`. |
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
| Control ROM 2 | `ALU_EN`, `FLAGS_WE`, `MAR_H_WE`, `RAM_OE`, `IDX_L_WE`, `IDX_H_WE`, due uscite riservate |

Il cablaggio riportato nel video 25 collega direttamente `IR[7:3]` alle cinque
linee `A3..A7`; `IR[2:0]` seleziona il registro generale e `IR[3:0]` raggiunge
il decoder ALU. Non e presente una EEPROM di dispatch nello schema mostrato.

> La ISA successiva distingue alcuni opcode che condividono gli stessi cinque
> bit alti (in particolare i salti condizionati). Il generatore conserva perciò
> una ROM di dispatch **opzionale** come estensione dell'hardware del video:
> senza un decoder aggiuntivo, quei salti non possono avere microsequenze
> differenti. Non collegarla come se facesse parte delle tre Control ROM.

> Il banco BOOT e definito: ROM 0 contiene tutti i segnali del trasferimento
> `EPROM[PC] -> MDR -> RAM[PC]`. Il passaggio a RUN e il reset finale di PC
> restano azioni hardware esterne al microcodice.

Posizione e polarita elettrica delle uscite si configurano in
[`tools/cu-bytecode/config/control_signals.c`](../tools/cu-bytecode/config/control_signals.c).
