; Carve injections for Helix.
; Adapted from tree-sitter-carve's queries/injections.scm.
; Inject the embedded language for fenced code, raw blocks, inline raw, math,
; and frontmatter so Helix highlights them with the target grammar.

(math
  (content) @injection.content
  (#set! injection.language "latex"))

(code_block
  (language) @injection.language
  (code) @injection.content)

(raw_block
  (raw_block_info
    (language) @injection.language)
  (content) @injection.content)

(raw_inline
  (content) @injection.content
  (raw_inline_attribute
    (language) @injection.language))

(frontmatter
  (language) @injection.language
  (frontmatter_content) @injection.content)
