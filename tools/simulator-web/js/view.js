import { ALU_OPCODES, FIXED_OPCODES, JUMP_OPCODES, VIDEO_BASE, VIDEO_WIDTH } from "./isa.js";
import { disassemble } from "./cpu.js";
import { BLOCK_INFO } from "./microcode.js";
import { displayChar, hex, parseNumber } from "./utils.js";

const bits = (value, width) => (value >>> 0)
  .toString(2)
  .padStart(width, "0")
  .replace(/(.{4})(?=.)/g, "$1 ");

const MICROSTEP_NAMES = Array.from({ length: 8 }, (_, index) => `T${index + 1}`);

export function sourceExecutionFor(state) {
  const microActive = state.micro.plan.length > 0 &&
    state.micro.current >= 0 &&
    state.micro.instructionAddress !== null;
  const mode = microActive ? "executing" : state.halted ? "halted" : "ready";
  const address = microActive
    ? state.micro.instructionAddress
    : state.halted
    ? state.trace[0]?.address
    : state.pc;
  const instruction = address === undefined ? null : state.program.get(address);
  return instruction
    ? {
      address,
      line: instruction.line,
      source: instruction.source,
      mode,
      phase: microActive ? state.micro.plan[state.micro.current]?.t : null,
    }
    : null;
}

