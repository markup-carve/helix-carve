; Carve highlights for Helix.
; Adapted from tree-sitter-carve's queries/highlights.scm and re-flavored for
; Helix's themable scope list (https://docs.helix-editor.com/themes.html).
;
; Key Helix-vs-Neovim scope differences applied here:
;   @markup.strong        -> @markup.bold
;   @markup.link (text)   -> @markup.link.text
;   @string.escape        -> @constant.character.escape
;   @markup.list (bullet) -> @markup.list.unnumbered / .numbered
; Neovim-only @spell / @nospell captures and conceal directives are dropped.

; --- Headings -----------------------------------------------------------------
; All six levels map correctly to .1 .. .6. The verified Carve heading markers
; are "# " (2 chars) through "###### " (7 chars). The whole heading node gets the
; numbered scope; the leading marker gets @markup.heading.marker.

(heading) @markup.heading

((heading
  (marker) @markup.heading.marker) @markup.heading.1
  (#eq? @markup.heading.marker "# "))

((heading
  (marker) @markup.heading.marker) @markup.heading.2
  (#eq? @markup.heading.marker "## "))

((heading
  (marker) @markup.heading.marker) @markup.heading.3
  (#eq? @markup.heading.marker "### "))

((heading
  (marker) @markup.heading.marker) @markup.heading.4
  (#eq? @markup.heading.marker "#### "))

((heading
  (marker) @markup.heading.marker) @markup.heading.5
  (#eq? @markup.heading.marker "##### "))

((heading
  (marker) @markup.heading.marker) @markup.heading.6
  (#eq? @markup.heading.marker "###### "))

; --- Thematic break / rules ---------------------------------------------------
(thematic_break) @punctuation.special

; --- Divs ---------------------------------------------------------------------
[
  (div_marker_begin)
  (div_marker_end)
] @punctuation.delimiter

; --- Code / raw blocks --------------------------------------------------------
[
  (code_block)
  (raw_block)
  (frontmatter)
] @markup.raw.block

[
  (code_block_marker_begin)
  (code_block_marker_end)
  (raw_block_marker_begin)
  (raw_block_marker_end)
] @punctuation.delimiter

(language) @label

(frontmatter_marker) @punctuation.delimiter

; --- Block quotes -------------------------------------------------------------
(block_quote) @markup.quote
(block_quote_marker) @punctuation.special

; --- Tables -------------------------------------------------------------------
(table_header) @markup.heading

(table_header
  "|" @punctuation.special)

(table_row
  "|" @punctuation.special)

(table_separator) @punctuation.special

(table_caption
  (marker) @punctuation.special)
(table_caption) @markup.italic

(caption
  (caption_marker) @punctuation.special)
(caption
  (caption_content) @markup.italic)

; --- Lists --------------------------------------------------------------------
[
  (list_marker_dash)
  (list_marker_star)
] @markup.list.unnumbered

[
  (list_marker_decimal_period)
  (list_marker_decimal_paren)
  (list_marker_decimal_parens)
  (list_marker_lower_alpha_period)
  (list_marker_lower_alpha_paren)
  (list_marker_lower_alpha_parens)
  (list_marker_upper_alpha_period)
  (list_marker_upper_alpha_paren)
  (list_marker_upper_alpha_parens)
  (list_marker_lower_roman_period)
  (list_marker_lower_roman_paren)
  (list_marker_lower_roman_parens)
  (list_marker_upper_roman_period)
  (list_marker_upper_roman_paren)
  (list_marker_upper_roman_parens)
] @markup.list.numbered

(list_marker_definition) @markup.list.numbered

(list_marker_task
  (unchecked)) @markup.list.unchecked

(list_marker_task
  (checked)) @markup.list.checked

(list_item
  (term) @type.builtin)

; --- Typographic replacements -------------------------------------------------
[
  (ellipsis)
  (en_dash)
  (em_dash)
  (quotation_marks)
] @punctuation.special

; --- Escapes / line breaks ----------------------------------------------------
[
  (hard_line_break)
  (backslash_escape)
] @constant.character.escape

; --- Inline emphasis ----------------------------------------------------------
(emphasis) @markup.italic
(strong) @markup.bold

(bold_italic) @markup.bold
(bold_italic) @markup.italic

(underline) @markup.underline
(strikethrough) @markup.strikethrough

(symbol) @string.special.symbol

(extension_inline) @function.macro
(mention) @constant
(tag) @tag

(insert) @markup.underline
(delete) @markup.strikethrough
(substitution) @markup.strikethrough
(editorial_comment) @comment

[
  (highlighted)
  (superscript)
  (subscript)
] @markup.raw

; Inline emphasis / verbatim / math delimiters
[
  (emphasis_begin)
  (emphasis_end)
  (bold_italic_begin)
  (bold_italic_end)
  (strong_begin)
  (strong_end)
  (underline_begin)
  (underline_end)
  (strikethrough_begin)
  (strikethrough_end)
  (superscript_begin)
  (superscript_end)
  (subscript_begin)
  (subscript_end)
  (highlighted_begin)
  (highlighted_end)
  (insert_begin)
  (insert_end)
  (delete_begin)
  (delete_end)
  (verbatim_marker_begin)
  (verbatim_marker_end)
  (math_marker)
  (math_marker_begin)
  (math_marker_end)
  (literal_marker)
  (literal_marker_begin)
  (literal_marker_end)
  (raw_inline_attribute)
  (raw_inline_marker_begin)
  (raw_inline_marker_end)
] @punctuation.delimiter

(math) @markup.raw
(verbatim) @markup.raw.inline
(raw_inline) @markup.raw.inline

; An inline literal (!`…`) captures its content verbatim like a code span, but
; renders as PROSE -- the <code> wrapper is dropped. So only its markers are
; styled (in the delimiter list above) and the node itself is deliberately left
; uncaptured, taking the default text style: giving it @markup.raw* would make
; it look like the code span it explicitly is not. Upstream's @none capture is a
; Neovim-ism and is dropped here, per the header note.

; --- Comments -----------------------------------------------------------------
[
  (comment_line)
  (fenced_comment_block)
  (comment)
  (inline_comment)
  (trailing_comment)
] @comment

(todo) @comment.warning
(note) @comment.note
(fixme) @comment.error

; --- Spans / attributes -------------------------------------------------------
(span
  ["[" "]"] @punctuation.bracket)

(inline_attribute
  ["{" "}"] @punctuation.bracket)

(block_attribute
  ["{" "}"] @punctuation.bracket)

[
  (class)
  (class_name)
] @type

(identifier) @tag

(key_value
  "=" @operator)
(key_value
  (key) @attribute)
(key_value
  (value) @string)

(boolean_attribute) @attribute

; --- Links / images -----------------------------------------------------------
(link_text
  ["[" "]"] @punctuation.bracket)

(autolink
  ["<" ">"] @punctuation.bracket)

(inline_link
  (inline_link_destination) @markup.link.url)

(link_reference_definition
  ":" @punctuation.special)

(full_reference_link
  (link_text) @markup.link.text)
(full_reference_link
  (link_label) @markup.link.label)
(full_reference_link
  ["[" "]"] @punctuation.bracket)

(collapsed_reference_link
  "[]" @punctuation.bracket)
(collapsed_reference_link
  (link_text) @markup.link.text)

(inline_link
  (link_text) @markup.link.text)

(full_reference_image
  (link_label) @markup.link.label)
(full_reference_image
  ["[" "]"] @punctuation.bracket)

(collapsed_reference_image
  "[]" @punctuation.bracket)

(image_description
  ["![" "]"] @punctuation.bracket)
(image_description) @markup.link.text

(link_reference_definition
  ["[" "]"] @punctuation.bracket)
(link_reference_definition
  (link_label) @markup.link.label)

(inline_link_destination
  ["(" ")"] @punctuation.bracket)

[
  (autolink)
  (inline_link_destination)
  (link_destination)
  (link_reference_definition)
] @markup.link.url

; --- Abbreviations ------------------------------------------------------------
(abbreviation_definition
  (abbreviation_marker) @punctuation.special)
(abbreviation_definition
  (abbreviation_expansion) @string)

; --- Footnotes ----------------------------------------------------------------
(footnote
  (reference_label) @markup.link.label)
(footnote_reference
  (reference_label) @markup.link.label)

[
  (footnote_marker_begin)
  (footnote_marker_end)
] @punctuation.bracket
