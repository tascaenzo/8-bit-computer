# Verifica del generatore e dei binari CU — 3 ottobre 2026

Verificata la copia di lavoro corrente, comprese le modifiche locali. Non
modificati sorgenti di produzione, test del repository o immagini destinate
alle EEPROM. Le prove con configurazioni alterate sono isolate in
`/tmp/cpu8-review-20261003`.

## Aggiornamento dopo conferma del cablaggio

Il proprietario ha confermato PC_LOAD attivo basso e ha riprogrammato soltanto
ROM1. La configurazione del generatore è quindi corretta; il punto 1 sotto
era una discordanza dei test e della documentazione, non un bug del binario.
Test CU, audit indipendente e tabella delle uscite sono stati allineati.
I test CU e l’audit delle 8192 parole/1376 sequenze passano nel repository.
La sola inversione di PC_LOAD cambia esclusivamente ROM1: non richiede
la riprogrammazione di ROM0 o ROM2. Il contenuto reale di ROM2 resta da
verificare per diagnosticare l’arresto prima del fetch.

## Esito iniziale

La tabella HLT non arresta la CPU al primo microstep. Le microsequenze stabili
sono coerenti con l'ISA documentata se PC_LOAD viene interpretato attivo basso.
Esistono però una discordanza di polarità fra sorgente e specifica, due difetti
degli strumenti e rischi temporali non risolti. Non è dimostrata la correttezza
elettrica del sistema o il contenuto delle EEPROM montate sulla CPU.

## Risultati e riproduzione

- Ricompilazione forzata del generatore: riuscita.
- Test CU originali: falliscono in `test_microcode.c:273` (SUB ROM1 atteso
  `60`, effettivo `62`).
- Test CU in copia temporanea: tutti passano dopo aver cambiato solo le attese
  conseguenti alla polarità PC_LOAD (`60→62`, `00→02`, decodifica del bit
  PC_LOAD invertita). Nessuna microsequenza modificata.
- Audit indipendente dei binari esistenti: fallisce con la mappa originale
  PC_LOAD attivo alto. In copia temporanea, cambiando soltanto la polarità
  di PL a basso, passa su 8192 parole, 86 opcode ISA × 16 flag = 1376 sequenze,
  tutti gli otto step, BOOT e HLT per tutti i 256 opcode.
- Rigenerazione in `/tmp`: identica byte per byte alle tre immagini esistenti.
- Test assembler: passano; simulatore web: 21/21; modello supervisore BOOT: 4/4.
  Questi ultimi controlli non simulano il timing dei binari sulla scheda.

```sh
make -B -C tools/cu-bytecode all test
tools/cu-bytecode/build/cpu8microcode -o /tmp/cpu8-review-20261003/microcode
python3 tools/cu-bytecode/tests/audit_rom_timing.py tools/cu-bytecode/build/microcode
python3 /tmp/cpu8-review-20261003/audit_rom_timing.py tools/cu-bytecode/build/microcode
make -C /tmp/cpu8-review-20261003/cu test
make -C tools/assembler test
npm --prefix tools/simulator-web test
python3 tools/cu-bytecode/tests/test_boot_supervisor.py
```

## 1. Polarità PC_LOAD incoerente — priorità alta

`config/control_signals.c:55` configura ROM1 D1 ACTIVE_LOW. La tabella
`docs/control-unit-eeprom-output-map.md:74`, i test e l'audit originale lo
interpretano ACTIVE_HIGH. La differenza rispetto alla polarità alta è D1
invertito in tutte le 8192 celle di ROM1. Gli hash di ROM0 e ROM2 coincidono
con quelli del precedente audit del 28 settembre; ROM1 è diversa.

Se il circuito richiede un comando alto, ROM1 carica il PC nei passi sbagliati
e non lo carica nei salti presi. Se D1 pilota un ingresso di caricamento attivo
basso direttamente, la configurazione può essere corretta: in quel caso sono
test, audit e documentazione da aggiornare. Non scegliere una polarità senza
verificare il percorso elettrico D1→PC e gli eventuali inverter.

Questo difetto non modifica D6 di ROM2 e non dimostra la causa dell'HLT precoce.

## 2. STA/STAI: indirizzo e dato rilasciati insieme alla chiusura di /WE

`src/microcode.c:268` e `:315`: STA T5 e STAI T3 selezionano MAR/IDX,
abilitano MDR e attivano RAM_WE contemporaneamente. Nel passo successivo,
NEXT_FETCH disabilita la scrittura e rilascia indirizzo e dato nella stessa
transizione. Manca una fase esplicita di preparazione e mantenimento dei bus.

