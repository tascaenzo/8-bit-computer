; Contatore in RAM: parte da counter e arriva a 10, poi HLT.
; Impostare il valore iniziale di counter tra 0 e 10 inclusi.
; R0 = contatore, R1 = incremento, R2 = limite.
; Ogni giro legge counter con LDA e, se inferiore a 10,
; lo incrementa e riscrive in RAM con STA.
; CMP confronta RA con RB senza modificare RA.
; JZ usa il flag Z prodotto da CMP: a 10 salta a done.
; Stato finale previsto: RAM[counter] = R0 = RA = 10 (0x0A), Z = 1.

.code 0x0000
LDI R1, 1
LDI R2, 10

loop:
LDA R0, counter
MOV RA, R0
MOV RB, R2
CMP
JZ done

MOV RB, R1
ADD
MOV R0, RA
STA R0, counter
JMP loop

done:
HLT

; Il boot copia anche questo byte dalla ROM alla RAM.
; Modificare 3 per scegliere il valore iniziale del conteggio.
.data
counter: .byte 3
