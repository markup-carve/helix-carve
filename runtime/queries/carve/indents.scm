; Carve indents for Helix.
; Helix uses @indent / @outdent captures (not Neovim's @indent.auto / .begin).
; Carve is a markup language, so indentation is largely content-driven; we only
; treat block containers that nest content as indent scopes, which keeps new
; lines inside list items, divs, and quotes aligned with their parent.

[
  (list_item)
  (div)
  (block_quote)
  (footnote)
] @indent
