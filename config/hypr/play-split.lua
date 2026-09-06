-- Native tiled player used by play-split. Omarchy floats class "mpv", so this
-- uses a dedicated app id and stays opaque so the mix isn't washed out.
o.window("^play-split$", {
  tile = true,
  tag = "-default-opacity",
  opacity = "1 1",
  idle_inhibit = "always",
  keep_aspect_ratio = true,
  content = "video",
})
