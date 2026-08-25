const COLORS = {
  background: "#071217",
  panel: "#0d2831",
  panelStrong: "#123640",
  border: "#557781",
  muted: "#91abb1",
  text: "#eaf5f5",
  accent: "#55dcc5",
  value: "#f3c875",
  address: "#86aeb8",
  data: "#58b9da",
  control: "#c79d62",
};

const FONT = "'IBM Plex Mono', 'SFMono-Regular', Consolas, monospace";
const ACTIVE_SHADOW = "drop-shadow(0 0 5px rgba(85, 220, 197, 0.72))";

function registerShapes(Graph) {
  if (globalThis.X6.__cpuSimulatorShapes) return;
  globalThis.X6.__cpuSimulatorShapes = true;

  const text = {
    fill: COLORS.text,
    fontFamily: FONT,
    textAnchor: "middle",
    textVerticalAnchor: "middle",
    pointerEvents: "none",
  };

  Graph.registerNode(
    "cpu-frame",
    {
      inherit: "rect",
      markup: [
        { tagName: "rect", selector: "body" },
        { tagName: "text", selector: "title" },
        { tagName: "text", selector: "subtitle" },
      ],
      attrs: {
        body: {
          refWidth: "100%",
          refHeight: "100%",
          rx: 20,
          ry: 20,
          fill: "rgba(13, 40, 49, 0.42)",
          stroke: "#41636c",
          strokeWidth: 2,
          strokeDasharray: "8 7",
        },
        title: {
          ...text,
          refX: 28,
          refY: 27,
          textAnchor: "start",
          fill: COLORS.accent,
          fontSize: 17,
          fontWeight: 700,
          letterSpacing: 1,
        },
        subtitle: {
          ...text,
          refX: 28,
          refY: 51,
          textAnchor: "start",
          fill: COLORS.muted,
          fontSize: 11,
        },
      },
    },
    true,
  );

  Graph.registerNode(
    "cpu-unit",
    {
      inherit: "rect",
      markup: [
        { tagName: "rect", selector: "body" },
        { tagName: "path", selector: "divider" },
        { tagName: "path", selector: "icon" },
        { tagName: "text", selector: "title" },
        { tagName: "text", selector: "subtitle" },
        { tagName: "text", selector: "value" },
      ],
      attrs: {
        body: {
          refWidth: "100%",
          refHeight: "100%",
          rx: 12,
          ry: 12,
          fill: COLORS.panel,
          stroke: COLORS.border,
          strokeWidth: 2,
        },
        divider: { fill: "none", stroke: "#375660", strokeWidth: 1 },
        icon: { fill: "none", stroke: "#6f949c", strokeWidth: 1.4 },
        title: {
          ...text,
          refX: "50%",
          refY: 22,
          fontSize: 15,
          fontWeight: 700,
        },
        subtitle: {
          ...text,
          refX: "50%",
          refY: 43,
          fill: COLORS.muted,
          fontSize: 11,
        },
        value: {
          ...text,
          refX: "50%",
          refY: 62,
          fill: COLORS.value,
          fontSize: 13,
          fontWeight: 700,
        },
      },
    },
    true,
  );

  Graph.registerNode(
    "cpu-register-bank",
    {
      inherit: "rect",
      markup: [
        { tagName: "rect", selector: "body" },
        { tagName: "path", selector: "divider" },
        { tagName: "text", selector: "title" },
        ...Array.from({ length: 8 }, (_, index) => ({
          tagName: "text",
          selector: `r${index}`,
        })),
        { tagName: "text", selector: "subtitle" },
      ],
      attrs: {
        body: {
          refWidth: "100%",
          refHeight: "100%",
          rx: 13,
          ry: 13,
          fill: "#102931",
          stroke: COLORS.border,
          strokeWidth: 2,
        },
        divider: { d: "M0 42 H260", stroke: "#3b5b64", strokeWidth: 1 },
        title: {
          ...text,
          refX: "50%",
          refY: 23,
          fontSize: 15,
          fontWeight: 700,
        },
        ...Object.fromEntries(
          Array.from({ length: 8 }, (_, index) => [
            `r${index}`,
            {
              ...text,
              refX: ["16%", "39%", "62%", "84%"][index % 4],
              refY: 72 + Math.floor(index / 4) * 42,
              fill: COLORS.value,
              fontSize: 13,
              fontWeight: 700,
              text: `R${index} 00`,
            },
          ]),
        ),
        subtitle: {
          ...text,
          refX: "50%",
          refY: 157,
          fill: COLORS.muted,
          fontSize: 10,
          text: "selettore 3 bit · bus dati 8 bit",
        },
      },
    },
    true,
  );

  Graph.registerNode(
    "cpu-alu",
    {
      inherit: "rect",
      markup: [
        { tagName: "path", selector: "body" },
        { tagName: "text", selector: "title" },
        { tagName: "text", selector: "subtitle" },
        { tagName: "text", selector: "value" },
      ],
      attrs: {
        body: {
          d: "M0 0 H105 L160 75 L105 150 H0 L38 75 Z",
          fill: "#164550",
          stroke: "#79cbc0",
          strokeWidth: 3,
          strokeLinejoin: "round",
        },
        title: {
          ...text,
          refX: "54%",
          refY: 48,
          fontSize: 22,
          fontWeight: 800,
          text: "ALU",
        },
        subtitle: {
          ...text,
          refX: "54%",
          refY: 125,
          fill: COLORS.muted,
          fontSize: 9,
          text: "LOGIC · ADD · SUB · CMP",
        },
        value: {
          ...text,
          refX: "54%",
          refY: 100,
          fill: COLORS.value,
          fontSize: 14,
          fontWeight: 700,
          text: "—",
        },
      },
    },
    true,
  );

  Graph.registerNode(
    "cpu-bus-label",
    {
      inherit: "rect",
      markup: [
        { tagName: "rect", selector: "body" },
        { tagName: "text", selector: "title" },
        { tagName: "text", selector: "value" },
      ],
      attrs: {
        body: {
          refWidth: "100%",
          refHeight: "100%",
          fill: "transparent",
          stroke: "none",
        },
        title: {
          ...text,
          refX: 0,
          refY: 10,
          textAnchor: "start",
          fill: COLORS.muted,
          fontSize: 11,
          fontWeight: 700,
          letterSpacing: 0.8,
        },
        value: {
          ...text,
          refX: 0,
          refY: 29,
          textAnchor: "start",
          fill: COLORS.value,
          fontSize: 13,
          fontWeight: 700,
        },
      },
    },
    true,
  );
}

