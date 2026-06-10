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

// Mirrors upstream search-symbols: returns {rows, count}.
export async function search(type, { q = "", channel = "", limit = 24, page = 1 } = {}) {
  const { table, select } = TYPES[type];
  const isBoxes = table === "boxes";

  // upstream strips all double quotes; "foo" (fully quoted) means exact match
  const trimmed = q.trim();
  const exact = /^"[^"']+"$/.test(trimmed);
  let needle = trimmed.replaceAll('"', "");
  if (!needle) needle = null;
  if (needle && !exact) needle = `"${needle}" *`; // quoted phrase + prefix wildcard

  const wheres = [];
  const args = [];
  let sql = `SELECT ${select}`;
  sql += needle
    ? ` FROM search s INNER JOIN ${table} j ON s.fk = j.id`
    : ` FROM ${table} j`;

  if (needle) {
    wheres.push("s.`table` = ?");
    args.push(table);
    wheres.push(exact ? "s.name = ?" : "s.name MATCH ?");
    args.push(needle);
  }
  if (channel && !isBoxes) {
    wheres.push("j.channel = ?");
    args.push(channel);
  }
  if (wheres.length) sql += " WHERE " + wheres.join(" AND ");

  const [{ n: count }] = await query(`SELECT COUNT(*) AS n FROM (${sql})`, args);

  if (needle && !isBoxes) sql += " ORDER BY LENGTH(s.name) ASC, rank ASC, j.channel ASC";
  sql += " LIMIT ? OFFSET ?";

  const rows = await query(sql, [...args, limit, (page - 1) * limit]);
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
