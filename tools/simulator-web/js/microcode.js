import { VIDEO_BASE } from "./isa.js";
import { disassemble } from "./cpu.js";
import { hex } from "./utils.js";

const phase = (t, title, description, signals, blocks, paths) => ({
  t,
  title,
  description,
  signals,
  blocks,
  paths,
});
const fetchAndDecode = (state, address, opcode, text) => [
  phase(
    "T1",
    "Fetch indirizzo",
    `PC (${hex(address, 4)}) → MAR.`,
    "PC_OUT · MAR_LOAD",
    ["pc", "mar"],
    ["pc-mar"],
  ),
  phase(
    "T2",
    "Lettura opcode",
    `MEM[MAR] restituisce ${hex(opcode)}.`,
    "/RD · MEM_OUT · MDR_LOAD",
    ["mar", "memory", "mdr"],
    ["mar-memory", "memory-mdr"],
  ),
  phase(
    "T3",
    "Carica IR",
    `IR ← ${hex(opcode)}; PC ← ${hex((address + 1) & 0xffff, 4)}.`,
    "MDR_OUT · IR_LOAD · PC_INC",
    ["mdr", "ir", "pc"],
    ["memory-mdr", "mdr-ir"],
  ),
  phase(
    "T4",
    "Decode",
    `${text}: la Control Unit genera i segnali per l’execute.`,
    "IR_OUT · CU_DECODE",
    ["ir", "cu"],
    ["ir-cu"],
  ),
];
const addressFetch = (address, low, high, target) => [
  phase(
    "T5",
    "Fetch addr_low",
    `Legge ${hex(low)} da ${hex((address + 1) & 0xffff, 4)}.`,
    "PC_OUT · MAR_LOAD · /RD · MDR_LOAD · PC_INC",
    ["pc", "mar", "memory", "mdr"],
    ["pc-mar", "mar-memory", "memory-mdr"],
  ),
  phase(
    "T6",
    "Fetch addr_high",
    `Legge ${hex(high)} e compone ${hex(target, 4)}.`,
    "PC_OUT · MAR_LOAD · /RD · MDR_LOAD · PC_INC",
    ["pc", "mar", "memory", "mdr"],
    ["pc-mar", "mar-memory", "memory-mdr"],
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
  const phases = fetchAndDecode(state, address, opcode, text);

  if (opcode >= 0x20 && opcode <= 0x27) {
    return phases.concat([
      phase(
        "T5",
        "Fetch immediato",
        `Legge ${hex(low)} da ${hex((address + 1) & 0xffff, 4)}.`,
        "PC_OUT · MAR_LOAD · /RD · MDR_LOAD · PC_INC",
        ["pc", "mar", "memory", "mdr"],
        ["pc-mar", "mar-memory", "memory-mdr"],
      ),
      phase(
        "T6",
        `Prepara R${reg}`,
        `MDR contiene il byte destinato a R${reg}.`,
        "MDR_OUT · Rn_SELECT",
        ["mdr", "registers"],
        ["cu-registers"],
      ),
      phase(
        "T7",
        "Execute",
        `R${reg} ← ${hex(low)}.`,
        "CLOCK · Rn_LOAD",
        ["cu", "registers"],
        ["cu-registers"],
      ),
    ]);
  }

  if (
    (opcode >= 0x40 && opcode <= 0x4f) ||
    (opcode >= 0xa0 && opcode <= 0xa8)
  ) {
    const store = opcode >= 0x48 && opcode <= 0x4f;
    const load = opcode >= 0x40 && opcode <= 0x47;
    const jump = opcode >= 0xa0 && opcode <= 0xa8;
    const description = store
      ? `MAR ← ${hex(target, 4)}; MEM[MAR] ← R${reg} (${
        hex(
          state.regs[reg],
        )
      }).${target >= VIDEO_BASE ? " La FPGA cattura la scrittura VRAM." : ""}`
      : load
      ? `MAR ← ${hex(target, 4)}; R${reg} ← MEM[MAR].`
      : `Se la condizione è vera, PC ← ${hex(target, 4)}.`;
    const blocks = jump
      ? ["cu", "pc", "ir"]
      : target >= VIDEO_BASE && store
      ? ["mar", "memory", "registers", "cu", "vram"]
      : ["mar", "memory", "registers", "cu"];
    const paths = jump
      ? ["ir-cu", "pc-mar"]
      : target >= VIDEO_BASE && store
      ? ["mar-memory", "cu-registers", "memory-vram"]
      : ["mar-memory", "cu-registers"];
    return phases.concat(addressFetch(address, low, high, target), [
      phase(
        "T7",
        "Execute",
        description,
        store
          ? "MAR_LOAD · Rn_OUT · MDR_LOAD · /WR"
          : load
          ? "MAR_LOAD · /RD · MDR_LOAD · Rn_LOAD"
          : "CU_COND · PC_LOAD",
        blocks,
        paths,
      ),
    ]);
  }
  if (opcode >= 0x60 && opcode <= 0x69) {
    return phases.concat([
      phase(
        "T5",
        "Seleziona ALU",
        `${text}: RA e RB alimentano la rete selezionata.`,
        "RA_OUT · RB_OUT · ALU_OP",
        ["cu", "registers", "alu"],
        ["cu-registers", "registers-alu"],
      ),
      phase(
        "T6",
        "Propagazione ALU",
        "La rete ALU produce risultato e segnali C, Z, N, O.",
        "ALU_ENABLE · FLAGS_IN",
        ["alu", "flags"],
        ["alu-flags"],
      ),
      phase(
        "T7",
        "Latch risultato",
        opcode === 0x69
          ? "CMP aggiorna solo i flag."
          : "RA riceve il risultato e il registro flag viene aggiornato.",
        opcode === 0x69 ? "FLAGS_LOAD" : "RA_LOAD · FLAGS_LOAD",
        ["alu", "registers", "flags"],
        ["registers-alu", "alu-flags"],
      ),
    ]);
  }
  if (opcode >= 0xc0 && opcode <= 0xd7) {
    return phases.concat([
      phase(
        "T5",
        "Seleziona sorgente",
        `${text}: il registro sorgente abilita il buffer dati.`,
        "REG_OUT",
        ["registers"],
        ["cu-registers"],
      ),
      phase(
        "T6",
        "Instrada sul bus",
        "La destinazione è selezionata e il dato è stabile.",
        "DATA_BUS · DEST_SELECT",
        ["registers", "cu"],
        ["cu-registers"],
      ),
      phase(
        "T7",
        "Latch trasferimento",
        "La destinazione cattura il valore sul fronte di clock.",
        "CLOCK · DEST_LOAD",
        ["registers", "cu"],
        ["cu-registers"],
      ),
    ]);
  }
  if (opcode >= 0x80 && opcode <= 0x8f) {
    const input = opcode <= 0x87;
    return phases.concat([
      phase(
        "T5",
        input ? "Seleziona input" : "Seleziona output",
        input
          ? `La periferica presenta ${hex(state.input)}.`
          : `R${reg} presenta ${hex(state.regs[reg])}.`,
        input ? "IN_ENABLE · DATA_BUS" : "REG_OUT · OUT_ENABLE",
        ["io", "registers"],
        ["io-registers"],
      ),
      phase(
        "T6",
        "Dato stabile",
        "Il byte resta stabile sul data bus.",
        "DATA_BUS_STABLE",
        ["io", "registers"],
        ["io-registers"],
      ),
      phase(
        "T7",
        "Execute I/O",
        input ? `R${reg} cattura l’input.` : "La periferica cattura il byte.",
        input ? "Rn_LOAD" : "OUT_LOAD",
        ["io", "registers"],
        ["io-registers"],
      ),
    ]);
  }
  const halt = opcode === 0x01;
  return phases.concat([
    phase(
      "T5",
      "Prepara execute",
      halt
        ? "HLT richiede l’arresto alla Control Unit."
        : "NOP non richiede trasferimenti aggiuntivi.",
      "CU_CONTROL",
      ["cu"],
      ["ir-cu"],
    ),
    phase(
      "T6",
      "Stabilizzazione",
      "Nessun nuovo trasferimento sul bus dati.",
      "—",
      ["cu"],
      [],
    ),
    phase(
      "T7",
      "Execute",
      halt
        ? "La Control Unit arresta la CPU."
        : "NOP termina senza modificare lo stato.",
      halt ? "HALT" : "—",
      ["cu"],
      [],
    ),
  ]);
}

export const BLOCK_INFO = {
  pc: [
    "PC · Program Counter",
    "Contiene l’indirizzo del prossimo byte istruzione. Durante il fetch lo presenta al MAR, poi viene incrementato.",
  ],
  mar: [
    "MAR · Memory Address Register",
    "È l’unico registro che guida fisicamente A[15:0]. Riceve PC durante il fetch e l’indirizzo dell’operando durante LDA/STA.",
  ],
  memory: [
    "Memoria unica",
    "Codice e dati condividono lo stesso spazio. In lettura restituisce un byte sul bus dati; in scrittura cattura il byte quando /WR è attivo.",
  ],
  mdr: [
    "MDR · Memory Data Register",
    "Trattiene il byte letto dalla memoria o il byte da scrivere. È il ponte fra memoria e data bus.",
  ],
  ir: [
    "IR · Instruction Register",
    "Memorizza l’opcode corrente. I suoi bit vanno alla Control Unit per il decode.",
  ],
  cu: [
    "CU · Control Unit",
    "Dal microciclo T e dall’opcode genera enable, load, /RD e /WR. Il dettaglio del microcodice è ancora una decisione di progetto.",
  ],
  registers: [
    "Registri generali e ALU",
    "R0–R7 conservano dati del programma. RA e RB alimentano l’ALU; RA riceve anche il risultato.",
  ],
  alu: [
    "ALU",
    "Esegue le operazioni logiche, ADD, SUB e CMP su RA/RB. Il risultato può tornare in RA.",
  ],
  flags: [
    "Registro flag",
    "Memorizza C, Z, N e O dopo ALU/CMP; i salti condizionati leggono questi bit.",
  ],
  vram: [
    "FPGA / VRAM",
    "La zona 0x4000–0x7FFF è memoria mappata. La FPGA cattura le scritture e legge la propria VRAM per generare il video.",
  ],
  io: [
    "Input / Output",
    "IN e OUT trasferiscono un byte fra una periferica esterna e un registro generale.",
  ],
};
