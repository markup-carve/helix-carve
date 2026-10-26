# helix-carve

Carve support for Helix, using the Tree-sitter Carve revision pinned in `languages.toml`. It provides highlighting, indentation, text objects, and optional `carve-lsp` support. See the [Carve documentation](https://markup-carve.github.io/carve/) for the markup language.

## Features

- Highlighting and language injections.
- Text objects and indentation.
- Optional language server features.

## Install

Merge this repository’s [`languages.toml`](languages.toml) into `~/.config/helix/languages.toml`, then install its queries and build the grammar as shown in the [guide](docs/guide.md#install).

## Usage

Verify the installation with `hx --health carve`.

## Documentation

- [Carve documentation](https://markup-carve.github.io/carve/)
- [Setup and full guide](docs/guide.md)
- [Documentation index](docs/README.md)

## License

[MIT](LICENSE)
