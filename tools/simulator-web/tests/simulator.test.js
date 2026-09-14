import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

import { assemble } from "../js/assembler.js";
import { createCpuState, resetCpu, stepCpu } from "../js/cpu.js";
import { FIXED_OPCODES, VIDEO_BASE } from "../js/isa.js";
import { planMicrocycles } from "../js/microcode.js";
import { DEFAULT_PROGRAM } from "../js/programs.js";
import { sourceExecutionFor } from "../js/view.js";

const loadBytes = (bytes) => {
  const state = createCpuState();
  state.mem.set(bytes);
  return state;
};

const executeAlu = (opcode, a, b) => {
  const state = loadBytes([opcode]);
  state.ra = a;
  state.rb = b;
  stepCpu(state, 0);
  return state;
};

test("l'assembler codifica registri, immediati e indirizzi little-endian", () => {
  const result = assemble(`
    LDI R7, 0xA5
    LDA R2, 0x1234
    STA R3, 0xBEEF
    MOV RA, R4
    MOV RB, R5
    MOV R6, RA
    JNO 0xCAFE
    HLT
  `);
  assert.deepEqual(
    Array.from(result.mem.slice(0, 16)),
    [0x27, 0xa5, 0x42, 0x34, 0x12, 0x4b, 0xef, 0xbe, 0xc4, 0xcd, 0xd6, 0xa8, 0xfe, 0xca, 0x01, 0x00],
  );
});

test("il programma demo completa la scrittura della VRAM", () => {
  const assembled = assemble(DEFAULT_PROGRAM);
  const state = createCpuState();
  state.mem = assembled.mem;
  state.program = assembled.program;
  for (let guard = 0; guard < 100 && !state.halted; guard++) stepCpu(state, 0);
  assert.equal(state.halted, true);
  assert.equal(state.cycles, 19);
  assert.equal(
    String.fromCharCode(...state.mem.slice(VIDEO_BASE, VIDEO_BASE + 9)),
    "CPU 8-BIT",
  );
});

test("MAR e MDR cambiano solo quando il microcodice prevede una scrittura", () => {
  const nop = loadBytes([FIXED_OPCODES.NOP]);
  nop.mar = 0xabcd;
  nop.mdr = 0x5a;
  stepCpu(nop, 0);
  assert.equal(nop.mar, 0xabcd);
  assert.equal(nop.mdr, 0x5a);

  const ldi = loadBytes([0x20, 0x7e]);
  ldi.mar = 0xabcd;
  ldi.mdr = 0x5a;
  stepCpu(ldi, 0);
  assert.equal(ldi.mar, 0xabcd);
  assert.equal(ldi.mdr, 0x7e);

  const jump = loadBytes([FIXED_OPCODES.JMP, 0x34, 0x12]);
  jump.mdr = 0x5a;
  stepCpu(jump, 0);
  assert.equal(jump.mar, 0x1234);
  assert.equal(jump.mdr, 0x5a);

  const input = loadBytes([0x80]);
  input.mar = 0xabcd;
  input.mdr = 0x5a;
  stepCpu(input, 0x42);
  assert.equal(input.regs[0], 0x42);
  assert.equal(input.mar, 0xabcd);
  assert.equal(input.mdr, 0x5a);

  const output = loadBytes([0x88]);
  output.mar = 0xabcd;
  output.mdr = 0x5a;
  output.regs[0] = 0x41;
  stepCpu(output, 0);
  assert.equal(output.output, 0x41);
  assert.equal(output.mar, 0xabcd);
  assert.equal(output.mdr, 0x5a);
});

test("IDX fa parte dello stato a 16 bit e resta inattivo finche l'ISA non lo usa", () => {
  const state = loadBytes([FIXED_OPCODES.NOP]);
  assert.equal(state.idx, 0);
  state.idx = 0xcafe;
  stepCpu(state, 0);
  assert.equal(state.idx, 0xcafe);
  resetCpu(state, true);
  assert.equal(state.idx, 0);
});

test("ADD e SUB impostano carry/borrow, zero, negativo e overflow", () => {
  const signedAdd = executeAlu(FIXED_OPCODES.ADD, 0x7f, 0x01);
  assert.equal(signedAdd.ra, 0x80);
  assert.deepEqual(signedAdd.flags, { C: 0, Z: 0, N: 1, O: 1 });

  const wrappedAdd = executeAlu(FIXED_OPCODES.ADD, 0xff, 0x01);
  assert.equal(wrappedAdd.ra, 0x00);
  assert.deepEqual(wrappedAdd.flags, { C: 1, Z: 1, N: 0, O: 0 });

  const borrowedSub = executeAlu(FIXED_OPCODES.SUB, 0x00, 0x01);
  assert.equal(borrowedSub.ra, 0xff);
  assert.deepEqual(borrowedSub.flags, { C: 1, Z: 0, N: 1, O: 0 });

  const signedSub = executeAlu(FIXED_OPCODES.SUB, 0x80, 0x01);
  assert.equal(signedSub.ra, 0x7f);
  assert.deepEqual(signedSub.flags, { C: 0, Z: 0, N: 0, O: 1 });
});

