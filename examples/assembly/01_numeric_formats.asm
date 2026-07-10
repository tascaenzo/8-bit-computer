; ESEMPIO ASSEMBLY 01
; Formati numerici supportati dal linguaggio assembly.
;
; Le quattro istruzioni LDI caricano sempre lo stesso valore: 42 decimale.
; Cambia solamente il modo in cui il numero viene scritto nel sorgente.
; L'assembler produrra in tutti e quattro i casi il byte 0x2A.

.code 0x0000

; Numero decimale: senza prefisso, il valore viene interpretato in base 10.
LDI R0, 42

; Numero esadecimale con prefisso 0x.
; Questa e la notazione usata principalmente negli esempi del progetto.
LDI R1, 0x2A

; Numero binario con prefisso 0b.
; Gli otto bit permettono di vedere direttamente il valore sul data bus.
LDI R2, 0b00101010

; Notazione esadecimale alternativa, comune in diversi linguaggi assembly.
LDI R3, $2A

; Al termine R0, R1, R2 e R3 contengono tutti 0x2A, cioe 42 decimale.
HLT
