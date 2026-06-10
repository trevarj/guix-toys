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

Everything below is the upstream README.

---

# toys

`toys` is an experiment to create a JSON API for exploring Guix channels on the internets.

Issue tracker is [here](https://todo.sr.ht/~whereiseveryone/toys).

The live instance can be found at [toys.whereis.social](https://toys.whereis.social).

## join

If you'd like to join our channel search send a patch to
~whereiseveryone/toys@lists.sr.ht adding your channel as an entry in
[channels.scm](https://git.sr.ht/~whereiseveryone/toys/tree/master/item/channels.scm).

## contribute

Send patches to ~whereiseveryone/toys@lists.sr.ht

jgart and [unwox](https://git.sr.ht/~unwox) can review patches and merge them.

See the
[good-first-issue](https://todo.sr.ht/~whereiseveryone/toys?search=label%3Agood-first-issue)
tags if you're looking for how to get started contributing.

## chat

Discussion regarding this project happens at `#whereiseveryone` on the Libera IRC network.

* IRC users can connect to `irc.libera.chat/#whereiseveryone`
* XMPP users can connect to `#whereiseveryone%irc.libera.chat@irc.cheogram.com`
* Matrix users can connect to `#libera_#whereiseveryone:matrix.org`

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

## support

If you wish to support the project please consider donating. All donations go
to covering hosting costs for our [toys instance](https://toys.whereis.social).
Currently we pay $12.5 a month for that.

Monero:
859s7UbwF8kFwnsJzaNvGf8H8zboVi9vg8U3TUM7N2J5AG8srsksZZhGn2unDGFXV5AesVMJd6FnCjgyESY48Ux3ArGobUc
