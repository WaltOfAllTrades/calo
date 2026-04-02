import { createAppHeader } from "../../appHeader/ui/appHeader.js";
import { getTodayLog } from "../application/getTodayLog.js";
import backIcon from "../../aboutPage/components/back.svg";

function formatTime(isoString) {
  const d = new Date(isoString);
  return d.toLocaleTimeString(undefined, {
    hour: "numeric",
    minute: "2-digit"
  });
}

function buildTable(rows, hasName, hasDescription) {
  const table = document.createElement("table");
  table.className = "show-log__table";

  const thead = document.createElement("thead");
  const headRow = document.createElement("tr");

  const cols = ["Time", "Cal"];
  if (hasName) cols.push("Item");
  if (hasDescription) cols.push("Details");

  for (const col of cols) {
    const th = document.createElement("th");
    th.textContent = col;
    headRow.appendChild(th);
  }
  thead.appendChild(headRow);
  table.appendChild(thead);

  const tbody = document.createElement("tbody");
  for (const row of rows) {
    const tr = document.createElement("tr");

    const timeTd = document.createElement("td");
    timeTd.textContent = formatTime(row.createdOn);
    tr.appendChild(timeTd);

    const calTd = document.createElement("td");
    calTd.className = "show-log__cal-cell";
    const sign = row.calories >= 0 ? "+" : "";
    calTd.textContent = sign + row.calories;
    if (row.calories < 0) calTd.classList.add("show-log__cal-cell--neg");
    tr.appendChild(calTd);

    if (hasName) {
      const nameTd = document.createElement("td");
      nameTd.textContent = row.name || "";
      tr.appendChild(nameTd);
    }

    if (hasDescription) {
      const descTd = document.createElement("td");
      descTd.textContent = row.description || "";
      tr.appendChild(descTd);
    }

    tbody.appendChild(tr);
  }
  table.appendChild(tbody);

  return table;
}

export function createShowLogPage({ onBack }) {
  const root = document.createElement("div");
  root.className = "show-log";

  const header = createAppHeader({
    leftIcon: backIcon,
    onLeftClick: onBack,
    centerText: "Calo"
  });
  root.appendChild(header);

  const body = document.createElement("div");
  body.className = "show-log__body";

  const title = document.createElement("h2");
  title.className = "show-log__title";
  title.textContent = "Today\u2019s Log";

  const subtitle = document.createElement("p");
  subtitle.className = "show-log__subtitle";
  subtitle.textContent = "Everything logged today at a glance.";

  body.appendChild(title);
  body.appendChild(subtitle);

  const scrollArea = document.createElement("div");
  scrollArea.className = "show-log__scroll";

  const empty = document.createElement("p");
  empty.className = "show-log__empty";
  empty.textContent = "No entries yet today.";
  scrollArea.appendChild(empty);

  body.appendChild(scrollArea);
  root.appendChild(body);

  getTodayLog().then(({ rows, hasName, hasDescription }) => {
    scrollArea.innerHTML = "";
    if (rows.length === 0) {
      scrollArea.appendChild(empty);
      return;
    }
    scrollArea.appendChild(buildTable(rows, hasName, hasDescription));
  });

  return root;
}
