#!/usr/bin/env bash
# Shared presentation helpers: 256-colour, box drawing, syntax-ish highlighting.
# Source this from a player:  . lib/ui.sh
# Portable to macOS bash 3.2 (no mapfile). Respects NO_COLOR / non-tty.

if [ -n "${NO_COLOR:-}" ] || { [ ! -t 1 ] && [ -z "${FORCE_COLOR:-}" ]; }; then
  CE=""; col(){ printf '%s' "$2"; }
else
  CE=$'\033[0m'; col(){ printf '\033[38;5;%sm%s\033[0m' "$1" "$2"; }
fi
# palette (256-colour)
FG=250; DIM=244; GREEN=42; RED=203; YELLOW=221; BLUE=75; PURPLE=177; CYAN=80; ORANGE=215
bold(){ printf '\033[1m%s\033[0m' "$1"; }
dim(){  col $DIM "$1"; }

# vlen <string>  — visible length, ignoring ANSI escapes
vlen(){ local s; s=$(printf '%s' "$1" | sed $'s/\033\\[[0-9;]*m//g'); printf '%s' "${#s}"; }
rep(){ local n=$1 ch=${2:-─} out=''; while [ "$n" -gt 0 ]; do out="$out$ch"; n=$((n-1)); done; printf '%s' "$out"; }

# box <colour> <title>   — draws a rounded box around stdin (colour-safe width)
box(){ local bc="$1" title="$2" w=0 line
  local tmp; tmp=$(cat); local IFS=$'\n'
  for line in $tmp; do local n; n=$(vlen "$line"); [ "$n" -gt "$w" ] && w=$n; done
  [ $(( ${#title}+2 )) -gt "$w" ] && w=$(( ${#title}+2 ))
  printf '%s %s %s%s\n' "$(col $bc '╭─')" "$(bold "$title")" \
    "$(col $bc "$(rep $((w-${#title}-1)))")" "$(col $bc '╮')"
  for line in $tmp; do
    local pad=$(( w - $(vlen "$line") ))
    printf '%s %s%s %s\n' "$(col $bc '│')" "$line" "$(rep $pad ' ')" "$(col $bc '│')"
  done
  printf '%s%s%s\n' "$(col $bc '╰')" "$(col $bc "$(rep $((w+2)))")" "$(col $bc '╯')"
}

# state badges
badge(){ case "$1" in
  merged)   printf '\033[48;5;93;38;5;231m MERGED \033[0m';;
  open)     printf '\033[48;5;28;38;5;231m OPEN \033[0m';;
  approved) col $GREEN '✓ approved';;
  changes)  col $ORANGE '± changes requested';;
  pass)     col $GREEN '✔';;
  run)      col $YELLOW '⧗';;
  wait)     col $DIM '○';;
esac; }

# diffline "+added" / "-removed" / "@@hunk@@"
diffline(){ case "$1" in
  +*)  col $GREEN "$1";;
  -*)  col $RED   "$1";;
  @@*) col $CYAN  "$1";;
  *)   dim "$1";;
esac; printf '\n'; }
