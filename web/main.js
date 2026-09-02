(function () {
  const textUI = document.querySelector(".text-ui");
  const defaultOrder = "text-right";
  let progressKeys = [];
  let animationFrameId = null;

  // Helper function to create individual key wrappers with optional hold progress indicators
  function createKey(key, hold, keyIndex) {
    const keyWrapper = document.createElement("span");
    keyWrapper.className = `text-ui__key-wrap${hold ? " is-hold" : ""}`;
    keyWrapper.dataset.keyIndex = keyIndex;

    const keyNode = document.createElement("kbd");
    keyNode.className = "text-ui__key";
    keyNode.textContent = key;
    keyWrapper.appendChild(keyNode);

    if (hold) {
      const progressNode = document.createElement("span");
      progressNode.className = "text-ui__progress";
      progressNode.setAttribute("aria-hidden", "true");
      keyWrapper.appendChild(progressNode);
    }

    return keyWrapper;
  }

  // Parses text lines and extracts bracketed tags to construct multi-line structured rows
  function renderText(text, order, hold, keyState) {
    text.split(/\r?\n/).forEach((line) => {
      const row = document.createElement("div");
      row.className = "text-ui__row";

      const parts = line.split(/(\[.*?\])/g).filter(Boolean);
      parts.forEach((part) => {
        if (/^\[.*\]$/.test(part)) {
          keyState.index += 1;
          row.appendChild(createKey(part.slice(1, -1), hold, keyState.index));
        } else {
          const textNode = document.createElement("span");
          textNode.className = "text-ui__label";
          textNode.textContent = part;
          row.appendChild(textNode);
        }
      });

      textUI.appendChild(row);
    });
  }

  // Main message listener handling NUI events from Lua
  window.addEventListener("message", (evt) => {
    const { data } = evt;

    if (!data) return false;

    // Show event: Clears previous UI content and parses new structured text rows
    if (data.type === "show") {
      const text = String(data.text ?? "");

      if (animationFrameId) cancelAnimationFrame(animationFrameId);
      textUI.replaceChildren();
      renderText(text, data.order || defaultOrder, data.hold === true, { index: 0 });

      textUI.classList.add("is-visible");
      progressKeys = [...textUI.querySelectorAll("[data-key-index]")];
      progressKeys.forEach((key) => {
        key.style.setProperty("--progress", "0deg");
      });
      // Hide event: Closes the UI and terminates active animation loops
    } else if (data.type === "hide") {
      if (animationFrameId) cancelAnimationFrame(animationFrameId);
      textUI.classList.remove("is-visible");
      progressKeys = [];
      // Reset event: Resets progress angles back to 0 degrees
    } else if (data.type === "progress_reset") {
      if (animationFrameId) cancelAnimationFrame(animationFrameId);
      progressKeys.forEach((key) => {
        key.style.setProperty("--progress", "0deg");
      });
      // Progress start event: Handles smooth circular animation using the key's specific duration
    } else if (data.type === "progress_start") {
      const targetKey = progressKeys.find(
        (key) => Number(key.dataset.keyIndex) === Number(data.index)
      );

      if (targetKey) {
        if (animationFrameId) cancelAnimationFrame(animationFrameId);

        const startTime = performance.now();
        const duration = Number(data.duration);

        // Frame-by-frame progress calculation updating CSS custom properties smoothly
        function updateProgress(currentTime) {
          const elapsed = currentTime - startTime;
          const progress = Math.min(elapsed / duration, 1);

          targetKey.style.setProperty("--progress", `${progress * 360}deg`);

          if (progress < 1) {
            animationFrameId = requestAnimationFrame(updateProgress);
          }
        }

        animationFrameId = requestAnimationFrame(updateProgress);
      }
    } else if (data.type === "progress") {
      const progresses = data.progresses || {};

      progressKeys.forEach((key) => {
        const progress = Math.max(
          0,
          Math.min(Number(progresses[key.dataset.keyIndex]) || 0, 1)
        );
        key.style.setProperty("--progress", `${progress * 360}deg`);
      });
    }
  });
})();