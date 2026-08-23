export const hex = (value, width = 2) =>
  `0x${(value >>> 0).toString(16).toUpperCase().padStart(width, "0")}`;
export const displayChar = (value) =>
  value >= 32 && value <= 126 ? String.fromCharCode(value) : "·";

export function parseNumber(token, symbols = {}, line = 0) {
  const raw = (token || "").trim();
  const symbol = raw.toUpperCase();
  if (Object.hasOwn(symbols, symbol)) return symbols[symbol];
  if (/^\$[0-9a-f]+$/i.test(raw)) return parseInt(raw.slice(1), 16);
  if (/^0x[0-9a-f]+$/i.test(raw)) return parseInt(raw, 16);
  if (/^0b[01]+$/i.test(raw)) return parseInt(raw.slice(2), 2);
  if (/^\d+$/.test(raw)) return Number(raw);
  throw new Error(`riga ${line}: valore o simbolo sconosciuto “${raw}”`);
}

export function parseRegister(token, line) {
  const match = /^R([0-7])$/i.exec((token || "").trim());
  if (!match) {
    throw new Error(`riga ${line}: registro non valido “${token || ""}”`);
  }
  return Number(match[1]);
}
