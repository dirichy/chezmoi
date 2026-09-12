skRegisterScript({ name: "chatgpt-input", domains: "chatgpt.com" }, ({ script }) => {
  const isEditable = (element) => {
    if (!element || !(element instanceof Element)) {
      return false;
    }

    return Boolean(
      element.closest(
        '#prompt-textarea, textarea, input[type="text"], [contenteditable="true"]'
      )
    );
  };

  const promptElement = () =>
    document.querySelector("#prompt-textarea") ||
    document.querySelector('textarea[data-testid="prompt-textarea"]') ||
    document.querySelector('[contenteditable="true"]');

  const focusPrompt = () => {
    const prompt = promptElement();
    if (!prompt) {
      return;
    }
    prompt.focus();
  };

  const sendButton = () =>
    document.querySelector('[data-testid="send-button"]:not([disabled])') ||
    document.querySelector('button[aria-label="Send prompt"]:not([disabled])') ||
    document.querySelector('button[aria-label="Send message"]:not([disabled])') ||
    document.querySelector('button[aria-label="发送"]:not([disabled])');

  const dispatchShiftEnter = (target) => {
    target.dispatchEvent(
      new KeyboardEvent("keydown", {
        key: "Enter",
        code: "Enter",
        bubbles: true,
        cancelable: true,
        shiftKey: true,
      })
    );
  };

  document.addEventListener(
    "keydown",
    (event) => {
      if (event.isComposing || event.key === "Process" || !isEditable(event.target)) {
        return;
      }

      if (event.key === "Escape") {
        skStopEvent(event);
        if (document.activeElement instanceof HTMLElement) {
          document.activeElement.blur();
        }
        getSelection()?.removeAllRanges();
        return;
      }

      if (event.key !== "Enter" || event.shiftKey || event.altKey || event.metaKey) {
        return;
      }

      skStopEvent(event);

      if (event.ctrlKey) {
        sendButton()?.click();
      } else {
        dispatchShiftEnter(event.target);
      }
    },
    true
  );

  api.mapkey("i", "#8Focus ChatGPT input", focusPrompt, {
    domain: script.urlPattern,
  });
});
