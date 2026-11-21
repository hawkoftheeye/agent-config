#!/usr/bin/env bash
# ~/.claude/statusline-command.sh
# Claude Code status line — mirrors the bash PS1 from ~/.config/bash/rc.d/30-prompt.sh
# (green hostname, blue cwd, red git branch) plus Claude session info.
# Context is rendered as a right-aligned graphical gauge.

input=$(cat)

# Parse JSON fields using python3 (jq not available on this machine)
py_get() {
  printf '%s' "$input" | python -c "import sys,json; d=json.load(sys.stdin); print($1,end='')" 2>/dev/null || true
}

# --- PS1-derived segments ---
host=$(hostname -s 2>/dev/null || hostname)

cwd=$(py_get "d.get('workspace',{}).get('current_dir','')")
[ -z "$cwd" ] && cwd="$(pwd)"

branch=$(py_get "d.get('workspace',{}).get('git_worktree','')")
if [ -z "$branch" ]; then
  branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null || true)
fi

# --- Claude session segments ---
model=$(py_get "d.get('model',{}).get('display_name','')")
remaining=$(py_get "str(d.get('context_window',{}).get('remaining_percentage') or '')")

# --- ANSI colours (same palette as PS1) ---
GREEN='\033[01;32m'
BLUE='\033[01;34m'
RED='\033[31m'
CYAN='\033[01;36m'
YELLOW='\033[01;33m'
RESET='\033[00m'

# --- Build left part (track visible text separately for width calculation) ---
left_text="$host"
left="$(printf "${GREEN}%s${RESET}" "$host")"

left_text="$left_text $cwd"
left="$left $(printf "${BLUE}%s${RESET}" "$cwd")"

if [ -n "$branch" ]; then
  left_text="$left_text ($branch)"
  left="$left $(printf "${RED}(%s)${RESET}" "$branch")"
fi

if [ -n "$model" ]; then
  left_text="$left_text [$model]"
  left="$left $(printf "${CYAN}[%s]${RESET}" "$model")"
fi

# --- Build context gauge (right-aligned) ---
right=""
right_text=""
if [ -n "$remaining" ]; then
  pct=$(printf "%.0f" "$remaining")
  filled=$((pct * 10 / 100))
  empty=$((10 - filled))

  gauge_chars=""
  i=0
  while [ $i -lt $filled ]; do
    gauge_chars="${gauge_chars}█"
    i=$((i + 1))
  done
  while [ $i -lt 10 ]; do
    gauge_chars="${gauge_chars}░"
    i=$((i + 1))
  done

  # Green ≥ 50%, yellow ≥ 25%, red below
  if [ "$pct" -ge 50 ]; then
    CTX_COLOR='\033[32m'
  elif [ "$pct" -ge 25 ]; then
    CTX_COLOR=$YELLOW
  else
    CTX_COLOR=$RED
  fi

  right_text="[${gauge_chars}] ${pct}%"
  right="$(printf "${CTX_COLOR}[%s] %d%%${RESET}" "$gauge_chars" "$pct")"
fi

# --- Compose line ---
if [ -n "$right" ]; then
  # Try multiple methods to get terminal width — tput/COLUMNS don't work in non-interactive subshells
  if [ -n "$COLUMNS" ] && [ "$COLUMNS" -gt 0 ] 2>/dev/null; then
    term_width="$COLUMNS"
  else
    term_width=$(stty size 2>/dev/null | awk '{print $2}')
    if [ -z "$term_width" ] || ! [ "$term_width" -gt 0 ] 2>/dev/null; then
      term_width=$(tput cols 2>/dev/null)
    fi
    if [ -z "$term_width" ] || ! [ "$term_width" -gt 0 ] 2>/dev/null; then
      term_width=120
    fi
  fi
  # Unicode block chars (█ ░) are 3 bytes in UTF-8; count display chars via python to get true display width
  left_len=$(printf '%s' "$left_text" | python -c "import sys; print(len(sys.stdin.read()))" 2>/dev/null || echo ${#left_text})
  right_len=$(printf '%s' "$right_text" | python -c "import sys; print(len(sys.stdin.read()))" 2>/dev/null || echo ${#right_text})
  # Subtract 1 as a safety margin so the last char never clips at the terminal edge
  pad=$((term_width - left_len - right_len - 1))
  [ "$pad" -lt 1 ] && pad=1
  padding=$(printf '%*s' "$pad" '')
  printf "%b%s%b\n" "$left" "$padding" "$right"
else
  printf "%b\n" "$left"
fi
