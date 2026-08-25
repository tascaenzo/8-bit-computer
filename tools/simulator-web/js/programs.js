export const DEFAULT_PROGRAM =
  `; Demo: scrive “CPU 8-BIT” nella prima riga della VRAM.
; La FPGA intercetta l'area 0x4000–0x7FFF.
.equ VIDEO, 0x4000

.code 0x0000
start:
  LDI R0, 0x43       ; C
  STA R0, VIDEO
  LDI R0, 0x50       ; P
  STA R0, 0x4001
  LDI R0, 0x55       ; U
  STA R0, 0x4002
  LDI R0, 0x20       ; spazio
  STA R0, 0x4003
  LDI R0, 0x38       ; 8
  STA R0, 0x4004
  LDI R0, 0x2D       ; -
  STA R0, 0x4005
  LDI R0, 0x42       ; B
  STA R0, 0x4006
  LDI R0, 0x49       ; I
  STA R0, 0x4007
  LDI R0, 0x54       ; T
  STA R0, 0x4008
  HLT

.data
counter: .byte 0x00`;
