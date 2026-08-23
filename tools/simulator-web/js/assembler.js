import {
  ADDRESS_INSTRUCTIONS,
  FIXED_OPCODES,
  MEMORY_SIZE,
  REGISTER_OPCODES,
} from "./isa.js";
import { parseNumber, parseRegister } from "./utils.js";

const stripComment = (line) => line.replace(/;.*/, "").trim();
const splitOperands = (text) =>
  text
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);

function instructionSize(mnemonic, line) {
  if (mnemonic === ".BYTE") return 1;
  if (mnemonic === "LDI") return 2;
  if (ADDRESS_INSTRUCTIONS.has(mnemonic)) return 3;
  if (
    Object.hasOwn(FIXED_OPCODES, mnemonic) ||
    Object.hasOwn(REGISTER_OPCODES, mnemonic) ||
    mnemonic === "MOV"
  ) {
    return 1;
  }
  throw new Error(`riga ${line}: istruzione sconosciuta “${mnemonic}”`);
}

function encode(record, symbols) {
  const args = splitOperands(record.argumentText);
  const value = (token) => parseNumber(token, symbols, record.line);
  const addressBytes = (address) => [address & 0xff, address >> 8];

  if (record.mnemonic === ".BYTE") {
    if (args.length !== 1) {
      throw new Error(`riga ${record.line}: .byte richiede un valore`);
    }
    const byte = value(args[0]);
    if (byte > 0xff) {
      throw new Error(`riga ${record.line}: .byte richiede un valore a 8 bit`);
    }
    return [byte];
  }
  if (record.mnemonic === "LDI") {
    if (args.length !== 2) {
      throw new Error(`riga ${record.line}: LDI richiede registro e valore`);
    }
    const immediate = value(args[1]);
    if (immediate > 0xff) {
      throw new Error(`riga ${record.line}: immediato fuori range`);
    }
    return [
      REGISTER_OPCODES.LDI | parseRegister(args[0], record.line),
      immediate,
    ];
  }
  if (record.mnemonic === "LDA" || record.mnemonic === "STA") {
    if (args.length !== 2) {
      throw new Error(
        `riga ${record.line}: ${record.mnemonic} richiede registro e indirizzo`,
      );
    }
    const address = value(args[1]);
    if (address > 0xffff) {
      throw new Error(`riga ${record.line}: indirizzo fuori range`);
    }
    return [
      REGISTER_OPCODES[record.mnemonic] | parseRegister(args[0], record.line),
      ...addressBytes(address),
    ];
  }
  if (ADDRESS_INSTRUCTIONS.has(record.mnemonic)) {
    if (args.length !== 1) {
      throw new Error(
        `riga ${record.line}: ${record.mnemonic} richiede un indirizzo`,
      );
    }
    const address = value(args[0]);
    if (address > 0xffff) {
      throw new Error(`riga ${record.line}: indirizzo fuori range`);
    }
    return [FIXED_OPCODES[record.mnemonic], ...addressBytes(address)];
  }
  if (record.mnemonic === "IN" || record.mnemonic === "OUT") {
    if (args.length !== 1) {
      throw new Error(
        `riga ${record.line}: ${record.mnemonic} richiede un registro`,
      );
    }
    return [
      REGISTER_OPCODES[record.mnemonic] | parseRegister(args[0], record.line),
    ];
  }
  if (record.mnemonic === "MOV") {
    if (args.length !== 2) {
      throw new Error(`riga ${record.line}: MOV richiede due operandi`);
    }
    const [to, from] = args.map((item) => item.toUpperCase());
    if (to === "RA") return [0xc0 | parseRegister(from, record.line)];
    if (to === "RB") return [0xc8 | parseRegister(from, record.line)];
    if (from === "RA") return [0xd0 | parseRegister(to, record.line)];
    throw new Error(
      `riga ${record.line}: MOV accetta solo RA/RB ← Rn oppure Rn ← RA`,
    );
  }
  if (args.length) {
    throw new Error(
      `riga ${record.line}: ${record.mnemonic} non richiede operandi`,
    );
  }
  return [FIXED_OPCODES[record.mnemonic]];
}

export function assemble(source) {
  const symbols = {};
  const records = [];
  let address = 0;
  const lines = source.replace(/\r/g, "").split("\n");

  lines.forEach((original, index) => {
    const lineNumber = index + 1;
    let line = stripComment(original);
    if (!line) return;
    const label = /^([A-Za-z_][A-Za-z0-9_]*):\s*(.*)$/.exec(line);
    if (label) {
      const name = label[1].toUpperCase();
      if (Object.hasOwn(symbols, name)) {
        throw new Error(`riga ${lineNumber}: simbolo duplicato “${label[1]}”`);
      }
      symbols[name] = address;
      line = label[2].trim();
      if (!line) return;
    }
    const [, token, argumentText = ""] = /^([^\s]+)(?:\s+(.*))?$/.exec(line);
    const mnemonic = token.toUpperCase();
    if (mnemonic === ".EQU") {
      const args = splitOperands(argumentText);
      if (
        args.length !== 2 ||
        !/^[A-Za-z_][A-Za-z0-9_]*$/.test(args[0]) ||
        Object.hasOwn(symbols, args[0].toUpperCase())
      ) {
        throw new Error(`riga ${lineNumber}: .equ non valida`);
      }
      symbols[args[0].toUpperCase()] = parseNumber(
        args[1],
        symbols,
        lineNumber,
      );
      return;
    }
    if (mnemonic === ".CODE" || mnemonic === ".DATA") {
      if (argumentText) {
        address = parseNumber(argumentText, symbols, lineNumber);
      }
      if (address > 0xffff) {
        throw new Error(`riga ${lineNumber}: indirizzo fuori range`);
      }
      return;
    }
    const size = instructionSize(mnemonic, lineNumber);
    if (address + size > MEMORY_SIZE) {
      throw new Error(`riga ${lineNumber}: programma oltre 0xFFFF`);
    }
    records.push({
      address,
      mnemonic,
      argumentText,
      line: lineNumber,
      source: original.trim(),
    });
    address += size;
  });

  const mem = new Uint8Array(MEMORY_SIZE);
  const program = new Map();
  records.forEach((record) => {
    const bytes = encode(record, symbols);
    bytes.forEach((byte, offset) => {
      mem[record.address + offset] = byte;
    });
    if (record.mnemonic !== ".BYTE") {
      program.set(record.address, { ...record, bytes });
    }
  });
  return { mem, program, symbols };
}
