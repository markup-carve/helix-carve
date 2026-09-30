#!/usr/bin/env sh
# Compare the languages.toml grammar pin against tree-sitter-carve main.
#
# Called from both the scheduled drift job and the pull-request gate: a
# schedule-only check can go red for a week without any pull request showing
# it, which is how the pin sat 32 commits behind while every gate was green.
#
# Usage: check-grammar-pin.sh <tree-sitter-carve checkout> [rev override]
set -eu

grammar_dir="${1:?usage: check-grammar-pin.sh <grammar checkout> [rev]}"
rev="${2:-}"

if [ -z "${rev}" ]; then
  rev="$(grep -oE 'tree-sitter-carve[^0-9a-f]*rev *= *"[0-9a-f]{40}"' languages.toml | grep -oE '[0-9a-f]{40}' | head -1)"
fi

if [ -z "${rev}" ]; then
  echo "::error::languages.toml: the [[grammar]] source has no 40-hex rev"
  exit 1
fi

if ! git -C "${grammar_dir}" cat-file -e "${rev}^{commit}" 2>/dev/null; then
  echo "::error::the grammar pins ${rev}, which is not a commit in markup-carve/tree-sitter-carve"
  exit 1
fi

if ! git -C "${grammar_dir}" merge-base --is-ancestor "${rev}" origin/main; then
  echo "::error::grammar ${rev} is not on main, so the pin came from an unmerged or rewritten branch"
  exit 1
fi

behind="$(git -C "${grammar_dir}" rev-list --count "${rev}..origin/main")"
echo "grammar pin: ${rev} ($(git -C "${grammar_dir}" log -1 --format=%s "${rev}"))"
echo "tree-sitter-carve main is ${behind} commit(s) ahead"

if [ "${behind}" -gt 0 ]; then
  echo "::error::the grammar pin ${rev} is ${behind} commit(s) behind tree-sitter-carve main $(git -C "${grammar_dir}" rev-parse origin/main); re-vendor the grammar"
  exit 1
fi
