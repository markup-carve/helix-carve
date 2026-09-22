/**
 * What `runtime/queries/carve/highlights.scm` actually paints.
 *
 * CI already asks the tree-sitter CLI whether each query compiles, and parses
 * every sample. Neither can see which of two overlapping patterns an editor ends
 * up showing, and a query file is not a list of independent facts: several
 * patterns claim the same node, and only one color reaches the screen. A pattern
 * that never wins is indistinguishable from a pattern that is not there, and
 * both stay green under a compile check alone.
 *
 * RESOLUTION RULE. Helix layers overlapping captures in the order they are
 * written, the later one patching over the earlier - which is what already makes
 * `@markup.heading.1` win over the `(heading) @markup.heading` line above it in
 * this file. Helix 25.07 ships no `(#set! priority N)` in any of its own bundled
 * queries and this file drops every `#set!` directive, so order is the whole
 * rule. This script resolves the same way: at a given start position, the last
 * capture that names a color is the winner. Upstream tree-sitter-carve writes
 * the same outcome with explicit priorities, and the two orders agree, which is
 * what makes the port faithful.
 *
 * Run it from a built checkout of the grammar revision pinned in
 * `languages.toml`, the way the workflow does, so the queries are checked
 * against the grammar this configuration actually ships against:
 *
 *   TS_CWD=/path/to/tree-sitter-carve node scripts/highlight-captures.mjs
 *
 * Environment:
 *   TS_CLI  command that runs the tree-sitter CLI, split on spaces.
 *           Default `tree-sitter`.
 *   TS_CWD  directory to run it from. tree-sitter resolves the language from
 *           the working directory, so this is the built grammar checkout.
 *           Default: the current directory.
 */
import { spawnSync } from 'node:child_process';
import { mkdtempSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join, resolve, basename } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const QUERY = resolve(__dirname, '../runtime/queries/carve/highlights.scm');

/*
 * Captures that are not a COLOR. This file drops Neovim's `@spell`, `@nospell`,
 * `@none` and the conceal directives, so the set is empty in practice - it is
 * here so that reintroducing one does not silently become the answer to every
 * case below, which is what happened upstream.
 */
const NOT_A_COLOR = new Set(['none', 'conceal', 'spell', 'nospell']);

/*
 * Composite figures (PART 9 4c, markup-carve/carve#1215). Each case names the
 * node by where it starts, because the whole point is which of two
 * same-looking kind words gets which color.
 */
