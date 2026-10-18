#!/usr/bin/env bash
# Record your OWN voiceover, one beat at a time, straight to site/audio/<slug>-beatNN.mp3.
#
# It reads the narration lines out of a video page (the say:'…' fields), prints each
# like a teleprompter, waits for you to press ENTER, records until you press ENTER
# again, trims the silence at both ends, then encodes to mp3. Re-run a single beat
# any time.
#
# Requires: ffmpeg (brew install ffmpeg). macOS mic via avfoundation.
#
# Usage:
#   ./record-voice.sh plan-dag            # record every beat of site/plan-dag.html
#   ./record-voice.sh plan-dag 4          # re-record just beat 4
#   MIC=1 ./record-voice.sh plan-dag      # pick a different mic index (see list below)
#   ./record-voice.sh --list              # list mics and exit
set -euo pipefail
cd "$(dirname "$0")"

MIC="${MIC:-1}"   # 1 = MacBook Pro Microphone (from ffmpeg device list)
# silence the Continuity-camera noise macOS prints on every avfoundation open
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES

if [ "${1:-}" = "--list" ]; then
  ffmpeg -f avfoundation -list_devices true -i "" 2>&1 | sed -n '/audio devices/,$p' | grep -E '^\[.*\] \[[0-9]+\]'
  exit 0
fi

SLUG="${1:?usage: ./record-voice.sh <page-slug> [beat]}"
ONLY="${2:-}"
PAGE="site/${SLUG}.html"
[ -f "$PAGE" ] || { echo "no such page: $PAGE"; exit 1; }
mkdir -p site/audio

python3 - "$PAGE" > /tmp/narration.txt <<'PY'
import re,sys
s=open(sys.argv[1]).read()
for line in re.findall(r"say:'([^']*)'", s):
    print(line)
PY
N=$(wc -l < /tmp/narration.txt | tr -d ' ')
[ "$N" -gt 0 ] || { echo "no say:'…' lines found in $PAGE"; exit 1; }

echo "══════════════════════════════════════════════════════════════"
echo " Voiceover recorder — $SLUG   ($N beats)   mic index: $MIC"
echo " Flow: [enter] to start, read the line, [enter] to stop. Silence is trimmed."
echo "       Redo any beat with:  ./record-voice.sh $SLUG <n>"
echo "══════════════════════════════════════════════════════════════"

record_one(){
  local i="$1" line out raw
  line=$(sed -n "${i}p" /tmp/narration.txt)
  out=$(printf "site/audio/%s-beat%02d.mp3" "$SLUG" "$i")
  raw="/tmp/${SLUG}-beat${i}.wav"
  echo
  printf '\033[1m─ BEAT %02d / %02d ─────────────────────────────────────\033[0m\n' "$i" "$N"
  printf '\033[38;5;221m“%s”\033[0m\n' "$line"
  printf '\033[2m[enter] to START…\033[0m'; read -r _
  echo "   ● recording — press [enter] the instant you finish speaking"
  # background recorder; quiet. -nostdin so our read() owns the keyboard.
  ffmpeg -nostdin -hide_banner -loglevel fatal \
         -f avfoundation -i ":${MIC}" -ac 1 -ar 44100 "$raw" >/dev/null 2>&1 &
  local pid=$!
  read -r _
  kill -INT "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true
  # trim silence at start AND end, then encode mono mp3.
  #  - silenceremove start: drop leading quiet below -45dB
  #  - areverse twice to trim the tail the same way
  ffmpeg -y -hide_banner -loglevel error -i "$raw" \
    -af "silenceremove=start_periods=1:start_silence=0.1:start_threshold=-45dB,areverse,silenceremove=start_periods=1:start_silence=0.2:start_threshold=-45dB,areverse" \
    -codec:a libmp3lame -q:a 5 "$out"
  rm -f "$raw"
  local dur; dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$out")
  printf '   ✔ saved %s  (%.1fs after trim)\n' "$out" "$dur"
  if awk "BEGIN{exit !($dur>20)}"; then
    echo "   ⚠ that is long — if you paused mid-line, redo:  ./record-voice.sh $SLUG $i"
  fi
}

if [ -n "$ONLY" ]; then record_one "$ONLY"
else for i in $(seq 1 "$N"); do record_one "$i"; done; fi

echo
echo "Done. Toggle 'Voiceover (MP3)' on the page to hear your track."
echo "Then lock beat timings to your takes:  ./measure-audio.sh $SLUG"
