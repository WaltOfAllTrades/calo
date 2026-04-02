import { createKeyButton } from "./components/keyButton.js";
import backspaceIcon from "./components/backspace.svg";
import enterIcon from "./components/enter.svg";

export function createKeypad({ onEnter, onBufferChange, onIntentChange }) {
  const state = {
    intent: "add",
    buffer: ""
  };

  const root = document.createElement("div");
  root.className = "keypad";

  function updateBuffer(newBuffer) {
    state.buffer = newBuffer;
    if (onBufferChange) onBufferChange(state.buffer);
  }

  function setIntent(next) {
    state.intent = next;
    if (onIntentChange) onIntentChange(state.intent);
    render();
  }

  function append(value) {
    const next = state.buffer + value;
    if (next.length > 5) return;
    updateBuffer(next);
  }

  function clear() {
    updateBuffer("");
  }

  function backspace() {
    updateBuffer(state.buffer.slice(0, -1));
  }

  function enter() {
    if (!state.buffer) return;
    onEnter({
      intent: state.intent,
      value: Number(state.buffer)
    });
    updateBuffer("");
    setIntent("add");
  }

  function isActiveIntent(label) {
    return (
      (label === "+" && state.intent === "add") ||
      (label === "−" && state.intent === "subtract")
    );
  }

  function render() {
    root.innerHTML = "";

    const keys = [
      { label: "+", variant: "intent", press: () => setIntent("add") },
      { label: "−", variant: "intent", press: () => setIntent("subtract") },
      { label: "C", variant: "action", press: clear },
      { label: "Backspace", variant: "action", press: backspace, icon: backspaceIcon },

      { label: "80", variant: "bonus-number", press: () => append("80") },
      { label: "7", variant: "number", press: () => append("7") },
      { label: "8", variant: "number", press: () => append("8") },
      { label: "9", variant: "number", press: () => append("9") },

      { label: "60", variant: "bonus-number", press: () => append("60") },
      { label: "4", variant: "number", press: () => append("4") },
      { label: "5", variant: "number", press: () => append("5") },
      { label: "6", variant: "number", press: () => append("6") },

      { label: "40", variant: "bonus-number", press: () => append("40") },
      { label: "1", variant: "number", press: () => append("1") },
      { label: "2", variant: "number", press: () => append("2") },
      { label: "3", variant: "number", press: () => append("3") },

      { label: "20", variant: "bonus-number", press: () => append("20") },
      { label: "00", variant: "bonus-number", press: () => append("00") },
      { label: "0", variant: "number", press: () => append("0") },
      { label: "Enter", variant: "action", press: enter, icon: enterIcon }
    ];

    keys.forEach(k => {
      root.appendChild(
        createKeyButton({
          label: k.label,
          variant: k.variant,
          onPress: k.press,
          active: k.variant === "intent" && isActiveIntent(k.label),
          icon: k.icon || null
        })
      );
    });
  }

  render();
  return root;
}