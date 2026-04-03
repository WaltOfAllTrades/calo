import { loadSettings, saveSetting } from "../application/settingsService.js";
import { createAboutPage } from "../../aboutPage/ui/aboutPage.js";
import { createShowLogPage } from "../../showLog/ui/showLog.js";
import { clearTodayLog, hasTodayEntries } from "../../calories/application/clearTodayLog.js";

export function createSettingsOverlay({ onClose, onDataChange }) {
  const overlay = document.createElement("div");
  overlay.className = "settings-overlay";

  const card = document.createElement("div");
  card.className = "settings-card";

  overlay.appendChild(card);

  overlay.addEventListener("click", (e) => {
    if (e.target === overlay) onClose();
  });

  async function render() {
    const settings = await loadSettings();
    card.innerHTML = "";

    // Header: logo + app name
    const header = document.createElement("div");
    header.className = "settings-card__header";

    const logo = document.createElement("div");
    logo.className = "settings-card__logo";

    const appName = document.createElement("span");
    appName.className = "settings-card__app-name";
    appName.textContent = "Calo";

    header.appendChild(logo);
    header.appendChild(appName);
    card.appendChild(header);

    // Nav buttons
    const navGroup = document.createElement("div");
    navGroup.className = "settings-card__nav";

    const todayLogBtn = createNavButton("Today's Log", () => {
      onClose();
      const logPage = createShowLogPage({
        onBack() {
          logPage.remove();
        },
        onDataChange
      });
      document.body.appendChild(logPage);
    });
    const reportsBtn = createNavButton("Reports", () => {
      onClose();
    });
    const aboutBtn = createNavButton("About", () => {
      onClose();
      const aboutPage = createAboutPage({
        onBack() {
          aboutPage.remove();
        }
      });
      document.body.appendChild(aboutPage);
    });

    navGroup.appendChild(todayLogBtn);
    navGroup.appendChild(reportsBtn);
    navGroup.appendChild(aboutBtn);
    card.appendChild(navGroup);

    // Separator
    card.appendChild(createSeparator());

    // Toggle: show log name
    card.appendChild(
      createToggleRow("Show log name", settings.showLogName, async (val) => {
        await saveSetting("showLogName", val);
      })
    );

    // Toggle: show log description
    card.appendChild(
      createToggleRow("Show log description", settings.showLogDescription, async (val) => {
        await saveSetting("showLogDescription", val);
      })
    );

    // Separator
    card.appendChild(createSeparator());

    // Daily target input
    card.appendChild(
      createTargetRow(settings.dailyTarget, async (val) => {
        await saveSetting("dailyTarget", val);
        onDataChange?.();
      })
    );

    // Close button
    const closeBtn = document.createElement("button");
    closeBtn.className = "settings-card__close";
    closeBtn.textContent = "Done";
    closeBtn.addEventListener("click", onClose);
    card.appendChild(closeBtn);

    // Clear daily log button (only if entries exist)
    const hasEntries = await hasTodayEntries();
    if (hasEntries) {
      card.appendChild(createClearLogButton(onDataChange));
    }
  }

  render();
  return overlay;
}

function createNavButton(label, onClick) {
  const btn = document.createElement("button");
  btn.className = "settings-card__nav-btn";
  btn.textContent = label;
  btn.addEventListener("click", onClick);
  return btn;
}

function createSeparator() {
  const sep = document.createElement("hr");
  sep.className = "settings-card__sep";
  return sep;
}

function createToggleRow(label, checked, onChange) {
  const row = document.createElement("label");
  row.className = "settings-card__toggle-row";

  const text = document.createElement("span");
  text.textContent = label;

  const toggle = document.createElement("input");
  toggle.type = "checkbox";
  toggle.className = "settings-card__toggle";
  toggle.checked = checked;
  toggle.addEventListener("change", () => onChange(toggle.checked));

  row.appendChild(text);
  row.appendChild(toggle);
  return row;
}

function createTargetRow(value, onChange) {
  const row = document.createElement("label");
  row.className = "settings-card__target-row";

  const text = document.createElement("span");
  text.textContent = "Daily target";

  const input = document.createElement("input");
  input.type = "number";
  input.className = "settings-card__target-input";
  input.inputMode = "numeric";
  input.value = value;
  input.min = "0";
  input.max = "99999";

  input.addEventListener("change", () => {
    const num = parseInt(input.value, 10);
    if (!Number.isNaN(num) && num >= 0) onChange(num);
  });

  row.appendChild(text);
  row.appendChild(input);
  return row;
}

function createClearLogButton(onDataChange) {
  const btn = document.createElement("button");
  btn.className = "settings-card__clear-log";
  btn.textContent = "Clear daily log";

  let confirming = false;

  btn.addEventListener("click", async () => {
    if (!confirming) {
      confirming = true;
      btn.textContent = "Tap to confirm removal";
      btn.classList.add("is-confirming");
      return;
    }

    await clearTodayLog();
    onDataChange?.();
    btn.textContent = "Daily log cleared";
    btn.classList.remove("is-confirming");
    btn.classList.add("is-cleared");
    btn.disabled = true;

    setTimeout(() => btn.remove(), 1200);
  });

  return btn;
}
