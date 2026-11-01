#!/bin/bash
# Push extra head branches (same commit) so a PR can be reviewed again: replay/pr-<n>/head-r<k>.
# Usage: push-rounds.sh <repo-suffix> <round numbers...>   e.g. push-rounds.sh wachi 2 3
set -euo pipefail
p="$1"; shift
url="git@github-csdev:niway-dev/kaipu-bench-${p}.git"
PAIRS=(
  "463 3ec7a138c3a878b38284fd13c801ab7226a34abb"
  "464 e45c845143ba72f35fea4fac2f9d62a186dff986"
  "465 dac8318b631e64780f65ce94b4aaa57261d7d63d"
  "466 b2705a9ce2593b29ae50235312a4226955bbbb36"
  "467 b12d760bd90b1e9619bab115f500f9c1a30cccf3"
)
refs=()
for pair in "${PAIRS[@]}"; do
  read -r n head <<<"$pair"
  for k in "$@"; do refs+=("${head}:refs/heads/replay/pr-${n}/head-r${k}"); done
done
git -C /tmp/kaipu-mine/repo push -q "$url" "${refs[@]}" 2>&1 | grep -v '^remote:' || true
gh api "repos/niway-dev/kaipu-bench-${p}/branches" --paginate --jq '[.[].name | select(test("head-r"))] | length'
