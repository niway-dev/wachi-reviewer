# kaipu-bench: a code-review benchmark on real pull requests

This repository is one of three identical copies, one per reviewer, so that no reviewer reads
another's comments:

- `niway-dev/kaipu-bench-wachi` — reviewed by [Wachi Reviewer](https://github.com/niway-dev/wachi-reviewer)
- `niway-dev/kaipu-bench-pullfrog` — reviewed by Pullfrog
- `niway-dev/kaipu-bench-coderabbit` — reviewed by CodeRabbit

It replays pull requests from the public repository
[niway-dev/kaipu-record](https://github.com/niway-dev/kaipu-record). Nothing here is for
development: branches are never merged, and the default branch holds only this file and the
reviewer's workflow.

## How a replay works

For each original pull request, two branches point at the exact commits the original reviewers
saw. No commit is rewritten, so the diff is byte-identical to the original:

- `replay/pr-<n>/base` — the original base commit
- `replay/pr-<n>/head` — the original head commit

A pull request from `head` to `base`, titled `[replay] <original title>`, is what the reviewer
sees. The methodology, the scoring and the results live in the Wachi repository under
`docs/benchmark/` and `docs/specs/2026-10-31-review-benchmark-design.md`.

## Two kinds of replay

- **Exhibition (field) replays** repeat pull requests that Wachi and Pullfrog both reviewed live
  on kaipu-record on 2026-10-31 (#463–#467). They show how each reviewer changed since. Both
  reviewers come in with priors from those live runs; this is stated, and no general claim is made
  from them.
- **Controlled replays** repeat the pull request that introduced a real, later-fixed bug, at its
  parent commit, with clean control pull requests mixed in. Findings are judged blind. These are
  where claims are made.

## Known limits

- The replayed commits carry kaipu-record's own workflows. They run on pull requests here and
  fail for lack of secrets; those failures are noise and are not part of the score.
- Branch histories are full up to each commit, so the history of a later replay can contain the
  fix of an earlier one. A reviewer that only sees the pull request's head cannot reach it; one
  that walks other branches could.
