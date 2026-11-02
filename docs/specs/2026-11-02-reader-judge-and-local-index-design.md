# A cheap reader per batch, one judge per pull request, and a local repository index

- **Status:** draft for discussion. **Do not merge until implemented.** Nothing here is built.
  Every number in this spec is a placeholder until the two gates below have run.
- **Issue:** #79.
- **Creates:** ADR 0014 (reader and judge, amends ADR 0009) and ADR 0015 (local index). Both
  proposed.
- **Reuses:** ADR 0001 (no hosted service), ADR 0002 and its amendment (dependencies only after a
  measured experiment), ADR 0007 (memory of judgements), ADR 0009 (admitted investigation).
- **Research:** [local index and model routing](../research/2026-11-02-local-index-and-model-routing.md),
  [the idea note](../research/2026-11-02-idea-cheap-reader-expensive-judge.md), and an adversarial
  review by GPT-6.1 Sol (added to this PR when it lands).
- **Written on:** Claude Opus 5.5.

## Summary (one minute)

Today each batch is one independent call on one model. The model reads everything, and no call
sees the whole pull request. The proposal splits reading from judging:

- **A cheap reader (Sonnet) reads every batch.** It posts the breadth findings it is good at
  (tests, docs, leftovers), and returns contracts and open questions with `file:line` citations.
- **One expensive judge (Opus) per pull request.** It reads all the batches' contracts together,
  plus the cited code and a budgeted slice of a local repository index. It goes deep where the
  readers pointed and where two batches meet.
- **The local index is rebuilt on the runner every run.** It uses tree-sitter definitions and
  references, ranked for the pull request's files and cut to a token budget, like Aider's
  repository map. Nothing is stored on a server.

The philosophy is the owner's: index what is possible locally, explore at the least cost, find the
references and know where to go deep.

**Two gates come before anything is built.** First, measure v1.4.0
([2026-11-02 hypothesis](../benchmark/2026-11-02/README.md)). Second, run v1.4.0 with Sonnet on
every batch (E1). The idea depends on what a cheap model notices: the judge can only go deep where
a reader pointed.

