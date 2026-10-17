# Making demos — repeatable process

This folder holds two worked examples and a launcher. Start with `./run.sh`.

## What's here
```
run.sh              launcher — ./run.sh 1 | 2 | all
play.sh             demo 1 player (synthetic PR flow)
play2.sh            demo 2 player (real PR #5, terminal<->review split)
script.md           demo 1 narrative (beats)
demo2-script.md     demo 2 narrative (beats)
assets/
  pr-metadata.txt   demo 1 cutaway: PR meta block
  gates.txt         demo 1 cutaway: CI gates (linked by HEAD SHA)
  pr5-metadata.txt  demo 2 cutaway: real PR #5 code-review card
  pr5-review.txt    demo 2 cutaway: real adopt-pr / review trail
```

## The two demos
- **Demo 1 (synthetic).** Terminal -> PR metadata -> CI gates. The link the
  viewer learns is the **HEAD SHA**: the same sha on the PR card is what the
  gates run against. Pure test data, safe to edit freely.
- **Demo 2 (real).** Split screen: Terminal on the left, code-review card +
  review trail on the right. Data is pulled from plan-api
  (`get_plan blockchain-service-endpoints`, step `read-endpoints`, PR #5).
  The link is **the PR number / status.targetPR**: `pr: 5` in the Terminal is
  the same `#5` on the review card, and the `adopt-pr` decision that wrote
  `status.targetPR=5` is why the step settled.

## How to play
```
./run.sh              # menu
./run.sh 2            # play demo 2 at narration pace
SPEED=0 ./run.sh 2    # fast, no delays (good for checking content)
./run.sh 2 --step     # press Enter between beats (good for recording voiceover)
./run.sh all          # both, back to back
```

## Inputs -> outputs (what each stage produces)
1. WRITE a `*-script.md`     (beats: SCREEN/TYPED/NARRATION/CALLOUT/WHY)
2. GATHER assets/            (real screenshots, or .txt cutaways like these)
   - real data comes from the Terminal itself (e.g. plan-api get_plan)
3. PREVIEW with a play*.sh   (the ASCII player here — proves pacing + links)
4. RECORD terminal           asciinema rec casts/<name>.cast        (free)
5. COMPOSE                   OBS: screen + picture-in-picture cutaways (free)
6. EDIT + CALLOUTS           Kdenlive / Shotcut: arrows, text, timing  (free)
7. RENDER                    render/demo.mp4

## Free tools
asciinema (record term) · OBS Studio (composite + PiP + overlays) ·
Kdenlive or Shotcut (edit + callouts) · Carbon / Silicon (pretty code/PR cards).

## Rules that keep demos consistent
- One `*-script.md` per demo; every beat names SCREEN + TYPED + NARRATION +
  CALLOUT + WHY.
- Cutaways animate IN as the related command is TYPED — never before.
- Every CALLOUT states WHY it matters and how it links to the other screen
  (Demo 1: HEAD SHA; Demo 2: PR number / status.targetPR).
- Keep beats 5-12s. Re-record a cast rather than fixing typos frame by frame.
- Prefer REAL data (demo 2) over synthetic (demo 1) for anything shown externally.

## New demo, from this template
```
cp demo2-script.md <name>-script.md      # edit the beats
# add cutaways under assets/ (pull real data from the Terminal)
cp play2.sh play-<name>.sh               # adjust LEFT[] + file refs
# add a case to run.sh
```
