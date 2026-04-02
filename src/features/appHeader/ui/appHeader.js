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

export function createAppHeader({
  onSettingsClick,
  settingsIcon,
  leftIcon,
  onLeftClick,
  centerText
} = {}) {
  const root = document.createElement("header");
  root.className = "app-header";

  // Left slot: icon button or brand text
  if (leftIcon) {
    const btn = document.createElement("button");
    btn.className = "app-header__left-action";
    btn.setAttribute("aria-label", "Back");

    const img = document.createElement("img");
    img.src = leftIcon;
    img.alt = "";
    img.className = "app-header__left-icon";
    btn.appendChild(img);
    if (onLeftClick) btn.addEventListener("click", onLeftClick);
    root.appendChild(btn);
  } else {
    const brand = document.createElement("span");
    brand.className = "app-header__brand";
    brand.textContent = "Calo";
    root.appendChild(brand);
  }

  // Center slot: static text or responsive date
  if (centerText) {
    const center = document.createElement("span");
    center.className = "app-header__center";
    center.textContent = centerText;
    root.appendChild(center);
  } else {
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
    root.appendChild(dateEl);

    function updateDate() {
      const { full, medium, short } = formatHeaderDate();
      dateFull.textContent = full;
      dateMedium.textContent = medium;
      dateShort.textContent = short;
    }

    updateDate();
    onDateChange(updateDate);
  }

  // Right slot: settings button or empty spacer
  if (settingsIcon && onSettingsClick) {
    const settingsBtn = document.createElement("button");
    settingsBtn.className = "app-header__settings";
    settingsBtn.setAttribute("aria-label", "Settings");

    const img = document.createElement("img");
    img.src = settingsIcon;
    img.alt = "";
    img.className = "app-header__settings-icon";
    settingsBtn.appendChild(img);
    settingsBtn.addEventListener("click", onSettingsClick);
    root.appendChild(settingsBtn);
  } else {
    const spacer = document.createElement("span");
    spacer.className = "app-header__spacer";
    root.appendChild(spacer);
  }

  return root;
}
