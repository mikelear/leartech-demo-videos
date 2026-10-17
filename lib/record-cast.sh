#!/usr/bin/env bash
# Record a player's output to an asciicast v2 .cast file (no asciinema needed).
# We capture the player's coloured output and synthesise timestamps so it
# replays beat-by-beat in asciinema-player on the web page.
#
# Usage: lib/record-cast.sh <player.sh> <out.cast> [cols] [rows] [dwell]
set -euo pipefail
cd "$(dirname "$0")/.."
PLAYER="$1"; OUT="$2"; COLS="${3:-96}"; ROWS="${4:-32}"; DWELL="${5:-3.4}"

RAW=$(SPEED=0 FORCE_COLOR=1 "./$PLAYER")
export RAW OUT COLS ROWS DWELL

python3 - <<'PY'
import json, os, re
out, cols, rows, dwell = os.environ["OUT"], int(os.environ["COLS"]), int(os.environ["ROWS"]), float(os.environ["DWELL"])
raw = os.environ["RAW"]
parts = [p for p in re.split(r'(?=\x1b\[3J)', raw) if p.strip()]
with open(out, "w") as f:
    f.write(json.dumps({"version":2,"width":cols,"height":rows,
        "theme":{"fg":"#d0d0d0","bg":"#0d1117"}}) + "\n")
    t = 0.0
    for p in parts:
        f.write(json.dumps([round(t,3), "o", p]) + "\n")
        t += dwell
print(f"wrote {out}: {len(parts)} beats, ~{t:.0f}s")
PY
