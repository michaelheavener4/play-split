#!/usr/bin/env bash
# Install play-split onto this Omarchy / Hyprland machine.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/play-split"
HYPR_DIR="$HOME/.config/hypr"
FLAGS="$HOME/.config/chromium-flags.conf"
EXT_DIR="$DATA_DIR/chromium-cc"
HOST_PATH="$BIN_DIR/play-split-captions-host"
HOST_NAME="com.play_split.captions"

backup() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  cp -a "$file" "$file.bak.$(date +%s)"
}

echo "Installing play-split -> $BIN_DIR and $DATA_DIR"

mkdir -p "$BIN_DIR" "$DATA_DIR"
install -m 755 "$ROOT/bin/play-split" "$BIN_DIR/play-split"
install -m 755 "$ROOT/bin/play-split-captions-host" "$HOST_PATH"
mkdir -p "$DATA_DIR/mpv/scripts" "$EXT_DIR"
cp -a "$ROOT/share/play-split/mpv/scripts/." "$DATA_DIR/mpv/scripts/"
cp -a "$ROOT/share/play-split/chromium-cc/." "$EXT_DIR/"

# Native messaging host (path is machine-specific).
manifest="$(sed "s|__HOST_PATH__|$HOST_PATH|g" "$ROOT/config/native-messaging/$HOST_NAME.json")"
browser_dirs=(
  "$HOME/.config/chromium"
  "$HOME/.config/google-chrome"
  "$HOME/.config/google-chrome-beta"
  "$HOME/.config/google-chrome-unstable"
  "$HOME/.config/BraveSoftware/Brave-Browser"
  "$HOME/.config/BraveSoftware/Brave-Browser-Beta"
  "$HOME/.config/BraveSoftware/Brave-Browser-Nightly"
  "$HOME/.config/microsoft-edge"
  "$HOME/.config/microsoft-edge-dev"
)
for dir in "${browser_dirs[@]}"; do
  mkdir -p "$dir/NativeMessagingHosts"
  printf '%s\n' "$manifest" >"$dir/NativeMessagingHosts/$HOST_NAME.json"
done

# Chromium --load-extension so YouTube CC state is reported.
mkdir -p "$(dirname "$FLAGS")"
if [[ ! -f "$FLAGS" && -f /usr/share/omarchy/config/chromium-flags.conf ]]; then
  cp /usr/share/omarchy/config/chromium-flags.conf "$FLAGS"
fi
if [[ ! -f "$FLAGS" ]]; then
  touch "$FLAGS"
fi
if ! grep -Fq "play-split/chromium-cc" "$FLAGS"; then
  backup "$FLAGS"
  if grep -q "^--load-extension=" "$FLAGS"; then
    sed -i "s|^--load-extension=\(.*\)$|--load-extension=\1,$EXT_DIR|" "$FLAGS"
  else
    printf '%s\n' "--load-extension=$EXT_DIR" >>"$FLAGS"
  fi
  echo "Added play-split captions extension to $FLAGS"
else
  echo "Chromium flags already include play-split captions extension"
fi

# Hyprland window rule.
mkdir -p "$HYPR_DIR"
cp "$ROOT/config/hypr/play-split.lua" "$HYPR_DIR/play-split.lua"
hyprland="$HYPR_DIR/hyprland.lua"
if [[ -f "$hyprland" ]]; then
  if grep -Eq 'require\(["'\'']hypr\.play-split["'\'']\)|o\.window\("\^play-split\$"' "$hyprland"; then
    echo "Hyprland already has a play-split window rule"
  else
    backup "$hyprland"
    printf '\nrequire("hypr.play-split")\n' >>"$hyprland"
    echo "Added require(\"hypr.play-split\") to $hyprland"
  fi
else
  echo "No $hyprland found; copied window rule to $HYPR_DIR/play-split.lua"
  echo "Add: require(\"hypr.play-split\")"
fi

# Keybinding. SUPER+SHIFT+M is Omarchy's Spotify launcher by default.
bindings="$HYPR_DIR/bindings.lua"
bind_line='o.bind("SUPER + SHIFT + M", "Play URL split", (os.getenv("HOME") or "") .. "/.local/bin/play-split")'
if [[ -f "$bindings" ]]; then
  if grep -q 'play-split' "$bindings"; then
    echo "Hyprland already binds play-split"
  else
    backup "$bindings"
    {
      printf '\n-- Was Omarchy'\''s Spotify launcher.\n'
      printf 'hl.unbind("SUPER + SHIFT + M")\n'
      printf '%s\n' "$bind_line"
    } >>"$bindings"
    echo "Bound SUPER + SHIFT + M to play-split (was Spotify)"
  fi
else
  echo "No $bindings found; bind SUPER + SHIFT + M to $BIN_DIR/play-split yourself"
fi

if command -v hyprctl >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 || true
  if errors="$(hyprctl configerrors 2>/dev/null || true)"; then
    if [[ -n "${errors//[$'\t\r\n ']/}" && "$errors" != "ok" && "$errors" != *"no errors"* ]]; then
      echo "hyprctl configerrors:"
      printf '%s\n' "$errors"
    fi
  fi
fi

missing=()
for cmd in mpv yt-dlp python3 wl-paste hyprctl busctl; do
  command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if ((${#missing[@]})); then
  echo "Missing commands: ${missing[*]}"
  echo "On Omarchy: omarchy pkg add ${missing[*]}"
fi

echo
echo "play-split installed."
echo "  command:  $BIN_DIR/play-split"
echo "  shortcut: SUPER + SHIFT + M"
echo "Restart Chromium so caption mirroring can load."
