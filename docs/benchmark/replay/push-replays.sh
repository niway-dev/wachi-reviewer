#!/bin/bash
# Push the replay base/head branches of the five 2026-10-31 PRs to each benchmark repository.
set -euo pipefail
cd /tmp/kaipu-mine/repo
PAIRS=(
  "463 c58b68f437293377f0188e6c460ad782a313dbb1 3ec7a138c3a878b38284fd13c801ab7226a34abb"
  "464 13b7ff5da65f3d0b59d0542132babf328ce373b3 e45c845143ba72f35fea4fac2f9d62a186dff986"
  "465 13b7ff5da65f3d0b59d0542132babf328ce373b3 dac8318b631e64780f65ce94b4aaa57261d7d63d"
  "466 13b7ff5da65f3d0b59d0542132babf328ce373b3 b2705a9ce2593b29ae50235312a4226955bbbb36"
  "467 13b7ff5da65f3d0b59d0542132babf328ce373b3 b12d760bd90b1e9619bab115f500f9c1a30cccf3"
)
for p in wachi pullfrog coderabbit; do
  url="git@github-csdev:niway-dev/kaipu-bench-${p}.git"
  refs=()
  for pair in "${PAIRS[@]}"; do
    read -r n base head <<<"$pair"
    refs+=("${base}:refs/heads/replay/pr-${n}/base" "${head}:refs/heads/replay/pr-${n}/head")
  done
  git push -q "$url" "${refs[@]}" 2>&1 | grep -v '^remote:' || true
  echo "$p: $(gh api "repos/niway-dev/kaipu-bench-${p}/branches" --paginate --jq 'length') branches"
done
