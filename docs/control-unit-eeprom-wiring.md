# Collegamenti EEPROM della Control Unit

Le tre EEPROM di controllo condividono lo stesso bus indirizzi. Il segnale
`BOOT_RUN` può utilizzare `A12` per selezionare due banchi di microcodice da
4096 byte: `0` per boot e `1` per run.

| Pin indirizzo | Segnale | Funzione |
| --- | --- | --- |
| `A0` | `µSTEP[0]` | Bit 0 del microstep. |
| `A1` | `µSTEP[1]` | Bit 1 del microstep. |
| `A2` | `µSTEP[2]` | Bit 2 del microstep; con `A0` e `A1` seleziona `T1..T8`. |
| `A3` | `µOP[0]` | Bit 0 del microprogramma prodotto dal dispatch. |
| `A4` | `µOP[1]` | Bit 1 del microprogramma prodotto dal dispatch. |
| `A5` | `µOP[2]` | Bit 2 del microprogramma prodotto dal dispatch. |
| `A6` | `µOP[3]` | Bit 3 del microprogramma prodotto dal dispatch. |
| `A7` | `µOP[4]` | Bit 4 del microprogramma; con `A3..A6` seleziona uno dei 32 microprogrammi. |
| `A8` | `C` | Flag Carry/Borrow. |
| `A9` | `Z` | Flag Zero. |
| `A10` | `N` | Flag Negative. |
| `A11` | `O` | Flag Overflow. |
| `A12` | `BOOT_RUN` | Seleziona il banco boot (`0`) oppure run (`1`). |

| EEPROM | Uscite dati |
| --- | --- |
| Control ROM 0 | `ADDR_SEL_0`, `ADDR_SEL_1`, `PC_INC`, `PC_LOAD`, `MAR_L_WE`, `MAR_H_WE`, `MEM_RD`, `MEM_WR` |
| Control ROM 1 | `IR_WE`, `MDR_WE`, `MDR_OE`, `RF_EN`, `RF_WR`, `RA_WE`, `RA_OE`, `RB_WE` |
| Control ROM 2 | `ALU_OE`, `FLAGS_WE`, `NEXT_FETCH`, `HALT`, `IDX_L_WE`, `IDX_H_WE`, due uscite riservate |

Colleghiamo direttamente solo `IR[3:0]` al decoder della ALU perché quattro bit rappresentano fino a 16 codici operazione (`0000`–`1111`).
Gli altri bit dell'IR identificano categoria e modalità dell'istruzione; il dispatch usa l'opcode completo `IR[7:0]` per produrre `µOP[4:0]`.

> Il generatore attuale contiene lo stesso microcodice nei due banchi selezionati
> da `A12`; prima di usare `BOOT_RUN` devono essere definite le microsequenze di boot.

Posizione e polarita elettrica delle uscite si configurano in
[`tools/cu-bytecode/config/control_signals.c`](../tools/cu-bytecode/config/control_signals.c).
