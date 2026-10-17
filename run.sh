#!/usr/bin/env bash
# Demo launcher. Usage:
#   ./run.sh            list demos
#   ./run.sh 1          demo 1 — synthetic PR flow
#   ./run.sh 2          demo 2 — real PR #5, terminal<->review split
#   ./run.sh 3          demo 3 — PR #239, presentation-quality colour
#   ./run.sh all        play all back to back
#   SPEED=0 ./run.sh 3  fast; add --step to page through:  ./run.sh 3 --step
#   NO_COLOR=1 ./run.sh 3   strip colour
set -euo pipefail
cd "$(dirname "$0")"

case "${1:-}" in
  1)   shift; ./play.sh "$@";;
  2)   shift; ./play2.sh "$@";;
  3)   shift; ./play-pr239.sh "$@";;
  all) ./play.sh; read -rp '[enter] next '; ./play2.sh; read -rp '[enter] next '; ./play-pr239.sh;;
  *)
    cat <<'EOF'
Demos in this folder:
  1  PR flow (synthetic)   terminal -> PR metadata -> CI gates, linked by HEAD SHA
       script.md · assets/pr-metadata.txt · assets/gates.txt
  2  Real PR #5 (split)    terminal (left) <-> code-review + review trail (right)
       demo2-script.md · assets/pr5-metadata.txt · assets/pr5-review.txt
  3  PR #239 (polished)    full colour: review card, diff hunk, gates, result
       play-pr239.sh · lib/ui.sh   [data is placeholder — see note in the script]

Run:  ./run.sh 1 | 2 | 3 | all
Flags: SPEED=0 (fast)   --step (page through)   NO_COLOR=1 (no colour)
EOF
    ;;
esac
