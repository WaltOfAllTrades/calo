import { onDateChange } from "../../today/today.js";

function formatHeaderDate() {
  const now = new Date();
  const tz = Intl.DateTimeFormat().resolvedOptions().timeZone;

  const full = now.toLocaleDateString(undefined, {
    weekday: "long",
    month: "long",
    day: "numeric",
    timeZone: tz
  });

  const medium = now.toLocaleDateString(undefined, {
    weekday: "short",
    month: "long",
    day: "numeric",
    timeZone: tz
  });

  const short = now.toLocaleDateString(undefined, {
    weekday: "short",
    month: "short",
    day: "numeric",
    timeZone: tz
  });

  return { full, medium, short };
}

export function createAppHeader({ onSettingsClick, settingsIcon }) {
  const root = document.createElement("header");
  root.className = "app-header";

  const brand = document.createElement("span");
  brand.className = "app-header__brand";
  brand.textContent = "Calo";

  const dateEl = document.createElement("span");
  dateEl.className = "app-header__date";

  const dateFull = document.createElement("span");
  dateFull.className = "app-header__date-full";

  const dateMedium = document.createElement("span");
  dateMedium.className = "app-header__date-medium";

  const dateShort = document.createElement("span");
  dateShort.className = "app-header__date-short";

  dateEl.appendChild(dateFull);
  dateEl.appendChild(dateMedium);
  dateEl.appendChild(dateShort);

  const settingsBtn = document.createElement("button");
  settingsBtn.className = "app-header__settings";
  settingsBtn.setAttribute("aria-label", "Settings");

  const img = document.createElement("img");
  img.src = settingsIcon;
  img.alt = "";
  img.className = "app-header__settings-icon";
  settingsBtn.appendChild(img);
  settingsBtn.addEventListener("click", onSettingsClick);

  root.appendChild(brand);
  root.appendChild(dateEl);
  root.appendChild(settingsBtn);

  function updateDate() {
    const { full, medium, short } = formatHeaderDate();
    dateFull.textContent = full;
    dateMedium.textContent = medium;
    dateShort.textContent = short;
  }

  updateDate();
  onDateChange(updateDate);

  return root;
}
