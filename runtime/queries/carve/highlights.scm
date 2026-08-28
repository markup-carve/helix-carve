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
; numbered scope; the leading marker gets @markup.heading.marker. The marker
; carries its whole separator RUN, so the level is matched rather than compared:
; a `##   h` marker is "##   " and an equality test against "## " lost its level.

(heading) @markup.heading

((heading
  (marker) @markup.heading.marker) @markup.heading.1
  (#match? @markup.heading.marker "^# +$"))

((heading
  (marker) @markup.heading.marker) @markup.heading.2
  (#match? @markup.heading.marker "^## +$"))

((heading
  (marker) @markup.heading.marker) @markup.heading.3
  (#match? @markup.heading.marker "^### +$"))

((heading
  (marker) @markup.heading.marker) @markup.heading.4
  (#match? @markup.heading.marker "^#### +$"))

((heading
  (marker) @markup.heading.marker) @markup.heading.5
  (#match? @markup.heading.marker "^##### +$"))

((heading
  (marker) @markup.heading.marker) @markup.heading.6
  (#match? @markup.heading.marker "^###### +$"))

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

; The colon fence's sigil family: `::: |`, `::: >` and `::: \`. Each opens a
; container whose body already carries its own color, so the sigil is the only
; character saying which one opened.
(line_block_marker) @punctuation.special
(block_quote_fence_marker) @punctuation.special
(local_hard_break_marker) @punctuation.special

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
  (braced_comment)
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

; A `.foo` in an attribute block, and the colon fence's TYPE WORD. The second
; used to be spelled `class_name` too, which is what the attribute rule is
; called - `admonition_type` is the construct the fence actually opens.
[
  (class)
  (admonition_type)
] @type

; --- Composite figures --------------------------------------------------------
; PART 9 4c (markup-carve/carve#1215). The kind word `figure` is RESERVED among
; the `:::` types: a BARE opener - the fence, its separator, the word, and
; nothing else - is one figure of ordered panels, not an admonition. An opener
; carrying a quoted title or a `[label]` is not that production and keeps the
; generic `@type` above.
;
; ONE PATTERN OVER ONE NODE. This used to be four: a pattern over the type word
; with `!title !label` predicates, plus three wildcard chains restoring `@type`
; on a bare opener nested inside a group, because a query has no transitive
; closure and GROUPS DO NOT NEST at any depth. The chains reached three levels,
; and a bare opener deeper than that kept the group color. The grammar now
; reads its own open-block stack, so a bare opener inside an open group is an
; `admonition_type` in the TREE and no query reconstructs the ancestry.
;
; The group caption needs no rule. It is an ordinary `^ ` line one line below
; the closing fence, and the grammar places it as a SIBLING of the container
; rather than inside it, where the `(caption)` patterns above already claim it.
;
; PRECEDENCE IS ORDER HERE, not `(#set! priority N)`. This file carries no
; `#set!` directive, and neither does any bundled query in Helix 25.07, because
; Helix layers overlapping captures in the order they are written so the later
; one patches over the earlier - which is what already makes `@markup.heading.1`
; win over the `(heading) @markup.heading` above it. Keep any new pattern in
; this block below the generic `@type` above.
(figure_group_marker) @type.builtin

(identifier) @tag

(key_value
  "=" @operator)
(key_value
  (key) @attribute)
(key_value
  (value) @string)

(boolean_attribute) @attribute

; The language attribute: `{:fr}`, `{:zh-Hant}` (markup-carve/carve#1114).
(language_attribute) @attribute

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

; A cross-reference with auto text is a LINK but not a URL: `</#Intro>` carries
; a heading id the renderer resolves to the target's own text, so it takes
; @markup.link.text rather than the @markup.link.url above. It used to parse as
; an autolink and take that capture, which colored a crossref as a web address.
(auto_text_link) @markup.link.text

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

; An inline note, `^[content]`. Its content is ordinary inline and highlights
; itself, so this marks the note as a whole - where it ends is the thing the
; construct is easy to get wrong about, and a tree dump is the only other place
; that shows it.
(inline_note) @markup.link.label

[
  (footnote_marker_begin)
  (footnote_marker_end)
] @punctuation.bracket
