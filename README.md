# play-split

Play a YouTube (or other media) URL in a tiled [mpv](https://mpv.io) pane on
Omarchy / Hyprland — no browser chrome.

`SUPER + SHIFT + M` grabs the clipboard URL (or a YouTube iframe embed),
closes the original YouTube window, and resumes from the current time with
captions matching YouTube's CC on/off.

## Install on another Omarchy machine

```bash
git clone https://github.com/michaelheavener4/play-split.git ~/Projects/play-split
cd ~/Projects/play-split
./install.sh
```

Then restart Chromium once so caption mirroring can load.

### Update

```bash
cd ~/Projects/play-split
git pull
./install.sh
```

## Usage

```bash
play-split                  # clipboard URL (or YouTube iframe HTML)
play-split <url> [title]
play-split --help
```

Or press **SUPER + SHIFT + M**.

In mpv: **c** or the corner **CC** button toggles subtitles.

## What the installer does

- Copies `play-split` and `play-split-captions-host` to `~/.local/bin`
- Copies mpv scripts and the Chromium companion extension to `~/.local/share/play-split`
- Registers the native messaging host so YouTube CC state can be read
- Appends the extension to `~/.config/chromium-flags.conf`
- Installs the Hyprland window rule (`~/.config/hypr/play-split.lua`)
- Binds **SUPER + SHIFT + M** (Omarchy's default for this key is Spotify)

## Dependencies

Already on a typical Omarchy install:

- `mpv`, `yt-dlp`, `python3`, `wl-clipboard`
- `hyprctl`, `busctl`
- Chromium (for YouTube CC mirroring)
- Node (yt-dlp's YouTube JS runtime)

## Uninstall

```bash
cd ~/Projects/play-split
./uninstall.sh
```
