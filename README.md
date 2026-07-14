# helix-carve

[Carve](https://markup-carve.github.io/carve/) markup language support for the
[Helix](https://helix-editor.com/) editor: syntax highlighting, textobjects,
injections, and indentation, backed by the
[tree-sitter-carve](https://github.com/markup-carve/tree-sitter-carve) grammar.

Carve is a post-Markdown lightweight markup language. Files use the `.crv`
extension.

## What you get

- Highlighting for headings (all six levels), bold / italic / underline /
  strikethrough, inline and block code, math, lists (bullet, ordered, task,
  definition), links and images, tables, divs, attributes, footnotes, and
  comments.
- Textobjects (`function`, `class`, `parameter`, `entry`, `comment`) for
  tree-sitter based selection and navigation.
- Language injections so fenced code blocks, raw blocks, inline raw spans, math
  (LaTeX), and frontmatter are highlighted with their target grammar.
- A `%%` comment token, so `gc` comment toggling works.

The queries are Helix-flavored: they use Helix's themable scope list
(`@markup.heading.1`, `@markup.bold`, `@markup.raw.inline`,
`@markup.link.url`, `@comment`, `@punctuation.special`, and so on), which
differs from the Neovim-flavored captures the upstream grammar ships.

## Install

### 1. Merge the language and grammar definitions

Copy the `[[language]]` and `[[grammar]]` entries from this repo's
[`languages.toml`](languages.toml) into your Helix `languages.toml`
(`~/.config/helix/languages.toml`):

```toml
[[language]]
name = "carve"
scope = "source.carve"
file-types = ["crv"]
roots = []
comment-token = "%%"
indent = { tab-width = 2, unit = "  " }

[[grammar]]
name = "carve"
source = { git = "https://github.com/markup-carve/tree-sitter-carve", rev = "5b63c7d4bbbf1818778744510db6220345c5dffb" }
```

> The `rev` pins a known-good grammar commit. Bump it when you want a newer
> grammar. For a fully offline build, point `source` at a local checkout
> instead: `source = { path = "/abs/path/to/tree-sitter-carve" }`.

### 2. Fetch and build the grammar

```bash
hx --grammar fetch
hx --grammar build
```

`fetch` clones the grammar source (skipped for a local `path` source); `build`
compiles it into `<helix-runtime>/grammars/carve.so`.

### 3. Install the queries

Copy this repo's `runtime/queries/carve/` into your Helix runtime's
`queries/carve/` directory. With the default config-dir runtime:

```bash
mkdir -p ~/.config/helix/runtime/queries/carve
cp runtime/queries/carve/*.scm ~/.config/helix/runtime/queries/carve/
```

Alternatively, set `HELIX_RUNTIME` to a directory that contains both
`grammars/` and `queries/`, and place the queries under `queries/carve/` there.

### 4. Verify

```bash
hx --health carve
```

You should see the parser, highlight queries, textobject queries, and indent
queries all marked present.

Open a `.crv` file (for example [`sample.crv`](sample.crv)) in Helix and
confirm headings, emphasis, code, lists, links, tables, divs, and comments are
colored.

## Files

```
helix-carve/
├── languages.toml                 # [[language]] + [[grammar]] entries to merge
├── runtime/
│   └── queries/
│       └── carve/
│           ├── highlights.scm     # Helix-flavored scopes; correct h1-h6 mapping
│           ├── injections.scm     # code / raw / math / frontmatter injections
│           ├── textobjects.scm    # function/class/parameter/entry/comment
│           └── indents.scm        # container-based indent scopes
├── sample.crv                     # feature-exercising example document
├── README.md
├── LICENSE                        # MIT
└── .gitignore
```

## Notes on the queries

- **Heading levels.** The upstream `tree-sitter-carve/queries/highlights.scm`
  has an off-by-one in its level-4/5/6 marker matches (it skips the four-hash
  marker and references a non-existent seven-hash marker). The query here maps
  all six markers (`# ` through `###### `) to `@markup.heading.1` ..
  `@markup.heading.6` correctly. Verified against a six-level sample (see below).
- **Dropped Neovim-only bits.** Neovim's `@spell` / `@nospell` captures and the
  conceal / `#offset!` directives used purely for concealing markers are not
  part of Helix's model, so they were left out to keep the queries clean.
- **Textobject suffixes.** Helix uses `.inside` / `.around` (not Neovim's
  `.inner` / `.outer`), and supports a fixed set of kinds; only the kinds that
  map onto Carve are kept.

## License

MIT. See [LICENSE](LICENSE). The bundled grammar (tree-sitter-carve) is also
MIT-licensed by its authors.
