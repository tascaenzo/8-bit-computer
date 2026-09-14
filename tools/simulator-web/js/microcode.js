import { disassemble } from "./cpu.js";
import { hex } from "./utils.js";

// Nomi funzionali allineati a docs/control-unit-microcode.md.
const phase = (t, title, description, signals, blocks, paths, preview = {}) => ({
  t,
  title,
  description,
  signals,
  blocks: [...new Set(["cu", ...blocks])],
  paths: [...new Set(["cu-control", ...paths])],
  preview,
});

const readPreview = (address, value, addressSource, updates = {}) => {
  const { active = [], ...values } = updates;
  return {
    addressBus: address,
    addressSource,
    dataBus: value,
    memoryAddress: address,
    memoryValue: value,
    ...values,
    active: ["addrsel", "address-bus", "data-bus", "memory", ...active],
  };
};

const aluResult = (opcode, a, b) => {
  let raw = a;
  if (opcode === 0x60) raw = a & b;
  else if (opcode === 0x61) raw = a | b;
  else if (opcode === 0x62) raw = a ^ b;
  else if (opcode === 0x63) raw = ~(a | b);
  else if (opcode === 0x64) raw = ~(a & b);
  else if (opcode === 0x65) raw = ~(a ^ b);
  else if (opcode === 0x66) raw = ~a;
  else if (opcode === 0x67) raw = a + b;
  else raw = a - b;
  const result = raw & 0xff;
  const arithmetic = opcode === 0x68 || opcode === 0x69;
  return {
    result,
    flags: {
      C: Number(opcode === 0x67 ? raw > 0xff : arithmetic && a < b),
      Z: Number(result === 0),
      N: Number((result & 0x80) !== 0),
      O: Number(opcode === 0x67
        ? ((~(a ^ b) & (a ^ result) & 0x80) !== 0)
        : arithmetic && ((a ^ b) & (a ^ result) & 0x80) !== 0),
    },
  };
};

const jumpTaken = (flags, opcode) => ({
  0xa0: true,
  0xa1: Boolean(flags.Z),
  0xa2: !flags.Z,
  0xa3: Boolean(flags.C),
  0xa4: !flags.C,
  0xa5: Boolean(flags.N),
  0xa6: !flags.N,
  0xa7: Boolean(flags.O),
  0xa8: !flags.O,
})[opcode];

const fetch = (address, opcode) => [
  phase(
    "T1",
    "Fetch opcode",
    `PC (${hex(address, 4)}) pilota A[15:0]; la memoria presenta ${hex(opcode)} sul data bus. IR cattura l'opcode e PC viene incrementato.`,
    "ADDR_SEL=PC(01) · MEM_RD · IR_WE · PC_INC",
    ["pc", "addrsel", "memory", "ir"],
    ["pc-selector", "selector-address", "address-memory", "memory-data", "data-ir", "ir-cu"],
    readPreview(address, opcode, "PC", {
      pc: (address + 1) & 0xffff,
      ir: opcode,
      active: ["pc", "ir"],
    }),
  ),
];

const addressOperand = (address, low, high, initialMar) => [
  phase(
    "T2",
    "Fetch addr_low",
    `Il PC legge ${hex(low)} da ${hex((address + 1) & 0xffff)} e lo salva in MAR[7:0].`,
    "ADDR_SEL=PC(01) · MEM_RD · MAR_L_WE · PC_INC",
    ["pc", "mar", "addrsel", "memory"],
    ["pc-selector", "selector-address", "address-memory", "memory-data", "data-mar"],
    readPreview((address + 1) & 0xffff, low, "PC", {
      pc: (address + 2) & 0xffff,
      mar: (initialMar & 0xff00) | low,
      active: ["pc", "mar"],
    }),
  ),
  phase(
    "T3",
    "Fetch addr_high",
    `Il PC legge ${hex(high)} da ${hex((address + 2) & 0xffff)} e completa MAR = ${hex(low | (high << 8), 4)}.`,
    "ADDR_SEL=PC(01) · MEM_RD · MAR_H_WE · PC_INC",
    ["pc", "mar", "addrsel", "memory"],
    ["pc-selector", "selector-address", "address-memory", "memory-data", "data-mar"],
    readPreview((address + 2) & 0xffff, high, "PC", {
      pc: (address + 3) & 0xffff,
      mar: low | (high << 8),
      active: ["pc", "mar"],
    }),
  ),
];

