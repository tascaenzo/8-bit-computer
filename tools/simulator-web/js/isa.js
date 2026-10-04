export const MEMORY_SIZE = 0x10000;
export const VIDEO_BASE = 0x4000;
export const VIDEO_WIDTH = 128;

export const FIXED_OPCODES = {
  HLT: 0x00,
  NOP: 0x01,
  AND: 0x60,
  OR: 0x61,
  XOR: 0x62,
  NOR: 0x63,
  NAND: 0x64,
  XNOR: 0x65,
  NOT: 0x66,
  ADD: 0x67,
  SUB: 0x78,
  CMP: 0x69,
  JMP: 0xa0,
  JZ: 0xb0,
  JNZ: 0xb8,
  JC: 0xe0,
  JNC: 0xe8,
  JN: 0xf0,
  JNN: 0xf8,
  JO: 0x30,
  JNO: 0xa8,
  LDX: 0xd8,
};

export const REGISTER_OPCODES = {
  LDI: 0x20,
  LDA: 0x40,
  STA: 0x48,
  LDAI: 0x50,
  STAI: 0x58,
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
  "LDX",
]);
export const ALU_OPCODES = new Set([
  ...Array.from({ length: 8 }, (_, index) => 0x60 + index),
  FIXED_OPCODES.SUB,
  FIXED_OPCODES.CMP,
]);
export const JUMP_OPCODES = new Set(
  [...ADDRESS_INSTRUCTIONS].filter((name) => name.startsWith("J") && name !== "LDX")
    .map((name) => FIXED_OPCODES[name]),
);
export const OPCODE_NAMES = Object.fromEntries(
  Object.entries(FIXED_OPCODES).map(([name, opcode]) => [opcode, name]),
);
