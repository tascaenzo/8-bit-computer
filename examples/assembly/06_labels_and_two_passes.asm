; ESEMPIO ASSEMBLY 06
; Label in avanti, confronto e assemblaggio in due passate.
;
; R0 e R1 contengono entrambi 5, quindi CMP attiva il flag Z.
; JZ salta alla label equal e il programma salva il valore 1 in R2.
;
; Per provare il ramo opposto basta cambiare R1 da 5 a 7:
; il salto JZ non viene eseguito e il programma salva zero in R2.

.code 0x0000

LDI R0, 5
LDI R1, 5

; La ALU lavora sui registri dedicati RA e RB.
MOV RA, R0
MOV RB, R1

; CMP confronta RA e RB, non modifica i registri e aggiorna i flag.
CMP

; equal viene usata prima della sua definizione.
; Nella prima passata l'assembler calcola il suo indirizzo.
; Nella seconda passata inserisce l'indirizzo dentro l'istruzione JZ.
JZ equal

; Questo ramo viene eseguito quando i due valori sono diversi.
LDI R2, 0
JMP done

; Questa label identifica l'indirizzo della prossima istruzione.
equal:
LDI R2, 1

; Anche done viene risolta dall'assembler come indirizzo a 16 bit.
done:
HLT
