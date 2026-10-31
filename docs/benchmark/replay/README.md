# Replay repositories

Files used to create the three benchmark repositories on 2026-10-31. `README.md` is the default
branch's readme in each repository; `wachi-workflow.yml` is the on-demand Wachi workflow installed
in `kaipu-bench-wachi` as `.github/workflows/wachi-bench.yml`; `push-replays.sh` pushes the
`replay/pr-<n>/{base,head}` branches from a kaipu-record clone. Pullfrog's repository carries
kaipu-record's `pullfrog.yml` unchanged; CodeRabbit's needs no workflow.

