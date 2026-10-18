#!/usr/bin/env bash
# Re-measure the per-beat MP3 durations and write them into the page's AUDIO_DUR
# array, so beats stretch to exactly fit your recordings.
#
# Usage: ./measure-audio.sh plan-dag
set -euo pipefail
cd "$(dirname "$0")"
SLUG="${1:?usage: ./measure-audio.sh <page-slug>}"
PAGE="site/${SLUG}.html"
[ -f "$PAGE" ] || { echo "no such page: $PAGE"; exit 1; }

durs=()
i=1
while :; do
  f=$(printf "site/audio/%s-beat%02d.mp3" "$SLUG" "$i")
  [ -f "$f" ] || break
  d=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$f")
  durs+=("$(printf '%.1f' "$d")")
  i=$((i+1))
done
[ "${#durs[@]}" -gt 0 ] || { echo "no site/audio/${SLUG}-beat*.mp3 found"; exit 1; }

arr="[$(IFS=,; echo "${durs[*]}")]"
echo "measured: $arr"

python3 - "$PAGE" "$arr" <<'PY'
import re,sys
p,arr=sys.argv[1],sys.argv[2]
s=open(p).read()
if "const AUDIO_DUR=" in s:
    s=re.sub(r"const AUDIO_DUR=\[[^\]]*\];", f"const AUDIO_DUR={arr};", s, count=1)
    open(p,"w").write(s); print("updated AUDIO_DUR in",p)
else:
    print("AUDIO_DUR not found in",p,"- is voiceover wired on this page yet?")
PY
