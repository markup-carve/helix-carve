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
