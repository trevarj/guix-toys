// sql.js-httpvfs is loaded as a UMD script in index.html and attaches
// createDbWorker to window.
import { indexDateFromConfigUrl } from "./util.js";
let workerPromise = null;
let indexDate = null; // "YYYY-MM-DD" parsed from the DB filename, once boot ran

async function boot() {
  const res = await fetch("db/config.json");
  if (!res.ok) throw new Error(`db/config.json: HTTP ${res.status}`);
  const config = await res.json();
  // config urls are resolved relative to the config file location by the
  // library only when from:"jsonconfig"; with inline config they must be
  // absolute or page-relative, so prefix the db/ directory ourselves.
  if (config.from === "inline" && !/^(https?:)?\//.test(config.config.url)) {
    config.config.url = new URL(`db/${config.config.url}`, document.baseURI).href;
  }
  indexDate = indexDateFromConfigUrl(config.config?.url ?? config.url);
  return window.createDbWorker(
    [config],
    new URL("vendor/sql.js-httpvfs/sqlite.worker.js", document.baseURI).href,
    new URL("vendor/sql.js-httpvfs/sql-wasm.wasm", document.baseURI).href
  );
}

export function getWorker() {
  workerPromise ??= boot();
  return workerPromise;
}

// "YYYY-MM-DD" of the deployed DB, or null before/after a failed boot. Sourced
// from the dated filename (db-YYYYMMDD…sqlite.png), so no extra fetch.
export function getIndexDate() {
  return indexDate;
}

export async function query(sql, params = []) {
  const worker = await getWorker();
  const t = performance.now();
  try {
    return await worker.db.query(sql, params);
  } finally {
    const ms = performance.now() - t;
    if (ms > 500) {
      console.warn(`[slow query ${Math.round(ms)}ms]`, sql.replace(/\s+/g, " ").slice(0, 120), params);
    }
  }
}