| # | Decision | Why | ADR |
| --- | --- | --- | --- |
| 1 | Reading and judging are separate calls on separate models, chosen by the engine; the model never picks a model or starts another call | Most of the cost is reading (cache reads ~50 %, writes ~36 %, output ~14 %); moving the reading to a cheaper model is where routing pays | 0014 (new) |
| 2 | A reader returns findings, contracts and open questions, each with `file:line` citations the engine checks. It returns **no verdict on another batch** and no prose summary of its batch | ADR 0009 rejected a pass over batch summaries: conclusions that say "correct" are ratified, not re-examined. Citations and code are evidence; summaries are conclusions | 0014, amends 0009 |
| 3 | Reader findings are posted directly after the engine's citation check; the judge adds or deepens, it does not gate them | Test-quality findings are Wachiman's most reliable output; they must not depend on a second model | 0014 |
| 4 | One judge per pull request sees every batch's contracts and open questions, the cited code slices and an index slice, **not the whole diff** | It is the only place two batches meet; giving it the whole diff would pay for the reading again | 0014 |
| 5 | The judge's budget is a separate reserve that readers cannot spend (default 40 % of `budget_usd`, a placeholder until E1) | ADR 0009, decision 3: depth must not eat breadth | reuses 0009 |
| 6 | The judge may request investigation; the engine admits it under ADR 0009's policy (finite count, separate reserve, no recursion, observation mode first) | Judgement in the model, execution in the engine | reuses 0009 |
| 7 | A local index (tree-sitter definitions and references, personalized PageRank over the pull request's files, token-budgeted) is rebuilt on the runner each run; `git grep` stays the floor for languages without a grammar | It finds what `git grep` misses, such as aliased consumers. It needs no server and no stored state | 0015 (new) |
| 8 | The index also groups related files into the same batch before reading, so most "batch 1 and batch 7" cases never split | Cheaper than a judge for the common case | 0015 |
| 9 | The index is not persisted. The GitHub Actions cache is used only if build time on large repositories is measured to hurt | A stored index can go stale; rebuilding it is cheap until measured otherwise | 0015 |
| 10 | Memory of judgements stays as ADR 0007, files in the consumer's repository via a draft PR. The last review's contracts go in its signed footer, so the next push reads them | Code-derived memory is rebuilt; judgement memory is the only state worth keeping | reuses 0007 |

## Open questions

1. **Does Sonnet notice what the judge needs?** E1 answers it. If a Sonnet reader does not flag
   the missed bugs as open contracts (`markCopySeen` ×2, Back re-float, Export re-list, `file://`
   drop, `loadURL` failure), the judge has nothing to deepen and decisions 1–6 fall.
2. **The judge's reserve.** 40 % of `budget_usd` is a placeholder until E1 shows reader and
   judge costs.
3. **Which grammars first.** Default: TS/TSX, the benchmark's languages. Then Go, Python, Rust,
   Java, Kotlin and Swift, each behind a measured experiment (ADR 0002 amendment).
4. **Is the index slice for the judge only, or for readers too?** Default: both. Readers get a
   smaller slice, replacing `evidence.json` from #69.
5. **Codex as reader or judge.** Default: out of scope until the Codex workflow integration
   exists (ADR 0004).

## Out of scope

- A hosted index or graph, and any data leaving the consumer's runner (ADR 0001).
- An orchestrator agent that starts subagents (the model would control spend).
- Type resolution and cross-file bindings: references stay by name, like Aider.
- A verification pass on every finding. Precision is 0 invalid in 35 reviews; this design is
  about recall.

## Failures this must protect against

- A reader misses the cue. The judge never looks, and the review is no better than a Sonnet-only
  review.
- A reader writes "correct" about its batch. The judge inherits it, which is ADR 0009's failure.
- The judge re-reads whole files and costs more than one Opus pass per batch.
- The index build is slow on a large repository and eats the 30-minute job.
- Ranking noise: the index slice lists irrelevant symbols and dilutes the prompt.
- Readers' findings get lost when the judge's call fails or times out.
- Two batches' contracts contradict each other, and the judge picks one silently.

## Acceptance criteria

- [ ] E1 is recorded: v1.4.0 with Sonnet on every batch, three runs, same five PRs, scored like the
  baseline.
- [ ] On the five benchmark PRs, the reader/judge pipeline finds at least as many real Medium+ bugs
  per run as v1.4.0 on Opus, at a lower cost per run.
- [ ] Expected issues per run (of 26) do not drop by more than one against v1.4.0 on Opus.
- [ ] No reader output contains a verdict on another batch or a prose summary. A test rejects
  both.
- [ ] When the judge's call fails, every reader finding is still posted, and the review says the
  judge did not run.
- [ ] The index builds in under 20 s on kaipu-record. If it does not finish, the review continues
  on `git grep`.
- [ ] The index slice holds the sibling `markCopySeen` call site for #465's new drag handle, and
  `onLibraryChanged` for `libraryChanged`.

## Detail

### How a review would run

1. **Plan:** the engine builds the index, then plans batches. Related files (by index edges) land
   in the same batch first, then by risk and size, as today.
2. **Read:** for each batch, a Sonnet call gets the batch's diff and a small index slice. It
   returns findings, contracts and open questions. The engine checks citations and posts the
   findings.
3. **Judge:** one Opus call gets every batch's contracts and open questions, the code each one
   cites, and an index slice centred on the open ones. It returns deep findings and investigation
   requests. The engine admits investigations under the reserve.
4. **Post:** reader findings, judge findings, contracts and coverage, in one review.

### What the reader must not return

- A verdict on another batch.
- A sentence that says code is correct without a citation.
- A summary of its batch.

The engine rejects these by shape. Semantics stay the judge's job.

### Why not each alternative

- **One Opus pass per batch, as today:** it reads everything at the expensive model's price, and
  no call sees two batches.
- **Sonnet then Opus per batch:** each judge still sees one batch.
- **An orchestrator with subagents:** the model controls spend. Pullfrog's prompt allows this, yet
  in 14 saved runs it started none.
- **A hosted graph:** ruled out by ADR 0001.

## Assessment by the author of this draft

**Good with conditions.**

The strongest part is decision 4: one place that sees the whole pull request. It also explains a
real miss. On #465 the batch with the drag handle never held the file whose call site pairs
`markCopySeen`.

The weakest part is that the reader caps recall. The judge cannot find what no reader pointed at,
and nothing yet says Sonnet points at the hard bugs.

Decision 8 (grouping related files by the index) may get most of the cross-batch benefit at
almost no cost, so it should be tried before the reader/judge split. The suggested order is:

1. v1.4.0 measured.
2. E1 (Sonnet only).
3. Index-driven grouping, measured.
4. Reader/judge, measured against 1–3.
