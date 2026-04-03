const DIGITS = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"];

function createDigitSlot(initial) {
  const slot = document.createElement("span");
  slot.className = "mini-daily-dash__digit-slot";

  const reel = document.createElement("span");
  reel.className = "mini-daily-dash__digit-reel";

  for (const d of DIGITS) {
    const s = document.createElement("span");
    s.textContent = d;
    reel.appendChild(s);
  }

  slot.appendChild(reel);

  const idx = DIGITS.indexOf(String(initial));
  reel.style.transform = `translateY(-${idx * 10}%)`;

  return {
    el: slot,
    setDigit(d) {
      const i = DIGITS.indexOf(String(d));
      reel.style.transform = `translateY(-${i * 10}%)`;
    }
  };
}

function renderNumber(container, value, slotCache) {
  const abs = Math.abs(value);
  const str = String(abs);
  const negative = value < 0;

  const signEl = container.querySelector(".mini-daily-dash__sign");
  if (signEl) signEl.textContent = negative ? "−" : "";

  const digitsEl = container.querySelector(".mini-daily-dash__digits");
  const targetLen = Math.max(str.length, 1);

  // Add new slots if needed
  while (slotCache.length < targetLen) {
    const s = createDigitSlot(0);
    slotCache.push(s);
  }

  // Remove excess slots from DOM
  while (digitsEl.children.length > targetLen) {
    digitsEl.removeChild(digitsEl.lastChild);
  }

  // Ensure correct slots are in the DOM and update digits
  for (let i = 0; i < targetLen; i++) {
    const charIdx = i - (targetLen - str.length);
    const d = charIdx >= 0 ? str[charIdx] : "0";
    if (digitsEl.children[i] !== slotCache[i].el) {
      if (digitsEl.children[i]) {
        digitsEl.replaceChild(slotCache[i].el, digitsEl.children[i]);
      } else {
        digitsEl.appendChild(slotCache[i].el);
      }
    }
    slotCache[i].setDigit(d);
  }
}

export function createMiniDailyDash() {
  const root = document.createElement("div");
  root.className = "mini-daily-dash";

  // Logged side
  const loggedCounter = document.createElement("div");
  loggedCounter.className = "mini-daily-dash__counter";

  const loggedSign = document.createElement("span");
  loggedSign.className = "mini-daily-dash__sign";
  const loggedDigits = document.createElement("div");
  loggedDigits.className = "mini-daily-dash__digits";
  const loggedRow = document.createElement("div");
  loggedRow.style.cssText = "display:flex;align-items:center;justify-content:center;gap:0.1em;";
  loggedRow.appendChild(loggedSign);
  loggedRow.appendChild(loggedDigits);

  const loggedLabel = document.createElement("span");
  loggedLabel.className = "mini-daily-dash__label";
  loggedLabel.textContent = "Logged";

  loggedCounter.appendChild(loggedRow);
  loggedCounter.appendChild(loggedLabel);

  // Divider
  const divider = document.createElement("div");
  divider.className = "mini-daily-dash__divider";

  // Remaining side
  const remainingCounter = document.createElement("div");
  remainingCounter.className = "mini-daily-dash__counter";

  const remainingSign = document.createElement("span");
  remainingSign.className = "mini-daily-dash__sign";
  const remainingDigits = document.createElement("div");
  remainingDigits.className = "mini-daily-dash__digits";
  const remainingRow = document.createElement("div");
  remainingRow.style.cssText = "display:flex;align-items:center;justify-content:center;gap:0.1em;";
  remainingRow.appendChild(remainingSign);
  remainingRow.appendChild(remainingDigits);

  const remainingLabel = document.createElement("span");
  remainingLabel.className = "mini-daily-dash__label";
  remainingLabel.textContent = "Remaining";

  remainingCounter.appendChild(remainingRow);
  remainingCounter.appendChild(remainingLabel);

  // Error row
  const errorEl = document.createElement("div");
  errorEl.className = "mini-daily-dash__error";

  const wrapper = document.createElement("div");
  wrapper.style.cssText = "inline-size:100%;display:flex;flex-direction:column;align-items:center;";
  wrapper.appendChild(root);
  wrapper.appendChild(errorEl);

  root.appendChild(loggedCounter);
  root.appendChild(divider);
  root.appendChild(remainingCounter);

  const loggedSlots = [];
  const remainingSlots = [];
  let ready = false;

  root.classList.add("is-initial");

  renderNumber(loggedCounter, 0, loggedSlots);
  renderNumber(remainingCounter, 0, remainingSlots);

  let errorTimeout = null;

  function enableTransitions() {
    if (!ready) {
      ready = true;
      requestAnimationFrame(() => {
        root.classList.remove("is-initial");
        // Force layout reflow so iOS applies transition before next transform change
        void root.offsetHeight;
      });
    }
  }

  return {
    root: wrapper,
    setLogged(value) {
      enableTransitions();
      renderNumber(loggedCounter, value, loggedSlots);
    },
    setRemaining(value) {
      enableTransitions();
      renderNumber(remainingCounter, value, remainingSlots);
    },
    showError(msg) {
      errorEl.textContent = msg;
      clearTimeout(errorTimeout);
      errorTimeout = setTimeout(() => {
        errorEl.textContent = "";
      }, 3000);
    },
    clearError() {
      clearTimeout(errorTimeout);
      errorEl.textContent = "";
    }
  };
}
