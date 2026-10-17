#!/usr/bin/env bash
# Demo 2 player: Terminal on the LEFT, PR/review cutaways on the RIGHT.
# Shows the SAME PR #5 in both panes so the link is visible.
# No deps. SPEED=0 ./play2.sh for fast; ./play2.sh --step to page through.
set -euo pipefail
cd "$(dirname "$0")"
SPEED="${SPEED:-1}"; STEP=0; [ "${1:-}" = "--step" ] && STEP=1
pause(){ [ "$SPEED" = 0 ] && return; sleep "$(awk "BEGIN{print $1*$SPEED}")"; }
gate(){ [ "$STEP" = 1 ] && read -rp $'  [enter] ' || pause 1.4; }

LW=40   # left (terminal) pane width
# render two files side by side: $1 left lines (array name), $2 right file
twopane(){ # $1=title  $2=right-file
  clear; printf "\033[1m%s\033[0m\n" "$1"
  printf '%*s\n' 78 '' | tr ' ' '-'
  paste -d'|' \
    <(printf "%s\n" "${LEFT[@]}" | awk -v w=$LW '{printf "%-*.*s\n", w, w, $0}') \
    <(sed 's/^/ /' "$2" | awk '{printf "%s\n",$0}') \
  | sed 's/|/ │ /'
  echo
}

LEFT=(
"$ get_plan blockchain-service-endpoints"
""
"plan:  blockchain-service-endpoints"
"phase: Failed"
""
"steps:"
"  read-endpoints"
"    kind:       pr"
"    pr:         5        <-- HERE"
"    prOutcome:  merged"
"    stepPhase:  Succeeded"
"    repo: mikelear/leartech-"
"          blockchain-api"
)
twopane "BEAT 1-2 — Terminal (left) ↔ PR #5 code review (right)" assets/pr5-metadata.txt
echo "  CALLOUT: Terminal 'pr: 5' === card '#5' — one PR, two screens."
gate

twopane "BEAT 3 — same step, the review / adopt trail" assets/pr5-review.txt
echo "  CALLOUT: adopt-pr wrote status.targetPR=5 -> that's why the step settled."
gate

LEFT=(
"$ get_plan blockchain-service-endpoints"
""
"  read-endpoints  ✔ Succeeded"
"    pr 5 · merged · adopted"
""
"(the PR screen and the Terminal"
" are the same object, PR #5)"
)
twopane "BEAT 4 — back in the Terminal: step is green" assets/pr5-metadata.txt
echo "  --- end of demo 2 ---"
