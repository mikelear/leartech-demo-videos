# Packaging as a product — the design-MCP pattern, applied to video

You're right: this IS the design loop. Research → render stand-alone HTML →
show the user → publish as a versioned artifact. The only video-specific part is
**what the research references** and **the artifact `kind`**. Below: the three
real questions.

---

## 1. "Special research" that can reference our repos / internal screens

The design MCP's research is `gateway__search` (look-and-feel, prior art). Video
research needs the same PLUS the ability to point at **real platform surfaces**,
because a video shows real screens. So "special research" = the normal research
with two extra, read-only sources:

- **The video repo itself** — the reference pages + FEATURES.md are the worked
  examples the agent copies (so it never invents structure).
- **Internal screens / data** — the tools that already exist:
  `mcp__plan__get_plan` / `get_plan_gates`, `gh pr view/diff/checks`, and a
  read-only clone of a named repo to read real diffs/paths.

Crucially this is **not new state**. It's a *reference list the agent is told to
read*, the same way design research is told "search the web". The seed list
("these are our example videos and screens") lives as **docs in this repo**
(FEATURES.md / AUTHORING.md / the reference pages), versioned in git — not in a
service table.

### So do we need an endpoint to "add repos"? No — and here's why it would hurt

Adding a repo-registry endpoint introduces exactly the state you're worried about:
a mutable list the MCP must own, back with storage, and keep in sync. The design
MCP deliberately avoids this — it has no "add a design source" endpoint; the
sources are the open web + the artifact registry it already reads.

Mirror that:
- **Example seeds** → git (this repo). PR to add an example. Reviewed, versioned,
  no runtime state.
- **Which repo THIS video is about** → a **parameter on the research call**
  (`research(topic, repos:[…])`), not a stored registry. Per-request, stateless.
- **Discovery of what exists** → `mcp__plan__list_plans`, `list_artifacts`,
  `gh repo list` — live reads, not a list we maintain.

That keeps the video MCP a **control-plane / stateless** service, same posture as
the artifact + design MCPs.

---

## 2. What a `kind: video-bundle` artifact looks like — does artifact-api support it?

Yes, unchanged. `kind` is a free string on the artifact manifest (today's registry
already carries `design-system`, `design-bundle`, `design-doc`, `markdown`). A
video is just another kind. The manifest is a list of files + sha/bytes; a video
bundle's files are simply the page and its audio:

```
kind:  video-bundle
label: plan-dag-explainer
target: mikelear/leartech-ship-proven-website      # who it's FOR
files:
  - path: index.html                 # the self-playing page (renamed from <slug>.html)
  - path: audio/beat01.mp3           # optional recorded voiceover
  - path: audio/beat02.mp3
  - path: SPEC.md                    # the beat spec + provenance (the 'DESIGN.md' of a video)
```

Publish is the identical cycle design uses: **create → presigned PUT (bytes go
direct to GCS) → finalize**. Same lineage, same sealed/immutable revisions, same
TTL. Nothing new in artifact-api. `ship-proven video publish <folder>` would own
the PUT, exactly as `design publish` does.

A site consumes it the same way too: resolve the artifact's download URL (or copy
the sealed bytes into `assets/`). The `target` field points dev agents / sites at
the right bundle.

---

## 3. The Plan route: who turns a bundle into an Angular PR?

Two distinct jobs — keep them apart:

**(a) Make the bundle** — the video MCP loop (research/scaffold/check/publish).
Output: a sealed `video-bundle` artifact. No Plan needed; this is interactive,
like designing.

**(b) Put it in the website** — a Plan with a `kind: pr` step whose dev agent
(`leartech-agent-ng` for Angular) reads the artifact and opens a PR that drops
the bundle into the Angular repo (`src/assets/videos/<slug>/` + a component that
iframes it). That's an ordinary dev-agent Initiative (R21): `{name, repo, branch,
goal}`, where the goal says "consume video-bundle artifact <id> and embed it".

So the route is:
```
video MCP loop ──► video-bundle artifact ──► Plan (kind: pr, agent=leartech-agent-ng)
                                             └─ reads the artifact, opens Angular PR
                                             └─ verify-release-flow auto-injects (R23)
```

The Plan does **not** hold the video; it holds a *reference to the artifact* in the
step goal, and the dev agent pulls the sealed bytes. (Same way a dev agent today
consumes a design artifact.) That keeps the Plan small, the bytes in GCS, and the
embed a normal reviewed PR through the standard gates.

---

## Recommendation (unchanged, now justified)

1. **It's the design pattern** — research → HTML → feedback → publish. Build the
   video MCP as a **sibling to design**, reusing artifact-api with `kind:video-bundle`.
2. **No "add repos" endpoint.** Example seeds live in this repo (git, reviewed);
   the repo a video is *about* is a **per-call parameter**; discovery is live reads.
   This avoids introducing state and keeps the MCP control-plane only.
3. **Two jobs, two mechanisms:** the MCP makes the bundle; a normal **`kind: pr`
   Plan on `leartech-agent-ng`** embeds it into the Angular site and goes through
   the usual gates. The Plan references the artifact id; it never carries the bytes.
4. **Keep the single-file format** — it's what makes the artifact trivially
   embeddable on anyone's site (iframe or `assets/` copy), Angular included.