test("CMP aggiorna solo i flag e non modifica RA o RB", () => {
  const state = executeAlu(FIXED_OPCODES.CMP, 0x10, 0x20);
  assert.equal(state.ra, 0x10);
  assert.equal(state.rb, 0x20);
  assert.deepEqual(state.flags, { C: 1, Z: 0, N: 1, O: 0 });
});

test("i salti condizionati distinguono condizione vera e falsa", () => {
  const taken = loadBytes([FIXED_OPCODES.JZ, 0x34, 0x12]);
  taken.flags.Z = 1;
  stepCpu(taken, 0);
  assert.equal(taken.pc, 0x1234);

  const skipped = loadBytes([FIXED_OPCODES.JZ, 0x34, 0x12]);
  skipped.flags.Z = 0;
  stepCpu(skipped, 0);
  assert.equal(skipped.pc, 0x0003);
});

test("le sequenze visuali numerano i microstep da T1 a T8", () => {
  const namesFor = (bytes) => planMicrocycles(loadBytes(bytes)).map(({ t }) => t);
  assert.deepEqual(namesFor([0x20, 0x42]), ["T1", "T2", "T3"]);
  assert.deepEqual(namesFor([0x40, 0x34, 0x12]), ["T1", "T2", "T3", "T4", "T5"]);
  assert.deepEqual(namesFor([0x48, 0x34, 0x12]), ["T1", "T2", "T3", "T4", "T5"]);
  assert.deepEqual(namesFor([0xa0, 0x34, 0x12]), ["T1", "T2", "T3", "T4"]);
  assert.deepEqual(namesFor([0xc0]), ["T1", "T2"]);
  for (const opcode of [0x00, 0x01, 0x20, 0x40, 0x48, 0x60, 0x80, 0xa0, 0xc0]) {
    const names = namesFor([opcode, 0x34, 0x12]);
    names.forEach((name, index) => assert.equal(name, `T${index + 1}`));
    assert.ok(names.length <= 8);
  }
});

test("l'evidenziazione sorgente segue PC e istruzione nei microstep", () => {
  const assembled = assemble(`
    ; commento iniziale
start:
    LDI R0, 0x2A
    STA R0, 0x4000
    HLT
  `);
  const state = createCpuState();
  state.mem = assembled.mem;
  state.program = assembled.program;

  assert.deepEqual(sourceExecutionFor(state), {
    address: 0,
    line: 4,
    source: "LDI R0, 0x2A",
    mode: "ready",
    phase: null,
  });

  state.micro.instructionAddress = 0;
  state.micro.plan = planMicrocycles(state);
  state.micro.current = 1;
  stepCpu(state, 0);
  assert.deepEqual(sourceExecutionFor(state), {
    address: 0,
    line: 4,
    source: "LDI R0, 0x2A",
    mode: "executing",
    phase: "T2",
  });

  state.micro.plan = [];
  state.micro.current = -1;
  state.micro.instructionAddress = null;
  assert.equal(sourceExecutionFor(state).line, 5);
});

test("CMP non abilita il data bus e gli opcode invalidi sono arrestati", () => {
  const cmp = loadBytes([FIXED_OPCODES.CMP]);
  const cmpExecute = planMicrocycles(cmp).at(-1);
  assert.equal(cmpExecute.signals, "FLAGS_WE · NEXT_FETCH");
  assert.equal(cmpExecute.preview.dataBus, null);
  assert.equal(cmpExecute.paths.includes("alu-ra"), false);

  const invalid = loadBytes([0x02]);
  const invalidExecute = planMicrocycles(invalid).at(-1);
  assert.equal(invalidExecute.t, "T2");
  assert.equal(invalidExecute.signals, "HALT");
});

