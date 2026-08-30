(function () {
  const textUI = document.querySelector(".text-ui");

  window.addEventListener("message", (evt) => {
    const { data } = evt;

    if (!data) return false;

    if (data.type === "show") {
      const text = String(data.text ?? "");
      const keys = [...text.matchAll(/\[(.*?)\]/g)].map((match) => match[1]);
      const label = text.replace(/\[(.*?)\]/g, "").replace(/\s{2,}/g, " ").trim();

      textUI.replaceChildren();

      if (label) {
        const textNode = document.createElement("span");
        textNode.className = "text-ui__label";
        textNode.textContent = label;
        textUI.appendChild(textNode);
      }

      keys.forEach((key) => {
        const keyNode = document.createElement("kbd");
        keyNode.textContent = key;
        textUI.appendChild(keyNode);
      });

      textUI.classList.add("is-visible");
    } else if (data.type === "hide") {
      textUI.classList.remove("is-visible");
    }
  });
})();
