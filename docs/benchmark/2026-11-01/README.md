# Replay 2026-11-01: Wachiman v1.3.0, three runs on the five field-benchmark PRs

- **What:** the five kaipu-record PRs of the [2026-10-31 field benchmark](../2026-10-31/README.md),
  replayed in [kaipu-bench-wachi](https://github.com/niway-dev/kaipu-bench-wachi) at the same
  base and head commits, reviewed three times each by Wachiman **v1.3.0** (same review prompt as
  v1.2.0; phase-0 fixes, brand header and aliases only). Claude Opus 5.5, on demand via
  `/wachi review`, whole PR, all files reviewed in all 15 runs.
- **Why:** before judging any improvement, measure how much one run differs from another.
- **Status of the findings:** the live findings were verified against the code on 2026-10-31. The
  replay findings are **not verified yet**; counts below are what was posted.
- **Other reviewers on the same five PRs:** Pullfrog and CodeRabbit sections below.
- **PRs:** round 1 [#1–#5](https://github.com/niway-dev/kaipu-bench-wachi/pulls?q=is%3Apr+label%3Areplay),
  round 2 #6–#10 (`head-r2` branches), round 3 #11–#15 (`head-r3`), each branch on the same
  commit so the engine sees a fresh PR (it does not re-review a head it already marked).
  Raw review bodies and inline comments: [raw/](raw/).

## Per run

| kaipu PR | Live 10-31 (v1.2.0) | Run 1 | Run 2 | Run 3 |
| --- | --- | --- | --- | --- |
| #463 | 4 · $0.62 | 3 · $0.63 | 4 · $0.59 | 3 · $0.63 |
| #464 | 1 · $0.36 | 1 · $0.51 | 2 · $0.49 | 1 · $0.54 |
| #465 | 2 · $0.48 | 2 · $0.52 | 3 · $0.50 | 4 · $0.57 |
| #466 | 2 · $0.46 | 3 · $0.58 | 2 · $0.53 | 2 · $0.59 |
| #467 | 8 · $1.36 | 6 · $1.56 | 4 · $1.48 | 7 · $1.84 |
| **Total** | **17 · $3.28** | **15 · $3.80** | **15 · $3.59** | **17 · $4.17** |

Zero invalid findings were found in the live set; the replay findings await the same check.

## Stability: how often each distinct finding appeared in four runs (live + 3 replays)

30 distinct findings across the four runs. 6 appeared every time, 12 appeared once.

| kaipu PR | Finding | Topic | Runs (of 4) |
| --- | --- | --- | --- |
| #463 | Late-frame "dropped and closed" path never tested | tests | **4** |
| #463 | "off" comment says it waits on the queue; it does not | docs | 3 |
| #463 | `releaseAll` JSDoc now sits on `releaseWebcam` | docs | 3 (never live) |
| #463 | **Camera cannot reopen → face recorded nowhere** (fixed live in `b0f028c`) | bug | 2 (live, run 2) |
| #463 | Hub-reset test name only exercises abort | tests | 2 |
| #464 | Pill `aria-label` hides the progressbar (Pullfrog's live finding) | a11y | 2 (runs 1, 3) |
| #464 | Ready cards retired before anyone saw them (list view, filter) | bug | 1 (live) |
| #464 | Copy loses Edit/Prepare/Tags/Delete while its ready card shows | bug | 1 (run 2) |
| #464 | "…and forgets it" test never checks the forget | tests | 1 |
| #465 | Drag test replaces the shared `electronAPI` stub and never restores it | tests | **4** |
| #465 | "Open in Export" test never checks the absent case | tests | **4** |
| #465 | Unreadable file leaves every card's size at "…" | bug | 1 (run 2) |
| #465 | Archive card accessible name reads "Export a copy for Archive copy" | cleanup | 1 |
| #465 | QA doc says drag the row; only the Drag button drags | docs | 1 |
| #466 | Docstring says the card closes on leaving the page; the floating window does not | docs | 3 (never live) |
| #466 | Reused hidden window can flash the previous recording's card | bug | 2 (runs 1, 3) |
| #466 | `recording-ready:show` accepts any renderer | security | 2 (live, run 2) |
| #466 | `show()` returns true before the card can paint | bug | 1 (live) |
| #466 | Test name says Edit-first is ignored; test asserts it closes | tests | 1 |
| #467 | Library drop test passes either way | tests | **4** |
| #467 | Sidebar "with and without a video" tests one case | tests | **4** |
| #467 | Orphaned CSS comment for the removed drop strip | cleanup | **4** |
| #467 | "Pick from Library" enabled while importing | bug | 3 |
| #467 | GitHub size bar label omits fits/over | a11y | 2 |
| #467 | Picker `role="dialog"` without focus management | a11y | 2 |
| #467 | **Finished Email export listed as "Chat" in Recent exports** | bug | 2 (runs 2, 3; never live; noticed by hand on 10-31) |
| #467 | Running row shows the title where finished rows show the destination | cleanup | 1 (live) |
| #467 | Badge "in progress" count untested | tests | 1 (live) |
| #467 | `EXPORT_ORDER` can silently miss a destination | cleanup | 1 |
| #467 | CSS comment calls 900×670 the default; it is the minimum | docs | 1 |

## Reading

1. **One run is not a measurement.** Between any two runs roughly half the findings change. The
   stable core is test quality and leftovers (6 findings, 4/4); functional bugs come and go: the
   most serious live catch (#463, face lost) reappeared in one of three replays, and the live-only
   bugs on #464 and #466 did not reappear at all. Any claim about a Wachiman version needs at least
   three runs per PR, and should be stated as "appears in k of n runs".
2. **The Pullfrog-only bugs were never found, in any of 15 runs.** Not `markCopySeen` (#464,
   #465), not the Back re-show (#466), not the Export re-list (#467), not the random gap ids
   (#463). This confirms the field-benchmark reading: the gap is the question the prompt does not
   ask, not luck. The [flow-questions design](../../specs/2026-10-31-flow-questions-and-evidence-design.md)
   targets exactly these; this table is its baseline.
3. **The replays found four functional candidates the live run did not** (#464 copy loses its
   actions, #465 size stuck at "…", #466 previous card flashes, #467 Email listed as Chat). The last
   one the orchestrating session had noticed by hand on 10-31 without either bot flagging it. All
   four still need verification against the code before they count.
4. **Cost drifts up slightly** ($3.28 live → $3.59–$4.17) with the same prompt; the engine's turn
   counts vary run to run, which is the same variance seen in findings.

## Pullfrog, fresh repository, one run (same five PRs)

Opened the same day in [kaipu-bench-pullfrog](https://github.com/niway-dev/kaipu-bench-pullfrog)
(#1–#5). The run logs say `learnings seeded … existing=no`: no stored memory from kaipu-record.
Claude Opus 5.5, effort high. Findings not yet verified against the code.

| kaipu PR | Live 10-31 | Replay | Replay findings |
| --- | --- | --- | --- |
| #463 | 1 · $2.20 | 2 · $2.05 (44 turns) | Random gap ids break the Share fingerprint (**same as live**); a superseded re-open closes the camera gap too early (**new**; the author fixed this on 10-31 in `8609fab`, which neither live review had flagged) |
| #464 | 2 · $1.23 | 1 · $1.08 (19) | Pill progressbar hidden from assistive tech (same as live). **`markCopySeen` not found** |
| #465 | 1 · $1.15 | 1 · $1.05 (21) | Library-detail bottom panel flickers between the first copy finishing and the re-list (new). **`markCopySeen` not found** |
| #466 | 2 · $1.14 | 1 · $1.38 (28) | Card shadow clipped by the 16 DIP window padding (same as live). **Back re-show not found** |
| #467 | 1 · $1.96 | 2 · $1.67 (35) | A file dropped on the Library now navigates the Electron window to `file://` (new, no `will-navigate` guard); orphaned CSS comment (Wachi's live finding, with a suggestion block). **Export re-list not found** |
| **Total** | **7 · $7.68** | **7 · $7.23** | |

**Reading.** Pullfrog is as variable as Wachiman. Of the five live findings that made it look
decisive on 10-31, the fresh run reproduced **one** (the random ids). The three `markCopySeen` /
re-list / Back bugs did not reappear, and three new candidates did, two of them potentially
serious (the gap closed by a superseded re-open, which the author did fix; the drop that navigates
the window). Whether the loss comes from run-to-run variance or from the missing kaipu learnings
cannot be separated with one fresh run; the live-plus-replay pair gives Pullfrog 2 of 2 runs on only
one finding. The conclusion for the design does not change: the flow questions target a class of
bug both reviewers find *sometimes*; the goal is to find it *every* run.

## CodeRabbit, fresh repository, one run (same five PRs)

Installed by the owner on [kaipu-bench-coderabbit](https://github.com/niway-dev/kaipu-bench-coderabbit);
no `.coderabbit.yaml`, default settings. Its automatic review **skipped all five PRs** ("auto reviews
are disabled on base/target branches other than the default branch"); each was then reviewed once
with the `@coderabbitai review` command, as its own message suggests. Model not selectable; cost
not visible to the consumer. Reviews took 3–8 minutes each. Findings not yet verified.

| kaipu PR | Actionable findings | What |
| --- | --- | --- |
| #463 | 0 | Walkthrough only; 21 files processed, 2 ignored by path filters |
| #464 | 2 | Accessible names of the ready card hide the destination (poster and drag buttons); a second note on the card's action code, supported by its own shell scripts over `ready-copies.ts` and the toast |
| #465 | 0 | Walkthrough only |
| #466 | 1 | A rejected `loadURL`/`loadFile` is unhandled, `show()` has already returned `true`, the window is never destroyed, so the card is lost for the session (the same path as Wachiman's live #466 finding) |
| #467 | 0 | Walkthrough only |
| **Total** | **3** | |

Each review also posts a "Walkthrough" table, pre-merge checks (title and description) and a
"Prompt for AI Agents" block per finding. None of the five Pullfrog-only live bugs appeared; none
of the Wachiman stable core (tests, leftovers) appeared either.

**Reading.** On these PRs CodeRabbit is the quietest of the three: 3 findings against Wachiman's
15–17 and Pullfrog's 7, with the "Code Graph Analysis" context it advertises. Its one functional
finding overlaps Wachiman's live catch on #466. One run is one run; the same variance caveat
applies, and its skip-by-default on non-default base branches is a configuration fact to record for
any future replay.

## Method notes

- Trigger: `/wachi review` comment by the operator, because a `pull_request` event would run the
  replayed commits' own `agent-review.yml` (v1.2.0), not the benchmark workflow on `main`. That
  workflow and `pr-checks.yml` are disabled in the repository's Actions settings.
- Repeat runs: the engine skips a head it has already marked, so runs 2 and 3 use branches
  `replay/pr-<n>/head-r2` and `head-r3` pointing at the same commit, each in its own PR.
- v1.3.0 reads the focus file, `CLAUDE.md` and `AGENTS.md` from the base commit; in these PRs
  they match the head's, so this should not change the prompt.
- Scripts: [`replay/open-replays.sh`](../replay/open-replays.sh), [`replay/push-rounds.sh`](../replay/push-rounds.sh),
  [`replay/open-rounds.sh`](../replay/open-rounds.sh).
- Same code path as the automatic review: `/wachi review` routes through `comment()` to the same
  `review()` the `pull_request` job calls (`src/cli.ts:121-122`, `src/engine.ts:1688`), with the
  same budgets and model. The only difference is the trigger.
- **Effort.** The adapter sets none, so Claude Code's default applied. Per the Claude Code
  changelog that default is `high` for API-key users since 2.1.94 (the pinned 2.1.304 is later),
  and Pullfrog's logs say `effort: high (default)`: the two ran at the same level. Depending on a
  provider default is still wrong; PR #56 makes effort an explicit, logged input.
