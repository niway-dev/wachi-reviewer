# E1: v1.4.0 with Sonnet 5.5 on every batch

- **Status:** hypothesis registered before any E1 run. Results are filled in later, in another
  commit.
- **Question:** how much of v1.4.0's gain survives on the cheaper model, which is also the default
  every consumer gets without configuring anything? Where does Sonnet fail, and why?
- **Opus reference:** [v1.4.0 results](../2026-11-02/README.md#results), from PR #82: 7.3 real
  Medium+ bugs per run, 11 of 14 distinct, 11–12 expected issues, 0 invalid, $6.96 per run.
- **Setup:** identical to the Opus runs except the model. Same five PRs, same commits, three runs
  (rounds 7, 8 and 9 in kaipu-bench-wachi), `review.yml@v1.4.0`, effort `high`,
  `model: claude-sonnet-5-5`. Every finding is checked against the code with the same method.

## Predictions

| Metric | v1.4.0 on Opus | Hypothesis on Sonnet | Failure if |
| --- | --- | --- | --- |
| Real Medium+ bugs per run (of 14) | 7.3 | **≥ 4.4** (60 % of Opus) | < 3.5 (Pullfrog's level) |
| Distinct real Medium+ bugs over three runs | 11 | **≥ 7** | ≤ 4 |
| Expected issues per run (of 26) | 11–12 | **≥ 9** | < 8 |
| Invalid findings per run | 0 | **≤ 1** | ≥ 3 |
| Cost per run | $6.96 | **≤ $3.50** (half of Opus or less) | > $5.00 |

"Worth it" means both: a Sonnet run keeps at least 60 % of Opus's real bugs, and it costs half or
less. If only one holds, the [reader and judge design](../../specs/2026-11-02-reader-judge-and-local-index-design.md)
(#80) has its target: the bugs Sonnet loses are the judge's job.

## Where Sonnet should hold and where it should fail

These predictions follow from what each change gives the model:

- **Should hold: the sibling call-site cases** (`markCopySeen` on #464 and on #465). The evidence
  file puts the pairing call in front of the model, so it is reading, not reasoning. Prediction:
  **≥ 4 of 6**.
- **Should hold: breadth** (test quality, stale docs, leftovers). Prediction: expected issues ≥ 9.
- **Should fail first: the reasoning cases.** Back re-float (#466, difficulty 5), the `file://`
  drop (#467, a removed handler with nothing new to grep), the queued camera-on (#463).
  Prediction: **together ≤ 5 of 9** (Opus: 8 of 9).

## How a miss will be diagnosed

Each lost bug, per batch, is placed in one of four causes:

1. **The evidence was not there.** `evidence.json` lacked the call site. Same input as Opus, so
   this should not happen; if it does, the batching differed.
2. **The evidence was there and no contract used it.** The model did not read or connect it.
3. **A contract stated the defect and no finding was posted.** Seen, not published.
4. **No contract and no finding.** The question was never answered.

This split is what tells the reader/judge design whether a Sonnet reader would hand the judge
enough. It is gate 2 of #80.
