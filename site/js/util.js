export function debounce(fn, ms) {
  let t;
  return (...args) => {
    clearTimeout(t);
    t = setTimeout(() => fn(...args), ms);
  };
}

export function esc(s) {
  return String(s ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

// inputs / propagated_inputs / licenses are stored as |-joined strings
export function splitField(s) {
  return s ? String(s).split("|") : [];
}

// licenses are |-joined markdown links: [Name](uri)
export function parseLicenses(s) {
  return splitField(s).map((l) => {
    const name = l.match(/\[(.*)\]/)?.[1] ?? l;
    const uri = l.match(/\((.*)\)/)?.[1] ?? "";
    return { name, uri };
  });
}

export function parseOrigin(s) {
  if (!s) return null;
  try { return JSON.parse(s); } catch { return null; }
}
