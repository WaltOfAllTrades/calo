import { createAppHeader } from "../../appHeader/ui/appHeader.js";
import { getTodayLog } from "../application/getTodayLog.js";
import { deleteLogEntry, updateLogEntry } from "../application/manageLogEntry.js";
import { createEditEntryCard } from "../components/editEntryCard.js";
import backIcon from "../../aboutPage/components/back.svg";

function formatTime(isoString) {
  const d = new Date(isoString);
  return d.toLocaleTimeString(undefined, {
    hour: "numeric",
    minute: "2-digit"
  });
}

function buildTable(rows, hasName, hasDescription, { onDelete, onEdit }) {
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
  let activeRow = null;

  function dismissActive() {
    if (!activeRow) return;
    const actions = activeRow.querySelector(".show-log__row-actions");
    if (actions) actions.remove();
    activeRow.classList.remove("is-active");
    activeRow = null;
  }

  for (const row of rows) {
    const tr = document.createElement("tr");
    tr.className = "show-log__row";
    tr.dataset.id = row.id;

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

  // Delegated tap on row
  tbody.addEventListener("click", (e) => {
    const tr = e.target.closest(".show-log__row");
    if (!tr) return;

    if (e.target.closest(".show-log__action-btn")) return;

    if (tr === activeRow) {
      dismissActive();
      return;
    }

    dismissActive();
    activeRow = tr;
    tr.classList.add("is-active");

    const id = Number(tr.dataset.id);
    const entry = rows.find((r) => r.id === id);

    const actionsBar = document.createElement("div");
    actionsBar.className = "show-log__row-actions";

    const editBtn = document.createElement("button");
    editBtn.className = "show-log__action-btn show-log__action-btn--edit";
    editBtn.setAttribute("aria-label", "Edit entry");
    editBtn.textContent = "✎";
    editBtn.addEventListener("click", (ev) => {
      ev.stopPropagation();
      dismissActive();
      onEdit(entry);
    });

    const deleteBtn = document.createElement("button");
    deleteBtn.className = "show-log__action-btn show-log__action-btn--delete";
    deleteBtn.setAttribute("aria-label", "Delete entry");
    deleteBtn.textContent = "✕";
    deleteBtn.addEventListener("click", (ev) => {
      ev.stopPropagation();
      dismissActive();
      onDelete(entry.id);
    });

    actionsBar.appendChild(editBtn);
    actionsBar.appendChild(deleteBtn);

    // Overlay on the last cell of the row
    const lastTd = tr.lastElementChild;
    lastTd.style.position = "relative";
    lastTd.appendChild(actionsBar);
  });

  // Outside tap dismisses active row
  document.addEventListener("click", (e) => {
    if (!activeRow) return;
    if (!table.contains(e.target)) dismissActive();
  }, { capture: true });

  return table;
}

export function createShowLogPage({ onBack, onDataChange }) {
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

  function renderLog() {
    getTodayLog().then(({ rows, hasName, hasDescription }) => {
      scrollArea.innerHTML = "";
      if (rows.length === 0) {
        scrollArea.appendChild(empty);
        return;
      }
      scrollArea.appendChild(
        buildTable(rows, hasName, hasDescription, {
          onDelete(id) {
            deleteLogEntry(id).then(() => {
              renderLog();
              onDataChange?.();
            });
          },
          onEdit(entry) {
            const card = createEditEntryCard({
              entry,
              onSave(fields) {
                updateLogEntry(entry.id, fields).then(() => {
                  renderLog();
                  onDataChange?.();
                });
              },
              onCancel() {}
            });
            document.body.appendChild(card);
          }
        })
      );
    });
  }

  renderLog();

  return root;
}