const CASES = [
    {
        name: 'a bare figure opener is a composite figure',
        source: '::: figure\n![one](a.png)\n^ (a) One\n:::\n^ Figure #: Group caption\n',
        at: [0, 4],
        expect: 'type.builtin',
    },
    {
        name: 'a quoted title keeps it a generic container',
        source: '::: figure "A titled figure div"\nx\n:::\n^ Not a group caption\n',
        at: [0, 4],
        expect: 'type',
    },
    {
        name: 'a [label] keeps it a generic container',
        source: '::: figure [g]\nx\n:::\n',
        at: [0, 4],
        expect: 'type',
    },
    {
        name: 'the outer opener of a nested pair is the group',
        source: '::: figure\n:::: figure\nx\n::::\n:::\n',
        at: [0, 4],
        expect: 'type.builtin',
    },
    {
        name: 'the inner opener of a nested pair is a generic container',
        source: '::: figure\n:::: figure\nx\n::::\n:::\n',
        at: [1, 5],
        expect: 'type',
    },
    {
        name: 'a bare opener one container deep inside a group is generic',
        source: '::: figure\n:::: note\n::::: figure\nx\n:::::\n::::\n:::\n',
        at: [2, 6],
        expect: 'type',
    },
    {
        name: 'a bare opener inside a quote inside a group is generic',
        source: '::: figure\n> quoted\n>\n> :::: figure\n> x\n> ::::\n:::\n',
        at: [3, 7],
        expect: 'type',
    },
    {
        name: 'a bare opener inside a list item inside a group is generic',
        source: '::: figure\n- item\n\n  :::: figure\n  x\n  ::::\n:::\n',
        at: [3, 7],
        expect: 'type',
    },
    {
        name: 'the intervening container itself keeps its own capture',
        source: '::: figure\n:::: note\n::::: figure\nx\n:::::\n::::\n:::\n',
        at: [1, 5],
        expect: 'type',
    },
    {
        name: 'a group inside another container kind is still a group',
        source: '::: note\n:::: figure\nx\n::::\n:::\n',
        at: [1, 5],
        expect: 'type.builtin',
    },
    {
        name: 'another kind word is a generic container',
        source: '::: note\nx\n:::\n',
        at: [0, 4],
        expect: 'type',
    },
    {
        name: 'the group caption after the closing fence is a caption',
        source: '::: figure\nx\n:::\n^ Figure #: Group caption\n',
        at: [3, 2],
        expect: 'markup.italic',
    },
    /*
     * The separator is a SPACE run and never a tab (grammar PART 7). A tab makes
     * the line a paragraph, so there is no `class_name` to color at all, and the
     * composite-figure pattern must not reach it.
     */
    {
        name: 'a tab after the fence is a paragraph, not a figure opener',
        source: ':::\tfigure\nx\n:::\n',
        at: [0, 4],
        expect: null,
    },
    /*
     * Both controls exist because a resolver that always answered `type.builtin`
     * and one that always answered null would each pass some of the rows above
     * without reading anything.
     */
    {
        name: 'control: plain prose has no color at all',
        source: 'plain prose\n',
        at: [0, 0],
        expect: null,
    },
    {
        name: 'control: a bare figure inside no group is not restored to generic',
        source: ':::: figure\nx\n::::\n',
        at: [0, 5],
        expect: 'type.builtin',
    },

    /*
     * WHAT THE GRAMMAR BUMP BROUGHT. Each row is a node the pinned grammar did
     * not have before, so each is a capture this file could not have carried -
     * and four of the five are constructs whose CONTENT already colors itself,
     * which is what makes an absent capture look like a working one.
     */
    {
        // The node starts at the brace - `(braced_comment [0, 2] - [0, 20])`
        // for the source below. Before 0.1.6 it began at the space in front.
        name: 'a braced comment is a comment',
        source: 'a {% not bold *b* %} z\n',
        at: [0, 2],
        expect: 'comment',
    },
    {
        name: 'a crossref with auto text is link text, not a URL',
        source: '# Intro\n\nsee </#intro>\n',
        at: [2, 4],
        expect: 'markup.link.text',
    },
    {
        name: 'an inline note is painted whole',
        source: 'x ^[a note] c\n',
        at: [0, 2],
        expect: 'markup.link.label',
    },
    {
        name: 'the line block sigil is painted',
        source: '::: |\na\n:::\n',
        at: [0, 4],
        expect: 'punctuation.special',
    },
    {
        name: 'the fenced block quote sigil is painted',
        source: '::: >\na\n:::\n',
        at: [0, 4],
        expect: 'punctuation.special',
    },
    {
        name: 'the local hard-break sigil is painted',
        source: '::: \\\na\n:::\n',
        at: [0, 4],
        expect: 'punctuation.special',
    },

    /*
     * THE TWO MARKERS THE PORT DROPPED. A definition list is two markers, not
     * one, and the `+` continuation is a list marker that opens no item - so
     * both look like ordinary prose when their capture is missing, which is
     * how they went unnoticed while every other list marker was covered.
     */
    {
        name: "a definition list's description marker is painted",
        source: ':: Term\n: The description.\n',
        at: [1, 0],
        expect: 'markup.list.numbered',
    },
    {
        name: 'the list continuation marker is painted',
        source: '- item\n+\nan attached block\n',
        at: [1, 0],
        expect: 'markup.list',
    },

    /*
     * THE RESERVED INCLUDE DIRECTIVE (PART 9 SS19, markup-carve/carve#291).
     * The two rows that matter are the NEGATIVE ones: before the grammar knew
     * the shape, `#section` parsed as a tag and an option slot as a mention, so
     * the selector of a construct the core leaves literal was painted as two
     * unrelated inline constructs. Both now have to resolve to the directive's
     * own colors, and a row asserting only the path would pass with the old
     * grammar's tag still on screen.
     */
    {
        name: 'the include directive opens with its own punctuation',
        source: 'See {{ chapters/intro.crv #intro }} here.\n',
        at: [0, 4],
        expect: 'punctuation.special',
    },
    {
        name: "the include directive's path is a path",
        source: 'See {{ chapters/intro.crv #intro }} here.\n',
        at: [0, 7],
        expect: 'string.special.path',
    },
    {
        name: 'the section selector is a label, NOT a tag',
        source: 'See {{ chapters/intro.crv #intro }} here.\n',
        at: [0, 26],
        expect: 'label',
    },
    {
        name: 'an option name is a parameter, NOT a mention',
        source: 'See {{ ch.crv @level:2 }} here.\n',
        at: [0, 14],
        expect: 'variable.parameter',
    },
    {
        name: "an option's value is a constant",
        source: 'See {{ ch.crv @level:2 }} here.\n',
        at: [0, 21],
        expect: 'constant',
    },
    /*
     * The glued selector is the canonical spelling in section 19, and it is a
     * different token run in the grammar - so it is a separate row, not the
     * same one with a space removed.
     */
    {
        name: 'a glued selector is still a section, not a tag',
        source: 'See {{ chapters/intro.crv#intro }} here.\n',
        at: [0, 25],
        expect: 'label',
    },
    /*
     * Control: a `#tag` that is NOT inside a directive keeps the tag color, so
     * the rows above cannot pass by the tag pattern having been deleted.
     */
    {
        name: 'control: a tag outside a directive is still a tag',
        source: 'See #intro here.\n',
        at: [0, 4],
        expect: 'tag',
    },
];