test("nessun microciclo crea contese sui bus", () => {
  const opcodes = [
    0x00, 0x01,
    ...Array.from({ length: 8 }, (_, i) => 0x20 + i),
    ...Array.from({ length: 16 }, (_, i) => 0x40 + i),
    ...Array.from({ length: 10 }, (_, i) => 0x60 + i),
    ...Array.from({ length: 16 }, (_, i) => 0x80 + i),
    ...Array.from({ length: 9 }, (_, i) => 0xa0 + i),
    ...Array.from({ length: 24 }, (_, i) => 0xc0 + i),
  ];
  for (const opcode of opcodes) {
    const state = loadBytes([opcode, 0x34, 0x12]);
    state.flags = { C: 1, Z: 1, N: 1, O: 1 };
    for (const item of planMicrocycles(state)) {
      const signals = new Set(item.signals.split(" · "));
      const dataSources = [
        signals.has("MEM_RD") && "MEM_RD",
        signals.has("MDR_OE") && "MDR_OE",
        signals.has("RF_EN") && !signals.has("RF_WR") && "RF_EN(read)",
        signals.has("RA_OE") && "RA_OE",
        signals.has("ALU_OE") && "ALU_OE",
        signals.has("IN_OE") && "IN_OE",
      ].filter(Boolean);
      const addressSources = [...signals].filter((name) => name.startsWith("ADDR_SEL="));
      assert.ok(dataSources.length <= 1, `${opcode.toString(16)} ${item.t}: ${dataSources}`);
      assert.ok(addressSources.length <= 1, `${opcode.toString(16)} ${item.t}: ${addressSources}`);
      addressSources.forEach((source) => {
        assert.match(source, /^ADDR_SEL=(?:IDX\(00\)|PC\(01\)|MAR\(10\)|NONE\(11\))$/);
      });
      assert.equal(signals.has("PC_A_OE"), false);
      assert.equal(signals.has("MAR_A_OE"), false);
    }
  }
});

test("le letture selezionano PC o MAR con il nuovo selettore indirizzi", () => {
  const lda = planMicrocycles(loadBytes([0x40, 0x34, 0x12]));
  assert.deepEqual(
    lda.map(({ preview }) => preview.addressSource || "NONE"),
    ["PC", "PC", "PC", "MAR", "NONE"],
  );
  assert.equal(lda[0].signals.includes("ADDR_SEL=PC(01)"), true);
  assert.equal(lda[3].signals.includes("ADDR_SEL=MAR(10)"), true);
});

test("ogni percorso microcodice esiste nella mappa del datapath", async () => {
  const diagramSource = await readFile(new URL("../js/diagram.js", import.meta.url), "utf8");
  const diagramPaths = new Set(
    [...diagramSource.matchAll(/pathKey:\s*"([^"]+)"/g)].map((match) => match[1]),
  );
  const opcodes = [0x00, 0x01, 0x20, 0x40, 0x48, 0x60, 0x69, 0x80, 0x88, 0xa0, 0xa1, 0xc0, 0xc8, 0xd0, 0x02];
  for (const opcode of opcodes) {
    const state = loadBytes([opcode, 0x34, 0x12]);
    for (const item of planMicrocycles(state)) {
      for (const path of item.paths) {
        assert.ok(diagramPaths.has(path), `percorso mancante: ${path}`);
      }
    }
  }
});

test("la memoria ha un solo ramo fisico verso il data bus", async () => {
  const diagramSource = await readFile(new URL("../js/diagram.js", import.meta.url), "utf8");
  assert.equal((diagramSource.match(/pathKey:\s*"memory-data"/g) || []).length, 1);
  for (const obsoletePath of [
    "memory-mdr",
    "memory-ir",
    "memory-mar",
    "mdr-memory",
  ]) {
    assert.equal(
      diagramSource.includes(`pathKey: "${obsoletePath}"`),
      false,
      `collegamento diretto non ammesso: ${obsoletePath}`,
    );
  }
});

test("il datapath contiene IDX e un solo selettore per PC, MAR e IDX", async () => {
  const diagramSource = await readFile(new URL("../js/diagram.js", import.meta.url), "utf8");
  for (const nodeId of ["idx", "addrsel"]) {
    assert.equal(diagramSource.includes(`id: "${nodeId}"`), true);
  }
  for (const path of [
    "pc-selector",
    "mar-selector",
    "idx-selector",
    "selector-address",
    "data-idx",
  ]) {
    assert.equal(diagramSource.includes(`pathKey: "${path}"`), true);
  }
  for (const obsoletePath of ["pc-address", "mar-address"]) {
    assert.equal(diagramSource.includes(`pathKey: "${obsoletePath}"`), false);
  }
});

test("I/O e FPGA non compaiono nel datapath corrente", async () => {
  const diagramSource = await readFile(new URL("../js/diagram.js", import.meta.url), "utf8");
  for (const removedId of ["io", "vram"]) {
    assert.equal(diagramSource.includes(`id: "${removedId}"`), false);
  }
  assert.equal(diagramSource.includes('pathKey: "io-data"'), false);
  assert.equal(diagramSource.includes('pathKey: "memory-vram"'), false);
});
