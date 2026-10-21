# Packaging this as a product — options & a recommendation

Question behind this: how do we let *anyone* design a video and put it on their
own site? Three sub-questions, answered in order.

---

## 1. Host-a-designer vs. ship-a-template — do both, in that order

They are not rivals; one feeds the other.

- **The artifact IS the deliverable.** A video is one self-contained HTML page
  (+ optional `audio/*.mp3`). It already runs on any static host. So the unit we
  hand a user is *the folder*, not a service.
- **The designer is how the folder gets made.** Same shape as Ship Proven design:
  research → render HTML → feedback → **publish as a versioned artifact**.

So: package the **template + authoring docs as a repo an LLM is pointed at**
(cheap, works today), and *also* expose a **"video design" path** that publishes
the result as an artifact (so dev agents and sites can consume it the same way
they consume designs).

## 2. How a user embeds it (Angular example)

The page is framework-agnostic. For an Angular project, the clean embed is an
iframe to the published artifact, or copy the folder into `src/assets/videos/`:

```html
<!-- component template -->
<iframe class="sp-video"
        [src]="videoUrl | safe"
        title="Ship Proven explainer"></iframe>
```
```
src/assets/videos/plan-dag/      ← the page + audio/, copied from the artifact
```

Nothing to build; the page carries its own JS/CSS. That's the whole point of the
single-file format, and the reason NOT to "do it as a proper Angular app" — the
moment it needs a framework it stops being portable to everyone's site.

## 3. The "Video Design" capability — MCP shape

### Add-on to the design MCP, or new MCP?

**New MCP, same contracts.** Reasons:
- The design MCP's *verbs* (create/revision/finalize/get/list artifacts) are
  generic — a video bundle is just another `kind`. We reuse the **artifact-api**
  unchanged (`kind: "video-bundle"`), so videos get lineage, GCS-direct upload,
  and dev-agent discovery for free. No new storage.
- What's *different* is the **research + render loop**, which is video-specific
  (the feature vocabulary in FEATURES.md, the beat model, the reference pages,
  the voiceover step). That belongs behind its own tool surface so the design
  MCP's guidance stays about look-and-feel, not timelines.

So: **`mcp__video__*` for the loop; artifact-api for storage.** Mirrors how
`ship-proven design publish` is a thin shell command over the generic artifact
cycle.

### What the tools look like

```
mcp__video__video_guidance()              → returns FEATURES.md + AUTHORING.md (the loaded standard)
mcp__video__list_examples()               → the reference pages in THIS repo (pr239, plan-dag, …)
mcp__video__research(topic, repos[])      → gateway__search + gh/plan-api pulls for REAL data
mcp__video__scaffold(spec)                → writes a new site/<slug>.html from the beat spec
mcp__video__check_render(file)            → Chrome-headless screenshot, assert non-blank (reuse design's check)
mcp__video__publish(folder, target)       → create → presigned PUT (page + audio) → finalize  == a video-bundle artifact
```

Publish is literally the design cycle with `kind:"video-bundle"`. A `research`
call is where the "point an LLM at our repos" idea becomes a tool:

### How the research element works

1. **Seed = this repo.** The reference pages + FEATURES.md + AUTHORING.md are the
   worked examples. `list_examples()` hands them over so the agent copies the
   closest one instead of inventing structure.
2. **Real data = the platform tools.** `research()` runs `gateway__search` for
   look/pattern references AND calls `mcp__plan__*` / `gh` to fetch the actual
   plan/PR/check data the video will show. (Golden rule: never fabricate a PR
   number or SHA.)
3. **Clone-on-demand.** For a video *about* a specific repo, the agent clones it
   (read-only) to read the real diff/paths — same as a dev agent would.
4. Output of `research()` is a **beat spec** (the FEATURES.md shape) pre-filled
   with real values, ready for `scaffold()`.

### Does it create artifacts like design does?

Yes — **the same way, different `kind`.** `design` → `design-bundle`/`design-doc`;
`video` → `video-bundle`. Same artifact-api, same sealed/lineage/TTL semantics,
same GCS-direct upload. A site then embeds by resolving the artifact's download
URL (or copying the sealed bytes into its repo).

---

## Recommendation (one line each)

1. **Keep the single-file format.** It's what makes "anyone's website" true. Do
   NOT rebuild as an Angular app.
2. **Ship this repo as the template + standard** an LLM is pointed at (works now).
3. **Add `mcp__video__*`** as a thin loop (research/scaffold/check/publish) over
   the **existing artifact-api** with `kind:"video-bundle"` — a sibling to design,
   not a fork of it.
4. **Embed = iframe to the artifact, or copy the folder** into `assets/`. One
   snippet, no build.
