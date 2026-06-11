# guix-toys — agent guide

Fork of [~whereiseveryone/toys](https://git.sr.ht/~whereiseveryone/toys) (a
Guile Scheme Guix extension that indexes Guix channels into SQLite) that adds
a **fully static** search frontend on GitHub Pages. Search runs in the
browser: sql.js-httpvfs (SQLite WASM in a worker) reads the database over
HTTP range requests, 16 KB at a time. Live at https://trevs.site/guix-toys/.

The upstream Scheme tree (`guix/`, `toys/`, `dev`, `manifest.scm`) is kept
as close to upstream as possible so `git merge upstream/master` stays easy.
Exception: `toys/discovery.scm` carries local fixes (per-module fail-soft
symbol scanning, transitive dependency load paths, metadata read from the
checkout root) — candidates for upstreaming; watch for conflicts on merge.
Our own code lives in `site/` and `.github/workflows/`.

## Architecture

- `site/` — vanilla JS, no build step, no framework.
  - `js/db.js` — boots the worker from `db/config.json`; queries >500 ms log
    a console warning.
  - `js/queries.js` — all SQL. Read the header comment before touching it.
  - `js/router.js` — hash routes: `#/?q=&type=&channel=` and
    `#/package/<channel>/<name>` (+ service/symbol/channel).
  - `js/app.js` — state, single-flight search gating, keyboard nav,
    expandable result cards.
  - `js/render.js` — HTML strings; `expandBody()` is shared by detail pages
    and inline card expansion.
  - `vendor/sql.js-httpvfs/` — vendored dist (0.8.12), committed.
  - `db/` — gitignored; CI fills it. For local dev put a DB + `config.json`
    here.
- `.github/workflows/build-deploy.yml` — weekly (Mon 03:00 UTC) +
  workflow_dispatch + push: syncs `channels.scm` from the sr.ht upstream
  (no PR, direct commit), indexes all channels with the upstream Guix
  extension, post-processes the DB, deploys everything to Pages.
- `.github/workflows/deploy-site.yml` — fast path (~1 min): pushes touching
  only `site/**` redeploy the frontend and **reuse the live DB** by
  downloading it from the live site.

## Hard-won invariants (violate these and the site breaks or crawls)

1. **The DB is deployed as `db-<date>.sqlite.png`.** The `.png` is
   load-bearing: GitHub Pages gzips `application/octet-stream` and Fastly
   applies Range requests to the *compressed* object, which corrupts
   httpvfs reads and breaks length detection. Image content types are never
   compressed. Don't "fix" the extension.
2. **`requestChunkSize` in `config.json` must equal the SQLite `page_size`
   (16384).** CI sets both.
3. **Dated DB filenames** (`db-YYYYMMDD…`) prevent stale CDN range mixing
   across deploys. Never reuse a filename for different bytes.
4. **Every page read costs one ~16 KB range request.** Query rules in
   `site/js/queries.js`:
   - Filters on FTS columns (`s.\`table\` = ?`, `s.channel = ?`) read one
     content row *per match* — put them in the MATCH expression as FTS5
     column filters (`table: "packages" AND name: "foo" *`) instead.
   - Never `ORDER BY rank` — bm25 intermittently wedges the old WASM
     SQLite (3.36) outright. Order by `s.rowid`.
   - The CI-rebuilt FTS rowid encodes `tablecode*1e14 + min(len(name),999)
     *1e11 + fk`, so `ORDER BY rowid LIMIT` streams shortest-name-first
     (upstream's relevance order) with zero content reads, and the join key
     decodes as `rowid % 1e11`. This encoding must stay in sync between
     `build-deploy.yml` (post-process step) and `queries.js`.
   - `COUNT(*)` over real tables pages the whole table through HTTP — use
     the precomputed `toys_counts(tbl, channel, n)` table.
   - LIMIT inside the FTS-only subquery; only the visible page of results
     may touch the data tables.
5. **The worker cannot cancel queries.** Searches are single-flight in
   `app.js` (`runSearch` collapses queued requests to the latest). Don't
   fire queries per keystroke without going through it.
6. **JS and DB schema deploy atomically.** If a change requires the
   rebuilt DB (new index, new encoding), commit with `[skip ci]` and
   dispatch `build-deploy.yml` manually so deploy-site.yml doesn't ship new
   JS against the old live DB.
7. The indexer loop in CI calls `./dev pull <file> <channel>` per channel
   with `timeout 20m` and warns on failure — upstream's all-channels driver
   would abort everything on one hard crash. Some channels always fail
   (e.g. repo moved and now 404s); that's expected, fail-soft — a
   dead/404'd channel URL is skipped, not patched.

## Local development

Host quirk: this is a Guix System machine — no FHS loader, so use
`guix shell <pkg> --` for anything not in the profile (`sqlite`,
`darkhttpd`, `ungoogled-chromium`).

```sh
# small test DB (3 channels, ~min): builds ~/.cache/guix/toys/db.sqlite
guix shell -- ./dev init && guix shell -- ./dev pull channels-test.scm

# or grab the real one (~70 MB)
curl -O https://trevs.site/guix-toys/db/$(curl -s https://trevs.site/guix-toys/db/config.json | grep -oP '"url": "\K[^"]+')

# apply the same post-processing CI does (FTS rebuild, indexes, toys_counts)
# — copy the SQL from the "Post-process DB" step of build-deploy.yml

# serve (python http.server does NOT do range requests; darkhttpd does)
guix shell darkhttpd -- darkhttpd site --port 8765 --addr 127.0.0.1
```

Point `site/db/config.json` at your DB file (url is relative to `db/`).

Headless testing (Playwright's bundled browsers can't exec on Guix):

```sh
guix shell ungoogled-chromium -- chromium --headless --no-sandbox \
  --timeout=8000 --dump-dom 'http://127.0.0.1:8765/#/?q=emacs'
# add --enable-logging=stderr to see worker XHR logs ("[xhr of size ...]")
# and the slow-query warnings; doubling XHR sizes = a sequential scan bug
```

CI smoke run without the 40-minute full index:
`gh workflow run build-deploy.yml -f channels_file=channels-test.scm`
(note: this deploys the small test DB to the live site until the next full
run).

## Conventions

- Commits are GPG-signed by the repo owner; don't add Co-Authored-By
  trailers.
- `[skip ci]` on commits that shouldn't trigger a deploy.
- Design language: Toy Machine skateboards homage — near-black `#0e0d0b`,
  blood red `#b3001b`, mustard `#e0a500`, Rubik Mono One display font,
  JetBrains Mono body, boxy 4px radii, film-grain overlay. Keep it dark and
  gritty; the mascot (`site/img/mascot.svg`) is an original one-eyed punk
  gnu (old devil kept at `mascot-devil.svg`).
- SQL semantics mirror upstream `guix/extensions/toys.scm`
  (`search-symbols`, the `/api/*` handlers) — if upstream's schema changes,
  CI's schema assertions fail; fix `queries.js` to match.
