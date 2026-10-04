; Verifica manuale della CU: 5 + 3 = 8, poi HLT.
; Guida per ogni microstep: docs/step-check-guide.md
; Caricare nella EEPROM PROGRAMMA, non nelle tre EEPROM CU.
; Dopo BOOT: selezionare RUN con clock basso e PC/microstep azzerati.
; T1 indica microstep 000 (chiamato anche T0 sulla scheda).
;
; PC=0000, opcode=20:
; T1: RAM[PC] -> IR, PC++.
; T2: RAM[PC] -> MDR (05), PC++.
; T3: MDR -> R0 (05).
; T4: NEXT_FETCH_n=0, ritorno a T1 al clock successivo.
.code 0x0000
LDI R0, 5
;
; PC=0002, opcode=21: stessa sequenza, MDR=03 e R1=03.
LDI R1, 3
;
; PC=0004, opcode=C0:
; T1: fetch e PC++.
; T2: R0 -> RA (05).
; T3: ritorno al fetch.
MOV RA, R0
;
; PC=0005, opcode=C9:
; T1: fetch e PC++.
; T2: R1 -> RB (03).
; T3: ritorno al fetch.
MOV RB, R1
;
; PC=0006, opcode=67:
; T1: fetch e PC++.
; T2: ALU -> RA (08), salva flag C=0 Z=0 N=0 O=0.
; T3: ritorno al fetch.
ADD
;
; PC=0007, opcode=00:
; T1: fetch e PC++ (PC=0008).
; T2: SYS_STEP_n=0 e IR[2:0]=000: arresto del sequencer.
HLT
