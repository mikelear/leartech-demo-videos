# Authoring a Ship Proven demo video — instructions for a new session

Read `FEATURES.md` first: it is the shared vocabulary. This file is the process.

## What a video IS
One self-contained HTML page in `site/`. No build step, no framework. It plays
itself: a timeline of **beats** drives a **spotlight**, **pins/wires**, **zoom**,
panel **reveal/dismiss**, a **caption** (shown + spoken), and the **scrubber /
auto-advance** chrome. Copy an existing page; don’t invent a new structure.

## Golden rule: data must be REAL
Every screen reflects real platform state. Pull it, don’t imagine it.
- Plans/steps/PR numbers: `mcp__plan__get_plan`, `list_plans`, `get_plan_gates`.
- PR metadata / checks / diff: `gh pr view <n> --repo <r> --json …`, `gh pr diff`, `gh pr checks`.
- Record provenance (what tool, which day) in the page footer and the commit.

## The process, start to finish
1. **Pick the story.** One sentence: what should the viewer understand?
   (e.g. “a gate caught a bad PR and nothing shipped”.)
2. **Gather real data** with the tools above. Keep the raw output.
3. **Choose the screens** (1–3 panels) and give every element you’ll reference a
   `data-k="…"` key.
4. **Write the beats.** One object per beat (see the shape below). Order them so
   the camera moves left→right and every claim links to another screen.
5. **Write narration twice per beat:** `txt` (HTML, shown) and `say` (plain, spoken).
6. **Preview** served, not `file://`: `python3 -m http.server 8080` → open the page.
7. **Voiceover (optional).** `./record-voice.sh <slug>` to record your own, then
   `./measure-audio.sh <slug>` to lock beat timings to the takes. Without MP3s the
   page uses the browser Synth voice automatically.
8. **Link it in:** add a card to `site/index.html`, set the previous video’s
   `nextVideo` to auto-advance here, and give this page a `?autoplay=1` entry.
9. **Commit & push** with a message that states the story and the data source.

## The beat shape (the one thing to get right)
```js
{ d: 6,                 // seconds (auto-stretches to the MP3 when voiceover is on)
  pane: 'gh',           // SPOTLIGHT: which panel is in focus
  set: ['term','gh'],   // which panels are on stage (grow = REVEAL, shrink = DISMISS)
  keys: ['g3'],         // HIGHLIGHT: data-k elements to ring in the active panel
  zoom: 'g3',           // ZOOM: optional element to magnify
  pin: { target:'t4', side:'right', html:'<b>← from</b> the step' },  // PIN on another panel
  wire:{ from:'typed', to:'g1' },   // WIRE: optional connector line
  fx: 'type'|'out'|'swap',          // TYPEWRITER / output / LIVE→AFTER
  step:'5 · title',     // caption eyebrow
  txt:'HTML narration', // CAPTION shown (word-revealed)
  say:'plain narration' // VOICEOVER spoken (and Synth fallback)
}
```

## Reference pages (copy the closest one)
- `pr239.html` — 4 logical screens of ONE PR; pins; caption cues.
- `plan-dag.html` — 3 panels; zoom; **recorded + synth voiceover**; the fullest example.
- `gate-catch.html` — 3 panels, the “safety” story.
- `bootstrap.html` — 3 panels, two clouds.
- `reveal.html` — **reveal**: one screen becomes three.
- `handoff.html` — **reveal + dismiss**: a screen enters, then leaves.
- `showcase.html` — every effect isolated (typewriter, wire, swap, zoom, voiceover).

## Don’t
- Don’t fabricate PR numbers, SHAs, or check results.
- Don’t add a bundler/framework — these are static pages on purpose.
- Don’t cut narration off: when voiceover is on, beats stretch via `AUDIO_DUR`.

## Is a headless MP4 export worth it?
Usually no. It would fork the format (a second renderer to keep in sync). The HTML
page is the artifact; to share a file, **screen-capture the playing page with OBS**.
Only build a headless exporter if a distribution channel truly needs a flat MP4.
