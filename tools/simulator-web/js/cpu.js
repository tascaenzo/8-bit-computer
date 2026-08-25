import { FIXED_OPCODES, MEMORY_SIZE, OPCODE_NAMES } from "./isa.js";
import { hex } from "./utils.js";

export function createCpuState() {
  return {
    mem: new Uint8Array(MEMORY_SIZE),
    regs: new Uint8Array(8),
    pc: 0,
    mar: 0,
    mdr: 0,
    ir: 0,
    ra: 0,
    rb: 0,
    flags: { C: 0, Z: 0, N: 0, O: 0 },
    halted: false,
    cycles: 0,
    input: 0,
    output: 0,
    program: new Map(),
    symbols: {},
    trace: [],
    lastWrite: null,
    micro: {
      plan: [],
      current: -1,
      instructionAddress: null,
      selectedBlock: null,
    },
  };
}

export function resetCpu(state, keepMemory = true) {
  if (!keepMemory) state.mem.fill(0);
  state.regs.fill(0);
  Object.assign(state, {
    pc: 0,
    mar: 0,
    mdr: 0,
    ir: 0,
    ra: 0,
    rb: 0,
    flags: { C: 0, Z: 0, N: 0, O: 0 },
    halted: false,
    cycles: 0,
    output: 0,
    trace: [],
    lastWrite: null,
  });
  clearMicroPlan(state);
}

export function loadProgram(state, assembled) {
  state.mem = assembled.mem;
  state.program = assembled.program;
  state.symbols = assembled.symbols;
  resetCpu(state, true);
}

export function clearMicroPlan(state) {
  state.micro.plan = [];
  state.micro.current = -1;
  state.micro.instructionAddress = null;
}

export function disassemble(state, opcode, address) {
  const reg = opcode & 7;
  const operandAddress = () =>
    state.mem[(address + 1) & 0xffff] |
    (state.mem[(address + 2) & 0xffff] << 8);
  if (opcode >= 0x20 && opcode <= 0x27) {
    return `LDI R${reg}, ${hex(state.mem[(address + 1) & 0xffff])}`;
  }
  if (opcode >= 0x40 && opcode <= 0x47) {
    return `LDA R${reg}, ${hex(operandAddress(), 4)}`;
  }
  if (opcode >= 0x48 && opcode <= 0x4f) {
    return `STA R${reg}, ${hex(operandAddress(), 4)}`;
  }
  if (opcode >= 0x80 && opcode <= 0x87) return `IN R${reg}`;
  if (opcode >= 0x88 && opcode <= 0x8f) return `OUT R${reg}`;
  if (opcode >= 0xa0 && opcode <= 0xa8) {
    return `${OPCODE_NAMES[opcode]} ${hex(operandAddress(), 4)}`;
  }
  if (opcode >= 0xc0 && opcode <= 0xc7) return `MOV RA, R${reg}`;
  if (opcode >= 0xc8 && opcode <= 0xcf) return `MOV RB, R${reg}`;
  if (opcode >= 0xd0 && opcode <= 0xd7) return `MOV R${reg}, RA`;
  return OPCODE_NAMES[opcode] || `DB ${hex(opcode)}`;
}

const readProgramByte = (state) => {
  const value = state.mem[state.pc];
  state.pc = (state.pc + 1) & 0xffff;
  return value;
};
const overflowAdd = (a, b, result) => (~(a ^ b) & (a ^ result) & 0x80) !== 0;
const overflowSub = (a, b, result) => ((a ^ b) & (a ^ result) & 0x80) !== 0;
const setFlags = (state, result, carry = false, overflow = false) => {
  state.flags = {
    C: Number(carry),
    Z: Number((result & 0xff) === 0),
    N: Number((result & 0x80) !== 0),
    O: Number(overflow),
  };
};
const jumpCondition = (state, opcode) =>
  ({
    0xa0: true,
    0xa1: state.flags.Z,
    0xa2: !state.flags.Z,
    0xa3: state.flags.C,
    0xa4: !state.flags.C,
    0xa5: state.flags.N,
    0xa6: !state.flags.N,
    0xa7: state.flags.O,
    0xa8: !state.flags.O,
  })[opcode];

function executeAlu(state, opcode) {
  const { ra: a, rb: b } = state;
  let result = a;
  const logic = {
    0x60: () => a & b,
    0x61: () => a | b,
    0x62: () => a ^ b,
    0x63: () => ~(a | b),
    0x64: () => ~(a & b),
    0x65: () => ~(a ^ b),
    0x66: () => ~a,
  };
  if (logic[opcode]) {
    result = logic[opcode]();
    state.ra = result & 0xff;
    setFlags(state, result);
    return;
  }
  if (opcode === 0x67) {
    const full = a + b;
    state.ra = full & 0xff;
    setFlags(state, full, full > 0xff, overflowAdd(a, b, full));
    return;
  }
  result = (a - b) & 0xff;
  if (opcode === 0x68) state.ra = result;
  setFlags(state, result, a < b, overflowSub(a, b, result));
}

export function stepCpu(state, input) {
  if (state.halted) return { halted: true };
  state.input = input;
  const address = state.pc;
  const opcode = readProgramByte(state);
  state.ir = opcode;
  const text = disassemble(state, opcode, address);
  const reg = opcode & 7;
  let error = null;

  if (opcode === FIXED_OPCODES.HLT) state.halted = true;
  else if (opcode === FIXED_OPCODES.NOP) {
    /* no operation */
  } else if (opcode >= 0x20 && opcode <= 0x27) {
    state.mdr = readProgramByte(state);
    state.regs[reg] = state.mdr;
  } else if (opcode >= 0x40 && opcode <= 0x4f) {
    const target = readProgramByte(state) | (readProgramByte(state) << 8);
    state.mar = target;
    if (opcode <= 0x47) {
      state.mdr = state.mem[target];
      state.regs[reg] = state.mdr;
    } else {
      state.mdr = state.regs[reg];
      state.mem[target] = state.mdr;
      state.lastWrite = target;
    }
  } else if (opcode >= 0x60 && opcode <= 0x69) executeAlu(state, opcode);
  else if (opcode >= 0x80 && opcode <= 0x87) {
    state.regs[reg] = input;
  } else if (opcode >= 0x88 && opcode <= 0x8f) {
    state.output = state.regs[reg];
  } else if (opcode >= 0xa0 && opcode <= 0xa8) {
    const target = readProgramByte(state) | (readProgramByte(state) << 8);
    state.mar = target;
    if (jumpCondition(state, opcode)) state.pc = target;
  } else if (opcode >= 0xc0 && opcode <= 0xc7) state.ra = state.regs[reg];
  else if (opcode >= 0xc8 && opcode <= 0xcf) state.rb = state.regs[reg];
  else if (opcode >= 0xd0 && opcode <= 0xd7) state.regs[reg] = state.ra;
  else {
    state.halted = true;
    error = `Opcode non supportato ${hex(opcode)} a ${
      hex(
        address,
        4,
      )
    }. CPU arrestata.`;
  }

  state.cycles++;
  state.trace.unshift({ address, text });
  if (state.trace.length > 40) state.trace.pop();
  return { address, opcode, text, halted: state.halted, error };
}
