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
             (SELECT COUNT(*) FROM packages AS p WHERE p.channel = j.id) AS packagesCount,
             (SELECT COUNT(*) FROM service_types AS s2 WHERE s2.channel = j.id) AS servicesCount,
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
// - table:/channel: filters live in the MATCH expression (posting-list
//   intersections; an SQL filter on FTS columns reads one content row per
//   matched document).
// - The CI-rebuilt FTS table encodes table, name length and join key into
//   the FTS rowid (code*1e14 + len*1e11 + fk). FTS iterates doclists in
//   rowid order, so ORDER BY rowid LIMIT streams upstream's
//   shortest-name-first order and stops early — no content reads, and no
//   ORDER BY rank, which wedges this WASM SQLite intermittently.
// - Exact-name matches use plain table indexes, no FTS at all.
function ftsMatch(table, needle, channel) {
  // separators ('_', '-') split tokens, so multi-token values become phrases
  const phrase = (s) => `"${s.replace(/[^a-zA-Z0-9]+/g, " ").trim()}"`;
  let m = `table: ${phrase(table)}`;
  if (needle) m += ` AND name: "${needle}" *`;
  if (channel) m += ` AND channel: ${phrase(channel)}`;
  return m;
}

// Mirrors upstream search-symbols: returns {rows, count} (count may be null).
export async function search(type, { q = "", channel = "", limit = 24, page = 1 } = {}) {
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
    return { rows, count: await browseCount(table, chan) };
  }

  if (exact) {
    const where = isBoxes ? "j.id = ?" : `j.name = ?${chan ? " AND j.channel = ?" : ""}`;
    const args = [needle, ...(chan ? [chan] : [])];
    const rows = await query(
      `SELECT ${select} FROM ${table} j WHERE ${where} LIMIT ? OFFSET ?`,
      [...args, limit, (page - 1) * limit]
    );
    const [{ n: count }] = await query(`SELECT COUNT(*) AS n FROM ${table} j WHERE ${where}`, args);
    return { rows, count };
  }

  const match = ftsMatch(table, needle, chan);
  const [{ n: count }] = await query(
    "SELECT COUNT(*) AS n FROM search s WHERE search MATCH ?",
    [match]
  );

  let rows;
  if (isBoxes) {
    // boxes.id is the channel name (text), so no rowid encoding — but the
    // table has ~100 rows, the fk join is fine
    rows = await query(
      `SELECT ${select} FROM search s INNER JOIN boxes j ON j.id = s.fk
       WHERE search MATCH ? ORDER BY s.rowid LIMIT ? OFFSET ?`,
      [match, limit, (page - 1) * limit]
    );
  } else {
    rows = await query(
      `SELECT ${select} FROM (
         SELECT s.rowid AS rid FROM search s WHERE search MATCH ?
         ORDER BY s.rowid LIMIT ? OFFSET ?
       ) m INNER JOIN ${table} j ON j.id = (m.rid % 100000000000) ORDER BY m.rid`,
      [match, limit, (page - 1) * limit]
    );
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
