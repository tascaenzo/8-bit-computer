export const MEMORY_SIZE = 0x10000;
export const VIDEO_BASE = 0x4000;
export const VIDEO_WIDTH = 128;

export const FIXED_OPCODES = {
  NOP: 0x00,
  HLT: 0x01,
  AND: 0x60,
  OR: 0x61,
  XOR: 0x62,
  NOR: 0x63,
  NAND: 0x64,
  XNOR: 0x65,
  NOT: 0x66,
  ADD: 0x67,
  SUB: 0x68,
  CMP: 0x69,
  JMP: 0xa0,
  JZ: 0xa1,
  JNZ: 0xa2,
  JC: 0xa3,
  JNC: 0xa4,
  JN: 0xa5,
  JNN: 0xa6,
  JO: 0xa7,
  JNO: 0xa8,
};

export const REGISTER_OPCODES = {
  LDI: 0x20,
  LDA: 0x40,
  STA: 0x48,
  IN: 0x80,
  OUT: 0x88,
};
export const ADDRESS_INSTRUCTIONS = new Set([
  "LDA",
  "STA",
  "JMP",
  "JZ",
  "JNZ",
  "JC",
  "JNC",
  "JN",
  "JNN",
  "JO",
  "JNO",
]);
export const OPCODE_NAMES = Object.fromEntries(
  Object.entries(FIXED_OPCODES).map(([name, opcode]) => [opcode, name]),
);