function ports() {
  const circle = {
    r: 4,
    magnet: false,
    stroke: "#82a7ae",
    strokeWidth: 1.5,
    fill: COLORS.background,
  };
  return {
    groups: {
      left: { position: "left", attrs: { circle } },
      right: { position: "right", attrs: { circle } },
      top: { position: "top", attrs: { circle } },
      bottom: { position: "bottom", attrs: { circle } },
    },
    items: [
      { id: "left", group: "left" },
      { id: "right", group: "right" },
      { id: "top", group: "top" },
      { id: "bottom", group: "bottom" },
    ],
  };
}

function absolutePorts(items) {
  return {
    groups: {
      absolute: {
        position: { name: "absolute" },
        attrs: {
          circle: {
            r: 4,
            magnet: false,
            stroke: "#82a7ae",
            strokeWidth: 1.5,
            fill: COLORS.background,
          },
        },
      },
    },
    items: items.map(({ id, x, y }) => ({
      id,
      group: "absolute",
      args: { x, y },
    })),
  };
}

export function createCpuDiagram(container, onBlockClick) {
  const { Graph } = globalThis.X6 || {};
  if (!Graph) throw new Error("AntV X6 non è stata caricata.");
  registerShapes(Graph);

  const graph = new Graph({
    container,
    width: container.clientWidth,
    height: container.clientHeight,
    background: { color: "transparent" },
    grid: {
      size: 10,
      visible: true,
      type: "dot",
      args: { color: "#17313a", thickness: 1 },
    },
    interacting: false,
    connecting: {
      router: { name: "manhattan", args: { step: 10, padding: 18 } },
      connector: { name: "rounded", args: { radius: 8 } },
    },
  });

  const nodes = new Map();
  const edges = new Map();
  const addUnit = (
    {
      id,
      x,
      y,
      width,
      height,
      blockKey,
      valueKey,
      title,
      subtitle = "",
      value = "",
      fill,
      icon = "",
      divider = "",
      nodePorts,
    },
  ) => {
    const node = graph.addNode({
      id,
      shape: "cpu-unit",
      x,
      y,
      width,
      height,
      zIndex: 3,
      ports: nodePorts || ports(),
      data: {
        blockKey,
        valueKey,
        baseFill: fill || COLORS.panel,
        baseStroke: COLORS.border,
      },
      attrs: {
        body: { fill: fill || COLORS.panel },
        title: { text: title },
        subtitle: { text: subtitle },
        value: { text: value, refY: height - 18 },
        icon: { d: icon },
        divider: { d: divider },
      },
    });
    nodes.set(id, node);
    return node;
  };

  graph.addNode({
    id: "cpu-frame",
    shape: "cpu-frame",
    x: 240,
    y: 35,
    width: 1085,
    height: 730,
    zIndex: -2,
    attrs: {
      title: { text: "CPU 8-BIT · DATAPATH" },
      subtitle: {
        text: "memoria unificata · bus indirizzi 16 bit · bus dati 8 bit",
      },
    },
  });
  graph.addNode({
    id: "external-label",
    shape: "cpu-bus-label",
    x: 25,
    y: 72,
    width: 200,
    height: 40,
    zIndex: 1,
    attrs: {
      title: { text: "MEMORIA ESTERNA" },
      value: { text: "RAM / ROM" },
    },
  });
  graph.addNode({
    id: "fetch-label",
    shape: "cpu-bus-label",
    x: 285,
    y: 105,
    width: 240,
    height: 30,
    zIndex: 1,
    attrs: {
      title: { text: "① FETCH / DECODE", fill: COLORS.accent },
      value: { text: "" },
    },
  });
  graph.addNode({
    id: "execute-label",
    shape: "cpu-bus-label",
    x: 285,
    y: 497,
    width: 280,
    height: 30,
    zIndex: 1,
    attrs: {
      title: { text: "② EXECUTE / WRITE-BACK", fill: COLORS.accent },
      value: { text: "" },
    },
  });

  addUnit({
    id: "memory",
    x: 25,
    y: 145,
    width: 185,
    height: 245,
    blockKey: "memory",
    valueKey: "memory",
    title: "MEMORIA 64 KiB",
    subtitle: "codice · dati",
    value: "MEM[0x0000] = 0x00",
    icon:
      "M24 73 H161 M24 103 H161 M24 133 H161 M24 163 H161 M61 58 V181 M98 58 V181 M135 58 V181",
    divider: "M0 48 H185",
    nodePorts: absolutePorts([
      { id: "address", x: "100%", y: 82 },
      { id: "data", x: "100%", y: 178 },
    ]),
  });
  addUnit({
    id: "pc",
    x: 300,
    y: 130,
    width: 135,
    height: 82,
    blockKey: "pc",
    valueKey: "pc",
    title: "PC",
    subtitle: "16 bit · INC / LOAD",
    value: "0x0000",
    divider: "M0 49 H135",
  });
  addUnit({
    id: "mar",
    x: 505,
    y: 130,
    width: 145,
    height: 82,
    blockKey: "mar",
    valueKey: "mar",
    title: "MAR",
    subtitle: "16 bit · LOW / HIGH",
    value: "0x0000",
    divider: "M0 49 H145",
    nodePorts: absolutePorts([
      { id: "jump", x: 0, y: "50%" },
      { id: "address", x: "35%", y: "100%" },
      { id: "data", x: "72%", y: "100%" },
    ]),
  });
  addUnit({
    id: "mdr",
    x: 720,
    y: 130,
    width: 130,
    height: 82,
    blockKey: "mdr",
    valueKey: "mdr",
    title: "MDR",
    subtitle: "8 bit · WE / OE",
    value: "0x00",
    divider: "M0 49 H130",
  });
  addUnit({
    id: "ir",
    x: 920,
    y: 130,
    width: 125,
    height: 82,
    blockKey: "ir",
    valueKey: "ir",
    title: "IR",
    subtitle: "8 bit · opcode",
    value: "0x00",
    divider: "M0 49 H125",
  });
  addUnit({
    id: "cu",
    x: 1110,
    y: 105,
    width: 175,
    height: 132,
    blockKey: "cu",
    valueKey: "cu",
    title: "CONTROL UNIT",
    subtitle: "µROM · µSTEP · C/Z/N/O",
    value: "IDLE",
    fill: "#183139",
    icon: "M26 64 H149 M26 82 H149 M26 100 H149",
    divider: "M0 48 H175",
  });
  const registerBank = graph.addNode({
    id: "registers",
    shape: "cpu-register-bank",
    x: 305,
    y: 525,
    width: 260,
    height: 185,
    zIndex: 3,
    ports: absolutePorts([
      { id: "bus", x: "50%", y: 0 },
      { id: "bottom", x: "50%", y: "100%" },
    ]),
    data: {
      blockKey: "registers",
      valueKey: "registers",
      baseFill: "#102931",
      baseStroke: COLORS.border,
    },
    attrs: { title: { text: "BANCO REGISTRI · R0–R7" } },
  });
  nodes.set("registers", registerBank);

  addUnit({
    id: "ra",
    x: 650,
    y: 525,
    width: 140,
    height: 76,
    blockKey: "ra",
    valueKey: "ra",
    title: "RA · operando A",
    subtitle: "8 bit · WE / OE",
    value: "0x00",
    fill: "#12313b",
    divider: "M0 45 H140",
  });
  addUnit({
    id: "rb",
    x: 650,
    y: 635,
    width: 140,
    height: 76,
    blockKey: "rb",
    valueKey: "rb",
    title: "RB · operando B",
    subtitle: "8 bit · WE",
    value: "0x00",
    fill: "#12313b",
    divider: "M0 45 H140",
  });
  const alu = graph.addNode({
    id: "alu",
    shape: "cpu-alu",
    x: 875,
    y: 540,
    width: 160,
    height: 150,
    zIndex: 3,
    ports: absolutePorts([
      { id: "in-a", x: 0, y: 58 },
      { id: "in-b", x: 0, y: 108 },
      { id: "out", x: "100%", y: 75 },
      { id: "result", x: 86, y: 0 },
      { id: "bottom", x: 86, y: "100%" },
    ]),
    data: {
      blockKey: "alu",
      valueKey: "alu",
      baseFill: "#164550",
      baseStroke: "#79cbc0",
    },
  });
  nodes.set("alu", alu);
  addUnit({
    id: "flags",
    x: 1110,
    y: 565,
    width: 175,
    height: 100,
    blockKey: "flags",
    valueKey: "flags",
    title: "FLAG REGISTER",
    subtitle: "latch C · Z · N · O",
    value: "C0 Z0 N0 O0",
    fill: "#182d35",
    divider: "M0 47 H175",
  });

  const addBusLabel = (id, x, y, width, title, color, nodePorts) => {
    const node = graph.addNode({
      id,
      shape: "cpu-bus-label",
      x,
      y,
      width,
      height: 46,
      zIndex: 2,
      ports: nodePorts,
      data: { valueKey: id },
      attrs: {
        body: {
          fill: "#0a1d25",
          stroke: color,
          strokeOpacity: 0.58,
          strokeWidth: 1,
          rx: 8,
          ry: 8,
        },
        title: { text: title, fill: color, refX: 12, refY: 15 },
        value: { text: "—", refX: 12, refY: 34 },
      },
    });
    nodes.set(id, node);
  };
  addBusLabel(
    "address-bus",
    260,
    275,
    820,
    "ADDRESS BUS · A[15:0]",
    COLORS.address,
    absolutePorts([
      { id: "memory", x: 0, y: 23 },
      { id: "pc", x: 108, y: 0 },
      { id: "mar", x: 296, y: 0 },
    ]),
  );
  addBusLabel(
    "data-bus",
    260,
    392,
    820,
    "DATA BUS · D[7:0]",
    COLORS.data,
    absolutePorts([
      { id: "memory", x: 0, y: 14 },
      { id: "mar", x: 349, y: 0 },
      { id: "mdr", x: 525, y: 0 },
      { id: "ir", x: 722, y: 0 },
      { id: "registers", x: 175, y: 46 },
      { id: "rb", x: 360, y: 46 },
      { id: "ra", x: 460, y: 46 },
      { id: "alu", x: 701, y: 46 },
    ]),
  );
  addBusLabel(
    "control-bus",
    260,
    449,
    820,
    "CONTROL BUS · enable / load / RD / WR",
    COLORS.control,
  );
  nodes.get("control-bus").attr("value/fontSize", 10);

  const addEdge = (
    {
      id,
      pathKey,
      source,
      target,
      color = COLORS.data,
      vertices,
      dashed = false,
      router = "orth",
      bidirectional = false,
      label,
    },
  ) => {
    const edge = graph.addEdge({
      id,
      source,
      target,
      vertices,
      zIndex: 1,
      router: {
        name: router,
        args: router === "manhattan"
          ? {
            step: 10,
            padding: 16,
            excludeShapes: ["cpu-frame", "cpu-bus-label"],
          }
          : { padding: 10 },
      },
      connector: { name: "rounded", args: { radius: 8 } },
      labels: label
        ? [{
          position: 0.5,
          attrs: {
            label: {
              text: label,
              fill: COLORS.muted,
              fontFamily: FONT,
              fontSize: 10,
            },
            body: { fill: COLORS.background, stroke: "#294751", rx: 4, ry: 4 },
          },
        }]
        : [],
      attrs: {
        line: {
          stroke: color,
          strokeWidth: 1.25,
          strokeOpacity: 0.22,
          strokeDasharray: dashed ? "7 6" : "",
          strokeLinejoin: "round",
          sourceMarker: bidirectional ? { name: "classic", size: 7 } : null,
          targetMarker: { name: "classic", size: 7 },
        },
      },
      data: { pathKey, color, dashed },
    });
    if (!edges.has(pathKey)) edges.set(pathKey, []);
    edges.get(pathKey).push(edge);
    return edge;
  };

  addEdge({
    id: "pc-address",
    pathKey: "pc-address",
    source: { cell: "pc", port: "bottom" },
    target: { cell: "address-bus", port: "pc" },
    color: COLORS.address,
    vertices: [{ x: 368, y: 248 }],
    router: "orth",
  });
  addEdge({
    id: "mar-address",
    pathKey: "mar-address",
    source: { cell: "mar", port: "address" },
    target: { cell: "address-bus", port: "mar" },
    color: COLORS.address,
    vertices: [{ x: 556, y: 248 }],
    router: "orth",
  });
  addEdge({
    id: "address-memory",
    pathKey: "address-memory",
    source: { cell: "address-bus", port: "memory" },
    target: { cell: "memory", port: "address" },
    color: COLORS.address,
    vertices: [{ x: 235, y: 296 }],
    router: "orth",
  });
  addEdge({
    id: "mar-pc",
    pathKey: "mar-pc",
    source: { cell: "mar", port: "jump" },
    target: { cell: "pc", port: "right" },
    color: COLORS.address,
    dashed: true,
  });
  addEdge({
    id: "memory-data",
    pathKey: "memory-data",
    source: { cell: "memory", port: "data" },
    target: { cell: "data-bus", port: "memory" },
    color: COLORS.data,
    vertices: [{ x: 235, y: 415 }],
    router: "orth",
    bidirectional: true,
  });
  addEdge({
    id: "data-mar",
    pathKey: "data-mar",
    source: { cell: "data-bus", port: "mar" },
    target: { cell: "mar", port: "data" },
    color: COLORS.data,
    vertices: [{ x: 609, y: 248 }],
    router: "orth",
  });
  addEdge({
    id: "data-mdr",
    pathKey: "mdr-data",
    source: { cell: "data-bus", port: "mdr" },
    target: { cell: "mdr", port: "bottom" },
    color: COLORS.data,
    vertices: [{ x: 785, y: 248 }],
    router: "orth",
    bidirectional: true,
  });
  addEdge({
    id: "data-ir",
    pathKey: "data-ir",
    source: { cell: "data-bus", port: "ir" },
    target: { cell: "ir", port: "bottom" },
    color: COLORS.data,
    vertices: [{ x: 982, y: 248 }],
    router: "orth",
  });
  addEdge({
    id: "data-registers",
    pathKey: "registers-data",
    source: { cell: "data-bus", port: "registers" },
    target: { cell: "registers", port: "bus" },
    color: COLORS.data,
    vertices: [{ x: 435, y: 505 }],
    router: "orth",
    bidirectional: true,
  });
  addEdge({
    id: "data-ra",
    pathKey: "ra-data",
    source: { cell: "data-bus", port: "ra" },
    target: { cell: "ra", port: "top" },
    color: COLORS.data,
    vertices: [{ x: 720, y: 505 }],
    router: "orth",
    bidirectional: true,
  });
  addEdge({
    id: "data-rb",
    pathKey: "data-rb",
    source: { cell: "data-bus", port: "rb" },
    target: { cell: "rb", port: "left" },
    color: COLORS.data,
    vertices: [{ x: 620, y: 505 }, { x: 620, y: 673 }],
    router: "orth",
  });
  addEdge({
    id: "ir-cu",
    pathKey: "ir-cu",
    source: { cell: "ir", port: "right" },
    target: { cell: "cu", port: "left" },
    color: COLORS.control,
    dashed: true,
  });
  addEdge({
    id: "cu-control",
    pathKey: "cu-control",
    source: { cell: "cu", port: "bottom" },
    target: { cell: "control-bus" },
    color: COLORS.control,
    dashed: true,
    vertices: [{ x: 1300, y: 280 }, { x: 1300, y: 472 }],
    router: "orth",
  });
  addEdge({
    id: "ra-alu",
    pathKey: "ra-alu",
    source: { cell: "ra", port: "right" },
    target: { cell: "alu", port: "in-a" },
    color: COLORS.data,
  });
  addEdge({
    id: "rb-alu",
    pathKey: "rb-alu",
    source: { cell: "rb", port: "right" },
    target: { cell: "alu", port: "in-b" },
    color: COLORS.data,
  });
  addEdge({
    id: "alu-data",
    pathKey: "alu-data",
    source: { cell: "alu", port: "result" },
    target: { cell: "data-bus", port: "alu" },
    color: COLORS.accent,
    vertices: [{ x: 961, y: 505 }],
    router: "orth",
  });
  addEdge({
    id: "alu-flags",
    pathKey: "alu-flags",
    source: { cell: "alu", port: "out" },
    target: { cell: "flags", port: "left" },
    color: COLORS.control,
  });
  graph.on("node:click", ({ node }) => {
    const blockKey = node.getData()?.blockKey;
    if (blockKey) onBlockClick?.(blockKey);
  });

  function fit() {
    const width = container.clientWidth;
    const height = container.clientHeight;
    if (!width || !height) return;
    graph.resize(width, height);
    graph.zoomToFit({ padding: 28, maxScale: 1 });
    graph.centerContent();
  }
  const resizeObserver = new ResizeObserver(fit);
  resizeObserver.observe(container);
  requestAnimationFrame(fit);

  function setValue(nodeId, selector, value, active = false) {
    const node = nodes.get(nodeId);
    if (!node) return;
    node.attr(`${selector}/text`, value);
    node.attr(`${selector}/fill`, active ? COLORS.accent : COLORS.value);
    node.attr(`${selector}/style/filter`, active ? ACTIVE_SHADOW : "none");
  }

  function update({ phase, selectedBlock, preview }) {
    const activeBlocks = new Set(phase?.blocks || []);
    nodes.forEach((node) => {
      const data = node.getData() || {};
      if (!data.blockKey) return;
      const active = activeBlocks.has(data.blockKey);
      const selected = selectedBlock === data.blockKey;
      node.attr(
        "body/fill",
        active ? "#144b50" : selected ? "#4a3d24" : data.baseFill,
      );
      node.attr(
        "body/stroke",
        active ? COLORS.accent : selected ? COLORS.value : data.baseStroke,
      );
      node.attr("body/strokeWidth", active || selected ? 3 : 2);
      node.attr("body/style/filter", active ? ACTIVE_SHADOW : "none");
    });
    edges.forEach((group, pathKey) => {
      const active = Boolean(phase?.paths.includes(pathKey));
      group.forEach((edge) => {
        const data = edge.getData();
        edge.attr("line/stroke", active ? COLORS.accent : data.color);
        edge.attr("line/strokeWidth", active ? 5 : 1.25);
        edge.attr("line/strokeOpacity", active ? 1 : 0.22);
        edge.attr("line/strokeDasharray", data.dashed ? "7 6" : "");
        edge.attr("line/style/filter", active ? ACTIVE_SHADOW : "none");
      });
    });

    setValue("pc", "value", preview.pcText, preview.active.has("pc"));
    setValue("mar", "value", preview.marText, preview.active.has("mar"));
    setValue("mdr", "value", preview.mdrText, preview.active.has("mdr"));
    setValue("ir", "value", preview.irText, preview.active.has("ir"));
    setValue("ra", "value", preview.raText, preview.active.has("ra"));
    setValue("rb", "value", preview.rbText, preview.active.has("rb"));
    setValue("alu", "value", preview.aluText, preview.active.has("alu"));
    setValue("flags", "value", preview.flagsText, preview.active.has("flags"));
    setValue(
      "memory",
      "value",
      preview.memoryText,
      preview.active.has("memory"),
    );
    setValue(
      "address-bus",
      "value",
      preview.addressBusText,
      preview.active.has("address-bus"),
    );
    setValue(
      "data-bus",
      "value",
      preview.dataBusText,
      preview.active.has("data-bus"),
    );
    setValue(
      "control-bus",
      "value",
      phase?.signals || "—",
      Boolean(phase),
    );
    setValue(
      "cu",
      "value",
      phase ? `${phase.t} · ${phase.title}` : "IDLE",
      activeBlocks.has("cu"),
    );
    const bank = nodes.get("registers");
    preview.regs.forEach((value, index) => {
      const active = preview.active.has(`r${index}`);
      bank.attr(
        `r${index}/text`,
        `R${index} ${value.toString(16).toUpperCase().padStart(2, "0")}`,
      );
      bank.attr(`r${index}/fill`, active ? COLORS.accent : COLORS.value);
      bank.attr(`r${index}/style/filter`, active ? ACTIVE_SHADOW : "none");
    });
  }

  return { graph, update, fit, dispose: () => resizeObserver.disconnect() };
}