const dir = mkdtempSync(join(tmpdir(), 'helix-carve-captures-'));
try {
    const paths = CASES.map((testCase, index) => {
        const path = join(dir, `case-${String(index).padStart(2, '0')}.crv`);
        writeFileSync(path, testCase.source);
        return path;
    });

    const cli = (process.env.TS_CLI ?? 'tree-sitter').split(' ').filter(Boolean);
    const args = [...cli.slice(1), 'query', '--captures', QUERY, ...paths];
    const run = spawnSync(cli[0], args, {
        cwd: process.env.TS_CWD || process.cwd(),
        encoding: 'utf8',
        maxBuffer: 64 * 1024 * 1024,
    });

    if (run.status !== 0) {
        console.log(`highlight captures: the query did not run (exit ${run.status})`);
        console.log(run.stdout ?? '');
        console.log(run.stderr ?? '');
        process.exit(1);
    }

    /*
     * `--captures` prints one line per source file, then one indented line per
     * capture in the order an editor would receive them.
     *
     * A file header is recognized by matching a path that was actually passed,
     * NOT by "this line is not indented". A capture's text is printed inline and
     * a capture spanning a newline therefore breaks its own line, leaving the
     * closing backtick alone in column 0 - which the indentation test read as
     * the start of another file and dropped every later capture into a bucket
     * nothing looked up. That is exactly the blockquote case here, and it
     * reported a real pattern as not matching.
     */
    const pending = new Set(paths);
    const byFile = new Map();
    let current = null;
    for (const line of run.stdout.split('\n')) {
        const candidate = line.trim();
        if (pending.has(candidate)) {
            pending.delete(candidate);
            current = basename(candidate);
            byFile.set(current, []);
            continue;
        }
        const match = /capture:\s*\d+\s*-\s*([\w.]+),\s*start:\s*\((\d+),\s*(\d+)\)/.exec(line);
        if (match && current) {
            byFile.get(current).push({ name: match[1], row: Number(match[2]), column: Number(match[3]) });
        }
    }

    const fails = [];
    CASES.forEach((testCase, index) => {
        const file = basename(paths[index]);
        const captures = byFile.get(file);
        if (!captures) {
            fails.push(`FAIL ${testCase.name}\n   the query printed nothing for ${file}`);
            return;
        }
        const [row, column] = testCase.at;
        const winner = captures
            .filter((capture) => capture.row === row && capture.column === column)
            .filter((capture) => !capture.name.startsWith('_') && !NOT_A_COLOR.has(capture.name))
            .at(-1);
        const got = winner ? winner.name : null;
        if (got !== testCase.expect) {
            fails.push(
                `FAIL ${testCase.name}\n   at ${row}:${column} the winning capture is ${got}, expected ${testCase.expect}`,
            );
        }
    });

    if (fails.length) {
        console.log(`highlight captures: ${fails.length} of ${CASES.length} failing`);
        for (const failure of fails) console.log(failure);
        process.exit(1);
    }

    console.log(`highlight captures: ${CASES.length} shapes resolve as expected`);
} finally {
    rmSync(dir, { recursive: true, force: true });
}
