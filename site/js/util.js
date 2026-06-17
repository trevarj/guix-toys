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

// Index date from the dated DB filename (CI stamps it db-YYYYMMDD[HHMM].
// sqlite.png). Returns "YYYY-MM-DD" or null — used for the freshness badge.
export function indexDateFromConfigUrl(url) {
  const m = String(url ?? "").match(/db-(\d{8})/);
  if (!m) return null;
  const s = m[1];
  return `${s.slice(0, 4)}-${s.slice(4, 6)}-${s.slice(6, 8)}`;
}

// Minimal Scheme tokenizer for signature/subscribe blocks. Escapes each
// token's text so `pre.textContent` still yields the raw code (copy works).
// Fails safe: on any error the caller should fall back to esc(code).
const SCH_KEYWORDS = new Set([
  "define", "define*", "defmacro", "lambda", "λ", "let", "let*", "letrec",
  "letrec*", "if", "cond", "case", "when", "unless", "begin", "do", "and",
  "or", "not", "set!", "quote", "quasiquote", "unquote", "unquote-splicing",
  "syntax", "syntax-rules", "syntax-case", "define-syntax", "module",
  "define-record-type", "parameterize", "match", "match-lambda", "cut",
  "service", "service-type", "operating-system", "modify-services",
  "simple-service", "map", "filter", "fold", "for-each", "cons", "list",
  "vector", "values", "call-with-values", "record-type",
]);

export function highlightScheme(code) {
  const src = String(code ?? "");
  let out = "";
  let i = 0;
  let headNext = false; // the identifier right after "(" is the call head
  const span = (cls, text) =>
    cls ? `<span class="${cls}">${esc(text)}</span>` : esc(text);
  while (i < src.length) {
    const c = src[i];
    if (c === ";") {
      // line comment
      const e = src.indexOf("\n", i);
      const end = e === -1 ? src.length : e;
      out += span("sch-com", src.slice(i, end));
      i = end;
      continue;
    }
    if (c === '"') {
      // string literal (handles backslash escapes)
      let j = i + 1;
      while (j < src.length) {
        if (src[j] === "\\") { j += 2; continue; }
        if (src[j] === '"') { j++; break; }
        j++;
      }
      out += span("sch-str", src.slice(i, j));
      i = j;
      continue;
    }
    if (c === "(" || c === ")") {
      out += span("sch-paren", c);
      headNext = c === "(";
      i++;
      continue;
    }
    if (c === "'") {
      out += span("sch-quote", c);
      i++;
      continue;
    }
    if (/\s/.test(c)) {
      let j = i;
      while (j < src.length && /\s/.test(src[j])) j++;
      out += span("", src.slice(i, j));
      i = j;
      continue;
    }
    // identifier / other run: anything not a delimiter
    let j = i;
    while (j < src.length && !/[\s()";']/.test(src[j])) j++;
    const tok = src.slice(i, j);
    if (headNext) {
      out += span("sch-head", tok);
      headNext = false;
    } else if (SCH_KEYWORDS.has(tok)) {
      out += span("sch-kw", tok);
    } else {
      out += span("", tok);
    }
    i = j;
  }
  return out;
}
