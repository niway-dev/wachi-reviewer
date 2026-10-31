# Multi-language risk map: how to get definitions, references and import edges

Date: 2026-10-31. Scope: Rust, Go, Java, Kotlin, Swift, (Python), on a GitHub Actions
ubuntu runner, under ADR 0002 (zero runtime deps). Read-only research. Items marked
**[UNVERIFIED]** were not checked (no Linux runner available; some come from memory).

## 1. Bottom line

- Recommended: **(a) as the default, plus (c) as an opt-in upgrade.** Zero-dep
  `git grep -nw` for references in every language, `Bun.Transpiler.scan()` for JS/TS
  import/export edges, and vendored tree-sitter WASM grammars (via `web-tree-sitter`
  pinned to 0.25.x) only to get definitions and import edges for the other languages.
- Semantic references (type-aware) for Rust/Go/Java/Kotlin/Swift need a build or an
  indexer. None is zero-cost. Not worth it for a "risk map" feeding an LLM reviewer.
- Verified that `web-tree-sitter` 0.25.10 loads and parses Go, Rust, Java, Kotlin, Swift
  and Python grammars under Bun 1.4.2 (details in section 5). Verified that the newest
  `web-tree-sitter` 0.27.1 does NOT load the community prebuilt grammars.

## 2. Per-language native tooling on a runner (nothing extra installed)

Runner image: Ubuntu 24.04, image version 20261026.354.1. Source:
https://github.com/actions/runner-images/blob/main/images/ubuntu/Ubuntu2404-Readme.md
(downloaded raw and grepped locally).

| Language | Preinstalled on runner (from readme) | Imports | Symbols | References |
|---|---|---|---|---|
| Go | Go 1.24.13 / 1.25.14 / 1.26.10 (cached tools; needs `setup-go` or PATH) | `go list -json -deps` (package level, needs module download) | `go doc -all pkg` (exported only) | none without gopls. `gopls` not listed **[UNVERIFIED that it is absent]** |
| Rust | Rust/Cargo 1.99.1, Rustup 1.29.2, Rustfmt, Clippy | `cargo metadata` = crate deps only, not `use` edges | none stable (`rustc -Zunpretty` is nightly) | none. `rust-analyzer` is a rustup component, not listed as installed **[UNVERIFIED]** |
| Java | JDK 8/11/17(default)/21/25, Maven 3.10.0, Gradle 9.8.2 | `javac` needs a compile; `javap` reads .class files | `javap` (post-compile only) | none |
| Kotlin | Kotlin 2.4.21 (kotlinc) | none standalone | none standalone | none. Compiler is slow and needs the classpath |
| Swift | Swift 6.4.1 | `swiftc -dump-ast` (needs the module to type-check) | `swift symbolgraph-extract` (needs a build) **[UNVERIFIED]** | IndexStore after `swift build` **[UNVERIFIED]** |
| Python | 3.12.3 system + cached 3.11 to 3.15 | stdlib `ast` module: imports, defs, usages by name | `ast` | name-based only (no semantic) |

Takeaway: the native tools are either package-level (imports only) or require a full
build/dependency download. None gives file:line references cheaply or reliably on a
PR checkout. Python `ast` is the only genuinely cheap native parser, and it needs
`python3` (present).

## 3. Cross-language tools

Repo facts from `gh api` on 2026-10-31 (license, archived, last push, stars).
Release asset sizes from the GitHub releases API for the latest tag.

