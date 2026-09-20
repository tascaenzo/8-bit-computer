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
| `D4` | 14 | `MDR_OE` | attivo alto | Porta MDR sul data bus per la scrittura RAM. |
| `D5` | 15 | `RAM_WE` | attivo basso | Scrive il byte di MDR nella RAM. |
| `D6` | 16 | `EPROM_OE` | attivo basso | Abilita l'EPROM programma sul data bus. |
| `D7` | 17 | `NEXT_FETCH` | attivo basso | Azzera il microstep e riparte da `T1`. |

Sequenza BOOT generata quando `BOOT_RUN = 0`:

```text
T1  ADDR_SEL=PC · EPROM_OE · MDR_WE
T2  ADDR_SEL=PC · MDR_OE · RAM_WE · PC_INC · NEXT_FETCH
```

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
| `T1` | `ADDR_SEL=PC`, `EPROM_OE`, `MDR_WE` | D0=1, D1=0, D3=1, D6=0; le altre inattive. |
| `T2` | `ADDR_SEL=PC`, `MDR_OE`, `RAM_WE`, `PC_INC`, `NEXT_FETCH` | D0=1, D1=0, D2=1, D4=1, D5=0, D7=0; le altre inattive. |

Le uscite attive basse inattive restano a `1`: in particolare `D5`, `D6` e
`D7` sono normalmente alte.
