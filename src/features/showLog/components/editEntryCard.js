export function createEditEntryCard({ entry, onSave, onCancel }) {
  const overlay = document.createElement("div");
  overlay.className = "edit-entry-overlay";

  const card = document.createElement("div");
  card.className = "edit-entry-card";

  const title = document.createElement("h3");
  title.className = "edit-entry-card__title";
  title.textContent = "Edit Entry";
  card.appendChild(title);

  const calLabel = document.createElement("label");
  calLabel.className = "edit-entry-card__label";
  calLabel.textContent = "Calories";
  const calInput = document.createElement("input");
  calInput.type = "number";
  calInput.inputMode = "numeric";
  calInput.className = "edit-entry-card__input";
  calInput.value = entry.calories;
  card.appendChild(calLabel);
  card.appendChild(calInput);

  const nameLabel = document.createElement("label");
  nameLabel.className = "edit-entry-card__label";
  nameLabel.textContent = "Item";
  const nameInput = document.createElement("input");
  nameInput.type = "text";
  nameInput.className = "edit-entry-card__input";
  nameInput.value = entry.name || "";
  card.appendChild(nameLabel);
  card.appendChild(nameInput);

  const descLabel = document.createElement("label");
  descLabel.className = "edit-entry-card__label";
  descLabel.textContent = "Log details";
  const descInput = document.createElement("textarea");
  descInput.className = "edit-entry-card__input edit-entry-card__textarea";
  descInput.rows = 2;
  descInput.value = entry.description || "";
  card.appendChild(descLabel);
  card.appendChild(descInput);

  const actions = document.createElement("div");
  actions.className = "edit-entry-card__actions";

  const cancelBtn = document.createElement("button");
  cancelBtn.className = "edit-entry-card__btn edit-entry-card__btn--cancel";
  cancelBtn.textContent = "Cancel";
  cancelBtn.addEventListener("click", () => {
    overlay.remove();
    onCancel?.();
  });

  const saveBtn = document.createElement("button");
  saveBtn.className = "edit-entry-card__btn edit-entry-card__btn--save";
  saveBtn.textContent = "Save";
  saveBtn.addEventListener("click", () => {
    const cal = parseInt(calInput.value, 10);
    if (Number.isNaN(cal)) return;
    overlay.remove();
    onSave({
      calories: cal,
      name: nameInput.value.trim(),
      description: descInput.value.trim()
    });
  });

  actions.appendChild(cancelBtn);
  actions.appendChild(saveBtn);
  card.appendChild(actions);

  overlay.appendChild(card);

  overlay.addEventListener("click", (e) => {
    if (e.target === overlay) {
      overlay.remove();
      onCancel?.();
    }
  });

  return overlay;
}
