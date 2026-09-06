-- CC control for play-split: click the corner button or press c to hide/show subs.
local ov = mp.create_osd_overlay("ass-events")
ov.z = 100

local hovered = false
local has_subs = false
local visible = true
local bound_click = false

local btn_w, btn_h, margin = 76, 36, 14

local function osd_size()
  local w, h = mp.get_osd_size()
  return w or 0, h or 0
end

local function button_rect()
  local w, h = osd_size()
  if w <= 0 or h <= 0 then
    return nil
  end
  return {
    x1 = w - margin - btn_w,
    y1 = h - margin - btn_h,
    x2 = w - margin,
    y2 = h - margin,
  }
end

local function mouse_in_osd(pos)
  if not pos or pos.hover == false then
    return nil
  end
  local ow, oh = osd_size()
  local ww = mp.get_property_number("osd-width") or ow
  local wh = mp.get_property_number("osd-height") or oh
  if ww <= 0 or wh <= 0 or ow <= 0 or oh <= 0 then
    return pos.x, pos.y
  end
  return pos.x * ow / ww, pos.y * oh / wh
end

local function in_button(pos)
  local rect = button_rect()
  local x, y = mouse_in_osd(pos)
  if not rect or not x then
    return false
  end
  return x >= rect.x1 and x <= rect.x2 and y >= rect.y1 and y <= rect.y2
end

local function tracks_have_subs()
  local tracks = mp.get_property_native("track-list") or {}
  for _, track in ipairs(tracks) do
    if track.type == "sub" then
      return true
    end
  end
  return false
end

local function refresh_state()
  has_subs = tracks_have_subs()
  visible = mp.get_property_bool("sub-visibility") and mp.get_property("sid") ~= "no"
end

local function render()
  local rect = button_rect()
  if not has_subs or not rect then
    ov.data = ""
    ov:update()
    return
  end

  local w, h = osd_size()
  ov.res_x = w
  ov.res_y = h

  local fill = visible and "2E7D32" or "222222"
  local border = hovered and "FFFFFF" or (visible and "69F0AE" or "777777")
  local fg = visible and "FFFFFF" or "AAAAAA"
  local label = visible and "CC" or "CC off"
  local x = rect.x1
  local y = rect.y1
  local bw = rect.x2 - rect.x1
  local bh = rect.y2 - rect.y1

  ov.data = string.format(
    "{\\an7\\bord2\\shad0\\1c&H%s&\\3c&H%s&\\p1}m %d %d l %d %d l %d %d l %d %d{\\p0}\n"
      .. "{\\an5\\pos(%d,%d)\\bord0\\shad0\\fs17\\b1\\fnmonospace\\1c&H%s&}%s",
    fill, border,
    x, y, x + bw, y, x + bw, y + bh, x, y + bh,
    x + bw / 2, y + bh / 2, fg, label
  )
  ov:update()
end

local function set_click_binding(enable)
  if enable and not bound_click then
    mp.add_forced_key_binding("MBTN_LEFT", "play-split-cc-click", function()
      mp.commandv("script-message", "play-split-cc-toggle")
    end)
    bound_click = true
  elseif not enable and bound_click then
    mp.remove_key_binding("play-split-cc-click")
    bound_click = false
  end
end

local function toggle()
  refresh_state()
  if not has_subs then
    mp.osd_message("No subtitles")
    return
  end

  if mp.get_property("sid") == "no" then
    mp.set_property("sid", "auto")
    mp.set_property_bool("sub-visibility", true)
    mp.osd_message("Subtitles on")
  elseif visible then
    mp.set_property_bool("sub-visibility", false)
    mp.osd_message("Subtitles off")
  else
    mp.set_property_bool("sub-visibility", true)
    mp.osd_message("Subtitles on")
  end
  refresh_state()
  render()
end

mp.register_script_message("play-split-cc-toggle", toggle)
mp.add_key_binding("c", "play-split-cc-key", toggle)

mp.observe_property("track-list", "native", function()
  refresh_state()
  render()
end)
mp.observe_property("sub-visibility", "bool", function()
  refresh_state()
  render()
end)
mp.observe_property("sid", "native", function()
  refresh_state()
  render()
end)
mp.observe_property("osd-dimensions", "native", function()
  render()
end)
mp.observe_property("mouse-pos", "native", function(_, pos)
  local now = has_subs and in_button(pos)
  if now ~= hovered then
    hovered = now
    render()
  end
  set_click_binding(now)
end)

refresh_state()
render()
