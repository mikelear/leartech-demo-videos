#!/usr/bin/env bash
# Minimal demo player: walks the beats, "types" commands, slides cutaways in on cue.
# No deps. Usage: ./play.sh            (auto, ~paced)
#                SPEED=0 ./play.sh     (fast, no delays)
#                ./play.sh --step      (press Enter between beats)
set -euo pipefail
cd "$(dirname "$0")"

SPEED="${SPEED:-1}"
STEP=0; [ "${1:-}" = "--step" ] && STEP=1

pause(){ [ "$SPEED" = 0 ] && return; sleep "$(awk "BEGIN{print $1*$SPEED}")"; }
gate(){ [ "$STEP" = 1 ] && { read -rp $'\n  [enter] '; } || pause 1.2; }
type_cmd(){ printf "  $ "; for ((i=0;i<${#1};i++)); do printf "%s" "${1:$i:1}"; pause 0.03; done; printf "\n"; }
cutaway(){ echo; sed 's/^/      │ /' "$1"; echo; }
beat(){ clear; printf "\033[1m%s\033[0m\n\n" "$1"; }

beat "BEAT 1 — Terminal"
echo "  (plain terminal — everything real)"
type_cmd "ls"; type_cmd "cd videos"
gate

beat "BEAT 2 — ship-proven shell"
echo "  (same terminal, now with tools + approval gates)"
type_cmd "/status"
printf "  → model: claude · approvals: write   \033[2m(callout: this is the live mode)\033[0m\n"
gate

beat "BEAT 3 — a step opens a PR"
type_cmd "run plan token-refresh"
echo "  ...step 'open-token-refresh' running"
printf "  \033[2m>> cutaway slides in: PR metadata\033[0m\n"
cutaway assets/pr-metadata.txt
echo "  CALLOUT: the 'pr' step settles only when reconciler sees status.targetPR"
gate

beat "BEAT 4 — same PR drives the gates screen"
printf "  \033[2m>> cutaway: CI gates for the SAME pr\033[0m\n"
cutaway assets/gates.txt
echo "  CALLOUT: gates run on HEAD SHA a1b9f3c — the link between the two screens"
gate

beat "BEAT 5 — resolve + close"
echo "  human approves → step settles → plan advances  ✔"
echo "  CALLOUT: Gate 3 is a human decision"
pause 1
echo; echo "  --- end of test demo ---"