export function planMicrocycles(state) {
  const address = state.pc;
  const opcode = state.mem[address];
  const text = disassemble(state, opcode, address);
  const reg = opcode & 7;
  const low = state.mem[(address + 1) & 0xffff];
  const high = state.mem[(address + 2) & 0xffff];
  const target = low | (high << 8);
  const base = fetch(address, opcode);

  if (opcode >= 0x20 && opcode <= 0x27) {
    return base.concat([
      phase(
        "T2", "Fetch immediato",
        `Legge ${hex(low)} da ${hex((address + 1) & 0xffff)} e lo salva in MDR.`,
        "ADDR_SEL=PC(01) · MEM_RD · MDR_WE · PC_INC",
        ["pc", "addrsel", "memory", "mdr"], ["pc-selector", "selector-address", "address-memory", "memory-data", "mdr-data"],
        readPreview((address + 1) & 0xffff, low, "PC", {
          pc: (address + 2) & 0xffff, mdr: low, active: ["pc", "mdr"],
        }),
      ),
      phase(
        "T3", `Scrivi R${reg}`,
        `MDR porta ${hex(low)} sul bus e R${reg} lo cattura.`,
        "MDR_OE · RF_EN · RF_WR · NEXT_FETCH",
        ["mdr", "registers"], ["mdr-data", "registers-data"],
        { dataBus: low, mdr: low, regs: { [reg]: low }, active: ["data-bus", "mdr", `r${reg}`] },
      ),
    ]);
  }

  if (opcode >= 0x40 && opcode <= 0x47) {
    const data = state.mem[target];
    return base.concat(addressOperand(address, low, high, state.mar), [
      phase(
        "T4", "Leggi dato memoria",
        `MAR pilota ${hex(target, 4)}; la memoria restituisce ${hex(data)} e MDR lo salva.`,
        "ADDR_SEL=MAR(10) · MEM_RD · MDR_WE",
        ["mar", "addrsel", "memory", "mdr"], ["mar-selector", "selector-address", "address-memory", "memory-data", "mdr-data"],
        readPreview(target, data, "MAR", { mar: target, mdr: data, active: ["mar", "mdr"] }),
      ),
      phase(
        "T5", `Scrivi R${reg}`,
        `MDR porta ${hex(data)} sul bus e R${reg} lo cattura.`,
        "MDR_OE · RF_EN · RF_WR · NEXT_FETCH",
        ["mdr", "registers"], ["mdr-data", "registers-data"],
        { dataBus: data, mdr: data, regs: { [reg]: data }, active: ["data-bus", "mdr", `r${reg}`] },
      ),
    ]);
  }

  if (opcode >= 0x48 && opcode <= 0x4f) {
    const data = state.regs[reg];
    return base.concat(addressOperand(address, low, high, state.mar), [
      phase(
        "T4", `Leggi R${reg}`,
        `R${reg} porta ${hex(data)} sul bus; MDR lo cattura prima della scrittura esterna.`,
        "RF_EN · MDR_WE",
        ["registers", "mdr"], ["registers-data", "mdr-data"],
        { dataBus: data, mdr: data, active: ["data-bus", "mdr", `r${reg}`] },
      ),
      phase(
        "T5", "Scrivi memoria",
        `MAR seleziona ${hex(target, 4)}; MDR presenta ${hex(data)} e la memoria esegue la scrittura.`,
        "ADDR_SEL=MAR(10) · MDR_OE · MEM_WR · NEXT_FETCH",
        ["mar", "addrsel", "mdr", "memory"],
        ["mar-selector", "selector-address", "address-memory", "mdr-data", "memory-data"],
        { mar: target, mdr: data, addressSource: "MAR", addressBus: target, dataBus: data, memoryAddress: target, memoryValue: data, active: ["mar", "addrsel", "mdr", "address-bus", "data-bus", "memory"] },
      ),
    ]);
  }

  if (opcode >= 0x60 && opcode <= 0x69) {
    const alu = aluResult(opcode, state.ra, state.rb);
    const cmp = opcode === 0x69;
    return base.concat([
      phase(
        "T2", cmp ? "Confronto e flag" : "ALU e write-back",
        cmp
          ? `${text}: la ALU calcola RA − RB solo per produrre C, Z, N, O; RA e RB restano invariati.`
          : `${text}: la ALU porta ${hex(alu.result)} sul bus, RA e il registro flag catturano il risultato.`,
        cmp ? "FLAGS_WE · NEXT_FETCH" : "ALU_OE · RA_WE · FLAGS_WE · NEXT_FETCH",
        ["ra", "rb", "alu", "flags"],
        cmp
          ? ["ra-alu", "rb-alu", "alu-flags"]
          : ["ra-alu", "rb-alu", "alu-data", "ra-data", "alu-flags"],
        {
          dataBus: cmp ? null : alu.result,
          alu: alu.result,
          ra: cmp ? state.ra : alu.result,
          flags: alu.flags,
          active: cmp
            ? ["ra", "rb", "alu", "flags"]
            : ["data-bus", "ra", "rb", "alu", "flags"],
        },
      ),
    ]);
  }

  if (opcode >= 0xa0 && opcode <= 0xa8) {
    const taken = jumpTaken(state.flags, opcode);
    return base.concat(addressOperand(address, low, high, state.mar), [
      phase(
        "T4", taken ? "Salto eseguito" : "Salto ignorato",
        taken
          ? `${text}: la condizione sui flag e vera, quindi PC riceve ${hex(target, 4)} dal MAR.`
          : `${text}: la condizione sui flag e falsa; PC mantiene ${hex((address + 3) & 0xffff, 4)}.`,
        taken ? "PC_LOAD · NEXT_FETCH" : "NEXT_FETCH",
        ["pc", "mar", "flags"], taken ? ["mar-pc", "ir-cu"] : ["ir-cu"],
        { pc: taken ? target : (address + 3) & 0xffff, mar: target, active: ["pc", "mar", "flags"] },
      ),
    ]);
  }

  if (opcode >= 0xc0 && opcode <= 0xc7) {
    const data = state.regs[reg];
    return base.concat([
      phase("T2", `R${reg} → RA`, `R${reg} porta ${hex(data)} sul bus; RA lo cattura.`, "RF_EN · RA_WE · NEXT_FETCH", ["registers", "ra"], ["registers-data", "ra-data"], { dataBus: data, ra: data, active: ["data-bus", "ra", `r${reg}`] }),
    ]);
  }
  if (opcode >= 0xc8 && opcode <= 0xcf) {
    const data = state.regs[reg];
    return base.concat([
      phase("T2", `R${reg} → RB`, `R${reg} porta ${hex(data)} sul bus; RB lo cattura.`, "RF_EN · RB_WE · NEXT_FETCH", ["registers", "rb"], ["registers-data", "data-rb"], { dataBus: data, rb: data, active: ["data-bus", "rb", `r${reg}`] }),
    ]);
  }
  if (opcode >= 0xd0 && opcode <= 0xd7) {
    const data = state.ra;
    return base.concat([
      phase("T2", `RA → R${reg}`, `RA porta ${hex(data)} sul bus e R${reg} lo cattura.`, "RA_OE · RF_EN · RF_WR · NEXT_FETCH", ["registers", "ra"], ["ra-data", "registers-data"], { dataBus: data, regs: { [reg]: data }, active: ["data-bus", "ra", `r${reg}`] }),
    ]);
  }

  // IN/OUT restano simulabili per compatibilita con l'ISA, ma sono test temporanei.
  if (opcode >= 0x80 && opcode <= 0x87) {
    return base.concat([
      phase("T2", `Input → R${reg}`, `La porta di test, non mostrata nello schema, presenta ${hex(state.input)} sul bus e R${reg} lo cattura.`, "IN_OE · RF_EN · RF_WR · NEXT_FETCH", ["registers"], ["registers-data"], { dataBus: state.input, regs: { [reg]: state.input }, active: ["data-bus", `r${reg}`] }),
    ]);
  }
  if (opcode >= 0x88 && opcode <= 0x8f) {
    const data = state.regs[reg];
    return base.concat([
      phase("T2", `R${reg} → Output`, `R${reg} porta ${hex(data)} sul bus; il registro output di test, non mostrato nello schema, lo cattura.`, "RF_EN · OUT_WE · NEXT_FETCH", ["registers"], ["registers-data"], { dataBus: data, active: ["data-bus", `r${reg}`] }),
    ]);
  }

  const halt = opcode === 0x01;
  const nop = opcode === 0x00;
  return base.concat([
    phase(
      "T2",
      halt ? "Arresta CPU" : nop ? "Nessuna operazione" : "Opcode non supportato",
      halt
        ? "HLT arresta il sequencer della Control Unit."
        : nop
        ? "NOP torna direttamente al fetch successivo."
        : `${hex(opcode)} non appartiene alla ISA v0.1: il simulatore arresta la CPU.`,
      halt || !nop ? "HALT" : "NEXT_FETCH",
      [],
      ["ir-cu"],
    ),
  ]);
}

