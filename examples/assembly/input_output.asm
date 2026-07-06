; Esempio didattico: lettura da input e scrittura su output.
;
; IN legge il valore presente sulla periferica o registro di input.
; OUT copia il valore verso la periferica o registro di output.
; NOP non modifica lo stato utile della CPU: serve come istruzione vuota.

.code 0x0000
NOP
IN R0
NOP
OUT R0
HLT
