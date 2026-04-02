import { createAppHeader } from "../../appHeader/ui/appHeader.js";
import backIcon from "../components/back.svg";
import aboutContentHtml from "./aboutContent.html?raw";

export function createAboutPage({ onBack }) {
  const root = document.createElement("div");
  root.className = "about-page";

  const header = createAppHeader({
    leftIcon: backIcon,
    onLeftClick: onBack,
    centerText: "Calo"
  });
  root.appendChild(header);

  const body = document.createElement("div");
  body.className = "about-page__body";

  const quote = document.createElement("blockquote");
  quote.className = "about-page__pullquote";

  const quoteText = document.createElement("p");
  quoteText.className = "about-page__pullquote-text";
  quoteText.textContent = "Simplicity is sophistication.";
  quote.appendChild(quoteText);

  const tagline = document.createElement("p");
  tagline.className = "about-page__tagline";
  tagline.textContent = "And 3-second calorie tracking rocks.";

  const contentWrapper = document.createElement("div");
  contentWrapper.innerHTML = aboutContentHtml;

  body.appendChild(quote);
  body.appendChild(tagline);
  body.appendChild(contentWrapper);
  root.appendChild(body);

  return root;
}
