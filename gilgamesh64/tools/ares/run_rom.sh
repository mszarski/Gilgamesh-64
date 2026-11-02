#!/usr/bin/env bash
# Headless N64 ROM runner built on ares (paraLLEl-RDP on Mesa lavapipe, LLE RSP) under Xvfb.
#
# Usage: run_rom.sh <rom.z64> <seconds> <out.png> [key-sequence]
#
#   <seconds>      wall-clock seconds to let the ROM boot/run before the key sequence starts
#   <out.png>      final screenshot (native N64 framebuffer, captured by ares itself)
#   [key-sequence] optional, whitespace/comma separated tokens, executed in order after <seconds>:
#        BUTTON         tap the N64 button (held 0.15 s)
#        BUTTON:SEC     hold the N64 button for SEC seconds
#        A+B:SEC        hold several buttons together (default 0.15 s)
#        wait:SEC       sleep SEC seconds
#        shot:FILE.png  take an intermediate screenshot
#        key:XKEY       tap a raw xdotool key name
#      Buttons: A B Z START L R  UP DOWN LEFT RIGHT (analog stick, full deflection)
#               DUP DDOWN DLEFT DRIGHT (d-pad)  CUP CDOWN CLEFT CRIGHT (C buttons)
#   Example: run_rom.sh game.z64 6 out.png "START wait:2 shot:/tmp/menu.png A UP:1.5 wait:1"
#
# Env: ARES_LOG=<file> (default <out>.log) receives ares stdout/stderr (incl. libdragon debugf
#      via ISViewer since HomebrewMode is on). KEEP_TMP=1 keeps the per-run temp dir.
#      ARES_EXTRA_ARGS="--setting General/ShowStatusBar=true ..." extra ares CLI args (word-split).
#      RAW_SHOT=1 keeps ares' raw VI-sized PNG (default: stretched to 4:3, e.g. 640x480).
#      WINDOW_SHOT=1 additionally saves <out>.window.png (Xvfb window grab, scaled output).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARES="${ARES:-$HERE/ares/build/rundir/bin/ares}"   # override with ARES=/path/to/ares
TEMPLATE="$HERE/ares-settings.template.bml"

