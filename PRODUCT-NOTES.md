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
3. **The artifact MCP (`mcp__design__*`)** — the ONLY MCP in the picture; it does
   **storage only**: create → presigned PUT → finalize → get/list. No research,
   no rendering, no GH access. `ship-proven design publish` is a thin shell command
   that just DRIVES that cycle (create, upload each file, finalize) — it adds no
   capability, only convenience.

   > **So "video publish" is NOT a new thing.** It is literally
   > `create_artifact(kind="video-bundle", files=[index.html, audio/*, SPEC.md])`
   > + PUT + finalize — the same three calls as any artifact. The only difference
   > is the `kind` label and which files you upload. A `ship-proven video publish`
   > wrapper is optional sugar (runs the PUT loop, defaults the kind, writes
   > provenance); you could call `mcp__design__create_artifact` directly instead.

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
| Render check | `check_render.sh` (a LOCAL shell script, lives in the design/standard repo — not here) | fold into the publish wrapper or a platform headless check; don't hard-depend on a laptop script |
| Publish/store | `mcp__design__*` (artifact CRUD) | **same MCP**, `kind: video-bundle` |

**There is almost no new MCP to build.** Video reuses the artifact MCP as-is
(just a new `kind`), reuses the gateway for research, reuses the render check, and
adds a **written standard (this repo)** plus a thin `ship-proven video publish`
shell command. The only *optional* new verb ever is a read-only repo-fetch, and
even that is a deliberate later decision (see below) — not required.

---

## Honest note: what a publish relies on locally (and what we should fix)

Two kinds of "local reliance", only one of which is inherent:

1. **The bytes are local — and that's correct, not a smell.** The caller always
   has the built HTML/audio in the working dir and PUTs them straight to GCS via
   the presigned URL. The MCP never carries bytes (control plane only). Nothing to
   change here; it's the same for any artifact.

2. **The render CHECK is a local shell script — that IS an avoidable dependency.**
   `check_render.sh` (Chrome headless, assert non-blank) is not in this repo; it's
   a laptop/session script referenced by the design doc. For a portable product we
   should NOT lean on it. Options:
   - fold "renders non-blank?" into the publish wrapper, or
   - make it a small platform check (headless render in a container) run at/around
     publish — not something the user must have installed.

   Until then: the render check is a *nice-to-have local step*, not a requirement
   for the artifact push. A publish succeeds without it; the check just catches a
   blank page before you seal it.

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
