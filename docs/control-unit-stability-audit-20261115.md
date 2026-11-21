# Verifica stabilità CPU e MAR — 15 novembre 2026

L'utente conferma che il 74HC377 per gli enable MAR e la protezione /WE
durante reset sono ancora proposte. L'errore sembra nel MAR; il clock manuale
migliora la stabilità ma non elimina il problema. Non sono state acquisite
forme d'onda né lette le EEPROM fisiche in questa verifica.

## Risultati riprodotti

- Build e test C CU e assembler: PASS.
- Simulatore: 23/23 PASS; è una verifica funzionale, non elettrica.
- Test Verilog FPGA: PASS (reset, UART, boot, decoder, core, testo 480p/720p,
  TMDS e AVI).
- Audit indipendente: 8192 parole fisiche e 1376 sequenze (86 opcode per 16
  combinazioni flag), BOOT e HLT: PASS.
- Audit memoria: PASS; STA prepara T5, scrive T6, mantiene T7, ritorna T8;
  STAI prepara T3, scrive T4, mantiene T5, ritorna T6.
- Le immagini correnti coincidono con l'archivio del 12 novembre: ROM0 in
  `output/cu/write-phases-20261112/`, ROM1/2 nella sottocartella `before/`.
  Il log di readback del 12 novembre riguarda CU0; non certifica oggi i tre chip.

L'audit `tests/audit_rom_timing.py` aveva ancora le attese STA/STAI precedenti
e falliva su STA/T5. Aggiornate queste attese, passa. Nessuna modifica al
microcodice di produzione e nessuna programmazione hardware.

Riproduzione dalla radice:

```sh
make -B -C tools/cu-bytecode test all
mkdir -p tmp/stability-audit-20261115
tools/cu-bytecode/build/cpu8microcode -o tmp/stability-audit-20261115/microcode
python3 tools/cu-bytecode/tests/audit_rom_timing.py tmp/stability-audit-20261115/microcode
python3 tools/cu-bytecode/audit_memory_safety.py --prefix tmp/stability-audit-20261115/microcode --report tmp/stability-audit-20261115/memory-audit.json
```

## Diagnosi da verificare sul banco

1. **Clock MAR derivato da CK AND enable EEPROM.** Se il sequencer cambia
   sulla salita, la ROM può attivare il nuovo enable mentre CK è ancora alto:
   la AND genera una salita locale anticipata. In T2/T3 cambiano anche PC,
   dato e controlli; il MAR può acquisire un byte non ancora valido. Eventuali
   transitori degli indirizzi EEPROM aggiungono un ulteriore rischio.
2. **Dato che cambia vicino alla cattura.** Anche stabilizzando l'enable,
   l'incremento PC e il clock locale MAR hanno percorsi diversi. Occorre
   controllare che il vecchio dato rimanga valido fino alla cattura e per
   l'hold richiesto dal registro reale.
3. **Reset senza blocco scrittura RAM.** È un rischio indipendente: un
   operando corrotto prima dell'esecuzione può apparire come errore MAR.
   BOOT/T1 richiede scrittura anche a clock fermo. Verificare gli operandi
   prima di attribuire il byte sbagliato al registro.
4. Controllare fronti/rimbalzi del CK principale e alimentazione sul MAR:
   i test software non escludono nessuno dei due.

Queste sono ipotesi di guasto coerenti con il circuito documentato, non
misure del guasto. Il miglioramento a clock lento non prova quale sia la causa.

## Prima prova: isolare MAR e PC

Usare `examples/assembly/test_mar_pc.asm`, già presente: non richiede ALU,
scritture dati RAM o periferiche durante RUN. Dopo BOOT i byte iniziali
devono essere `A0 04 00 00 20 04 00`.

Le righe sotto indicano lo stato **dopo il fronte che chiude il microstep**;
il contatore può già mostrare lo step seguente.

| Step eseguito | Dato prima del fronte | Risultato atteso |
| --- | --- | --- |
| T1 | A0 | IR=A0, PC=0001 |
| T2 | 04 | MAR basso=04, PC=0002 |
| T3 | 00 | MAR=0004, PC=0003 |
| T4 | bus dati non significativo | PC=0004, MAR invariato |
| T5 | bus dati non significativo | PC=0004, ritorno al fetch |

Il programma deve poi terminare con R0=04 e PC=0007. Un arresto con PC=0004
può invece indicare salto fallito e fetch dell'HLT all'indirizzo 0003.

Con oscilloscopio, osservare CK CPU, enable MAR basso e CK sul pin del MAR
basso; ripetere per MAR alto. Trigger sulla salita del clock locale:

- una salita utile alla chiusura di T2 per il basso e di T3 per l'alto;
- nessuna salita aggiuntiva dovuta all'entrata nello step o dentro CK alto;
- se il clock è corretto, acquisire insieme dato al pin D e clock locale,
  confrontando setup/hold con il datasheet del registro effettivamente montato;
- se anche il CK principale ha più fronti, risolvere prima generatore,
  antirimbalzo e distribuzione.

Ripetere il test almeno 20 volte e annotare il primo step divergente,
separando ripartenze RUN e nuove copie BOOT. LED e multimetro mostrano stati
stabili ma non dimostrano l'assenza di impulsi brevi.

## Intervento candidato e limiti

La proposta `mar-clock-abilitazioni-memorizzate.md` conserva gli enable alla
discesa e li mantiene durante la salita successiva. È mirata al primo rischio;
non garantisce da sola l'hold dei dati e non protegge gli altri registri.
Il 377 non ha clear: rispettare la sua inizializzazione documentata e montare
prima l'inibizione /WE durante reset richiesta dalla procedura. Non applicare
un impulso sotto reset sul circuito attuale assumendo che la RAM sia protetta.

Per definire il cablaggio definitivo servono sigle complete di MAR, porte AND,
RAM e generatore/distribuzione CK effettivi, oltre alla prima cattura errata.

## Disallineamenti documentali da considerare

Gli audit storici descrivono anche sequenze superate. Inoltre il piano visuale
STA/STAI in `tools/simulator-web/js/microcode.js` mostra ancora scrittura T5/T3
e ritorno T6/T4: non usarlo come riferimento temporale della CU corrente.
La simulazione delle istruzioni può passare pur con questa differenza.

## Fonti primarie consultate

- [Microchip AT28C64B](https://ww1.microchip.com/downloads/en/DeviceDoc/doc0270.pdf): lettura asincrona e tempi di accesso.
- [TI SN74HCT574](https://www.ti.com/lit/ds/symlink/sn74hct574.pdf): cattura sul fronte e requisiti temporali; usare i valori del componente realmente montato.
- [TI SN74HC377](https://www.ti.com/lit/ds/symlink/sn74hc377.pdf): clock enable e assenza di clear.
