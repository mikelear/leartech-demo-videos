# Packaging as a product — the Ship Proven design PATTERN, applied to video

Important correction first, because it changes how we build the video version.

## "Design MCP" is not one thing — it's three parts, and the process is the shell

Ship Proven design is **not** a single MCP that does research + render + publish.
It's a *pattern made of three separable pieces*:

1. **The process (research → render → feedback → publish)** — this lives in the
   **shell loop + a written standard**, not in an MCP.
   - Research is `gateway__search` (a **gateway** tool) + reading real data.
   - Render is the shell/agent writing HTML to the working folder.
   - Feedback is the operator conversation — no tool does it.
   - The standard that *describes* this loop is a doc:
     `designing_in_ship_proven` (served by the **ship_proven** guidance server,
     sourced from the plan-catalog repo). It is text, not logic.
2. **The render check** — `check_render.sh` (Chrome headless screenshot). A shell
   script, not an MCP.
3. **The artifact MCP (`mcp__design__*`)** — this is the ONLY MCP in the picture,
   and it does **storage only**: create → presigned PUT → finalize → get/list.
   It does **no research, no rendering, no GH access.** `ship-proven design
   publish` is a thin shell command that drives that storage cycle.

So when I said "the design MCP researches" — that was wrong. **Research is the
gateway + live-data tools; the MCP just stores the result.** Verified: the
`mcp__design__*` surface is purely artifact CRUD (no search, no repo-read verb).

### Why this matters for video

It means we should copy the **pattern**, not build a monolithic "video MCP that
does everything":

| Design piece | Mechanism | Video equivalent |
|---|---|---|
| Process/standard | a doc (`designing_in_ship_proven`) + shell loop | **FEATURES.md + AUTHORING.md in this repo** (the standard) |
| Research | `gateway__search` + real data (`mcp__plan__*`, `gh`, clone) | **same** — reference THIS repo's examples + real screens |
| Render | shell writes HTML | shell writes the self-playing page |
| Render check | `check_render.sh` | same (reuse it) |
| Publish/store | `mcp__design__*` (artifact CRUD) | **same MCP**, `kind: video-bundle` |

**There is almost no new MCP to build.** Video reuses the artifact MCP as-is
(just a new `kind`), reuses the gateway for research, reuses the render check, and
adds a **written standard (this repo)** plus a thin `ship-proven video publish`
shell command. The only *optional* new verb ever is a read-only repo-fetch, and
even that is a deliberate later decision (see below) — not required.

---

## The Repo is the standard; the loop just consumes it

Same conclusion as before, now correctly placed: the "process" for video is a
**doc + shell loop**, exactly like `designing_in_ship_proven` is a doc + shell
loop. This repo (FEATURES.md + reference pages) is that doc-and-examples standard.

| Capability | Standard lives in… | Kept current by… | The loop just… |
|---|---|---|---|
| Plans | plan-catalog rules R1–R27 | reviewed PRs | lints against them |
| Design | `designing_in_ship_proven` doc | reviewed PRs | follows it; stores via `mcp__design__*` |
| **Video** | **this repo (FEATURES.md + examples)** | **reviewed PRs (feature loop)** | **follows it; stores via `mcp__design__*` (kind:video-bundle)** |

### Two separated loops
```
FEATURE loop (slow, outside any MCP): web research/ideas → PR to this repo →
  named feature in FEATURES.md + a reference page that renders → review → merge.
DESIGN loop (fast, the shell): research (gateway + real data, reads THIS repo)
  → render HTML → feedback → ship-proven video publish (→ video-bundle artifact).
```
The feature loop answers "any new effects out there?" once, into the standard.
The design loop never adds a feature not in the repo.

---

## Referencing a screen's SOURCE

### Now: local clone (what we've been doing)
`git clone <repo>` read-only, read real files/diffs/screen markup, pull live run
data from `mcp__plan__*` / `gh`. No new infra, honest provenance.

### Later (optional): MCP-mediated repo read
Neither the artifact MCP nor the ship_proven guidance server reads repos today —
their auth is OAuth/DCR scoped to `leartechapi:artifact:*` / `leartechapi:mcp:*`,
i.e. the control planes, **not a GitHub identity**. DCR governs *who may call the
MCP*; it does not grant repo read. If we ever want a hosted designer with no
laptop, add a narrow, read-only `read_repo_file` verb behind a platform GH app
with its own `repo:read` scope — a deliberate new surface, DCR-governed,
least-privilege. Not an accident of reuse.

---

## The rest: kind, embed, Plan route

### `kind: video-bundle` — artifact-api supports it as-is
`kind` is a free string (registry already carries design-system/-bundle/-doc).
Files = the page + optional audio + SPEC.md (the video's "DESIGN.md"). Same
create → presigned PUT (bytes direct to GCS) → finalize cycle, lineage/TTL.

### Embed anywhere (Angular)
Single-file page → iframe the artifact, or copy into `src/assets/videos/<slug>/`.
No build step — the reason to keep the single-file format.

### Who makes the Angular PR
A normal **`kind: pr` Plan on `leartech-agent-ng`**: goal "consume video-bundle
artifact `<id>` and embed it". Plan holds the artifact *id*, not bytes; the dev
agent pulls the sealed bundle; verify-release-flow auto-injects (R23).

---

## Recommendation (summary)

1. **Copy the pattern, not a monolith.** Video = a written standard (this repo) +
   the gateway for research + the render check + the **existing artifact MCP**
   (`kind:video-bundle`) + a thin `ship-proven video publish`. Little new code.
2. **This repo is the standard** (FEATURES.md + examples): product surface,
   examples, research seed, versioned.
3. **Two loops:** slow reviewed feature loop keeps the repo current; the fast
   design loop (shell) only consumes repo + real data.
4. **Screen source = local clone now**; a DCR-governed read-only repo-fetch verb
   is a possible later capability, not an existing one.
5. **Embed via a `kind:pr` ng Plan** referencing the artifact id.
