# leartech-demo-videos

Self-playing, single-file explainer “videos” for Ship Proven — and the process to
make more. Each video is one static HTML page: real screens side by side, a
spotlight that moves between them, narration at the bottom, cross-screen pins
(arrow + tooltip on another panel), optional zoom, and an optional browser
voiceover. The videos chain automatically (“up next” countdown).

This repo is the **benchmark / reference** for producing demo videos.

## The reel (`site/`)

Open `site/index.html` (served, not `file://`, so query-string autoplay works):

```
cd site && python3 -m http.server 8080
# then visit http://localhost:8080/site/index.html   (or /index.html if serving site/)
```

Or from the repo root:

```
python3 -m http.server 8080
# http://localhost:8080/site/index.html
```

| # | Page | What it shows | Data source |
|---|------|---------------|-------------|
| 1 | `pr239.html` | One PR, four screens — terminal → review card → diff → CI gates, linked by the head SHA | PR #239, `leartech-orchestrator-controller` (live via `gh`) |
| 2 | `plan-dag.html` | A plan DAG → the merged PR it produced → the verify-release flow — **has zoom + voiceover** | plan `blockchain-service-endpoints` (plan API) |
| 3 | `showcase.html` | Feature reference: typewriter, connector line, live→after swap, zoom, voiceover | synthetic |
| 4 | `gate-catch.html` | A gate catches a mistake — agent’s PR doesn’t fix it, stays red, closed un-merged | plan `scratch-diagnose-a-check-it-did-not-break` (PR #3) |
| 5 | `bootstrap.html` | Nothing → a running service on GCP **and** Azure from one bootstrap plan | plan `blockchain-service-bootstrap` |

## Features (all built)

- **Moving spotlight** — dim every panel, brighten the active one.
- **In-panel highlight** — ring the exact line / check being discussed.
- **Cross-screen pins** — arrow + tooltip on *another* panel, extra text above the main narration.
- **Zoom** — push in on the active panel and magnify the ringed element (videos 2 & 3).
- **Voiceover** — toggle the browser Speech Synthesis API to read each beat’s `say:` line (videos 2 & 3). No audio files needed; it uses the viewer’s installed system voice.
- **Connector line** — animated SVG wire between panels (video 3).
- **Live → after** — flip a check from pending to merged on screen (video 3).
- **Auto-advance** — “up next” countdown that plays the next video; `?autoplay=1` starts on arrival.
- **Scrubber + chapters** — click the track to jump; each beat is a chapter.

### Do I need to create/record a voice?

No. The voiceover uses the **browser’s built-in Speech Synthesis** (the viewer’s
OS voice), driven by the `say:` text already written into each beat. Nothing to
record. If you later want a *branded* voice, swap the `speak()` helper to play a
pre-rendered audio file per beat instead — the beat timings are already defined.

## Authoring a new video

Each page is self-contained. The moving parts live in two places:

1. **HTML panels** — give any element you want to spotlight/pin/zoom a
   `data-k="..."` key.
2. **`BEATS` array** (in the page’s `<script>`) — one object per beat:
   ```js
   { d:6,                       // seconds
     pane:'term',               // which panel is active/spotlit
     keys:['t2'],               // data-k elements to highlight in the active panel
     step:'2 · title',          // caption eyebrow
     txt:'HTML narration…',     // caption body (shown)
     say:'plain narration…',    // optional voiceover line (spoken)
     pin:{target:'g1',side:'left',html:'…'},  // optional cross-screen arrow+tooltip
     zoom:'g4' }                // optional element to magnify
   ```

The ASCII players (`play*.sh`, `lib/ui.sh`) and `casts/` are the earlier
terminal-only prototypes kept for reference; `PROCESS.md` documents the full
inputs→outputs pipeline and the free tools (asciinema, OBS, Kdenlive/Shotcut).

## Data provenance

Metadata in videos 1, 2, 4, 5 was captured live via `gh` and the plan API on
2026-10-17. Video 3 is synthetic. Terminal panels reconstruct the real plan
steps faithfully.
