# Mappa uscite EEPROM della Control Unit

Questa e la mappa di cablaggio delle uscite `D0..D7` delle tre AT28C64 della
Control Unit. Le tre EEPROM condividono gli ingressi `A0..A12`; le loro uscite
formano insieme la microistruzione della CPU.

La sorgente di verita usata dal generatore dei binari e
[`tools/cu-bytecode/config/control_signals.c`](../tools/cu-bytecode/config/control_signals.c).

## Pin dati AT28C64

| Uscita | Pin DIP-28 |
| --- | ---: |
| `D0` | 9 |
| `D1` | 10 |
| `D2` | 11 |
| `D3` | 13 |
| `D4` | 14 |
| `D5` | 15 |
| `D6` | 16 |
| `D7` | 17 |

`Attivo basso` significa che il segnale e attivo quando la EEPROM presenta
uno zero logico sul rispettivo pin.

## Control ROM 0 — BOOT EPROM → RAM

Questa EEPROM contiene tutti i segnali necessari al primo test fisico del
ciclo BOOT.

| Uscita | Pin | Segnale | Polarita | Uso |
| --- | ---: | --- | --- | --- |
| `D0` | 9 | `ADDR_SEL_0` | attivo alto | Bit 0 del selettore PC/MAR/IDX. |
| `D1` | 10 | `ADDR_SEL_1` | attivo alto | Bit 1 del selettore PC/MAR/IDX. |
| `D2` | 11 | `PC_INC` | attivo alto | Incrementa PC dopo la copia. |
| `D3` | 13 | `MDR_WE` | attivo alto | Salva il byte letto da EPROM in MDR. |
| `D4` | 14 | `MDR_OE` | attivo basso | Porta MDR sul data bus per la scrittura RAM. |
| `D5` | 15 | `RAM_WE` | attivo basso | Scrive nella RAM il byte presente sul bus dati. |
| `D6` | 16 | `EPROM_OE` | attivo basso | Abilita l'EPROM programma sul data bus. |
| `D7` | 17 | `NEXT_FETCH` | attivo basso | Azzera il microstep e riparte da `T1`. |

Sequenza BOOT generata quando `BOOT_RUN = 0`:

```text
T1  ADDR_SEL=PC · EPROM_OE · RAM_WE
T2  ADDR_SEL=PC · EPROM_OE · PC_INC
T3  ADDR_SEL=PC · EPROM_OE · NEXT_FETCH
```

### Tabella di verita ridotta — solo BOOT, Control ROM 0

Durante BOOT (`A12=0`) IR e flag non influenzano la parola di controllo: sono
quindi indicati con `X`. Il cablaggio reale dei microstep e invertito rispetto
all'ordine numerico degli indirizzi: `A0=µSTEP[2]`, `A1=µSTEP[1]`,
`A2=µSTEP[0]`.

| Fase | `µSTEP[2:0]` | `A2 A1 A0` fisici | Indirizzo EEPROM | `D7..D0` | Byte | Effetto |
| --- | --- | --- | ---: | --- | ---: | --- |
| T1 | `000` | `000` | `0x0000` | `10010001` | `0x91` | EPROM → bus → RAM, PC stabile. |
| T2 | `001` | `100` | `0x0004` | `10110101` | `0xB5` | `/WE_RAM` torna alto; EPROM mantiene valido il dato sul bus; PC incrementa al clock. |
| T3 | `010` | `010` | `0x0002` | `00110001` | EPROM presenta il byte al nuovo PC; reset del microstep a T1. |

Per tutte le righe: `A12=0`, `A11..A3=X` e `D0=1`, `D1=0` selezionano il PC.
In T1 `D5=D6=0` abilitano la copia, mentre `D2=0` lascia fermo il PC.
In T2 `D5=1` disabilita la scrittura, `D6=0` mantiene il dato EPROM sul bus
e `D2=1` abilita l'incremento del PC. In T3 `D6=0` mantiene l'EPROM sul bus
dati e `D7=0` attiva `NEXT_FETCH`; `D5=1` impedisce la scrittura nella RAM.

## Control ROM 1 — registri e caricamento indirizzi

| Uscita | Pin | Segnale | Polarita | Uso |
| --- | ---: | --- | --- | --- |
| `D0` | 9 | `IR_WE` | attivo alto | Salva l'opcode in IR. |
| `D1` | 10 | `PC_LOAD` | attivo alto | Carica PC dal MAR durante un salto. |
| `D2` | 11 | `MAR_L_WE` | attivo alto | Salva il byte basso di MAR. |
| `D3` | 13 | `RF_EN` | attivo alto | Abilita il banco registri `R0..R7`. |
| `D4` | 14 | `RF_RW` | attivo alto | Con `RF_EN`, alto = scrittura; basso = lettura. |
| `D5` | 15 | `RA_EN` | attivo alto | Abilita il registro operando RA. |
| `D6` | 16 | `RA_RB_RW` | attivo alto | Alto = scrittura RA/RB; basso = lettura RA. |
| `D7` | 17 | `RB_EN` | attivo alto | Abilita il registro operando RB. |

## Control ROM 2 — ALU, RAM e IDX

| Uscita | Pin | Segnale | Polarita | Uso |
| --- | ---: | --- | --- | --- |
| `D0` | 9 | `ALU_EN` | attivo basso | Abilita il risultato della ALU sul data bus. |
| `D1` | 10 | `FLAGS_WE` | attivo alto | Salva i flag `C`, `Z`, `N`, `O`. |
| `D2` | 11 | `MAR_H_WE` | attivo alto | Salva il byte alto di MAR. |
| `D3` | 13 | `RAM_OE` | attivo basso | Abilita la RAM sul data bus. |
| `D4` | 14 | `IDX_L_WE` | attivo alto | Salva il byte basso di IDX. |
| `D5` | 15 | `IDX_H_WE` | attivo alto | Salva il byte alto di IDX. |
| `D6` | 16 | riservato | — | Disponibile per un'estensione futura. |
| `D7` | 17 | riservato | — | Disponibile per un'estensione futura. |

## Verifica rapida del primo chip

Per un test BOOT con sola Control ROM 0 collegata, osserva le uscite seguenti:

| Microstep | Uscite attive | Livelli fisici attesi |
| --- | --- | --- |
| `T1` | `ADDR_SEL=PC`, `EPROM_OE`, `RAM_WE` | `D7..D0 = 10010001` (`0x91`). |
| `T2` | `ADDR_SEL=PC`, `EPROM_OE`, `PC_INC` | `D7..D0 = 10110101` (`0xB5`). |
| `T3` | `ADDR_SEL=PC`, `EPROM_OE`, `NEXT_FETCH` | `D7..D0 = 00110001` (`0x31`). |

Le uscite attive basse inattive restano a `1`: in particolare `D5`, `D6` e
`D7` sono normalmente alte.
