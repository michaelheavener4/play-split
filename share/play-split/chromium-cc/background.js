chrome.runtime.onMessage.addListener((msg) => {
  if (!msg || msg.type !== "captions" || !msg.payload) return;
  chrome.runtime.sendNativeMessage("com.play_split.captions", msg.payload, () => {
    void chrome.runtime.lastError;
  });
});
