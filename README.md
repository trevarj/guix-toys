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
