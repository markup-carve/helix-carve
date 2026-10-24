# Changelog

All notable changes to helix-carve are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Releases before 0.1.5 are described on the
[releases page](https://github.com/markup-carve/helix-carve/releases).

## [Unreleased]

## [0.1.9] - 2026-10-24

Helix highlighting now follows the grammar fixes for continuation markers and nested quotes.

### Fixes

- A refused or unowned `+` stays in paragraph text, including nested quotes and lines before a blank line (#70).
- Continuation markers attach to the right list item after lazy lines, while indented quote markers and shallower quoted lines keep their intended structure (#70).

**Full Changelog**: https://github.com/markup-carve/helix-carve/compare/0.1.8...0.1.9

## [0.1.8] - 2026-10-23

### Fixed

- Pin tree-sitter-carve 0.1.11, which reads the `+` continuation
  marker by its owner's column per markup-carve/carve#3421: an indented or
  refused lone `+` is text, glued quote prefixes `>+`, `>>+`, `> >+` and
  `>> +` are text, and a first-block `+` in a footnote, description or
  stacked opener attaches its block (#62, #63, #64, #65, #67, #68).
- With the same pin, a quote-prefixed `+` reads like its unquoted twin, also
  at a quoted item's content column, and a paragraph continues lazily onto a
  line with fewer quote markers (#67).
- With the same pin, quote markers in nested containers match at their own
  column, list and fence ownership is read at the reached column, and a
  valueless include option parses as an option (#60, #61, #63).

### Improved

- The `+` continuation marker is captured as `@operator` instead of
  `@markup.list`, as tree-sitter-carve 0.1.11 does, so themes tell it from a
  list marker (#67).
- Color `table` as reserved above a CSV or TSV code include
  (`{{ data.csv @code:csv }}`), which renders as a table like a CSV fence (#67).

## [0.1.7] - 2026-10-18

### Improved

- Color reserved `kbd`, `abbr` and `time` keys on spans, `table` above CSV or TSV fences, and `loose` above lists. Quoted and stacked block attributes keep the same colors (#55).
- Inject CSV and TSV into delimited table code. A delimited table textobject selects the code body once; pipe table rows and captions keep their selections (#55).
- Pin tree-sitter-carve at `fd44e74`, including the Carve 0.1.10 corpus, CSV/TSV table nodes, and the parser fixes from markup-carve/tree-sitter-carve#559, markup-carve/tree-sitter-carve#563, and markup-carve/tree-sitter-carve#568 (#54, #56, #55, #58).

## [0.1.6] - 2026-10-14

### Fixed

- `TODO`, `NOTE` and `FIXME` are marked only inside `%%`, `%%%` and `{% %}`
  comments, through Helix's `comment` grammar. In prose the engine renders
  them as plain words, so they are no longer highlighted there.
- Plain `---` front matter is highlighted as YAML, as upstream does.
- A Markdown fence labeled `carve` or `crv` highlights its body as Carve.
- The README install snippet matches `languages.toml`: `roots = [".git"]` and
  the `carve-lsp` language server (#52).

These come with the grammar pin moving from tree-sitter-carve `3d68321` to
the 0.1.9 tag (`54289cd`), in #47, #48, #49, #52 and #53. Highlighting
follows the grammar, so that is where they come from.

- Block structure around quoted lists, comments, fences, tables, line blocks,
  continuation markers and lazy lines follows the engine
  (markup-carve/tree-sitter-carve#539, markup-carve/tree-sitter-carve#542,
  markup-carve/tree-sitter-carve#546, markup-carve/tree-sitter-carve#551,
  markup-carve/tree-sitter-carve#555).
- Long paragraphs and lines parse in near-linear time, and a stale delimiter
  note no longer hangs the parser (markup-carve/tree-sitter-carve#545,
  markup-carve/tree-sitter-carve#547).
- Very wide colon, code and comment fences are read at full width
  (markup-carve/tree-sitter-carve#547, markup-carve/tree-sitter-carve#548,
  markup-carve/tree-sitter-carve#549).
- Citation, comment, column and quote-cap readings follow the engine, and a
  braced span stays open across a bracket that holds its closer
  (markup-carve/tree-sitter-carve#544,
  markup-carve/tree-sitter-carve#553).

- An include option glued to the next one, such as
  `{{ c.crv@shift:1@lines:1-2 }}`, reads as two options, and an option with
  no value, such as `{{ c.crv @k }}`, no longer breaks the directive
  (markup-carve/tree-sitter-carve#533, markup-carve/tree-sitter-carve#534).
- A table row splits around escapes the way the engine does: an escaped tick
  opens no code run (markup-carve/tree-sitter-carve#528).
- A standalone caption detaches after two blank lines, email autolinks such as
  `<a@b.com>` are recognized, and the Djot quote forms `{"` and `"}` stay text
  (markup-carve/tree-sitter-carve#540).
- Inline extensions whose name starts with an underscore are read, an
  abbreviation definition can interrupt a paragraph, and tab padding inside
  inline attribute blocks is refused (markup-carve/tree-sitter-carve#540,
  markup-carve/tree-sitter-carve#541).
- The nesting cap of 200 covers quotes, lists, colon fences and footnotes
  together, and `[t][@a]` stays text (markup-carve/tree-sitter-carve#541).

### Changed

- The highlights query drops the five `list_marker_*_parens` patterns, which
  name markers the grammar never produces (#52).
- The queries drop the `comment` node, which tree-sitter-carve removed with
  the Djot `%comment%` attribute item, including its comment textobject, so
  the patterns that named it would no longer compile
  (markup-carve/tree-sitter-carve#541).

## [0.1.5] - 2026-10-08

### Added

- The README documents export and import. Export is carve-lsp's Export as
  Markdown and Export as HTML code actions, reached with `space` `a`. Import
  runs `carve migrate --from markdown` three ways: a `:sh` one-liner that
  writes a sibling `.crv`, `:pipe` over the whole buffer, and a shell
  function (#27).

### Fixed

These come with the grammar pin moving from tree-sitter-carve 0.1.6 to
`03445e4`. Highlighting follows the grammar, so that is where they come from.

- A construct on an unterminated last line completes, and its containers close
  with it. A fence or caption at the end of a buffer used to parse as an error.
- Fences, footnotes and lists respect a quote's boundary, and definition terms
  are recognized inside description bodies.
- Links and spans keep their scopes, and a `%%` comment inside a forced span
  ends at that span's closer rather than at the end of the line.
- Caption markup ends before a following block opener, and a named container
  with invalid metadata keeps its children.

### Known

- An include option with no space before its `@`, such as
  `{{ ch.crv@shift:auto }}`, is not recognized and paints as prose. A defect in
  tree-sitter-carve, not in these queries (#40).
