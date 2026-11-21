# helix-carve

Carve 0.2 support for Helix, using the Tree-sitter Carve revision pinned in `languages.toml`. Carve 0.1 source can read differently; `carve upgrade` rewrites it. It provides highlighting, indentation, text objects, and optional `carve-lsp` support. See the [Carve documentation](https://markup-carve.github.io/carve/) for the markup language.

## Features

- Highlighting and language injections.
- Text objects and indentation.
- A tags query for symbol pickers and a spell-check query for [Mitos](docs/guide.md#mitos).
- Optional language server features.

## Install

Merge this repository’s [`languages.toml`](languages.toml) into `~/.config/helix/languages.toml`, then install its queries and build the grammar as shown in the [guide](docs/guide.md#install). The grammar pin is `rev = "333ae69c00b47ee0c071e9bd444ce2cec906314c"`, matching `languages.toml`.

## Usage

Verify the installation with `hx --health carve`.

## Documentation

- [Carve documentation](https://markup-carve.github.io/carve/)
- [Setup and full guide](docs/guide.md)
- [Documentation index](docs/README.md)

## License

[MIT](LICENSE)