export const BLOCK_INFO = {
  pc: ["PC · Program Counter", "Con ADDR_SEL=PC (01) viene collegato al bus indirizzi nel fetch; PC_INC lo incrementa e PC_LOAD lo carica dal MAR durante un salto."],
  mar: ["MAR · Memory Address Register", "MAR_L_WE e MAR_H_WE lo caricano dal data bus; ADDR_SEL=MAR (10) lo collega ad A[15:0] per dati e periferiche memory-mapped."],
  idx: ["IDX · Index Register", "Registro indice a 16 bit. IDX_L_WE e IDX_H_WE ne caricano le due meta dal data bus; ADDR_SEL=IDX (00) lo collega ad A[15:0]. Gli opcode indicizzati sono ancora da definire."],
  addrsel: ["Selettore del bus indirizzi", "ADDR_SEL_1:0 sceglie una sola sorgente: 00=IDX, 01=PC, 10=MAR, 11=nessuna. In questo modo PC, MAR e IDX non possono creare contesa su A[15:0]."],
  memory: ["Memoria unificata", "MEM_RD abilita la memoria selezionata a guidare D[7:0]; MEM_WR scrive il byte gia stabile sul bus. Lo schema corrente mostra soltanto RAM / ROM."],
  mdr: ["MDR · Memory Data Register", "MDR_WE cattura un byte dal data bus; MDR_OE lo riporta sul data bus senza coinvolgere direttamente la memoria."],
  ir: ["IR · Instruction Register", "IR_WE salva l'opcode. I suoi bit vanno direttamente al banco registri, al decoder ALU e al decoder/EEPROM di dispatch."],
  cu: ["Control Unit a microcodice", "A0–A2 ricevono µSTEP, A3–A7 µOP, A8–A11 i flag C/Z/N/O e A12 BOOT_RUN. In modalita RUN genera i segnali funzionali mostrati; NEXT_FETCH riporta il sequencer al fetch comune."],
  registers: ["Banco registri e ALU", "RF_EN abilita R0–R7; IR[2:0] seleziona il registro e RF_WR decide lettura o scrittura. RA e RB alimentano l'ALU; RA puo pilotare il bus con RA_OE."],
  ra: ["RA · Registro operando A", "RA_WE cattura D[7:0]. RA alimenta l’ingresso A della ALU, riceve il risultato e puo pilotare il data bus tramite RA_OE."],
  rb: ["RB · Registro operando B", "RB_WE cattura D[7:0] e alimenta l’ingresso B della ALU. Nella revisione corrente RB non pilota direttamente il data bus."],
  alu: ["ALU", "IR[3:0] seleziona l'operazione. ALU_OE porta il risultato sul bus; FLAGS_WE salva C, Z, N e O. CMP non scrive il risultato in RA."],
  flags: ["Registro flag", "Memorizza C, Z, N e O solo con FLAGS_WE. I quattro bit possono entrare negli indirizzi della Control ROM per i salti condizionati."],
};
