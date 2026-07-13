; ESEMPIO ASSEMBLY 02
; Costanti, direttive, label e accesso alla memoria.
;
; Risultato previsto:
; - R0 riceve il valore 10;
; - il valore viene scritto nella cella counter;
; - R1 rilegge la stessa cella;
; - al termine R0 e R1 contengono entrambi il valore 10.

; .equ crea una costante simbolica e non genera byte macchina.
.equ START_VALUE, 0x0A

; .code imposta a 0x0000 l'indirizzo della prima istruzione.
; La direttiva viene usata dall'assembler, ma non viene eseguita dalla CPU.
.code 0x0000

; LDI occupa due byte: opcode di LDI R0 e valore immediato 0x0A.
LDI R0, START_VALUE

; counter e una label. L'assembler ne calcolera automaticamente l'indirizzo.
; STA occupa tre byte: opcode, byte basso e byte alto dell'indirizzo.
STA R0, counter

; LDA legge la cella counter e copia il suo contenuto nel registro R1.
LDA R1, counter

; Se la memoria dati e scrivibile, entrambi i registri contengono 0x0A.
HLT

; .data senza indirizzo colloca i dati subito dopo il codice.
; La direttiva non crea una memoria separata.
; Codice e dati condividono lo stesso spazio di memoria Von Neumann.
.data

; Il codice occupa gli indirizzi da 0x0000 a 0x0008.
; L'assembler assegna quindi a counter il primo indirizzo libero: 0x0009.
; .byte inserisce in 0x0009 un singolo byte inizializzato a zero.
counter: .byte 0x00
