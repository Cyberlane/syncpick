const copyButtons = document.querySelectorAll("[data-copy]");

for (const button of copyButtons) {
  button.addEventListener("click", async () => {
    const label = button.querySelector(".copy-label");
    const originalLabel = label.textContent;

    try {
      await navigator.clipboard.writeText(button.dataset.copy);
      label.textContent = "Copied";
      button.setAttribute("aria-label", "Homebrew install command copied");
    } catch {
      label.textContent = "Select command";
    }

    window.setTimeout(() => {
      label.textContent = originalLabel;
      button.setAttribute("aria-label", "Copy Homebrew install command");
    }, 1800);
  });
}
