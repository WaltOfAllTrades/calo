import { createKeypad } from "../features/keypad/keypad.js";
import { createCalorieEntryDisplay } from "../features/calorieEntryDisplay/ui/calorieEntryDisplay.js";
import { logCalEntry } from "../features/calories/application/logCalEntry.js";
import { createSettingsOverlay } from "../features/settings/ui/settingsOverlay.js";
import { createMiniDailyDash } from "../features/miniDailyDash/ui/miniDailyDash.js";
import { getTodayDashData } from "../features/miniDailyDash/application/getDashData.js";
import { createAppHeader } from "../features/appHeader/ui/appHeader.js";
import settingsIcon from "../features/settings/components/settings.svg";

const app = document.getElementById("app");

function openSettings() {
  const overlay = createSettingsOverlay({
    onClose() {
      overlay.remove();
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

// Calorie entry display
const display = createCalorieEntryDisplay();
app.appendChild(display.root);

// Logging guard
let isLogging = false;

app.appendChild(
  createKeypad({
    onBufferChange(buffer) {
      display.setBuffer(buffer);
    },
    onIntentChange(intent) {
      display.setIntent(intent);
    },
    async onEnter({ intent, value }) {
      if (isLogging) {
        dash.showError("Still logging — please wait");
        return;
      }
      isLogging = true;
      dash.clearError();
      try {
        const signed = intent === "add" ? value : -value;
        await logCalEntry(signed);
        await refreshDash();
      } catch {
        dash.showError("Log failed — please try again");
      } finally {
        isLogging = false;
      }
    }
  })
);
