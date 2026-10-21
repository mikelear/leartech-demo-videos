# Worked example: "make me a video about repo X" — what actually happens

## First, the thing you just asked: WHERE does the copy/clone/render happen?

**All of it happens LOCALLY, in the shell session — not on the MCP.** This is the
whole reason there's no GH-credential problem:

- The **shell** (this session, on your machine) runs `git clone`, reads files,
  copies the example page, edits beats, and writes the local HTML. It uses **your**
  `gh`/git credentials — the ones already authenticated here.
- The **MCP** only ever returns **text** (the standard doc) and, at publish time,
  **stores an artifact** (create → presigned PUT → finalize). It never clones,
  never reads a repo, never needs a GitHub token. That's why we didn't have to
  give it one.

So "copy the closest page" = a local `cp` in the shell's working dir. The MCP is
not in that path at all. The only moment the MCP is involved is step 6 (publish),
and even then the **bytes go direct from your machine to GCS** via the presigned
URL — the MCP is a control plane that hands out the URL and seals the manifest.

```
YOUR MACHINE (shell)                         MCP / platform
  git clone leartech-demo-videos   ───────── (not involved)
  git clone mikelear/<repo-X>      ───────── (not involved)
  ask for the standard doc         ────────► ship_proven server returns TEXT
  gateway__search / gh / plan-api  ────────► (gateway + plan-api; still not the design MCP)
  cp example.html → site/<slug>.html  ────── local, your creds
  edit beats, open the HTML locally  ─────── local
  publish: create_artifact         ────────► design MCP returns a presigned PUT URL
  PUT the bytes ───────────────────────────► GCS (direct; MCP never sees bytes)
  finalize_artifact                ────────► design MCP seals the manifest
```

If we ever wanted a **hosted** designer (no laptop), THAT is when the MCP would
need repo access — and we'd add a narrow read-only `read_repo_file` verb behind a
platform GitHub app with its own scope. Until then, clone + copy are local and the
credential question never arises.

---

## The honest answer to "does it build from the examples or from scratch?"


There are **two layers of knowledge**, and only one is served by the MCP:

| Layer | Where it lives | Served by the MCP? | Enough to BUILD from? |
|---|---|---|---|
| **The loop + the feature NAMES** | catalogue doc `designing-videos-in-ship-proven.md` (72 lines) | ✅ yes (`designing_videos_in_ship_proven`) | ❌ no — it's the *map*, not the *material* |
| **The actual how (beat shape, the ~20k-line reference pages, FEATURES.md field-by-field)** | the `leartech-demo-videos` repo | ❌ no | ✅ yes — you COPY the closest page |

So: **the MCP doc tells the session the loop and points it at the repo. The build
material is the repo itself.** The session must have the repo to copy from —
otherwise it would build a lookalike from scratch and drift from the standard.

That's deliberate (it mirrors design: the MCP serves text, the bytes/examples
live where they're reviewed). But it means **the clone is a required step**, and
right now the catalogue doc only *names* the repo — it doesn't force the session
to clone it before rendering. That's the gap to close.

## The intended flow, end to end

```
1. You:   "clone the videos repo and the repo I want a video about"
   Shell:  git clone leartech-demo-videos           # the STANDARD + examples
           git clone mikelear/<repo-X>              # the subject's real source
```
```
2. Shell asks the MCP for the loop:
           mcp__ship_proven__designing_videos_in_ship_proven   # the map
   → it learns: research → render ONE self-playing page against the fixed
     feature vocabulary in leartech-demo-videos → feedback → publish.
```
```
3. Research (REAL data, never invented):
           gateway__search  ...                      # look-and-feel refs
           mcp__plan__get_plan / get_plan_gates      # real plan/step/PR state
           gh pr view|diff|checks  (repo-X)          # real PR metadata
           read <repo-X clone> files                 # real screen markup/paths
   Output: a beat spec (FEATURES.md shape) filled with REAL values.
```
```
4. Render — COPY the closest reference page, don't start blank:
           cp leartech-demo-videos/site/plan-dag.html  site/<slug>.html
           edit the BEATS array + panels to the beat spec
   The ~20k-line pages ARE the implementation of every effect; copying one is how
   you inherit spotlight/pins/zoom/reveal/voiceover correctly instead of
   re-deriving them.
```
```
5. Feedback — open site/<slug>.html locally, watch it, revise. (Your "local HTML".)
```
```
6. Publish — the folder becomes a kind:video-bundle artifact
           create_artifact(kind="video-bundle", files=[<slug>.html, audio/*, SPEC.md])
           → PUT each → finalize
```

## So, concretely, for repos in `mikelear` now

Today (before any further MCP work), you'd do exactly this in the shell:

> "Clone `leartech-demo-videos` and `mikelear/<repo>`. Read
> `designing_videos_in_ship_proven`. Research PR #N on `<repo>` with `gh` and the
> plan API, then build me a 3-screen video by copying the closest page in
> `leartech-demo-videos/site/`, and show me the local HTML."

That works now because the standard doc tells the session to copy the examples,
and the examples are in the cloned repo.

## The gaps this reveals (worth a follow-up)

1. **The catalogue doc should say "clone and COPY the closest page" explicitly** —
   not just "reference the examples". A session reading only the 72-line doc might
   still render from scratch. → one-line tightening of the doc (feature-loop PR).
2. **A machine-readable `features.json`** in the videos repo (name → beat field)
   so a session/agent can validate a beat spec against the standard without
   parsing prose. → feature-loop PR to this repo.
3. **A scaffold helper** (optional) — `cp` the closest page + strip its BEATS to a
   template — so "copy the closest example" is one command, not a judgement call.

## Does research spawn a BA agent?

No. "Research" here is **tools the session calls itself** — `gateway__search`,
`mcp__plan__*`, `gh`, reading the clone. It is not a spawned `leartech-agent-ba`
run. (A BA *question* Issue is a different mechanism, for when a capability is
UNKNOWN — e.g. an unsupported store/language — not for gathering a video's data.)
If we later wanted hosted, no-laptop research, that'd be a deliberate new verb,
not a BA agent.
