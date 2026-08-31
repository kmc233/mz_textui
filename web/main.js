(function () {
  const textUI = document.querySelector(".text-ui");
  const defaultOrder = "text-right";
  let progressKeys = [];

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

  function renderText(text, order, hold, keyState) {
    text.split(/\r?\n/).forEach((line) => {
      const row = document.createElement("div");
      row.className = "text-ui__row";

      const parts = line.split(/(\[.*?\])/g).filter(Boolean);
      const nodes = parts.map((part) => {
        if (/^\[.*\]$/.test(part)) {
          keyState.index += 1;
          return createKey(part.slice(1, -1), hold, keyState.index);
        }

        const textNode = document.createElement("span");
        textNode.className = "text-ui__label";
        textNode.textContent = part;
        return textNode;
      });

      if (order === "original") {
        nodes.forEach((node) => row.appendChild(node));
      } else {
        nodes
          .filter((node) => node.classList.contains("text-ui__label"))
          .forEach((node) => row.appendChild(node));
        nodes
          .filter((node) => node.classList.contains("text-ui__key-wrap"))
          .forEach((node) => row.appendChild(node));
      }

      textUI.appendChild(row);
    });
  }

  window.addEventListener("message", (evt) => {
    const { data } = evt;

    if (!data) return false;

    if (data.type === "show") {
      const text = String(data.text ?? "");

      textUI.replaceChildren();
      renderText(text, data.order || defaultOrder, data.hold === true, { index: 0 });

      textUI.classList.add("is-visible");
      progressKeys = [...textUI.querySelectorAll("[data-key-index]")];
      progressKeys.forEach((key) => {
        key.style.setProperty("--progress", "0deg");
      });
    } else if (data.type === "hide") {
      textUI.classList.remove("is-visible");
      progressKeys = [];
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
