# CPU8 CU Bytecode Generator

Generatore C99 del microcodice per la Control Unit della CPU didattica a 8 bit.
Traduce le microsequenze documentate in tre immagini da 8 KiB per le tre ROM
di controllo AT28C64 in parallelo.

La specifica di riferimento e
[`docs/control-unit-microcode.md`](../../docs/control-unit-microcode.md).
Per le prove sulla scheda usare il
[registro delle verifiche](../../docs/control-unit-test-log.md), che parte
dalla tabella di verita del BOOT.

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

Per scegliere un altro prefisso:

```sh
tools/cu-bytecode/build/cpu8microcode -o /tmp/cpu8-control
```

## Mappa delle ROM di controllo

Le tre EEPROM condividono l'indirizzo:

```text
A0..A2  = microstep T1..T8
A3..A7  = IR[7:3]
A8      = C
A9      = Z
A10     = N
A11     = O
A12     = BOOT_RUN (0 = boot, 1 = run)
```

Mappa delle uscite:

| ROM | Bit 0..7                                                                                    |
| --- | ------------------------------------------------------------------------------------------- |
| 0   | `ADDR_SEL_0`, `ADDR_SEL_1`, `PC_INC`, `MDR_WE`, `MDR_OE`, `RAM_WE`, `EPROM_OE`, `NEXT_FETCH` |
| 1   | `IR_WE`, `PC_LOAD`, `MAR_L_WE`, `RF_EN`, `RF_RW`, `RA_EN`, `RA_RB_RW`, `RB_EN`               |
| 2   | `ALU_EN`, `FLAGS_WE`, `MAR_H_WE`, `RAM_OE`, `IDX_L_WE`, `IDX_H_WE`, due bit riservati        |

## Configurazione dei segnali

Le costanti simboliche per tutti i pin AT28C64 e per i segnali collegati ad
`A0..A12` e `D0..D7` sono in
[`config/control_signals.h`](config/control_signals.h). La mappa delle uscite
e la polarita e in [`config/control_signals.c`](config/control_signals.c).
Ogni riga di uscita contiene:

```c
{segnale, "nome", numero_rom, bit_D0_D7, pin_DIP_AT28C64, polarita}
```

Esempi:

```c
{CTRL_PC_INC, "PC_INC", 0, 2, 11, ACTIVE_HIGH},
{CTRL_RAM_OE, "RAM_OE", 0, 6, 16, ACTIVE_LOW},
```

`ACTIVE_HIGH` scrive `1` quando il segnale e attivo; `ACTIVE_LOW` scrive `0`
quando e attivo e mantiene normalmente l'uscita a `1`. Dopo una modifica basta
ricompilare e rigenerare:

```sh
make -C tools/cu-bytecode clean all test generate
```

Il generatore verifica anche la corrispondenza tra uscita e pin DIP della
AT28C64: `D0..D7` devono essere rispettivamente i pin
`9, 10, 11, 13, 14, 15, 16, 17`.

I codici del selettore del bus indirizzi e i livelli di `BOOT_RUN` sono in
[`config/architecture.h`](config/architecture.h). La configurazione predefinita
usa `00=IDX`, `01=PC`, `10=MAR`, `11=nessuna sorgente`.

Il video 25 collega direttamente `IR[7:3]` ad `A3..A7` delle tre Control ROM:
non e prevista una quarta EEPROM di dispatch.

## Stato iniziale

Sono implementate `NOP`, `HLT`, `LDI`, `LDA`, `STA`, le operazioni ALU, `CMP`,
i tre trasferimenti `MOV` e tutti i salti. Gli opcode riservati e le istruzioni
provvisorie `IN`/`OUT` vanno a `UOP_INVALID`, che arresta il sequencer in `T2`.

Prima di generare le immagini, il tool verifica automaticamente che:

- una sola sorgente piloti il data bus;
- lettura e scrittura memoria non siano contemporanee;
- `RF_RW` sia sempre accompagnato da `RF_EN`;
- nessuna uscita EEPROM sia assegnata a due segnali;
- selettore indirizzi e livelli `BOOT_RUN` abbiano valori validi.

`IDX_L_WE` e `IDX_H_WE` sono gia assegnati alle uscite fisiche, ma rimangono
inattivi finche la ISA non definisce gli opcode per `IDX`. I due banchi boot e
run sono entrambi generati; per ora contengono le stesse microsequenze, in
attesa della definizione del ciclo di copia ROM -> RAM. `EPROM_OE` e quindi
presente nella configurazione ma resta inattivo nelle immagini attuali.
