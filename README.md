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
- Language-server support via
  [carve-lsp](https://github.com/markup-carve/carve-lsp) - diagnostics, hover,
  completion, go-to-definition, workspace-wide rename, find-references,
  code actions and formatting. Optional: install the server and it works,
  skip it and everything above still does.

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
source = { git = "https://github.com/markup-carve/tree-sitter-carve", rev = "5c23b644538805dfb1fac51aad8b9b06bff2a849" }
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

### 4. Install the language server (optional)

```bash
npm i -g @markup-carve/carve-lsp
```

`languages.toml` already declares it as `carve-lsp --stdio`. Skip this step and
Helix simply reports the server as unavailable; highlighting, textobjects,
injections and indentation are unaffected.

What it adds over the queries: the queries know the document's SHAPE, the server
knows what its identifiers MEAN. Unresolved `[^footnote]` references, `</#id>`
cross-references that point at nothing, and Markdown habits that silently render
wrong in Carve (`**bold**` is two literal asterisks around bold text here) are
diagnostics, not highlighting. Rename is workspace-wide, so renaming a heading
id updates every reference to it.

### 5. Verify

```bash
hx --health carve
```

You should see the parser, highlight queries, textobject queries, and indent
queries all marked present. If you installed the server, the language servers
line names `carve-lsp`.

Open a `.crv` file (for example [`sample.crv`](sample.crv)) in Helix and
confirm headings, emphasis, code, lists, links, tables, divs, and comments are
colored.

## Export and import

### Export to Markdown or HTML

With carve-lsp installed, open the code action menu on a `.crv` file
(`space` then `a`) and pick **Export as Markdown** or **Export as HTML**. The
result goes next to the source: `notes.crv` becomes `notes.md` or `notes.html`.
If Helix leaves the target open as a modified buffer, write it with `:w`. The
actions need a carve-lsp release newer than 0.1.7.

### Import from Markdown or HTML

Converting the other way uses `carve migrate`, which prints the Carve source to
stdout. It needs the `carve` CLI on PATH, for example from `cargo install
carve-lang`. The npm package does not work for this yet: `npx` and its
installed `carve` exit without output until a carve-js entry-point bug is fixed.

From Helix, with the `.md` file open:

```
:sh set -- "%{buffer_name}"; carve migrate --from markdown "$1" > "${1%%.*}.crv"
```

This writes `notes.crv` next to `notes.md`, overwriting an existing one. Helix
turns `%%` into a single `%` before the shell sees it. `%{buffer_name}` needs
Helix 25.01 or newer. Use `--from html` for HTML.

To replace the open buffer instead, select everything with `%` and run
`:pipe carve migrate --from markdown`, then save it under a new name with
`:w notes.crv`.

Outside the editor, a shell function does the same:

```bash
carve-import() { carve migrate --from "${2:-markdown}" "$1" > "${1%.*}.crv"; }
```

`carve-import notes.md` writes `notes.crv`; `carve-import page.html html`
converts HTML.

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
├── scripts/
│   └── highlight-captures.mjs     # what the highlights query actually paints
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
- **The include directive carries a base layer.** Upstream paints the PARTS of
  a `{{ ... }}` directive and leaves the rest of the run uncolored. The port
  adds `(include_directive) @function.macro` underneath them, so the padding and
  a malformed `include_extra` read as directive rather than as prose; the part
  patterns still win where they match.
- **Dropped priority directives.** Upstream tags some patterns with `(#set!
  priority N)`. This file carries none: Helix 25.07 ships no priority directive
  in any of its own bundled queries, and layers overlapping captures in the
  order they are written so the later one patches over the earlier - which is
  already what makes `@markup.heading.1` win over the `(heading)
  @markup.heading` line above it. Where upstream expresses precedence with a
  number, the port expresses it with position, so new patterns have to go in the
  right place rather than anywhere in the file.

## Effective captures

`tree-sitter query` prints every match. Several patterns claim the same node and
only one of them reaches the screen, so a pattern that never wins looks exactly
like a pattern that is not there - a compile check cannot tell them apart.
`scripts/highlight-captures.mjs` resolves the winner at a position the way Helix
does, and asserts it. It shells out to the tree-sitter CLI, so it needs no
dependencies of its own; point it at a built checkout of the pinned grammar:

```bash
TS_CWD=/path/to/tree-sitter-carve node scripts/highlight-captures.mjs
```
