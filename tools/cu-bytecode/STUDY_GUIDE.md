# Guida allo studio del generatore della Control Unit

`cu-bytecode` genera i binari per le tre EEPROM AT28C64 della Control Unit.
Le tre ROM condividono i 13 ingressi di indirizzo e producono, insieme, una
microistruzione da 24 bit. Il tool genera anche una ROM di dispatch opzionale
che traduce l'opcode in un microprogramma (`uOP`).

## Idea generale

Le linee di indirizzo condivise sono:

```text
A0..A2   = uSTEP[0..2]
A3..A7   = IR[3..7] nel cablaggio del video 25
A8..A11  = flag C, Z, N, O
A12      = BOOT_RUN
```

Le linee `D0..D7` sono invece uscite diverse per ogni EEPROM. Il generatore
prima costruisce una parola logica, dove `1` significa segnale attivo, poi usa
la configurazione fisica per trasformarla nei tre byte EEPROM, applicando
anche le polarita attive basse.

## Ordine di lettura consigliato

1. `README.md`
2. `config/control_signals.h`
3. `config/control_signals.c`
4. `config/architecture.h`
5. `include/microcode.h`
6. `src/microcode.c`
7. `src/main.c`
8. `include/output.h` e `src/output.c`
9. `tests/test_microcode.c`

## Configurazione: `config/control_signals.h`

Contiene tutte le costanti simboliche della AT28C64: pin `A0..A12`,
`IO0..IO7`, `/CE`, `/OE`, `/WE`, GND, VCC e NC. Contiene inoltre i nomi
funzionali, per esempio `CPU8_CONTROL_ROM_PIN_USTEP_0`,
`CPU8_CONTROL_ROM_PIN_FLAG_C` e `CPU8_CONTROL_ROM_PIN_D6`.

Definisce anche `ControlEepromAddressConfig`, la struttura dati per la mappa
degli ingressi comuni alle tre EEPROM.

## Configurazione: `config/control_signals.c`

Questo e il file da modificare quando cambia il cablaggio.

`CPU8_CONTROL_EEPROM_ADDRESS_CONFIGS` mappa i 13 segnali di ingresso agli
indirizzi `A0..A12`. La tabella e comune a ROM 0, ROM 1 e ROM 2.

`CPU8_CONTROL_SIGNAL_CONFIGS` mappa le uscite. Ogni riga ha questa forma:

```c
{ segnale_logico, nome, numero_rom, bit_D0_D7, pin_AT28C64, polarita }
```

Esempio:

```c
{CTRL_RAM_OE, "RAM_OE", 0, 6, CPU8_CONTROL_ROM_PIN_D6, ACTIVE_LOW}
```

Significa: ROM 0, `D6`, pin fisico 16, segnale attivo basso.

## `config/architecture.h`

Contiene i codici del selettore del bus indirizzi (`IDX`, `PC`, `MAR` o
nessuna sorgente) e i livelli di `BOOT_RUN`. Se cambia il cablaggio del
decoder, modifica questo file invece delle microsequenze.

## `include/microcode.h`

E il contratto pubblico del progetto. Dichiara:

- `ControlWord`, parola logica dei segnali;
- `ControlSignal`, le maschere dei 22 segnali;
- `MicroOp`, i microprogrammi;
- flag, modi CPU e funzioni di generazione.

## `src/microcode.c`

E il motore del generatore. `microcode_word` descrive le microsequenze di
fetch, load, store, ALU, movimenti e salti. Lo stesso file:

- converte opcode in microprogramma con `dispatch_opcode`;
- valuta le condizioni usando i flag `C`, `Z`, `N`, `O`;
- verifica che non esistano contese sul data bus;
- applica la polarita fisica con `encode_control_word`;
- riempie tutte le 8192 celle delle tre ROM.

La ROM di dispatch e un'estensione opzionale rispetto al video 25: serve alla
ISA corrente per distinguere opcode che condividono gli stessi bit alti.

## `src/main.c`

E il punto di ingresso di `cpu8microcode`: costruisce le immagini, le valida e
scrive `microcode-rom0.bin`, `microcode-rom1.bin`, `microcode-rom2.bin` e
`microcode-dispatch.bin`. L'opzione `-o` cambia il prefisso dei file.

## `include/output.h` e `src/output.c`

Gestiscono solo la scrittura binaria su disco. La separazione mantiene il
motore del microcodice indipendente dall'I/O e semplice da testare.

## `tests/test_microcode.c`

Contiene test con `assert` per dispatch, 13 ingressi comuni, microsequenze,
polarita, pin `D0..D7` e contese sul data bus.

## Compilare e generare

```sh
make -C tools/cu-bytecode
make -C tools/cu-bytecode test
make -C tools/cu-bytecode generate
```

I binari vengono creati in `tools/cu-bytecode/build/`.

## Percorso pratico

1. Confronta `CPU8_CONTROL_EEPROM_ADDRESS_CONFIGS` con il cablaggio reale.
2. Controlla i gruppi di otto uscite in `CPU8_CONTROL_SIGNAL_CONFIGS`.
3. Esegui i test prima e dopo ogni modifica.
4. Rigenera le immagini e programma una EEPROM alla volta.

## Limiti attuali

- Il BOOT copia in ciclo continuo gli 8 KiB della EPROM: il passaggio a RUN e
  l'azzeramento finale di PC restano azioni hardware esterne.
- `HLT` non ha ancora una linea fisica tra i 22 segnali del video 25.
- `IDX` non ha incremento automatico: `LDX` lo ricarica esplicitamente.
