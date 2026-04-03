import { createKeypad } from "../features/keypad/keypad.js";
import { createCalorieEntryDisplay } from "../features/calorieEntryDisplay/ui/calorieEntryDisplay.js";
import { createAdditionalLoggingDetails } from "../features/additionalLoggingDetails/ui/additionalLoggingDetails.js";
import { logCalEntry } from "../features/calories/application/logCalEntry.js";
import { createSettingsOverlay } from "../features/settings/ui/settingsOverlay.js";
import { loadSettings } from "../features/settings/application/settingsService.js";
import { createMiniDailyDash } from "../features/miniDailyDash/ui/miniDailyDash.js";
import { getTodayDashData } from "../features/miniDailyDash/application/getDashData.js";
import { createAppHeader } from "../features/appHeader/ui/appHeader.js";
import settingsIcon from "../features/settings/components/settings.svg";
///////// This import is just to seed some test data — the function is called at the end of this file remove for production
import { seedTestData } from "../features/calories/infrastructure/seedTestData.js";

const app = document.getElementById("app");

async function applyFieldVisibility() {
  const settings = await loadSettings();
  details.setVisibility(settings);
  const hasDetails = settings.showLogName || settings.showLogDescription;
  app.classList.toggle("has-details", hasDetails);
}

function openSettings() {
  const overlay = createSettingsOverlay({
    onClose() {
      overlay.remove();
      applyFieldVisibility();
      refreshDash();
    },
    onDataChange() {
      refreshDash();
    }
  });
  document.body.appendChild(overlay);
}

// App header
app.appendChild(
  createAppHeader({ onSettingsClick: openSettings, settingsIcon })
);

// Mini daily dash
const dash = createMiniDailyDash();
app.appendChild(dash.root);

async function refreshDash() {
  const { logged, remaining } = await getTodayDashData();
  dash.setLogged(logged);
  dash.setRemaining(remaining);
}
refreshDash();

// Bottom group: details + display + keypad
const bottomGroup = document.createElement("div");
bottomGroup.className = "app-bottom-group";

// Additional logging details
const details = createAdditionalLoggingDetails();
bottomGroup.appendChild(details.root);

// Calorie entry display
const display = createCalorieEntryDisplay();
bottomGroup.appendChild(display.root);

// Logging guard
let isLogging = false;

bottomGroup.appendChild(
  createKeypad({
    onBufferChange(buffer) {
      display.setBuffer(buffer);
    },
    onIntentChange(intent) {
      display.setIntent(intent);
    },
    async onEnter({ intent, value }) {
      if (value === 0) return;
      if (isLogging) {
        dash.showError("Still logging — please wait");
        return;
      }
      isLogging = true;
      dash.clearError();
      try {
        const signed = intent === "add" ? value : -value;
        await logCalEntry(signed, details.getName(), details.getDescription());
        details.clear();
        await refreshDash();
      } catch {
        dash.showError("Log failed — please try again");
      } finally {
        isLogging = false;
      }
    }
  })
);

app.appendChild(bottomGroup);
applyFieldVisibility();

// Test data seeder — other end in src/features/calories/infrastructure/seedTestData.js
seedTestData().then(refreshDash);