| Tool | Languages | Output | Size (linux x86_64) | CI install cost | License | Health | Pin by SHA? |
|---|---|---|---|---|---|---|---|
| ripgrep | any text | textual matches, file:line | 2 MB (musl tarball, 15.2.0) | ~1 s download | Unlicense | very active (push 2026-10-27) | yes (release asset + published .sha256) |
| universal-ctags | ~150 incl. Go, Rust, Java, Kotlin, Swift, Python | **definitions only** (tags: name, file, line, kind); no references; limited imports | no official Linux binary in releases (v6.2.1, 2025-10-25); apt `universal-ctags` or build from source | apt ~5-10 s **[UNVERIFIED]** | GPL-2.0 | active (push 2026-10-29) | source tag SHA yes; apt version pinning only by package version |
| tree-sitter CLI | grammar-based, any | parse trees, `tree-sitter query` (tags.scm gives defs + refs by name); needs grammars cloned/compiled | large (tens of MB, **[UNVERIFIED]**) | grammar compile needs a C compiler | MIT | very active | release asset yes |
| web-tree-sitter (WASM) | any grammar with a .wasm | full syntax tree in-process; queries | runtime `web-tree-sitter.wasm` 210 KB (0.27.1) plus the JS glue; grammars 0.2 to 4 MB each | 0 s (vendored) | MIT | active | vendored file = pinned by git SHA |
| ast-grep (`sg`/`ast-grep`) | built-in JS/TS, Go, Rust, Java, Kotlin, Swift, Python and more (**language list from memory, UNVERIFIED**) | structural match of patterns, JSON output with file/line/range | 8 MB zip (0.51.0, 2026-10-15) | ~2 s download | MIT | very active (push 2026-10-31, 16k stars) | release asset yes; checksums **[UNVERIFIED]** |
| Semgrep | many, includes all targets | pattern findings; not a symbol index. Cross-file call graph is paid (Pro) **[UNVERIFIED]** | pip package, large (hundreds of MB, **[UNVERIFIED]**) | 20-60 s via pip **[UNVERIFIED]** | LGPL-2.1 engine; rules have their own licenses | very active (v1.183.0, 2026-10-29) | pip hash pins yes |
| SCIP indexers | per language, semantic | full defs + refs + imports, protobuf `index.scip` | scip-typescript, scip-go, scip-java; Rust via `rust-analyzer scip` | needs a working build/type-check: minutes | Apache-2.0 | active (scip-go push 2026-10-22, scip-java 2026-10-30) | yes (versions / SHAs); Swift indexer: none known **[UNVERIFIED]**; Kotlin only via scip-java with Gradle/Maven |
| GitHub code navigation (stack-graphs) | tree-sitter + stack graphs | precise-ish name resolution | n/a | n/a | Apache-2.0 | **repo archived** (last push 2025-09-09). Not usable as a dependency | n/a |

Notes:
- ctags is the cheapest "where is this symbol defined" tool, but it adds a GPL-2.0
  binary and an apt step. tree-sitter WASM gives the same definitions plus import
  nodes, with no external binary.
- ast-grep is the best single binary if we accept one pinned download: one tool,
  many languages, JSON output, but it matches patterns, so we would write a pattern
  per language and construct (function, class, import) ourselves.
- SCIP gives true semantic references but only if the project builds; PR checkouts of
  arbitrary repos often do not (missing deps, private registries). Too fragile for
  a deterministic CI pre-step.

## 4. Is anything preinstalled on ubuntu-latest?

Source: raw `Ubuntu2404-Readme.md`, image 20261026.354.1. A case-insensitive grep for
`ripgrep|ctags|tree-sitter|ast-grep|semgrep` returned **no matches**. Not listed:
ripgrep, universal-ctags, tree-sitter, ast-grep, Semgrep, Bun.

Caveats:
- The readme lists tools the image team chooses to document. It is not a full `dpkg`
  dump, so a binary could exist undocumented. I could not run a runner to check
  `which rg`. **[UNVERIFIED on a live runner]**
- Announcement in the same readme: `ubuntu-latest` moves to Ubuntu 26.04 in
  November 2026. Tool inventory may change; re-check
  https://github.com/actions/runner-images/blob/main/images/ubuntu/Ubuntu2604-Readme.md
  before relying on it **[not fetched]**.
- `git` 2.56.0 and Node 22 are listed, so `git grep` is guaranteed. Python 3.12.3,
  Go, Rust, JDKs, Kotlin and Swift are listed, so native parsers exist in principle.

## 5. Empirical checks (all run locally on macOS, Bun 1.4.2, Apple Silicon)

