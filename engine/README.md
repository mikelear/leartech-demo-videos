# The video engine — how a session uses it instead of writing it

## The problem this solves
Every video page used to inline the same ~180-line engine (spotlight, pins, zoom,
captions, scrubber, voiceover). The model re-emitted it each time as a giant
`write_file`. That's wasteful and drifts.

## The split
- `sp-video.js` + `sp-video.css` — the **engine**: the fixed implementation of
  every feature in FEATURES.md. Reviewed once, reused by every video.
- A video page now contains **only**: its panels (with `data-k` anchors) and a
  `BEATS` array passed to `SPVideo.mount({...})`. ~45 lines, not ~210.

See `TEMPLATE.html` and `example-pr-tekton/` for the whole thing.

## How a FRESH session knows to use it (the process)

1. The session asks the served standard: `designing_videos_in_ship_proven`.
   That doc points at `leartech-demo-videos` and says: **copy the engine, don't
   write one.**
2. The session gets the engine locally — either because it cloned
   `leartech-demo-videos` (the standard + examples), or by copying the two files
   next to its page:
   ```bash
   git clone https://github.com/mikelear/leartech-demo-videos
   cp leartech-demo-videos/engine/sp-video.{js,css} .
   cp leartech-demo-videos/engine/TEMPLATE.html index.html
   ```
3. It edits only the panels + the `beats:` array in `index.html` with the real
   data it researched (`gh`, plan-api, bash/Tekton). It does **not** rewrite the
   engine.
4. Open `index.html` served; iterate; publish the folder (`index.html`,
   `sp-video.js`, `sp-video.css`, optional `audio/`, `SPEC.md`) as a
   `kind:video-bundle` artifact.

Because the page `<script src="sp-video.js">`s the engine, a video bundle just
carries those two files alongside — still one self-contained folder, embeddable
by iframe or `assets/` copy.

## So the model writes almost nothing
The big `write_file` becomes a 45-line page. The engine is a reviewed asset in the
repo, fetched/copied — exactly the "don't re-derive from scratch" principle the
standard already states for the examples.

## Beat fields (the only thing an author writes)
```js
{ d:6, pane:'gh', set:['gh','tk'], keys:['g1'], zoom:'g3',
  pin:{target:'t1',side:'right',html:'…'}, fx:'type'|'out'|'swap',
  step:'2 · title', txt:'HTML shown', say:'plain spoken' }
```
- `set` present on any beat → panels reveal/dismiss to match (progressive reveal).
- `audioSlug`/`audioDur` + `audio/beatNN.mp3` → recorded voiceover; else browser speech.
- `nextVideo:{title,href}` → auto-advance.
