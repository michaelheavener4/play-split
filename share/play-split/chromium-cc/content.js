function videoIdFromUrl(url) {
  try {
    const u = new URL(url);
    if (/(^|\.)youtu\.be$/i.test(u.hostname)) {
      return u.pathname.split("/").filter(Boolean)[0] || null;
    }
    if (u.searchParams.get("v")) return u.searchParams.get("v");
    const m = u.pathname.match(/\/(?:embed|shorts|live)\/([^/?]+)/);
    if (m) return m[1];
  } catch (e) {}
  return null;
}

function playerEl() {
  return document.getElementById("movie_player") || document.querySelector(".html5-video-player");
}

function readTrack(player) {
  if (!player || typeof player.getOption !== "function") return null;
  try {
    const track = player.getOption("captions", "track");
    if (track && track.languageCode) return track;
  } catch (e) {}
  return null;
}

function readState() {
  const btn = document.querySelector(".ytp-subtitles-button");
  const pressed = btn ? btn.getAttribute("aria-pressed") === "true" : null;
  const capWin = document.querySelector(".ytp-caption-window-container, .caption-window");
  const capVisible = !!(capWin && capWin.offsetParent !== null && String(capWin.textContent || "").trim());
  const track = readTrack(playerEl());

  let on;
  if (pressed !== null) on = pressed;
  else if (track) on = true;
  else on = capVisible;

  return {
    on: !!on,
    lang: (track && track.languageCode) || null,
    kind: (track && track.kind) || null,
    url: location.href,
    video_id: videoIdFromUrl(location.href),
    ts: Date.now() / 1000,
  };
}

let lastSent = "";

function publish() {
  if (!location.pathname.includes("/watch") && !location.pathname.includes("/embed") && !location.pathname.includes("/shorts") && !location.pathname.includes("/live")) {
    return;
  }
  const state = readState();
  const key = JSON.stringify({ on: state.on, lang: state.lang, video_id: state.video_id });
  if (key === lastSent) return;
  lastSent = key;
  chrome.runtime.sendMessage({ type: "captions", payload: state }, () => {
    void chrome.runtime.lastError;
  });
}

document.addEventListener(
  "click",
  (ev) => {
    if (ev.target && ev.target.closest && ev.target.closest(".ytp-subtitles-button")) {
      setTimeout(publish, 50);
      setTimeout(publish, 300);
    }
  },
  true
);

const mo = new MutationObserver(() => publish());
mo.observe(document.documentElement, {
  subtree: true,
  childList: true,
  attributes: true,
  attributeFilter: ["aria-pressed", "class"],
});

setInterval(publish, 1000);
publish();
