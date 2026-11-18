; Carve injections for Helix.
; Adapted from tree-sitter-carve's queries/injections.scm.
; Inject the embedded language for fenced code, raw blocks, inline raw, math,
; and frontmatter so Helix highlights them with the target grammar.

; TODO, NOTE and FIXME are marked inside comments only, by Helix's `comment`
; grammar. In prose the engine renders them as plain words.
([
  (comment_line)
  (trailing_comment)
] @injection.content
  (#set! injection.language "comment"))

([
  (fenced_comment_block
    (content) @injection.content)
  (braced_comment
    (content) @injection.content)
]
  (#set! injection.language "comment"))

(math
  (content) @injection.content
  (#set! injection.language "latex"))

(code_block
  (language) @injection.language
  (code) @injection.content)

(table
  (language) @injection.language
  (code) @injection.content)

(raw_block
  (raw_block_info
    (language) @injection.language)
  (content) @injection.content)

; Raw inline spans. The grammar gives the format as one `{=name}` token, not a
; language node, so each format is named here.
(raw_inline
  (content) @injection.content
  (raw_inline_attribute) @_format
  (#eq? @_format "{=html}")
  (#set! injection.language "html"))

(raw_inline
  (content) @injection.content
  (raw_inline_attribute) @_format
  (#any-of? @_format "{=xml}" "{=svg}")
  (#set! injection.language "xml"))

(raw_inline
  (content) @injection.content
  (raw_inline_attribute) @_format
  (#eq? @_format "{=css}")
  (#set! injection.language "css"))

(raw_inline
  (content) @injection.content
  (raw_inline_attribute) @_format
  (#any-of? @_format "{=js}" "{=javascript}")
  (#set! injection.language "javascript"))

(raw_inline
  (content) @injection.content
  (raw_inline_attribute) @_format
  (#eq? @_format "{=json}")
  (#set! injection.language "json"))

(raw_inline
  (content) @injection.content
  (raw_inline_attribute) @_format
  (#any-of? @_format "{=latex}" "{=tex}")
  (#set! injection.language "latex"))

(raw_inline
  (content) @injection.content
  (raw_inline_attribute) @_format
  (#eq? @_format "{=typst}")
  (#set! injection.language "typst"))

(raw_inline
  (content) @injection.content
  (raw_inline_attribute) @_format
  (#any-of? @_format "{=markdown}" "{=md}")
  (#set! injection.language "markdown"))

(frontmatter
  (language) @injection.language
  (frontmatter_content) @injection.content)

; Plain `---` frontmatter is YAML.
(frontmatter
  !language
  (frontmatter_content) @injection.content
  (#set! injection.language "yaml"))