if [ $# -lt 3 ]; then sed -n "2,/^set -e/p" "$0" | sed '$d' | sed 's/^# \{0,1\}//'; exit 2; fi
ROM="$(realpath "$1")"; SECS="$2"; OUT="$(realpath -m "$3")"; SEQ="${4:-}"
LOG="${ARES_LOG:-${OUT%.png}.log}"
[ -f "$ROM" ] || { echo "ROM not found: $ROM" >&2; exit 1; }
[ -x "$ARES" ] || { echo "ares binary missing: $ARES" >&2; exit 1; }

declare -A KEYMAP=(
  [A]=x [B]=c [Z]=z [START]=Return [L]=q [R]=e
  [UP]=Up [DOWN]=Down [LEFT]=Left [RIGHT]=Right
  [DUP]=i [DDOWN]=k [DLEFT]=j [DRIGHT]=l
  [CUP]=w [CDOWN]=s [CLEFT]=a [CRIGHT]=d
)

TMP="$(mktemp -d "${TMPDIR:-/tmp}/n64run.XXXXXX")"
mkdir -p "$TMP/shots"
cp "$TEMPLATE" "$TMP/settings.bml"
XVFB_PID=""; ARES_PID=""
cleanup() {
  [ -n "$ARES_PID" ] && kill "$ARES_PID" 2>/dev/null && sleep 0.3 && kill -9 "$ARES_PID" 2>/dev/null || true
  [ -n "$XVFB_PID" ] && kill "$XVFB_PID" 2>/dev/null || true
  [ "${KEEP_TMP:-0}" = 1 ] || rm -rf "$TMP"
}
trap cleanup EXIT

# Start Xvfb on a free display
DISP=""
for n in $(shuf -i 100-499 -n 40); do
  [ -e "/tmp/.X$n-lock" ] && continue
  Xvfb ":$n" -screen 0 800x600x24 -nolisten tcp >"$TMP/xvfb.log" 2>&1 &
  XVFB_PID=$!
  for _ in $(seq 50); do [ -e "/tmp/.X11-unix/X$n" ] && break; sleep 0.1; done
  if kill -0 "$XVFB_PID" 2>/dev/null && [ -e "/tmp/.X11-unix/X$n" ]; then DISP=$n; break; fi
  XVFB_PID=""
done
[ -n "$DISP" ] || { echo "Xvfb failed to start" >&2; cat "$TMP/xvfb.log" >&2; exit 1; }
export DISPLAY=":$DISP"

export VK_ICD_FILENAMES="${VK_ICD_FILENAMES:-/usr/share/vulkan/icd.d/lvp_icd.json}"
export SDL_AUDIODRIVER="${SDL_AUDIODRIVER:-dummy}"
export GDK_BACKEND=x11 NO_AT_BRIDGE=1

"$ARES" --settings-file "$TMP/settings.bml" --system "Nintendo 64" --no-file-prompt \
  --setting "Paths/Screenshots=$TMP/shots/" --setting "Paths/Saves=$TMP/" \
  ${ARES_EXTRA_ARGS:-} "$ROM" >"$LOG" 2>&1 &
ARES_PID=$!

press() {   # press <seconds> key...
  local dur="$1"; shift
  xdotool keydown "$@"; sleep "$dur"; xdotool keyup "$@"
  sleep 0.1
}

screenshot() {  # screenshot <dest.png>
  local dest="$1" before after f
  before="$(find "$TMP/shots" -name "*.png" | wc -l)"
  for attempt in 1 2 3; do
    press 0.2 F12
    for _ in $(seq 40); do
      after="$(find "$TMP/shots" -name "*.png" | wc -l)"
      [ "$after" -gt "$before" ] && break 2
      sleep 0.1
    done
  done
  f="$(find "$TMP/shots" -name "*.png" -printf "%T@ %p\n" | sort -n | tail -1 | cut -d" " -f2- || true)"
  if [ -n "$f" ] && [ "$after" -gt "$before" ]; then
    sleep 0.2; mkdir -p "$(dirname "$dest")"
    if [ "${RAW_SHOT:-0}" = 1 ]; then
      mv "$f" "$dest"
    else
      # ares saves the raw VI output (e.g. 640x240 for a 320x240 non-interlaced game);
      # stretch to the 4:3 aspect a TV would show (nearest-neighbour).
      local w; w="$(identify -format %w "$f")"
      convert "$f" -filter point -resize "${w}x$((w * 3 / 4))!" "$dest" && rm -f "$f"
    fi
  else
    echo "warn: ares screenshot hotkey failed; grabbing the X window instead" >&2
    import -display "$DISPLAY" -window root "$dest"
  fi
  echo "screenshot: $dest"
}

# Give the ares main window X input focus (no window manager under Xvfb); ares only
# handles hotkeys (screenshot) while its window is focused.
focus_ares() {
  local w
  w="$(xdotool search --onlyvisible --pid "$ARES_PID" 2>/dev/null | tail -1 || true)"
  [ -n "$w" ] && xdotool windowfocus --sync "$w" 2>/dev/null || true
}
for _ in $(seq 30); do
  xdotool search --onlyvisible --pid "$ARES_PID" >/dev/null 2>&1 && break; sleep 0.1
done
focus_ares
# RECORD=<file.mkv>: lossless screen capture of the whole Xvfb display for the rest of the run
if [ -n "${RECORD:-}" ]; then
  ffmpeg -loglevel error -y -f x11grab -draw_mouse 0 -framerate "${RECORD_FPS:-30}" -video_size 800x600 -i "$DISPLAY" \
    -c:v libx264 -preset ultrafast -qp 0 "$RECORD" </dev/null &
  REC_PID=$!
fi
sleep "$SECS"
focus_ares
kill -0 "$ARES_PID" 2>/dev/null || { echo "ares exited early; log: $LOG" >&2; cat "$LOG" >&2; exit 1; }

for tok in ${SEQ//,/ }; do
  case "$tok" in
    wait:*)  sleep "${tok#wait:}" ;;
    shot:*)  screenshot "$(realpath -m "${tok#shot:}")" ;;
    key:*)   press 0.15 "${tok#key:}" ;;
    *)
      btns="${tok%%:*}"; dur=0.15; [[ "$tok" == *:* ]] && dur="${tok#*:}"
      keys=()
      IFS='+' read -ra parts <<<"$btns"
      for b in "${parts[@]}"; do
        k="${KEYMAP[${b^^}]:-}"; [ -n "$k" ] || { echo "unknown button: $b" >&2; exit 1; }
        keys+=("$k")
      done
      press "$dur" "${keys[@]}" ;;
  esac
done

[ -n "$SEQ" ] && sleep 0.3
screenshot "$OUT"
if [ -n "${REC_PID:-}" ]; then kill -INT "$REC_PID" 2>/dev/null; wait "$REC_PID" 2>/dev/null; echo "recording: $RECORD"; fi
if [ "${WINDOW_SHOT:-0}" = 1 ]; then
  import -display "$DISPLAY" -window root -trim +repage "${OUT%.png}.window.png" && echo "window shot: ${OUT%.png}.window.png"
fi
