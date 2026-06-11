// SQL translated from upstream guix/extensions/toys.scm (search-symbols and
// the /api/* handlers). Keep in sync if the upstream schema changes.
import { query } from "./db.js";

export const TYPES = {
  packages: {
    table: "packages",
    label: "packages",
    select: `j.name, j.channel, j.module, j.file, j.url, j.version, j.homepage,
             j.licenses, j.synopsis, j.inputs, j.propagated_inputs AS propagatedInputs,
             j.origin, j.description, j.build_system AS buildSystem`,
  },
  services: {
    table: "service_types",
    label: "services",
    select: "j.name, j.channel, j.module, j.file, j.url, j.description",
  },
  symbols: {
    table: "public_symbols",
    label: "symbols",
    select: "j.name, j.channel, j.module, j.file, j.url, j.doc, j.signature",
  },
  channels: {
    table: "boxes",
    label: "channels",
    select: `j.id AS name, j.branch, j.\`commit\`, j.url, j.synopsis,
             COALESCE((SELECT n FROM toys_counts WHERE tbl = 'packages' AND channel = j.id), 0) AS packagesCount,
             COALESCE((SELECT n FROM toys_counts WHERE tbl = 'service_types' AND channel = j.id), 0) AS servicesCount,
             j.subscription_snippet AS subscriptionSnippet`,
  },
};

// Browse-mode totals come from the toys_counts table precomputed in CI;
// COUNT(*) on the big tables would page the whole DB through range requests.
const countCache = new Map();
async function browseCount(table, channel) {
  const key = `${table}/${channel}`;
  if (countCache.has(key)) return countCache.get(key);
  let n = null;
  try {
    const rows = await query(
      "SELECT n FROM toys_counts WHERE tbl = ? AND channel = ?",
      [table, channel]
    );
    n = rows[0]?.n ?? 0;
  } catch {
    if (table === "boxes") {
      n = (await query("SELECT COUNT(*) AS n FROM boxes"))[0].n;
    }
    // other tables: unknown (old DB without toys_counts)
  }
  countCache.set(key, n);
  return n;
}

// Over httpvfs every stray page read is a 16 KB range request, so search
// must stay inside the FTS index until the final, LIMITed join:
// - The CI-rebuilt FTS table encodes table, name length and join key into
//   the FTS rowid (code*1e14 + len*1e11 + fk). FTS iterates doclists in
//   rowid order, so ORDER BY rowid LIMIT streams upstream's
//   shortest-name-first order and stops early — no content reads, and no
//   ORDER BY rank, which wedges this WASM SQLite intermittently.
// - The table filter is a rowid RANGE on that encoding, not a `table:`
//   MATCH term: that term's doclist spans half the corpus (~hundreds of
//   KB intersected per query), while the range is pushed into the FTS
//   cursor for free — and all four types then share one name-doclist scan
//   (warm cache across the per-type queries of an all-mode search).
// - The channel filter stays in the MATCH expression (column filter).
// - Exact-name matches use plain table indexes, no FTS at all.
const TABLE_CODE = { packages: 1, service_types: 2, public_symbols: 3, boxes: 4 };
const CODE_TYPE = ["", "packages", "services", "symbols", "channels"];
const RID = 100000000000000; // code multiplier
const FK = 100000000000; // fk modulus

function ftsMatch(needle, channel) {
  // separators ('_', '-') split tokens, so multi-token values become phrases
  const phrase = (s) => `"${s.replace(/[^a-zA-Z0-9]+/g, " ").trim()}"`;
  let m = `name: "${needle}" *`;
  if (channel) m += ` AND channel: ${phrase(channel)}`;
  return m;
}

