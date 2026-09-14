# CPU8 CU Bytecode Generator

Generatore C99 del microcodice per la Control Unit della CPU didattica a 8 bit.
La prima versione traduce le microsequenze documentate in quattro immagini da
8 KiB pronte per EEPROM AT28C64: tre ROM di controllo in parallelo e una ROM di
dispatch opcode -> `uOP`.

La specifica di riferimento e
[`docs/control-unit-microcode.md`](../../docs/control-unit-microcode.md).

## Build, test e generazione

```sh
make -C tools/cu-bytecode
make -C tools/cu-bytecode test
make -C tools/cu-bytecode generate
```

`generate` crea nella cartella `build/`:

- `microcode-rom0.bin`: segnali 0-7;
- `microcode-rom1.bin`: segnali 8-15;
- `microcode-rom2.bin`: segnali 16-23;
- `microcode-dispatch.bin`: conversione opcode -> `uOP[4:0]`.

Per scegliere un altro prefisso:

```sh
tools/cu-bytecode/build/cpu8microcode -o /tmp/cpu8-control
```

## Mappa delle ROM di controllo

Le tre EEPROM condividono l'indirizzo:

```text
A0..A2  = microstep T1..T8
A3..A7  = uOP[4:0]
A8      = C
A9      = Z
A10     = N
A11     = O
A12     = BOOT_RUN (0 = boot, 1 = run)
```

Mappa delle uscite:

| ROM | Bit 0..7                                                                                   |
| --- | ------------------------------------------------------------------------------------------ |
| 0   | `ADDR_SEL_0`, `ADDR_SEL_1`, `PC_INC`, `PC_LOAD`, `MAR_L_WE`, `MAR_H_WE`, `MEM_RD`, `MEM_WR` |
| 1   | `IR_WE`, `MDR_WE`, `MDR_OE`, `RF_EN`, `RF_WR`, `RA_WE`, `RA_OE`, `RB_WE`                   |
| 2   | `ALU_OE`, `FLAGS_WE`, `NEXT_FETCH`, `HALT`, `IDX_L_WE`, `IDX_H_WE`, due bit riservati       |

## Configurazione dei segnali

La posizione e la polarita di ogni uscita sono definite in
[`config/control_signals.c`](config/control_signals.c). Ogni riga contiene:

```c
{segnale, "nome", numero_rom, bit, polarita}
```

Esempi:

```c
{CTRL_PC_INC, "PC_INC", 0, 2, ACTIVE_HIGH},
{CTRL_MEM_RD, "MEM_RD", 0, 6, ACTIVE_LOW},
```

`ACTIVE_HIGH` scrive `1` quando il segnale e attivo; `ACTIVE_LOW` scrive `0`
quando e attivo e mantiene normalmente l'uscita a `1`. Dopo una modifica basta
ricompilare e rigenerare:

```sh
make -C tools/cu-bytecode clean all test generate
```

I codici del selettore del bus indirizzi e i livelli di `BOOT_RUN` sono in
[`config/architecture.h`](config/architecture.h). La configurazione predefinita
usa `00=IDX`, `01=PC`, `10=MAR`, `11=nessuna sorgente`.

La ROM di dispatch usa `IR[7:0]` sulle linee basse. Le restanti linee di
indirizzo sono ignorate e la tabella viene replicata su tutti gli 8 KiB.

## Stato iniziale

Sono implementate `NOP`, `HLT`, `LDI`, `LDA`, `STA`, le operazioni ALU, `CMP`,
i tre trasferimenti `MOV` e tutti i salti. Gli opcode riservati e le istruzioni
provvisorie `IN`/`OUT` vanno a `UOP_INVALID`, che arresta il sequencer in `T2`.

Prima di generare le immagini, il tool verifica automaticamente che:

- una sola sorgente piloti il data bus;
- lettura e scrittura memoria non siano contemporanee;
- `RF_WR` sia sempre accompagnato da `RF_EN`;
- nessuna uscita EEPROM sia assegnata a due segnali;
- selettore indirizzi e livelli `BOOT_RUN` abbiano valori validi.

`IDX_L_WE` e `IDX_H_WE` sono gia assegnati alle uscite fisiche, ma rimangono
inattivi finche la ISA non definisce gli opcode per `IDX`. I due banchi boot e
run sono entrambi generati; per ora contengono le stesse microsequenze, in
attesa della definizione del ciclo di copia ROM -> RAM.
