import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { assemble } from "../js/assembler.js";
import { createCpuState, stepCpu } from "../js/cpu.js";

test("Hello counter prints all 256 decimal values, wraps, waits for BUSY and preserves code", async () => {
  const source = await readFile(new URL("../../../examples/assembly/video_hello_counter.asm", import.meta.url), "utf8");
  const assembled = assemble(source);
  const codeSize = Math.max(...Array.from(assembled.program.values(), record => record.address + record.bytes.length));
  const binary = assembled.mem.slice(0, codeSize);
  assert.ok(binary.length < 0x100, "code must fit below the RAM counter and within a 256-byte BOOT");
  const state = createCpuState();
  const memory = assembled.mem;
  memory[0x100] = 0xa5; // Runtime initialization must replace arbitrary RAM contents.
  const lines = [];
  const counterWrites = [];
  let line = "";
  let busyReadsRemaining = 3;
  let busyReads = 0;
  let clears = 0;
  const registers = new Map();
  // Instruction-level MMIO model: force multiple BUSY polls after clear and
  // newline. This verifies the polling paths, not FPGA electrical timing.
  state.mem = new Proxy(memory, {
    get(target, key) {
      if (key === String(0x2018)) {
        if (busyReadsRemaining > 0) {
          busyReadsRemaining--;
          busyReads++;
          return 2;
        }
        return 1;
      }
      if (typeof key === "string" && /^\d+$/.test(key) && Number(key) >= 0x2000) {
        throw new Error(`unexpected MMIO read ${Number(key).toString(16)}`);
      }
      const value = Reflect.get(target, key, target);
      return typeof value === "function" ? value.bind(target) : value;
    },
    set(target, key, value) {
      const address = Number(key);
      if (address < 0x2000) {
        assert.equal(address, 0x100, "only the RAM variable may be written");
        counterWrites.push(value);
        target[address] = value;
        return true;
      }
      assert.equal(busyReadsRemaining, 0, "video writes during BUSY must be avoided");
      assert.ok([0x2000, 0x2020, 0x2028, 0x2040].includes(address));
      if (address === 0x2000) line += String.fromCharCode(value);
      else if (address === 0x2020 && value === 1) {
        line = "";
        lines.length = 0;
        clears++;
        busyReadsRemaining = 3;
      } else if (address === 0x2020 && value === 3) {
        lines.push(line);
        line = "";
        busyReadsRemaining = 3;
      } else registers.set(address, value);
      return true;
    },
  });
  for (let guard = 0; guard < 200000 && lines.length < 258; guard++) {
    const result = stepCpu(state, 0);
    assert.equal(result.error, null);
    assert.equal(state.halted, false);
  }
  assert.equal(lines.length, 258);
  assert.equal(lines[0], "HELLO WORLD");
  assert.deepEqual(lines.slice(1), Array.from({ length: 257 }, (_, i) => `VAR = ${String(i & 255).padStart(3, "0")}`));
  assert.deepEqual(counterWrites, Array.from({ length: 257 }, (_, i) => i & 255));
  assert.equal(memory[0x100], 0);
  assert.equal(clears, 1);
  assert.ok(busyReads >= 3 * 259);
  assert.equal(registers.get(0x2028), 0x0f);
  assert.equal(registers.get(0x2040), 0x1c);
  assert.deepEqual(memory.slice(0, binary.length), new Uint8Array(binary));
});
