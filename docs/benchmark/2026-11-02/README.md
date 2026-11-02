# Benchmark 2026-11-02: does v1.4.0 find the bugs v1.3.0 missed?

- **Status:** hypothesis registered before any v1.4.0 run. The results section is filled in after
  the runs, in a later commit; this commit's date is the proof the predictions came first.
- **Baseline:** [2026-11-01 replay](../2026-11-01/README.md), Wachiman v1.3.0, three runs on
  kaipu-record #463–#467. Per-issue analysis in [`../2026-11-01/prs/`](../2026-11-01/prs/).
- **Same setup as the baseline:** same five PRs at the same commits, in
  [kaipu-bench-wachi](https://github.com/niway-dev/kaipu-bench-wachi), three runs on new
  `head-r<k>` branches, Claude Opus 5.5, effort `high`, started with `/wachi review`. Only the
  pinned engine version changes, from `v1.3.0` to `v1.4.0`. Every posted finding is checked against
  the code with the same method as the baseline.

## What changed from v1.3.0 to v1.4.0

| PR | Change | Touches what the model reviews? |
| --- | --- | --- |
| #56 | Reasoning effort is an explicit input (`high`, as before by default) | No: same level as the baseline |
| #67 | Turn cap (`--max-turns 40`) and a 900 s wall-clock kill per call | Only if a batch hits a limit |
| #68 | Review every push incrementally; a rebase with no content change costs nothing | No: the replays have no pushes |
| #69 | **Call-site evidence:** each batch gets the other call sites of the symbols its new lines call | **Yes** |
| #70 | **Flow and failure questions**, `contracts[]` with checked citations, `confidence`, severity calibration in `RULES` | **Yes** |
| #73 | The engine posts a low-confidence `fix` or `blocker` as a `question` | Labels only |

## Baseline (v1.3.0, three runs)

| Metric | Value |
| --- | --- |
| Real Medium+ bugs found per run (of 14) | 0, 3, 1 (mean 1.3) |
| Distinct real Medium+ bugs over the three runs | 3 |
| Expected issues found per run (of 26) | 10, 10, 11 |
| Invalid findings per run | 0 |
| Cost per run, five PRs | $3.80, $3.59, $4.17 (mean $3.85) |
| Message quality, mean (0–5) | 4.87; points lost on Signal: comment-only issues labelled `Fix` |

For comparison: Pullfrog 3.5 real Medium+ bugs per run at $7.15; CodeRabbit 2.5.

## Predictions

### Per bug, from the change that targets it

| PR | Bug (from the [baseline table](../2026-11-01/README.md#the-real-bugs-severity-medium-or-high)) | Targeted by | v1.3.0 | Predicted v1.4.0 |
| --- | --- | --- | --- | --- |
| #464 | Show in Finder and drag skip `markCopySeen` | #69: the toast's call site pairs `markCopySeen` with `startFileDrag` | 0/3 | **≥ 2/3** |
| #465 | The new Drag handle skips `markCopySeen` | #69, same sibling call site | 0/3 | **≥ 2/3** |
| #467 | Export never re-lists the Library when an export finishes | #69 (library-detail's refresh) and #70 (background work finishes) | 0/3 | **≥ 1/3** |
| #466 | Back re-floats the always-on-top card | #70 (Back, remount with the same history entry) | 0/3 | **≥ 1/3** |
| #467 | A file dropped on the Library navigates the window to `file://` | #70 (what the removed path did before) | 0/3 | **≥ 1/3** |
| #466 | `show()` returns true before the card renders; a failed load loses the card | #70 (failure paths) | 0/3 | **≥ 2/3** |
| #463 | The take's first relay feed is ignored | #70 (failure paths: never delivers) | 0/3 | **≥ 1/3** |
| #463 | A queued camera-on reopens the camera after a newer off | #70 (failure paths: superseded request) | 0/3 | **≥ 1/3** |
| #467 | Orphaned CSS comment | #70 severity test: comment-only is never `Fix` | `Fix` 3/3 | **`Fix` 0/3** |

### Overall

| Metric | v1.3.0 | Hypothesis | Failure if |
| --- | --- | --- | --- |
| Real Medium+ bugs per run (of 14) | 1.3 | **≥ 3.0** | < 2.0 |
| Distinct real Medium+ bugs over three runs | 3 | **≥ 7** | ≤ 4 |
| Expected issues per run (of 26) | 10–11 | **≥ 9** | < 8 |
| Invalid findings per run | 0 | **≤ 1** | ≥ 3 |
| Cost per run | $3.85 | **$4.50–$6.00** | > $7.15 (Pullfrog's) |

Reaching 3.0 at 60–80 % of Pullfrog's cost, without losing the test findings, would mean
competing on the bugs a user feels while keeping the coverage the baseline already had.

### How to tell why, if it fails

The new `contracts[]` output records what the model answered, so a miss can be placed:

1. **The evidence did not hold the sibling call.** `evidence.json` in the batch log lacks the
   pairing call site: the extractor or its caps are wrong.
2. **The evidence held it and no contract used it.** The model did not read the evidence: the
   prompt placement or wording is wrong.
3. **A contract states the gap and no finding was posted.** The model saw it and decided not to
   publish: the publication rules (`RULES`, confidence) are wrong.
4. **Expected issues drop below 9.** More questions took attention from the test findings.

### Not measured here

Review on push (#68) and the turn cap (#67) do not show on a replay without pushes. They are
tested live on kaipu-record with a push to an already reviewed pull request.

## Results

Filled in after the three runs, with the same tables as the baseline and one row per prediction:
met, not met, and which of the four causes above applies.
