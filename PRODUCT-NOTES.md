# Packaging as a product — the design-MCP pattern, applied to video

You're right: this IS the design loop. Research → render stand-alone HTML →
show the user → publish as a versioned artifact. The decisions below settle
*where the knowledge lives* and *what the MCP does*.

---

## The key choice: the Repo is the standard; the MCP just consumes it

Two ways the video loop could learn its features:

- **(A) MCP researches features at run time** — on every design it also asks
  "are there new effects out on the web?" → the MCP carries evolving knowledge,
  results drift run-to-run, and "what a video can do" has no fixed definition.
- **(B) The Repo defines the standard; the MCP only reads it** — the video MCP's
  research references THIS repo (examples + FEATURES.md) and real platform data,
  and **never invents new features**. Keeping the repo current is a *separate,
  slower process* outside the MCP.

**Choose (B).** It's the same shape as the rest of the platform:

| Capability | The standard lives in… | Kept current by… | The MCP/loop just… |
|---|---|---|---|
| Plans | `leartech-plan-catalog` rules R1–R27 | reviewed PRs to the catalog | lints against them |
| Ship Proven guidance | docs in the catalog repo | reviewed PRs | serves the current text |
| **Video** | **this repo (FEATURES.md + examples)** | **reviewed PRs (feature pipeline)** | **copies examples, builds, publishes** |

This gives you the "nice abstract setup": **the Video Repo IS the product
surface.** It is simultaneously the standard, the example library, and the
research seed. The MCP is a thin, stateless consumer of it.

### Why (B) beats (A)

- **Determinism.** "What a video can do" = what FEATURES.md says, today, for
  everyone. Not whatever the web surfaced this run. Same reason plan-lint is a
  fixed rule set, not an LLM opinion.
- **A real standard.** A published FEATURES.md + reference pages is something a
  user (or another LLM) can be *pointed at* and trust. That's the offering.
- **No run-time drift / no state in the MCP.** The MCP stays control-plane: read
  the repo, read live platform data, render, publish. Nothing to keep in sync.
- **Governance.** A new effect (say "Ken Burns pan") lands by PR to this repo —
  reviewed, with a reference page proving it renders — exactly like a new
  PlanTemplate. The gate is the merge.

---

## So the architecture is two separated loops

```
┌─ FEATURE loop (slow, outside the MCP) ───────────────────────────┐
│  web research / ideas  ─►  PR to leartech-demo-videos            │
│  adds: a named feature in FEATURES.md + a reference page that    │
│  renders (check_render)  ─►  review  ─►  merge = new standard    │
└──────────────────────────────────────────────────────────────────┘
            │  (the repo is the published standard + seed)
            ▼
┌─ DESIGN loop (fast, the MCP) ────────────────────────────────────┐
│  research(topic, repos[])  — reads THIS repo's examples          │
│                             + real data (plan-api / gh / clone)  │
│  scaffold(spec)            — copies closest example, fills beats │
│  check_render(file)        — Chrome headless, non-blank          │
│  feedback (operator looks at the stand-alone HTML)               │
│  publish(folder)          — create → PUT → finalize              │
│                             == a kind:video-bundle artifact      │
└──────────────────────────────────────────────────────────────────┘
```

- The **feature loop** keeps the repo's capabilities current. Human-paced,
  reviewed, rare. This is where "are there new features out on the web?" is
  answered — once, into the standard — not on every design.
- The **design loop** is the MCP. It asks only: *given the current standard and
  this real data, build the video the user described.* It never adds a feature
  that isn't in the repo; if a user wants one, that's a feature-loop PR.

---

## What this means concretely

- **MCP research = repo + real data, full stop.** `research()` reads
  FEATURES.md/examples and pulls real plan/PR/screen data. It does **not** scan
  the web for new effects — that's the feature loop's job.
- **No "add repos" endpoint, no state.** Example seeds are git-versioned in this
  repo; the repo a video is *about* is a per-call parameter; discovery is live
  reads (`list_plans`, `gh`). Same stateless posture as the design MCP.
- **The repo is versioned, so videos are reproducible.** A video bundle can
  record which revision of FEATURES.md it was built against (provenance in
  SPEC.md), the way a Plan records the rules revision it passed.

---

## The rest (unchanged): kind, embed, Plan route

### `kind: video-bundle` — artifact-api supports it as-is
`kind` is a free string (registry already carries design-system/-bundle/-doc).
A video bundle's files are the page + optional audio + a SPEC.md (the video's
"DESIGN.md"). Same create → presigned PUT (bytes direct to GCS) → finalize cycle,
same lineage/TTL. `ship-proven video publish <folder>` owns the PUT.

### Embed anywhere (Angular example)
Single-file page → iframe the artifact, or copy the folder into
`src/assets/videos/<slug>/`. No build step; that portability is the whole reason
to keep the single-file format rather than rebuild as an Angular app.

### Who makes the Angular PR
Not the MCP. A normal **`kind: pr` Plan on `leartech-agent-ng`** whose goal is
"consume video-bundle artifact `<id>` and embed it". The Plan holds the artifact
*id*, never the bytes; the dev agent pulls the sealed bundle; verify-release-flow
auto-injects (R23) and the usual gates apply.

---

## Recommendation

1. **Make the Video Repo the standard** (FEATURES.md + reference pages) — it is
   the product: standard, examples, and research seed in one versioned place.
2. **Separate the two loops.** Feature loop (PRs to this repo, where web research
   lands once) keeps capabilities current; the video MCP only consumes the repo
   + real data. The MCP stays stateless/control-plane.
3. **Reuse artifact-api with `kind:video-bundle`** — a sibling to design, not a
   fork; same publish cycle, lineage, embed story.
4. **Embed via a `kind:pr` ng Plan** referencing the artifact id, through the
   normal gates.
