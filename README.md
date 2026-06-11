# guix-toys

A fork of [~whereiseveryone/toys](https://git.sr.ht/~whereiseveryone/toys) that
publishes a **fully static** search site to GitHub Pages. Search runs entirely
in your browser: the upstream SQLite FTS5 database is served as a static file
and queried with [sql.js-httpvfs](https://github.com/phiresky/sql.js-httpvfs)
(SQLite compiled to WASM, fetching only the needed pages via HTTP range
requests).

- `site/` — the static frontend (vanilla JS, no build step)
- `.github/workflows/build-deploy.yml` — weekly CI: syncs `channels.scm` from
  upstream, rebuilds the database with the upstream Guix indexer, deploys to Pages
- `channels-test.scm` — trimmed channel list for smoke runs
  (`gh workflow run build-deploy.yml -f channels_file=channels-test.scm`)

Local development: build a test DB with `./dev init && ./dev pull
channels-test.scm`, post-process it to `page_size=16384`, copy it to `site/db/`
with a matching `config.json`, then serve `site/` with any server that supports
range requests (e.g. `darkhttpd site` — not `python -m http.server`).

In production the database is deployed with a `.png` extension: GitHub Pages
gzips `application/octet-stream` responses and serves range requests from the
*compressed* object, which breaks sql.js-httpvfs, but it never compresses
image content types.

## development

Start a development environment:

```sh
guix shell
# or even
guix shell --container --network
```

Initialize the database:

```sh
./dev init
```

Pull symbols data:

```sh
./dev pull channels.scm
# or only pull specific channel
./dev pull channels.scm CHANNEL-NAME
```

Run the server:

```sh
./dev serve
```

Visit [http://localhost:8080](http://localhost:8080).
