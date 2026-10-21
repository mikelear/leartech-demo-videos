# A real worked run: build a video from the shell (bash + fresh clones + Tekton)

Status of the platform wiring, so you know what's live:
- `leartech-plan-catalog#121` (the served standard doc) — **open, green, awaiting review**.
- `leartech-mcp-servers#153` (serves it as `designing_videos_in_ship_proven`) — **open, checks running**.
- So the *served guidance* isn't live until those merge. **Everything below works
  today anyway**, because the shell clones the examples repo and uses bash — it
  doesn't depend on the MCP serving the doc.

The subject: a video about **PR #239** on `leartech-orchestrator-controller`
(the maestro-audience fix), showing the terminal, the GitHub PR, and the **Tekton
dashboard** for its CI — three screens, all real.

---

## Step 0 — set up a clean workspace (bash, local, your creds)
```bash
mkdir -p ~/leartech/video-run && cd ~/leartech/video-run
git clone https://github.com/mikelear/leartech-demo-videos          # the STANDARD + examples
git clone --depth 1 https://github.com/mikelear/leartech-orchestrator-controller  # the subject's source
```
You tell the shell where these are; it reads them with bash. Nothing on the MCP.

## Step 1 — get the loop (served doc once merged; the repo's docs until then)
```bash
# once #121/#153 merge:
#   ask the shell: designing_videos_in_ship_proven
# until then, the same content is in the examples repo:
sed -n '1,80p' leartech-demo-videos/FEATURES.md
sed -n '1,80p' leartech-demo-videos/AUTHORING.md
```

## Step 2 — RESEARCH with real data (never invented)

### The PR screen (GitHub)
```bash
R=mikelear/leartech-orchestrator-controller
gh pr view 239 --repo $R --json number,title,state,headRefName,baseRefName,author,additions,deletions
gh pr diff 239 --repo $R | head -60
gh pr checks 239 --repo $R          # ← this also gives you the Tekton URLs
```

### The Tekton dashboard screen (internal)
`gh pr checks` returns each check's `detailsUrl`, which ARE the Tekton dashboard
PipelineRun links. Pull them out, and (optionally) hit the dashboard/API your
shell can reach:
```bash
gh pr checks 239 --repo $R | awk -F'\t' '{print $1"\t"$4}'   # name  ->  detailsUrl
# e.g. gcp/test -> https://tekton-dashboard-jx.jx.leartech.com/#/namespaces/jx/pipelineruns/...-test-dlwwh
# your shell can curl the dashboard/API if it needs run detail:
#   curl -s "$DETAILS_URL" | ...        (bash can see it; the MCP cannot)
```

### An internal plan/step screen (plan-api), if the PR came from a plan
```bash
# via the shell's plan tools (read-only):
#   mcp__plan__get_plan <name>            → step phases, pr, prOutcome
#   mcp__plan__get_plan_gates <name> <step> → the same CI checks, platform-side
```

Collect the real values into a beat spec (FEATURES.md shape): title, branch,
head SHA, the gate list + their Tekton URLs, the diff hunk you want to show.

## Step 3 — RENDER by copying the closest example (local `cp`, then edit)
```bash
cd leartech-demo-videos
# closest shape: pr239 already is terminal+PR+gates; for a Tekton panel, plan-dag's
# pipeline panel is the closest third screen. Start from whichever is nearer:
cp site/pr239.html ../video-run-239.html
# then edit the BEATS array + panels:
#  - panel 1 terminal: the gh/plan commands you actually ran
#  - panel 2 github:   the real #239 metadata from step 2
#  - panel 3 tekton:   a 'pipeline' panel listing the real check names + a pin to the
#                      detailsUrl, reusing plan-dag.html's pipeline markup
```
The ~20k-line pages already implement spotlight/pins/zoom/reveal/voiceover — you
inherit them by copying, you don't re-derive them.

## Step 4 — FEEDBACK: open the local HTML
```bash
cd ~/leartech/video-run
python3 -m http.server 8080
# open http://localhost:8080/video-run-239.html , watch, tell the shell what to change
```
This is your "local HTML" — exactly like the examples, produced by the shell.

## Step 5 — (optional) your own voiceover, local
```bash
cd leartech-demo-videos
./record-voice.sh <slug>      # teleprompter per beat → audio/<slug>-beatNN.mp3
./measure-audio.sh <slug>     # lock beat timings to your takes
```

## Step 6 — PUBLISH as a versioned artifact (control-plane MCP; bytes → GCS)
```
# the shell calls:
#   mcp__design__create_artifact(kind="video-bundle",
#       label="orchestrator-239-explainer",
#       target="mikelear/leartech-orchestrator-controller",
#       files=[{path:"index.html"}, {path:"audio/beat01.mp3"}, ..., {path:"SPEC.md"}])
#   → PUT each file to the returned presigned URL   (direct to GCS, not via MCP)
#   → mcp__design__finalize_artifact(...)            (seals the revision)
```
`SPEC.md` is the video's rationale + provenance (which PR, which data, which
FEATURES revision) — the equivalent of design's DESIGN.md.

## Step 7 — (optional) embed on the website
A normal `kind:pr` Plan on `leartech-agent-ng`: goal "consume video-bundle
artifact `<id>`; drop it in `src/assets/videos/orchestrator-239/` and add a
component that iframes it." The Plan carries the artifact **id**, not the bytes;
verify-release-flow auto-injects; normal gates apply.

---

## What's local vs. platform (the one-line mental model)
- **Local (bash, your creds):** clone, `gh`, `curl` Tekton, read files, `cp` the
  example, edit beats, open the HTML, record audio. Can see *everything* you can.
- **Platform:** the gateway (web research spend), plan-api (read plan/gates), and
  the design/artifact MCP (hand out a presigned URL + seal the manifest). None of
  them clone or read your repos — which is why no GH token on the MCP is needed.
