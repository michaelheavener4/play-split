#!/usr/bin/env bash
# Remove play-split files. Leaves Hyprland bindings/window rules in place.
set -euo pipefail

BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/play-split"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/play-split"
FLAGS="$HOME/.config/chromium-flags.conf"
HOST_NAME="com.play_split.captions"
EXT_DIR="$DATA_DIR/chromium-cc"

echo "Removing play-split binaries and data"

rm -f "$BIN_DIR/play-split" "$BIN_DIR/play-split-captions-host"
rm -rf "$DATA_DIR" "$STATE_DIR"

for dir in \
  "$HOME/.config/chromium" \
  "$HOME/.config/google-chrome" \
  "$HOME/.config/google-chrome-beta" \
  "$HOME/.config/google-chrome-unstable" \
  "$HOME/.config/BraveSoftware/Brave-Browser" \
  "$HOME/.config/BraveSoftware/Brave-Browser-Beta" \
  "$HOME/.config/BraveSoftware/Brave-Browser-Nightly" \
  "$HOME/.config/microsoft-edge" \
  "$HOME/.config/microsoft-edge-dev"
do
  rm -f "$dir/NativeMessagingHosts/$HOST_NAME.json"
done

if [[ -f "$FLAGS" ]] && grep -Fq "play-split/chromium-cc" "$FLAGS"; then
  cp -a "$FLAGS" "$FLAGS.bak.$(date +%s)"
  # Drop the play-split path from --load-extension, including a leading/trailing comma.
  python3 - "$FLAGS" "$EXT_DIR" <<'PY'
import pathlib, sys
path, ext = pathlib.Path(sys.argv[1]), sys.argv[2]
lines = path.read_text().splitlines(keepends=True)
out = []
for line in lines:
    if line.startswith("--load-extension="):
        prefix, _, rest = line.partition("=")
        parts = [p for p in rest.strip().split(",") if p and p != ext]
        if parts:
            out.append(prefix + "=" + ",".join(parts) + "\n")
    else:
        out.append(line)
path.write_text("".join(out))
PY
  echo "Removed play-split from $FLAGS"
fi

echo
echo "Left Hyprland config alone. To undo the shortcut and window rule:"
echo "  remove the play-split bind from ~/.config/hypr/bindings.lua"
echo "  remove require(\"hypr.play-split\") from ~/.config/hypr/hyprland.lua"
echo "  rm ~/.config/hypr/play-split.lua"
echo "Restart Chromium after uninstall if it was running."
