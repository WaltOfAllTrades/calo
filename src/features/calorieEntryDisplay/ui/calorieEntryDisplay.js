export function createCalorieEntryDisplay() {
  const root = document.createElement("div");
  root.className = "calorie-entry-display";

  const intentEl = document.createElement("span");
  intentEl.className = "calorie-entry-display__intent";
  intentEl.textContent = "Add";

  const valueEl = document.createElement("span");
  valueEl.className = "calorie-entry-display__value";

  root.appendChild(intentEl);
  root.appendChild(valueEl);

  return {
    root,
    setIntent(intent) {
      intentEl.textContent = intent === "add" ? "Add" : "Sub";
    },
    setBuffer(buffer) {
      valueEl.textContent = buffer;
    }
  };
}
