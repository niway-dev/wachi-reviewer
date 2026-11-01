#!/bin/bash
# Open the five exhibition replay pull requests in one benchmark repository.
# Usage: open-replays.sh <wachi|pullfrog|coderabbit>
set -euo pipefail
p="$1"; R="niway-dev/kaipu-bench-${p}"
gh label create replay -R "$R" --color 5319e7 --description "Replayed kaipu-record pull request; never merged" 2>/dev/null || true
title_of() {
  case "$1" in
    463) echo "fix(desktop): turning the camera off and on mid-take keeps the face in its own track";;
    464) echo "feat(desktop): ready copy shows up in the Library; minimizable export widget";;
    465) echo "feat(desktop): recording detail — title on top, destinations strip, copies from this original";;
    466) echo 'feat(desktop): float "Your video is ready" outside the app window';;
    467) echo "feat(desktop): Export screen with its own rail entry (replaces Prepare)";;
  esac
}
for n in 463 464 465 466 467; do
  body=$(gh pr view "$n" -R niway-dev/kaipu-record --json body --jq .body)
  head_sha=$(gh api "repos/${R}/git/ref/heads/replay/pr-${n}/head" --jq .object.sha)
  base_sha=$(gh api "repos/${R}/git/ref/heads/replay/pr-${n}/base" --jq .object.sha)
  gh pr create -R "$R" --base "replay/pr-${n}/base" --head "replay/pr-${n}/head" --label replay \
    --title "[replay] $(title_of "$n")" \
    --body "$(printf '> **Replay of [niway-dev/kaipu-record#%s](https://github.com/niway-dev/kaipu-record/pull/%s)** for the code-review benchmark. Base `%s`, head `%s`: the same commits the original reviewers saw, so the diff is byte-identical. Never merged. Method and scoring: [wachiman/docs/benchmark](https://github.com/niway-dev/wachiman/tree/main/docs/benchmark). The original description follows.\n\n---\n\n%s' "$n" "$n" "${base_sha:0:7}" "${head_sha:0:7}" "$body")"
done
gh pr list -R "$R" --label replay --json number,title --jq '.[] | "#\(.number) \(.title)"'