### 5a. Zero-dep baseline on the kaipu clone (`/tmp/kaipu-mine/repo`, 2084 tracked files)

Script: `/tmp/refscan/scan2.ts` (and `scan.ts` for the working tree). It calls
`new Bun.Transpiler({loader}).scan(src)` and `git -C repo grep -nw <symbol>`.

Important finding: **`markCopySeen` does not exist at HEAD (5e464c9f)** (0 matches
with `-w`, 0 with case-insensitive substring). It was added in history by commits
3d1ae697 / 17ba43b1 and later removed or renamed. So I ran against 3d1ae697, which
is also the realistic "symbol added by a PR" case.

| Target | Rev | Scan time | Imports / exports | Symbol | Refs | Files | grep time |
|---|---|---|---|---|---|---|---|
| `main/library/index.ts` | 3d1ae697 | 23 ms (cold) | 20 / 6 | `markCopySeen` | 14 | 6 | 24 ms |
| same | 3d1ae697 | | | `startFileDrag` | 12 | 10 | 23 ms |
| same | HEAD | 15 ms | 15 / 7 | `startFileDrag` | 11 | 8 | 22 ms |
| same | HEAD, working tree, no path filter | 5 ms | 15 / 7 | `startFileDrag` | 15 | 11 | 51 ms |

- Unfiltered `git grep -nw` also hits Markdown docs (audit and spec files) in the
  15-hit run; restricting to `'*.ts' '*.tsx'` removed 4 doc hits. A path filter by
  language extension is needed.
- At HEAD, `startFileDrag` references include: definition type
  (`shared/types/electron-api.ts:291`), channel constant (`shared/types/ipc.ts:450`),
  handler (`main/library/index.ts:202`), preload bridge, 2 renderer call sites, a
  test spy and a test setup stub. That is useful for a reviewer, but textual:
  it cannot tell the IPC channel key from the API method with the same name.
- Cost: tens of milliseconds per symbol on 2k files. For 50 symbols that is ~1 s.
  Not a bottleneck.

### 5b. web-tree-sitter under Bun (`/tmp/refscan/w25`, `/tmp/refscan/wts`)

Parsed one tiny snippet with an import and a recursive call per language, using
prebuilt grammars downloaded from `tree-sitter-wasms@0.1.13` (unpkg).

| Combination | Result |
|---|---|
| `web-tree-sitter@0.27.1` + `tree-sitter-wasms@0.1.13` grammars | **FAIL** for all 6: `Language.load` throws an empty `Error` in `getDylinkMetadata` (WASM dynamic-link metadata mismatch between toolchains) |
| `web-tree-sitter@0.25.10` + same grammars | **OK** for Go, Rust, Java, Kotlin, Swift, Python (`hasError=false`, 1-12 ms load+parse each) |

Grammar sizes (wasm): go 236 KB, python 476 KB, java 430 KB, rust 819 KB,
swift 3.1 MB, kotlin 4.1 MB, typescript 2.3 MB. Six non-TS grammars total ~9.1 MB.
`web-tree-sitter` 0.25 package plus its wasm: ~0.2 MB runtime (0.27.1 wasm is
210 KB; 0.25.10 size not measured).

Caveats: (1) The package `tree-sitter-wasms` is 51.8 MB unpacked, and the
`@vscode/tree-sitter-wasm` alternative is 22 MB; we would copy only needed `.wasm`
files. (2) The Bun auto-install ran once and put `web-tree-sitter@0.27.1` into
`~/.bun/install/cache` as a side effect of my test import; nothing global or in any
repo was modified. (3) The runtime itself is an npm package, which touches ADR 0002
if "zero runtime dependencies" counts vendored files; vendoring the JS glue plus
wasm into the repo (pinned, license MIT) is the way to keep `package.json` clean.
(4) I did not run the tags/queries (definitions, call sites) over real source, only
confirmed parse works. Query authoring per language is the real work. **[NOT BUILT]**
(5) Whether the action's bundle step (single-file build) can embed/locate the
`.wasm` files next to the bundle was not tested.

## 6. Design options compared

