import { assemble } from "./assembler.js";
import {
  clearMicroPlan,
  createCpuState,
  loadProgram,
  resetCpu,
  stepCpu,
} from "./cpu.js";
import { planMicrocycles } from "./microcode.js";
import { DEFAULT_PROGRAM } from "./programs.js";
import { parseNumber } from "./utils.js";
import { createView } from "./view.js";
import { createCpuDiagram } from "./diagram.js";

const state = createCpuState();
let view;
const diagram = createCpuDiagram(
  document.getElementById("cpuDiagram"),
  (block) => {
    state.micro.selectedBlock = state.micro.selectedBlock === block
      ? null
      : block;
    view?.renderMicro(state);
  },
);
view = createView(document, diagram);
let timer = null;

function readInput() {
  try {
    const value = parseNumber(view.el("inputValue").value, {}, 0);
    if (value > 0xff) throw new Error();
    return value;
  } catch {
    throw new Error("Input non valido: usa un byte, per esempio 0x2A.");
  }
}
function stop() {
  if (timer) {
    clearInterval(timer);
    timer = null;
  }
  view.el("run").disabled = false;
  view.el("pause").disabled = true;
}
function runInstruction() {
  try {
    const result = stepCpu(state, readInput());
    if (result.error) view.setMessage(result.error, true);
    view.render(state);
    if (result.halted) {
      stop();
      view.setStatus("CPU arrestata");
    } else view.setStatus("In esecuzione");
  } catch (error) {
    stop();
    view.setMessage(error.message, true);
  }
}
function assembleAndReset() {
  try {
    loadProgram(state, assemble(view.el("source").value));
    stop();
    view.render(state);
    view.setMessage(
      `Assemblato: ${state.program.size} istruzioni, ${
        Object.keys(state.symbols).length
      } simboli. PC pronto a 0x0000.`,
    );
    view.setStatus("Assemblato");
  } catch (error) {
    stop();
    view.setMessage(error.message, true);
    view.setStatus("Errore assembly", true);
  }
}
function run() {
  if (!state.program.size) assembleAndReset();
  if (!state.program.size || state.halted) return;
  clearMicroPlan(state);
  timer = setInterval(() => {
    for (let i = 0; i < 8 && !state.halted; i++) runInstruction();
  }, 35);
  view.el("run").disabled = true;
  view.el("pause").disabled = false;
}
function microStep() {
  stop();
  if (state.halted) {
    view.setStatus("CPU arrestata");
    return;
  }
  if (!state.micro.plan.length || state.micro.current >= 6) {
    state.micro.instructionAddress = state.pc;
    state.micro.plan = planMicrocycles(state);
    state.micro.current = -1;
  }
  state.micro.current++;
  const phase = state.micro.plan[state.micro.current];
  if (state.micro.current === 6) {
    runInstruction();
    if (!state.halted) view.setStatus("T7 completato");
  } else {
    view.render(state);
    view.setStatus(`${phase.t} · ${phase.title}`);
  }
}

view.el("assemble").addEventListener("click", assembleAndReset);
view.el("step").addEventListener("click", () => {
  stop();
  clearMicroPlan(state);
  if (!state.program.size) assembleAndReset();
  if (state.program.size) runInstruction();
});
view.el("run").addEventListener("click", run);
view.el("pause").addEventListener("click", () => {
  stop();
  view.setStatus("In pausa");
});
view.el("reset").addEventListener("click", () => {
  resetCpu(state, true);
  stop();
  view.render(state);
  view.setStatus("Reset eseguito");
});
view.el("loadDemo").addEventListener("click", () => {
  view.el("source").value = DEFAULT_PROGRAM;
  assembleAndReset();
});
view
  .el("memoryAddress")
  .addEventListener("change", () => view.renderMemory(state));
view.el("clearTrace").addEventListener("click", () => {
  state.trace = [];
  view.render(state);
});
view.el("microStep").addEventListener("click", microStep);
view.el("microReset").addEventListener("click", () => {
  clearMicroPlan(state);
  view.render(state);
  view.setStatus("Microciclo azzerato");
});
view.el("source").value = DEFAULT_PROGRAM;
assembleAndReset();
