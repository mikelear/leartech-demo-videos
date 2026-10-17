#!/usr/bin/env bash
# Presentation-quality player for REAL PR #239
# (mikelear/leartech-orchestrator-controller). Data pulled live via gh on
# 2026-10-17. Colour review card, real diff hunk, real CI gates, result.
#
#   ./play-pr239.sh            narration pace
#   SPEED=0 ./play-pr239.sh    fast
#   ./play-pr239.sh --step     page through (for voiceover)
#   NO_COLOR=1 ...             strip colour
set -euo pipefail
cd "$(dirname "$0")"
. lib/ui.sh

SPEED="${SPEED:-1}"; STEP=0; [ "${1:-}" = "--step" ] && STEP=1
export FORCE_COLOR=1
pause(){ [ "$SPEED" = 0 ] && return; sleep "$(awk "BEGIN{print $1*$SPEED}")"; }
gate(){ [ "$STEP" = 1 ] && read -rp "$(dim '  [enter] ')" _ || pause 1.8; }
type_cmd(){ printf '  %s ' "$(col 42 '❯')"; local s="$1"
  for ((i=0;i<${#s};i++)); do printf '%s' "${s:$i:1}"; pause 0.015; done; printf '\n'; }
title(){ clear; printf '\n  %s   %s\n\n' "$(bold "$1")" "$(dim "$2")"; }

# ── REAL DATA (gh pr view 239, 2026-10-17) ───────────────────────────────────
REPO="mikelear/leartech-orchestrator-controller"; NUM=239
PR_TITLE="fix(maestro): announce with aud=leartech-maestro-service"
BRANCH="fix/maestro-announce-audience → main"
AUTHOR="mikelear"
SHA="be8dffc"
STATE="OPEN"               # az/test still pending at capture time
# ─────────────────────────────────────────────────────────────────────────────

# BEAT 1 — Terminal names the PR → review card
title "Pull Request #$NUM" "$REPO"
type_cmd "gh pr view $NUM --repo $REPO"
printf '\n'
box $PURPLE "PR #$NUM · CODE REVIEW" <<EOF
$(col $FG "$PR_TITLE")

$(dim 'state ')$(badge open)   $(dim 'files ')$(col $FG '2')  $(col $GREEN '+26') $(col $RED '-1')
$(dim 'branch') $(col $BLUE "$BRANCH")
$(dim 'head  ') $(col $YELLOW "$SHA")
$(dim 'author') $(col $FG "$AUTHOR")
EOF
printf '  %s the Terminal PR #%s is the same object as %s\n' \
  "$(dim 'CALLOUT:')" "$NUM" "$(col $PURPLE 'the review card ↑')"
gate

# BEAT 2 — the real symptom→fix story (from the PR body)
title "Why this PR exists" "symptom → root cause → fix"
box $ORANGE "SYMPTOM" <<EOF
$(col $FG 'Every plan stalls at its first step. Controller logs')
$(col $RED '  maestro: unexpected status 401 announcing run.completed')
$(col $FG 'Steps sit AwaitingReview forever (seen: fx-ticker bootstrap).')
EOF
box $BLUE "ROOT CAUSE — not a maestro code change" <<EOF
$(col $FG 'maestro 0.0.29 ≡ 0.0.30 byte-identical. Enforcement arrived:')
$(col $FG 'it now verifies') $(col $CYAN 'aud=leartech-maestro-service') $(col $FG 'inbound.')
$(col $FG 'The controller minted an') $(col $RED 'audience-less') $(col $FG 'token → 401.')
$(dim 'The authgraph predicted this edge on 2026-09-12 (Enforced:false).')
EOF
printf '  %s the fix adds the audience the token was missing\n' "$(dim 'CALLOUT:')"
gate

# BEAT 3 — the real diff hunk
title "The fix ↔ the code" "internal/controller/maestro_producer.go"
box $BLUE "maestro_producer.go  ($(col $GREEN '+10') $(col $RED '-1'))" <<EOF
$(diffline '@@ const + MaestroAudience @@')
$(diffline '+ // MaestroAudience is the aud claim maestro enforces inbound.')
$(diffline '+ // proven-by: TestNewMaestroProducer_MintsTheMaestroAudience')
$(diffline '+ const MaestroAudience = "leartech-maestro-service"')
$(diffline '  func NewMaestroProducer(baseURL string) ... {')
$(diffline '-   hc := authedHTTPClient()')
$(diffline '+   hc := authedHTTPClientForAudience(MaestroAudience)')
EOF
box $ORANGE "comment-gate · the test that proves it" <<EOF
$(col $CYAN 'proven-by') $(col $FG 'TestNewMaestroProducer_MintsTheMaestroAudience')
$(dim 'asserts cfg.EndpointParams.Get("audience") == the maestro audience,')
$(dim 'or maestro 401s the announce.')
EOF
printf '  %s prose that asserts behaviour names a %s test — that is the gate\n' \
  "$(dim 'CALLOUT:')" "$(col $CYAN 'proven-by')"
gate

# BEAT 4 — the real CI gates, both clusters
title "CI gates @ $SHA" "the HEAD SHA links review ↔ gates"
box $CYAN "GATES · PR #$NUM @ $SHA" <<EOF
$(dim 'gcp cluster')                     $(dim 'az cluster')
$(badge pass) gcp/lint          $(dim 'pass')   $(badge pass) az/lint          $(dim 'pass')
$(badge pass) gcp/test          $(dim 'pass')   $(badge run)  az/test          $(dim 'running')
$(badge pass) gcp/ai-review     $(dim 'pass')   $(badge pass) az/ai-review     $(dim 'pass')
$(badge pass) gcp/end2end       $(dim 'pass')   $(badge pass) az/end2end       $(dim 'pass')
$(badge pass) gcp/govulncheck   $(dim 'pass')   $(badge pass) az/security-scan $(dim 'pass')
EOF
printf '  %s every check runs against %s — the %s on the review card\n' \
  "$(dim 'CALLOUT:')" "$(col $YELLOW "$SHA")" "$(col $YELLOW 'same head sha')"
printf '  %s Lighthouse merge-status: %s (az/test still green-pending)\n' \
  "$(dim 'NOTE:')" "$(col $YELLOW 'not mergeable yet')"
gate

# BEAT 5 — the link, stated
title "One PR, four screens" ""
box $GREEN "THE THREAD" <<EOF
$(badge pass) review card   $(dim '— PR #'"$NUM"', title, state')
$(badge pass) diff hunk     $(dim '— the audience fix + proven-by test')
$(badge pass) CI gates      $(dim '— run on head '"$SHA")
$(badge pass) terminal      $(dim '— gh pr view, the source of all of it')
EOF
printf '  %s they are the same object #%s — PR number + %s are the links\n\n' \
  "$(dim 'CALLOUT:')" "$NUM" "$(col $YELLOW 'head sha')"