L'audit segnala entrambe le transizioni. È un rischio temporale concreto,
non una prova di corruzione: la sua manifestazione dipende dai ritardi reali.
Preparazione → scrittura → chiusura con bus mantenuti → ritorno rientra negli
otto step, ma serve anche qualificare /WE contro i transitori delle ROM.

## 3. Configurazione degli indirizzi non validata — difetto riprodotto

`validate_signal_config()` verifica le uscite ma non verifica che i 13
ingressi indirizzo siano una permutazione completa di segnali e pin validi.
`microcode_address()` ignora un pin sconosciuto e combina duplicati con OR.
`build_control_roms()` non rileva celle duplicate o mancanti; il buffer nel
main non è inizializzato.

In copia temporanea, assegnando µSTEP0 allo stesso pin di µSTEP1:
validazione e generazione restituiscono successo, ma 4096 celle di ROM0
rimangono al valore sentinella precedente alla generazione. Nel main tali
celle possono contenere dati indeterminati. La configurazione attuale non
presenta duplicati: questo non altera i tre binari verificati oggi.

Correzione: validare unicità, completezza e validità degli ingressi e verificare
che ogni indirizzo sia scritto esattamente una volta.

## 4. Dipendenze Make incomplete — difetto riprodotto

`Makefile:24` non include `include/microcode.h` nelle dipendenze degli oggetti
di produzione; `:34` non lo include nelle dipendenze del test. Anche
`include/output.h` manca per i consumatori.

In copia temporanea, dopo build completa, aggiornare il timestamp di
microcode.h fa ricompilare solo control_signals.o e rilinkare il generatore:
microcode.o, main.o e il test restano vecchi. Modificare enum o maschere nel
header può quindi produrre un eseguibile incoerente e riutilizzare test vecchi.
La ricompilazione forzata eseguita oggi esclude questo problema dai binari
esaminati. Usare dipendenze automatiche o elencare tutti gli header consumati.

## HLT e ordine dei microstep

Cablaggio previsto: A0=µSTEP2, A1=µSTEP1, A2=µSTEP0. Gli offset fisici dei
passi logici 0..7 sono `0,4,2,6,1,5,3,7`, non `0,1,2,3,4,5,6,7`.

Esempio RUN, IR=00, flag=0:

| µSTEP logico | Nome progetto | Indirizzo EEPROM | ROM0 | ROM1 | ROM2 | D6 ROM2 |
| --- | --- | --- | --- | --- | --- | --- |
| 000 | T1 (fetch; T0 nella domanda) | 1000 | F5 | 03 | 41 | 1 |
| 001 | T2 (HLT) | 1004 | F3 | 02 | 09 | 0 |
| 010 | T3 (ritorno NOP) | 1002 | 73 | 02 | 49 | 1 |

D6 è alto in tutto BOOT e in tutti i fetch, per ogni IR e flag. È basso solo
nel secondo passo RUN del gruppo IR[7:3]=00000. La OR con IR[2:0] arresta
soltanto opcode 00. Pertanto l'arresto con µSTEP realmente 000 non è causato
da un byte HLT errato in questa ROM2. Restano da misurare i livelli ai pin,
verificare il contenuto del chip montato e gli ingressi del contatore.

## Questioni che richiedono lo schema o misure

- Enable grezzi delle ROM combinati con clock mediante AND possono generare
  fronti locali aggiuntivi se cambiano mentre il clock è alto. È già descritto
  nell'audit temporale del 28 settembre; i test funzionali non lo escludono.
- CMP abilita solo FLAGS_WE: valido se i flag sono disponibili sul risultato
  ALU interno con il buffer CPU disabilitato; da verificare sul circuito.
- Il cambio BOOT→RUN non azzera autonomamente PC e microstep nel microcodice:
  richiede il controllo/reset esterno documentato. Il modello del supervisore
  non prova che il circuito reale implementi tale passaggio.

## Identificazione delle immagini esaminate

Tutte da 8192 byte. SHA-256:

```text
ROM0 bcd68d8330227aaab5fe3195cb19cef1b6a31963cf08d59ad3ec47118bd2fff3
ROM1 16f14126654ba83568b82573219d1dd35ba458f64795f2503c81eea46d5dc114
ROM2 f0748d039591f55060a6eab2e96dd69f5fdd4f9bc5aef1a25f6c2ea12115c01d
```
