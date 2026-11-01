#!/bin/bash
# Open round-k replay PRs (head-r<k> -> base) in kaipu-bench-wachi and ask Wachi to review them.
set -euo pipefail
R="niway-dev/kaipu-bench-wachi"
title_of() { case "$1" in
  463) echo "fix(desktop): turning the camera off and on mid-take keeps the face in its own track";;
  464) echo "feat(desktop): ready copy shows up in the Library; minimizable export widget";;
  465) echo "feat(desktop): recording detail — title on top, destinations strip, copies from this original";;
  466) echo 'feat(desktop): float "Your video is ready" outside the app window';;
  467) echo "feat(desktop): Export screen with its own rail entry (replaces Prepare)";;
esac; }
for k in "$@"; do for n in 463 464 465 466 467; do
  body=$(gh pr view "$n" -R niway-dev/kaipu-record --json body --jq .body)
  url=$(gh pr create -R "$R" --base "replay/pr-${n}/base" --head "replay/pr-${n}/head-r${k}" --label replay \
    --title "[replay r${k}] $(title_of "$n")" \
    --body "$(printf '> **Replay of [niway-dev/kaipu-record#%s](https://github.com/niway-dev/kaipu-record/pull/%s), run %s** for the code-review benchmark. Same base and head commits as the round-1 replay (a second branch name on the same commit, so the reviewer sees a fresh pull request). Never merged. Method: [wachiman/docs/benchmark](https://github.com/niway-dev/wachiman/tree/main/docs/benchmark).\n\n---\n\n%s' "$n" "$n" "$k" "$body")")
  num=${url##*/}
  gh pr comment "$num" -R "$R" --body "/wachi review" >/dev/null
  echo "round $k: #$num <- kaipu #$n"
done; done
