// sql.js-httpvfs is loaded as a UMD script in index.html and attaches
// createDbWorker to window.
let workerPromise = null;

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

export async function query(sql, params = []) {
  const worker = await getWorker();
  return worker.db.query(sql, params);
}
