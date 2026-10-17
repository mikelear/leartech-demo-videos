# Demo script — TEST narrative

Format: each BEAT is one unit of the timeline.
- SCREEN: what the viewer sees (primary source)
- CUTAWAY: a snippet overlaid in a corner / full-screen inset
- TYPED: the command typed on screen (if any)
- NARRATION: what is said / subtitle text
- CALLOUT: on-screen annotation (arrow + short text), and WHY it matters

---

## BEAT 1 — Open on the Terminal
- SCREEN: plain Terminal
- TYPED: `ls` then `cd videos`
- NARRATION: "We start in a normal terminal. Everything here is real."
- CALLOUT: none

## BEAT 2 — Enter the ship-proven shell
- SCREEN: Terminal transitions to the ship-proven shell prompt
- TYPED: `/status`
- NARRATION: "The ship-proven shell wraps the same terminal but adds tools and approval gates."
- CALLOUT: arrow -> the status line. WHY: shows which model + approval mode is live.

## BEAT 3 — Kick off a step that opens a PR
- SCREEN: ship-proven shell, a plan step running
- TYPED: (command that triggers the step)
- NARRATION: "This step produces a pull request. Watch the PR metadata on the right."
- CUTAWAY: assets/pr-metadata.txt  (PR Meta block slides in, top-right)
- CALLOUT: box around the PR title + step name.
  WHY: this is the 'pr' step — it only settles once the reconciler sees status.targetPR.

## BEAT 4 — Tie the PR back to another screen
- SCREEN: ship-proven shell (dimmed)
- CUTAWAY: assets/gates.txt  (CI gates for the same step, full inset)
- NARRATION: "The same PR drives the CI gates screen. One PR, two views."
- CALLOUT: line connecting PR head SHA -> gate 'comment-gate'.
  WHY: the gate runs against the PR HEAD SHA — that's the relationship between the two screens.

## BEAT 5 — Resolve + close
- SCREEN: ship-proven shell
- NARRATION: "Human approves, the step settles, the plan advances."
- CALLOUT: checkmark on the step. WHY: Gate 3 is a human decision.

---
## Notes on timing
Keep each beat 5-12s. Cutaways animate IN as the relevant command is TYPED, not before.
