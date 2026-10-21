# Dev plan — making "video" a first-class Ship Proven capability

Grounded in the ACTUAL repos/files (probed 2026-10-21). The theme from
PRODUCT-NOTES stands: **reuse the design pattern; add almost no new MCP.** Most of
the work is a standard (docs + this repo), one small guidance entry, and one thin
publish wrapper. Everything is shippable through the normal gates.

## Repos we will change

| Repo | Why | Size |
|---|---|---|
| `mikelear/leartech-demo-videos` (THIS repo) | The standard + examples + seed. Already exists; keep curating. | ongoing |
| `mikelear/leartech-plan-catalog` | Add the written standard doc `docs/designing-videos-in-ship-proven.md` (sibling to `designing-in-ship-proven.md`). | 1 doc |
| `mikelear/leartech-mcp-servers` | Add a `video_guidance` entry to **shipprovenserver** so the standard is served like the others. (NO new storage MCP.) | small |
| `mikelear/leartech-ship-proven-website` | Consume a published `video-bundle` artifact and embed it (first real embed). | 1 feature PR |
| `mikelear/leartech-artifact-api` | **Probably nothing.** `kind` is already a free string. Only touch if we want to *validate* `video-bundle` shape. | 0 (maybe) |

## What we are NOT building
- No new storage MCP — reuse `mcp__design__*` (artifact CRUD) with `kind:video-bundle`.
- No "add repos" endpoint / registry — screen source is a local clone (now) or a
  deliberate future `read_repo_file` verb (not this plan).
- No framework rewrite — the single-file page is the artifact.

---

## Step 1 — Curate the standard in THIS repo  (leartech-demo-videos)
Already most done. Finish:
- Keep `FEATURES.md` as the canonical feature vocabulary (one name per effect).
- Keep `AUTHORING.md` as the process.
- Ensure each named feature has at least one reference page that renders.
- Add a machine-readable `features.json` (name → beat-field) so a tool/agent can
  validate a beat spec against the standard without parsing prose.
Deliverable: PRs to this repo. This is the **feature loop**.

## Step 2 — Write the video standard doc  (leartech-plan-catalog)
- New file `docs/designing-videos-in-ship-proven.md`, sibling to the design doc.
- Content: the loop (research → render self-playing HTML → feedback → publish as
  `kind:video-bundle`), pointing at THIS repo for FEATURES/AUTHORING/examples.
- Merged via the catalog's normal PR review (this is how a standard becomes real).

## Step 3 — Serve the standard  (leartech-mcp-servers / internal/shipprovenserver)
- Add a `video_guidance` (or `designing_videos`) entry in `content.go` + `tools.go`
  that returns the new catalog doc, exactly like `designing_in_ship_proven`.
- Tests in `content_test.go` / `tools_test.go` (comment-gate: assert proven-by).
- Result: `mcp__ship_proven__*` can serve the video standard; sessions get the
  current text, not a memory.

## Step 4 — Thin publish path (choose the lightest that works)
Two options; prefer (a):
- **(a) No code, document the three calls.** A session publishes with
  `mcp__design__create_artifact(kind="video-bundle", files=[index.html, audio/*, SPEC.md])`
  → PUT each file → `finalize_artifact`. Add this recipe to AUTHORING.md. Zero new code.
- **(b) `ship-proven video publish <folder>` wrapper** (if a CLI exists to host it)
  that loops the PUT, defaults `kind`, writes `SPEC.md` provenance, and optionally
  runs a render check. Pure convenience over (a).
Decision gate: only build (b) once there's a CLI to put it in; (a) unblocks now.

## Step 5 — Render check, de-laptopped (optional, later)
- Today `check_render.sh` is a local script. For portability, fold "renders
  non-blank?" into the publish wrapper (b) or a small platform headless check.
- Not required for a publish to succeed; it just catches a blank page pre-seal.

## Step 6 — First real embed  (leartech-ship-proven-website)
- Publish one bundle (e.g. the `plan-dag` explainer) as a `video-bundle` artifact.
- A `kind:pr` Plan on `leartech-agent-ng` whose goal: "consume video-bundle
  artifact `<id>`; drop it into `src/assets/videos/plan-dag/` and add a component
  that iframes it." Plan holds the artifact **id**, not the bytes.
- verify-release-flow auto-injects (R23); normal gates apply.

---

## Order of work
1. Step 1 (this repo) + Step 2 (catalog doc) in parallel — both just docs/examples.
2. Step 3 (serve it) — small Go PR with tests.
3. Step 4a (document the publish recipe) — unblocks real publishes immediately.
4. Step 6 (first embed via ng Plan) — proves the end-to-end loop on the website.
5. Step 4b / Step 5 (wrapper + de-laptopped render check) — only if/when a CLI
   host exists and we want the convenience.

## First publishable milestone
After Steps 1–4a + 6: a reviewed standard, served guidance, a real
`video-bundle` artifact in the registry, and a merged PR embedding it on the
Ship Proven website — using **existing** artifact-api and **no new MCP**.
