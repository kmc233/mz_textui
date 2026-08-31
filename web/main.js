(function () {
  const textUI = document.querySelector(".text-ui");
  const defaultOrder = "text-right";

  function createKey(key, hold) {
    const keyWrapper = document.createElement("span");
    keyWrapper.className = `text-ui__key-wrap${hold ? " is-hold" : ""}`;

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

  function renderText(text, order, hold) {
    const parts = text.split(/(\[.*?\])/g).filter(Boolean);
    const nodes = parts.map((part) => {
      if (/^\[.*\]$/.test(part)) return createKey(part.slice(1, -1), hold);

      const textNode = document.createElement("span");
      textNode.className = "text-ui__label";
      textNode.textContent = part;
      return textNode;
    });

    if (order === "original") {
      nodes.forEach((node) => textUI.appendChild(node));
      return;
    }

    nodes
      .filter((node) => node.classList.contains("text-ui__label"))
      .forEach((node) => textUI.appendChild(node));
    nodes
      .filter((node) => node.classList.contains("text-ui__key-wrap"))
      .forEach((node) => textUI.appendChild(node));
  }

  window.addEventListener("message", (evt) => {
    const { data } = evt;

    if (!data) return false;

    if (data.type === "show") {
      const text = String(data.text ?? "");

      textUI.replaceChildren();
      renderText(text, data.order || defaultOrder, data.hold === true);

      textUI.classList.add("is-visible");
      textUI.style.setProperty("--progress", "0deg");
    } else if (data.type === "hide") {
      textUI.classList.remove("is-visible");
    } else if (data.type === "progress") {
      const progress = Math.max(0, Math.min(Number(data.progress) || 0, 1));
      textUI.style.setProperty("--progress", `${progress * 360}deg`);
    }
  });
})();