export function createView(root = document, diagram = null) {
  const el = (id) => root.getElementById(id);
  let sourceSynchronized = true;
  let sourceLocation = null;
  let lastSourceLine = null;
  const setStatus = (text, error = false) => {
    const target = el("status");
    target.textContent = text;
    target.style.color = error ? "var(--danger)" : "var(--accent)";
  };
  const setMessage = (text, error = false) => {
    const target = el("message");
    target.textContent = text;
    target.style.color = error ? "var(--danger)" : "var(--accent-2)";
  };

  function positionSourceHighlight(line, ensureVisible = false) {
    const source = el("source");
    const highlight = el("sourceExecutionHighlight");
    const style = root.defaultView.getComputedStyle(source);
    const lineHeight = Number.parseFloat(style.lineHeight);
    const paddingTop = Number.parseFloat(style.paddingTop);
    const paddingBottom = Number.parseFloat(style.paddingBottom);
    const lineTop = (line - 1) * lineHeight;
    const viewportHeight = source.clientHeight - paddingTop - paddingBottom;

    if (
      ensureVisible &&
      (lineTop < source.scrollTop || lineTop + lineHeight > source.scrollTop + viewportHeight)
    ) {
      source.scrollTop = Math.max(0, lineTop - viewportHeight / 2 + lineHeight / 2);
    }

    const top = paddingTop + lineTop - source.scrollTop;
    highlight.style.top = `${top}px`;
    highlight.style.height = `${lineHeight}px`;
    highlight.hidden = top + lineHeight <= 0 || top >= source.clientHeight;
  }

  function renderSourceExecution(state) {
    const status = el("sourceRunState");
    const editor = el("sourceEditor");
    const highlight = el("sourceExecutionHighlight");
    if (!sourceSynchronized) {
      sourceLocation = null;
      lastSourceLine = null;
      highlight.hidden = true;
      editor.className = "source-editor";
      status.className = "source-run-state dirty";
      status.textContent = "SORGENTE MODIFICATO · riassembla per sincronizzare l’esecuzione";
      return;
    }

    sourceLocation = sourceExecutionFor(state);
    if (!sourceLocation) {
      lastSourceLine = null;
      highlight.hidden = true;
      editor.className = "source-editor";
      status.className = "source-run-state";
      status.textContent = "Nessuna istruzione sorgente associata al PC";
      return;
    }

    const changedLine = lastSourceLine !== sourceLocation.line;
    lastSourceLine = sourceLocation.line;
    editor.className = `source-editor ${sourceLocation.mode}`;
    status.className = `source-run-state ${sourceLocation.mode}`;
    const prefix = sourceLocation.mode === "executing"
      ? `IN ESECUZIONE · ${sourceLocation.phase}`
      : sourceLocation.mode === "halted"
      ? "CPU ARRESTATA SU"
      : "PROSSIMA ISTRUZIONE";
    status.textContent = `${prefix} · ${hex(sourceLocation.address, 4)} · riga ${sourceLocation.line} · ${sourceLocation.source}`;
    positionSourceHighlight(sourceLocation.line, changedLine);
  }

  function setSourceSynchronized(value) {
    sourceSynchronized = value;
    if (!value) renderSourceExecution({});
  }

  function syncSourceScroll() {
    if (sourceLocation) positionSourceHighlight(sourceLocation.line);
  }

  function aluPreview(opcode, a, b) {
    let result = a;
    if (opcode === 0x60) result = a & b;
    else if (opcode === 0x61) result = a | b;
    else if (opcode === 0x62) result = a ^ b;
    else if (opcode === 0x63) result = ~(a | b);
    else if (opcode === 0x64) result = ~(a & b);
    else if (opcode === 0x65) result = ~(a ^ b);
    else if (opcode === 0x66) result = ~a;
    else if (opcode === 0x67) result = a + b;
    else if (opcode === FIXED_OPCODES.SUB || opcode === FIXED_OPCODES.CMP) result = a - b;
    result &= 0xff;
    const overflow = opcode === 0x67
      ? ((~(a ^ b) & (a ^ result)) & 0x80) !== 0
      : opcode === FIXED_OPCODES.SUB || opcode === FIXED_OPCODES.CMP
      ? (((a ^ b) & (a ^ result)) & 0x80) !== 0
      : false;
    return {
      result,
      flags: {
        C: Number(
          opcode === 0x67
            ? a + b > 0xff
            : (opcode === FIXED_OPCODES.SUB || opcode === FIXED_OPCODES.CMP) && a < b,
        ),
        Z: Number(result === 0),
        N: Number((result & 0x80) !== 0),
        O: Number(overflow),
      },
    };
  }

  function datapathPreview(state, phase) {
    const preview = {
      pc: state.pc,
      mar: state.mar,
      idx: state.idx,
      mdr: state.mdr,
      ir: state.ir,
      ra: state.ra,
      rb: state.rb,
      regs: Array.from(state.regs),
      alu: null,
      flags: { ...state.flags },
      addressBus: null,
      addressSource: "NONE",
      dataBus: null,
      memoryAddress: state.mar,
      memoryValue: state.mem[state.mar],
      active: new Set(),
    };
    const planned = phase?.preview;
    if (planned) {
      // Lo stato interno di un microciclo include gli effetti dei microcicli
      // precedenti, anche se la CPU architetturale viene aggiornata solo alla
      // fine dell'istruzione.
      state.micro.plan
        .slice(0, state.micro.current + 1)
        .forEach((item) => {
          const itemPreview = item.preview || {};
          for (const key of ["pc", "mar", "idx", "mdr", "ir", "ra", "rb"]) {
            if (itemPreview[key] !== undefined) preview[key] = itemPreview[key];
          }
          if (itemPreview.flags) preview.flags = { ...itemPreview.flags };
          if (itemPreview.regs) {
            Object.entries(itemPreview.regs).forEach(([index, value]) => {
              preview.regs[Number(index)] = value;
            });
          }
        });
      for (const key of [
        "alu",
        "addressBus",
        "addressSource",
        "dataBus",
        "memoryAddress",
        "memoryValue",
      ]) {
        if (planned[key] !== undefined) preview[key] = planned[key];
      }
      preview.active = new Set(planned.active || []);
      return preview;
    }
    const t = state.micro.current;
    if (t < 0) return preview;
    const address = state.micro.instructionAddress ?? state.pc;
    const opcode = state.mem[address];
    const reg = opcode & 7;
    const low = state.mem[(address + 1) & 0xffff];
    const high = state.mem[(address + 2) & 0xffff];
    const showMemoryRead = (memoryAddress, value) => {
      preview.mar = memoryAddress;
      preview.mdr = value;
      preview.addressBus = memoryAddress;
      preview.dataBus = value;
      preview.memoryAddress = memoryAddress;
      preview.memoryValue = value;
      ["mar", "mdr", "address-bus", "data-bus", "memory"].forEach((key) =>
        preview.active.add(key)
      );
    };

    if (t >= 6) {
      if (opcode >= 0x20 && opcode <= 0x27) {
        preview.dataBus = low;
        preview.active.add("data-bus");
        preview.active.add(`r${reg}`);
      } else if (opcode >= 0x40 && opcode <= 0x4f) {
        const target = low | (high << 8);
        preview.addressBus = target;
        preview.dataBus = state.mdr;
        preview.memoryAddress = target;
        preview.memoryValue = state.mem[target];
        ["mar", "mdr", "address-bus", "data-bus", "memory", `r${reg}`]
          .forEach((key) => preview.active.add(key));
      } else if (ALU_OPCODES.has(opcode)) {
        const alu = aluPreview(opcode, state.ra, state.rb);
        preview.alu = opcode === FIXED_OPCODES.CMP ? alu.result : state.ra;
        ["ra", "rb", "alu", "flags"].forEach((key) => preview.active.add(key));
      } else if (JUMP_OPCODES.has(opcode)) {
        preview.addressBus = low | (high << 8);
        preview.active.add("pc");
        preview.active.add("address-bus");
      } else if (opcode >= 0xc0 && opcode <= 0xd7) {
        preview.dataBus = opcode <= 0xc7
          ? state.ra
          : opcode <= 0xcf
          ? state.rb
          : state.regs[reg];
        preview.active.add("data-bus");
        preview.active.add(
          opcode <= 0xc7 ? "ra" : opcode <= 0xcf ? "rb" : `r${reg}`,
        );
      } else if (opcode >= 0x80 && opcode <= 0x8f) {
        preview.dataBus = opcode <= 0x87 ? state.regs[reg] : state.output;
        preview.active.add("data-bus");
        preview.active.add(`r${reg}`);
      }
      return preview;
    }
    if (t === 0) {
      preview.mar = address;
      preview.addressBus = address;
      ["pc", "mar", "address-bus"].forEach((key) => preview.active.add(key));
    } else if (t === 1) {
      showMemoryRead(address, opcode);
    } else if (t === 2) {
      preview.pc = (address + 1) & 0xffff;
      preview.mdr = opcode;
      preview.ir = opcode;
      preview.dataBus = opcode;
      ["pc", "mdr", "ir", "data-bus"].forEach((key) => preview.active.add(key));
    } else if (t === 3) {
      preview.pc = (address + 1) & 0xffff;
      preview.ir = opcode;
      ["pc", "ir"].forEach((key) => preview.active.add(key));
    } else if (opcode >= 0x20 && opcode <= 0x27) {
      showMemoryRead((address + 1) & 0xffff, low);
      preview.pc = (address + 2) & 0xffff;
      preview.active.add("pc");
      if (t === 5) {
        preview.regs[reg] = low;
        preview.active.add(`r${reg}`);
      }
    } else if (
      (opcode >= 0x40 && opcode <= 0x4f) || JUMP_OPCODES.has(opcode)
    ) {
      const operandAddress = (address + (t === 4 ? 1 : 2)) & 0xffff;
      showMemoryRead(operandAddress, t === 4 ? low : high);
      preview.pc = (address + (t === 4 ? 2 : 3)) & 0xffff;
      preview.active.add("pc");
    } else if (ALU_OPCODES.has(opcode)) {
      const alu = aluPreview(opcode, state.ra, state.rb);
      preview.alu = alu.result;
      preview.flags = alu.flags;
      ["ra", "rb", "alu", "flags"].forEach((key) => preview.active.add(key));
    } else if (opcode >= 0xc0 && opcode <= 0xd7) {
      const value = opcode <= 0xc7
        ? state.regs[reg]
        : opcode <= 0xcf
        ? state.regs[reg]
        : state.ra;
      preview.dataBus = value;
      preview.active.add("data-bus");
      if (t === 5) {
        if (opcode <= 0xc7) {
          preview.ra = value;
          preview.active.add("ra");
        } else if (opcode <= 0xcf) {
          preview.rb = value;
          preview.active.add("rb");
        } else {
          preview.regs[reg] = value;
          preview.active.add(`r${reg}`);
        }
      }
    } else if (opcode >= 0x80 && opcode <= 0x8f) {
      const value = opcode <= 0x87 ? state.input : state.regs[reg];
      preview.dataBus = value;
      preview.active.add("data-bus");
      if (t === 5 && opcode <= 0x87) {
        preview.regs[reg] = value;
        preview.active.add(`r${reg}`);
      }
    }
    return preview;
  }

  function renderDatapathValues(state, phase) {
    const preview = datapathPreview(state, phase);
    diagram?.update({
      phase,
      selectedBlock: state.micro.selectedBlock,
      input: state.input,
      output: state.output,
      preview: {
        ...preview,
        pcText: hex(preview.pc, 4),
        marText: hex(preview.mar, 4),
        idxText: hex(preview.idx, 4),
        mdrText: hex(preview.mdr),
        irText: hex(preview.ir),
        raText: hex(preview.ra),
        rbText: hex(preview.rb),
        aluText: preview.alu === null ? "—" : hex(preview.alu),
        flagsText:
          `C${preview.flags.C} Z${preview.flags.Z} N${preview.flags.N} O${preview.flags.O}`,
        addressBusText: preview.addressBus === null
          ? "—"
          : `${hex(preview.addressBus, 4)} · ${bits(preview.addressBus, 16)}`,
        addressSourceText: `${preview.addressSource} · ${
          { IDX: "00", PC: "01", MAR: "10", NONE: "11" }[preview.addressSource]
        }`,
        dataBusText: preview.dataBus === null
          ? "—"
          : `${hex(preview.dataBus)} · ${bits(preview.dataBus, 8)}`,
        memoryText: `MEM[${hex(preview.memoryAddress, 4)}] = ${
          hex(preview.memoryValue)
        }`,
      },
    });
  }

  function renderRegisters(state) {
    const items = Array.from(
      { length: 8 },
      (_, index) =>
        `<div class="reg"><span>R${index}</span><b>${
          hex(
            state.regs[index],
          )
        }</b></div>`,
    );
    items.push(
      `<div class="reg"><span>PC</span><b>${hex(state.pc, 4)}</b></div>`,
      `<div class="reg"><span>IDX</span><b>${hex(state.idx, 4)}</b></div>`,
      `<div class="reg"><span>RA</span><b>${hex(state.ra)}</b></div>`,
      `<div class="reg"><span>RB</span><b>${hex(state.rb)}</b></div>`,
    );
    el("registers").innerHTML = items.join("");
    el("flags").innerHTML = Object.entries(state.flags)
      .map(
        ([name, value]) =>
          `<div class="flag ${
            value ? "on" : ""
          }"><span>${name}</span><b>${value}</b></div>`,
      )
      .join("");
  }

  function renderMemory(state) {
    let base = state.pc & 0xfff0;
    try {
      base = parseNumber(el("memoryAddress").value, {}, 0) & 0xfff0;
    } catch {
      /* keep PC page */
    }
    const cells = ['<div class="mem-head"></div>'];
    for (let col = 0; col < 16; col++) {
      cells.push(
        `<div class="mem-head">${col.toString(16).toUpperCase()}</div>`,
      );
    }
    for (let row = 0; row < 16; row++) {
      const rowAddress = (base + row * 16) & 0xffff;
      cells.push(`<div class="mem-label">${hex(rowAddress, 4)}</div>`);
      for (let col = 0; col < 16; col++) {
        const address = (rowAddress + col) & 0xffff;
        const classes = [
          address === state.pc && "at-pc",
          address === state.mar && "at-mar",
          address === state.idx && "at-idx",
          address === state.lastWrite && "changed",
        ]
          .filter(Boolean)
          .join(" ");
        cells.push(
          `<div class="${classes}" title="${hex(address, 4)} · ${
            state.mem[address]
          } dec">${
            state.mem[address]
              .toString(16)
              .toUpperCase()
              .padStart(2, "0")
          }</div>`,
        );
      }
    }
    el("memory").innerHTML = cells.join("");
  }

  function renderScreen(state) {
    const cells = [];
    for (let y = 0; y < 20; y++) {
      for (let x = 0; x < 40; x++) {
        const address = VIDEO_BASE + y * VIDEO_WIDTH + x;
        cells.push(
          `<span class="cell${
            state.lastWrite === address ? " changed" : ""
          }" title="X ${x}, Y ${y}, ${hex(address, 4)}">${
            displayChar(
              state.mem[address],
            )
          }</span>`,
        );
      }
    }
    el("screen").innerHTML = cells.join("");
  }

  function renderMicro(state) {
    const phase = state.micro.plan[state.micro.current];
    const addressSource = phase?.preview?.addressSource || "NONE";
    // Il decode è combinatorio: IR seleziona la microistruzione dopo T1,
    // mentre FETCH ed EXECUTE sono le fasi osservabili ai fronti di clock.
    const executionStage = !phase || phase.t === "T1" ? "FETCH" : "EXECUTE";
    const executionPhase = el("executionPhase");
    executionPhase.dataset.stage = executionStage.toLowerCase();
    executionPhase.innerHTML = `FASE <b>${executionStage}</b>`;
    el("addressSource").textContent = `${addressSource} (${
      { IDX: "00", PC: "01", MAR: "10", NONE: "11" }[addressSource]
    })`;
    el("timing").innerHTML = MICROSTEP_NAMES.map((name, index) => {
      const item = state.micro.plan[index];
      const label = item?.title ||
        (!state.micro.plan.length && index === 0 ? "Pronto al fetch" : "—");
      return `<div class="micro-phase ${
        index === state.micro.current ? "active" : ""
      }${item ? "" : " unused"}"><b>${name}</b><span>${label}</span></div>`;
    }).join("");
    renderDatapathValues(state, phase);
    const selected = state.micro.selectedBlock
      ? BLOCK_INFO[state.micro.selectedBlock]
      : null;
    const detail = selected
      ? `<h3>${selected[0]}</h3><p>${selected[1]}</p>${
        phase
          ? `<code class="signals">Fase attiva: ${phase.t} · ${phase.title}</code>`
          : ""
      }<p class="detail-note">Clicca un altro blocco o azzera T per tornare alla spiegazione del microciclo.</p>`
      : phase
      ? `<h3>${phase.t} · ${phase.title}</h3><p>${phase.description}</p><code class="signals">${phase.signals}</code><p class="detail-note">Clicca un blocco nello schema per leggerne il ruolo permanente.</p>`
      : '<h3>Pronto al microciclo</h3><p>Premi “Step microciclo”: T1 mostrerà il fetch dell’opcode puntato dal PC.</p><p class="detail-note">Il diagramma mostra i percorsi funzionali, non tutti i buffer TTL singoli.</p>';
    el("microDetail").innerHTML = detail;
  }

  function render(state) {
    renderSourceExecution(state);
    renderRegisters(state);
    el("cycles").textContent = state.cycles;
    el("mar").textContent = hex(state.mar, 4);
    el("idx").textContent = hex(state.idx, 4);
    el("mdr").textContent = hex(state.mdr);
    el("ir").textContent = hex(state.ir);
    el("output").textContent = hex(state.output);
    el("outputChar").textContent = displayChar(state.output);
    const next = state.program.get(state.pc);
    el("instruction").textContent = state.halted
      ? "HLT — CPU arrestata"
      : next
      ? `${hex(state.pc, 4)}  ${next.source}`
      : `${hex(state.pc, 4)}  ${
        disassemble(
          state,
          state.mem[state.pc],
          state.pc,
        )
      }`;
    renderMemory(state);
    renderScreen(state);
    renderMicro(state);
    el("trace").innerHTML = state.trace
      .map(
        (item) =>
          `<li><span class="pc-trace">${
            hex(
              item.address,
              4,
            )
          }</span> ${item.text}</li>`,
      )
      .join("") || "<li>Nessuna istruzione eseguita.</li>";
  }
  el("source").addEventListener("scroll", syncSourceScroll);
  return {
    el,
    render,
    renderMemory,
    renderMicro,
    setMessage,
    setSourceSynchronized,
    setStatus,
  };
}