// Merged per-type counts for one needle: a single GROUP BY over the shared
// name doclist instead of four COUNT queries. Returns {packages: n, ...}.
export async function searchCounts(q, channel = "") {
  const trimmed = q.trim();
  const needle = trimmed.replaceAll('"', "");
  if (!needle || /^"[^"']+"$/.test(trimmed)) return null;
  const rows = await query(
    `SELECT s.rowid / ${RID} AS code, COUNT(*) AS n
     FROM search s WHERE search MATCH ? GROUP BY code`,
    [ftsMatch(needle, channel)]
  );
  const counts = { packages: 0, services: 0, symbols: 0, channels: 0 };
  for (const { code, n } of rows) {
    if (CODE_TYPE[code]) counts[CODE_TYPE[code]] = n;
  }
  if (channel) counts.channels = 0; // channel filter never applies to boxes
  return counts;
}

// Mirrors upstream search-symbols: returns {rows, count} (count is null
// when skipped — pass noCount or rely on rows.length < limit shortcut).
export async function search(type, { q = "", channel = "", limit = 24, page = 1, noCount = false } = {}) {
  const { table, select } = TYPES[type];
  const isBoxes = table === "boxes";

  // upstream strips all double quotes; "foo" (fully quoted) means exact match
  const trimmed = q.trim();
  const exact = /^"[^"']+"$/.test(trimmed);
  const needle = trimmed.replaceAll('"', "");
  const chan = channel && !isBoxes ? channel : "";

  if (!needle) {
    // browse mode: plain table scan of the first pages only
    const rows = await query(
      `SELECT ${select} FROM ${table} j${chan ? " WHERE j.channel = ?" : ""} LIMIT ? OFFSET ?`,
      [...(chan ? [chan] : []), limit, (page - 1) * limit]
    );
    return { rows, count: noCount ? null : await browseCount(table, chan) };
  }

  if (exact) {
    const where = isBoxes ? "j.id = ?" : `j.name = ?${chan ? " AND j.channel = ?" : ""}`;
    const args = [needle, ...(chan ? [chan] : [])];
    const rows = await query(
      `SELECT ${select} FROM ${table} j WHERE ${where} LIMIT ? OFFSET ?`,
      [...args, limit, (page - 1) * limit]
    );
    const count = rows.length < limit && page === 1
      ? rows.length
      : (await query(`SELECT COUNT(*) AS n FROM ${table} j WHERE ${where}`, args))[0].n;
    return { rows, count };
  }

  const match = ftsMatch(needle, chan);
  const lo = TABLE_CODE[table] * RID;
  const hi = lo + RID;
  const ridRange = "s.rowid >= ? AND s.rowid < ?";

  // rows FIRST (they are what the user is waiting for), count after — and
  // only when the page is full (otherwise count == what we can see)
  let rows;
  if (isBoxes) {
    // boxes.id is the channel name (text), so no rowid encoding — but the
    // table has ~100 rows, the fk join is fine
    rows = await query(
      `SELECT ${select} FROM search s INNER JOIN boxes j ON j.id = s.fk
       WHERE search MATCH ? AND ${ridRange} ORDER BY s.rowid LIMIT ? OFFSET ?`,
      [match, lo, hi, limit, (page - 1) * limit]
    );
  } else {
    rows = await query(
      `SELECT ${select} FROM (
         SELECT s.rowid AS rid FROM search s WHERE search MATCH ? AND ${ridRange}
         ORDER BY s.rowid LIMIT ? OFFSET ?
       ) m INNER JOIN ${table} j ON j.id = (m.rid % ${FK}) ORDER BY m.rid`,
      [match, lo, hi, limit, (page - 1) * limit]
    );
  }

  let count = null;
  if (!noCount) {
    if (rows.length < limit && page === 1) {
      count = rows.length;
    } else {
      const r = await query(
        `SELECT COUNT(*) AS n FROM search s WHERE search MATCH ? AND ${ridRange}`,
        [match, lo, hi]
      );
      count = r[0].n;
    }
  }
  return { rows, count };
}

// Exact lookup for detail views; may return several rows (same name in
// different modules/versions).
export function lookup(type, channel, name) {
  const { table, select } = TYPES[type];
  if (table === "boxes") {
    return query(`SELECT ${select} FROM boxes j WHERE j.id = ?`, [name]);
  }
  return query(
    `SELECT ${select} FROM ${table} j WHERE j.channel = ? AND j.name = ?`,
    [channel, name]
  );
}

export function allChannels() {
  return query("SELECT id FROM boxes ORDER BY id");
}
