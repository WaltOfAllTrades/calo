export function createKeyButton({
  label,
  variant,
  onPress,
  active = false,
  icon = null
}) {
  const btn = document.createElement("button");
  btn.className = `key-button key-button--${variant}`;
  if (active) btn.classList.add("is-active");

  if (icon) {
    const img = document.createElement("img");
    img.className = "key-button__icon";
    img.src = icon;
    img.alt = label;
    img.setAttribute("aria-hidden", "true");
    btn.setAttribute("aria-label", label);
    btn.appendChild(img);
  } else {
    const labelNode = document.createElement("span");
    labelNode.className = "key-button__label";
    labelNode.textContent = label;
    btn.appendChild(labelNode);
  }

  btn.addEventListener("click", onPress);
  return btn;
}