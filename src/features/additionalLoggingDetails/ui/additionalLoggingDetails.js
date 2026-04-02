export function createAdditionalLoggingDetails() {
  const root = document.createElement("div");
  root.className = "additional-logging-details";

  const nameInput = document.createElement("input");
  nameInput.type = "text";
  nameInput.className = "additional-logging-details__field additional-logging-details__name";
  nameInput.placeholder = "Item";
  nameInput.setAttribute("aria-label", "Item name");

  const descInput = document.createElement("textarea");
  descInput.className = "additional-logging-details__field additional-logging-details__desc";
  descInput.placeholder = "Log details";
  descInput.rows = 2;
  descInput.setAttribute("aria-label", "Log details");

  root.appendChild(nameInput);
  root.appendChild(descInput);

  return {
    root,
    getName() {
      return nameInput.value.trim();
    },
    getDescription() {
      return descInput.value.trim();
    },
    clear() {
      nameInput.value = "";
      descInput.value = "";
    },
    setVisibility({ showLogName, showLogDescription }) {
      nameInput.style.display = showLogName ? "" : "none";
      descInput.style.display = showLogDescription ? "" : "none";
      root.style.display =
        showLogName || showLogDescription ? "flex" : "none";
    }
  };
}