| | (a) Zero-dep | (b) One pinned binary (ast-grep) | (c) Vendored tree-sitter WASM |
|---|---|---|---|
| Languages | JS/TS import/export edges via Bun; all others textual only | JS/TS, Go, Rust, Java, Kotlin, Swift, Python | same set, any grammar we vendor |
| Definitions | JS/TS: exports from `scan()`. Others: regex heuristics (`func X`, `fn x`, `class X`) | pattern per construct, structural | syntax-tree queries per language, accurate for declarations |
| Import edges | JS/TS only | pattern per language (`import ...`, `use ...`) | tree queries, accurate syntax; path resolution still ours |
| References | textual `git grep -nw` (word match, no scoping) | still pattern/name based | same textual precision as (a) unless we add scope logic; a tree walk removes hits in comments and strings |
| Precision | low-medium, noisy on common names | medium | medium-high for syntax, still not semantic |
| CI time | ~0 s + ~20-50 ms per symbol (measured) | ~2 s download + scan **[estimated]** | ~0 s (vendored); parse ms per file (measured 1-12 ms on toy files) |
| Added size | 0 | 8 MB binary fetched at runtime (not in repo) | ~0.2 MB runtime + 0.2 to 4 MB per grammar vendored in the repo (Kotlin and Swift are the big ones) |
| ADR 0002 fit | perfect | breaks "zero dependency" in spirit (external binary, supply chain; mitigated by SHA pin + checksum) | borderline: vendored third-party code, no runtime install |
| Maintenance | lowest | pattern syntax changes across ast-grep releases | grammar/runtime version pairing is fragile (0.27.1 failed with the grammars tested) |

## 7. Recommendation

1. Ship (a) now for all languages: JS/TS via `Bun.Transpiler.scan()`; everything else
   via `git grep -nw` limited to the language's extensions and with a skip of
   comment-only hits not attempted. Output shape stays identical across languages,
   with a field `precision: "textual" | "parsed"`.
2. Add (c) only for definition and import extraction in Go, Rust, Java, Python first
   (small grammars: 0.2 to 0.8 MB), then Swift and Kotlin if the size is acceptable.
   Pin `web-tree-sitter` at 0.25.x and vendor the grammar `.wasm` files with a
   checksum list.
3. Skip SCIP, Semgrep and ctags: SCIP needs a successful build, Semgrep is heavy,
   ctags adds a GPL binary and gives definitions only.

Why: the reviewer is an LLM that reads the code anyway. It needs a candidate list of
callers and importers, with counts, not a proof of semantic binding. Textual refs cost
20-50 ms and no new supply chain.

### Strongest argument against

Textual references are wrong exactly where the risk map matters most: common names
(`get`, `run`, `Handler`, `New`), overloads, methods with the same name on different
types, re-exports, and Kotlin/Swift extensions. Reference counts then mislead: a
count of 40 may be 3 real callers, and a true caller through an alias or trait
dispatch (Rust, Java interfaces) is invisible. A wrong "blast radius" number could
steer the reviewer worse than none. The honest counter-design is (b)+(c) with scope
awareness or an opt-in SCIP step for languages whose build already runs in the
consumer's CI; the cost is complexity and a build prerequisite. Mitigation inside
(a): label the field "textual", cap and rank hits, and drop hits inside comments
and strings once tree-sitter is available.

## 8. Not verified (summary)

- Absence of `rg`, `ctags`, `tree-sitter` on a live runner (only the published readme
  checked); Ubuntu 26.04 inventory.
- ast-grep language list and checksum availability; Semgrep and tree-sitter CLI
  sizes and install time; universal-ctags apt install time.
- `gopls` / `rust-analyzer` presence on the runner; Swift IndexStore and symbolgraph
  behavior; SCIP indexer behavior on a PR checkout.
- tree-sitter query output (definitions, calls) per language; bundling `.wasm` into
  the action; `web-tree-sitter` 0.25.10 wasm size.
- Test files: `/tmp/refscan/scan.ts`, `scan2.ts`, `wts/p.ts` (throwaway).
