; Carve textobjects for Helix.
; Adapted from tree-sitter-carve's queries/textobjects.scm.
; Helix uses the .inside / .around suffixes (not Neovim's .inner / .outer) and
; supports a fixed set of textobject kinds: function, class, parameter, comment,
; test, entry. Only those that map sensibly onto Carve are kept.

; Classes: the highest structural level.
(thematic_break) @class.around

(section
  (section_content) @class.inside) @class.around

; Functions: the next level (headings, divs, quotes, code/raw blocks, lists,
; tables, footnotes).
(heading
  (content) @function.inside) @function.around

(div
  (content) @function.inside) @function.around

(block_quote
  (content) @function.inside) @function.around

(code_block
  (code) @function.inside) @function.around

(raw_block
  (content) @function.inside) @function.around

(list
  (_) @function.inside) @function.around

(table
  (_) @function.inside) @function.around

(footnote
  (footnote_content) @function.inside) @function.around

; Entries: list items and table cells.
(list_item
  (list_item_content) @entry.inside) @entry.around

(table_row) @entry.around

[
  (table_cell_alignment)
  (table_cell)
] @entry.inside

; Parameters: attribute pieces and the inside of inline emphasis spans.
(block_attribute
  (args) @parameter.inside) @parameter.around

(inline_attribute
  (args) @parameter.inside) @parameter.around

(emphasis
  (content) @parameter.inside) @parameter.around

(strong
  (content) @parameter.inside) @parameter.around

(bold_italic
  (content) @parameter.inside) @parameter.around

(underline
  (content) @parameter.inside) @parameter.around

(strikethrough
  (content) @parameter.inside) @parameter.around

(verbatim
  (content) @parameter.inside) @parameter.around

[
  (key)
  (value)
] @parameter.inside

; Comments.
(comment
  (content) @comment.inside) @comment.around
