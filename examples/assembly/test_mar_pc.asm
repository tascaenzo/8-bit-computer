; Test immediato MAR -> PC: nessuna ALU, CMP o condizione.
; Dopo BOOT: PC=0, RUN, clock manuale fermo basso.
;
; JMP loop di prova:
; T1: bus=A0, IR=A0; PC passa da 0 a 1.
; T2: bus=04, MAR basso=04; PC passa a 2.
; T3: bus=00, MAR completo=0004; PC passa a 3.
; T4: /PC_LOAD=0, PC_INC=0; al fronte attivo PC deve diventare 4.
;     Verificare MAR=0004 sugli ingressi paralleli dei quattro 74161,
;     /CLR=1, /LOAD=0 e un fronte di salita sui loro pin di clock.
;     Se il clock PC e ancora gated solo da PC_INC, in T4 manca il fronte:
;     il test evidenzia il problema, non lo aggira.
; T5: ritorno al fetch; PC resta 4, IR resta A0.
;
; Salto riuscito: LDI R0,4, poi HLT; stato finale R0=4, PC=7.
; Salto ignorato (PC rimasto a 3): HLT immediato; PC finale=4.
; Quindi PC=4 durante HLT NON dimostra che il salto sia riuscito.
; Durante T4/T5 il bus dati non e pilotato. Misurare PC sulle Q dei 74161.

.code 0x0000
JMP target
HLT                 ; 0003: arresto se il PC non viene caricato

target:             ; 0004: destinazione del salto
LDI R0, 4
HLT                 ; 0006: arresto dopo il salto riuscito
