# Demo 2 — a REAL PR, shown linked to the Terminal

Source: plan `blockchain-service-endpoints`, step `read-endpoints`, PR #5 (merged).
All metadata below is pulled from plan-api (mcp__plan__get_plan), not invented.

## BEAT 1 — Terminal: ask the plan API
- SCREEN: ship-proven shell (left half of screen stays visible the whole demo)
- TYPED: `get_plan blockchain-service-endpoints`
- NARRATION: "We ask the plan API about one plan. The step we care about is read-endpoints."
- CALLOUT: highlight step `read-endpoints` -> pr "5", prOutcome "merged".
  WHY: the Terminal is the source of the PR number — that's the link.

## BEAT 2 — Cutaway: the PR / code-review metadata block
- SCREEN: Terminal dims to the left; PR card slides in right
- CUTAWAY: assets/pr5-metadata.txt
- NARRATION: "Here's that same PR #5 as a reviewer sees it."
- CALLOUT: arrow from Terminal's `pr: 5` -> card's `#5`.
  WHY: one PR number, two screens — Terminal and review view are the same object.

## BEAT 3 — Cutaway: the review / step decisions
- SCREEN: PR card stays, review-trail inset appears below it
- CUTAWAY: assets/pr5-review.txt
- NARRATION: "The step only settled when a human adopted the merged PR back onto it."
- CALLOUT: box around the adopt-pr decision.
  WHY: status.targetPR=5 is what let the reconciler settle the step (adopt_pr).

## BEAT 4 — Back to Terminal: the step is Succeeded
- SCREEN: Terminal full again
- TYPED: `get_plan blockchain-service-endpoints  # read-endpoints -> Succeeded`
- NARRATION: "Merged PR, adopted back, step green. The two screens tell one story."
- CALLOUT: checkmark on read-endpoints.
