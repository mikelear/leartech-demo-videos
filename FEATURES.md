# Ship Proven demo videos — the feature vocabulary

A shared language so anyone (a person or another session) can *order* a video in
plain words, and so the engine has one name per behaviour. Each feature has a
**name**, what it does, and the **script field** that turns it on.

A video is a list of **beats**. A beat is one span of time with: which screen is
in focus, what’s highlighted, which cross-screen notes show, and the narration.

---

## Screens (the panels on the STAGE)

- **Panel** — one screen: a `terminal`, a `github` card, a `pipeline`, a `diff`, a `cloud` column.
- **Stage** — the row of panels. 1, 2 or 3 wide.

## Camera & focus

- **Spotlight** — dim every panel, brighten the active one.  `beat.pane`
- **Highlight** — ring a specific element inside a panel.  `beat.keys: ['g3']`
- **Zoom** — push in on the active panel and magnify one element.  `beat.zoom: 'g3'`
  - (“zoom out” = simply the next beat with no `zoom`, camera returns to normal.)

## Cross-screen storytelling

- **Pin** — an arrow + tooltip placed on *another* panel, with its own text
  (extra writing beyond the bottom narration).  `beat.pin: {target, side, html}`
- **Wire** — an animated connector line drawn between two elements/panels.  `beat.wire: {from, to}`

## Panels entering & leaving (choreography)

- **Reveal** — bring a panel ONTO the stage mid-video (slides in).  `beat.set` grows
- **Dismiss** — send a panel OFF the stage mid-video (slides out).  `beat.set` shrinks
- **Handoff** — a reveal followed later by a dismiss of the same panel (a named combo).

## State changes inside a panel

- **Typewriter** — a command types itself in character by character.  `beat.fx:'type'`
- **Swap** (a.k.a. **Live→After**) — flip a value on screen (pending→merged, red→green).  `beat.fx:'swap'`

## Narration

- **Caption** — the bottom narration bar.  `beat.txt` (shown) / `beat.say` (spoken)
- **Word-reveal** — caption pops in and reveals word-by-word to draw the eye (always on).
- **Voiceover** — audio track. Two sources, user’s choice:
  - **Recorded** — your own MP3 per beat (`audio/<slug>-beatNN.mp3`). Record with `record-voice.sh`.
  - **Synth** — the browser Speech API reads `beat.say`. Automatic fallback when no MP3.

## Flow

- **Scrubber** — click the timeline to jump; each beat is a **Chapter**.
- **Auto-advance** — “Up next” countdown chains to the next video.  `nextVideo`
- **Autoplay** — `?autoplay=1` starts on arrival (used by auto-advance).

## Export (not a core feature)

- **Screen-capture** — record the playing page with OBS for an MP4. Preferred over a
  headless pipeline: the HTML stays the source of truth.

---

## How to ORDER a video (plain English → fields)

> “Three screens. Start on the **terminal** with a **typewriter** command. After the
> command, **reveal** the **github** panel and **pin** a note from the PR number back to
> the terminal. Then **zoom** the test check. **Reveal** a **pipeline** panel and draw a
> **wire** from the merge to the release. End with a **swap**: test goes green, PR flips
> to merged. **Recorded voiceover.** **Auto-advance** to video 2.”

Every bolded word is a feature above and maps to a beat field. That paragraph is a
complete, buildable spec.
