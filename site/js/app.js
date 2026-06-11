import { debounce } from "./util.js";
import { search, lookup, allChannels, TYPES } from "./queries.js";
import { parseRoute, onRoute, setSearchUrl } from "./router.js";
import { card, detail, expandBody, groupSection, emptyState } from "./render.js";

const PAGE_SIZE = 24;
const GROUP_SIZE = 8;

const $omnibox = document.getElementById("omnibox");
const $chips = document.getElementById("type-chips");
const $channel = document.getElementById("channel-filter");
const $status = document.getElementById("status");
const $results = document.getElementById("results");
const $loadMore = document.getElementById("load-more");
const $sentinel = document.getElementById("sentinel");

const state = { q: "", type: "all", channel: "", page: 1, count: 0 };
let queryToken = 0; // discard stale async results

function setStatus(text) {
  $status.textContent = text;
}

function syncControls() {
  if ($omnibox.value !== state.q) $omnibox.value = state.q;
  for (const btn of $chips.querySelectorAll(".chip")) {
    btn.classList.toggle("active", btn.dataset.type === state.type);
  }
  $channel.value = state.channel;
}

// --- search rendering -------------------------------------------------------

// The worker can't cancel a running query, so only one search runs at a
// time; while one is in flight, later requests collapse into the latest.
let inFlight = false;
let queued = null;
async function runSearch(opts = {}) {
  if (inFlight) {
    queued = opts;
    return;
  }
  inFlight = true;
  try {
    await doSearch(opts);
  } finally {
    inFlight = false;
    if (queued) {
      const next = queued;
      queued = null;
      runSearch(next);
    }
  }
}

async function doSearch({ append = false } = {}) {
  const token = ++queryToken;
  if (!append) {
    state.page = 1;
    setStatus("searching…");
  }

  try {
    if (state.type === "all") {
      const types = Object.keys(TYPES);
      const settled = await Promise.all(
        types.map((t) =>
          search(t, { q: state.q, channel: state.channel, limit: GROUP_SIZE, page: 1 })
        )
      );
      if (token !== queryToken) return;
      // count can be null on DBs without toys_counts — fall back to row counts
      const total = settled.reduce((n, r) => n + (r.count ?? r.rows.length), 0);
      $loadMore.hidden = true;
      if (!total) {
        $results.innerHTML = emptyState(state.q);
        setStatus("");
        return;
      }
      $results.innerHTML = types
        .map((t, i) =>
          settled[i].rows.length
            ? groupSection(t, TYPES[t].label, settled[i].rows, settled[i].count, state)
            : ""
        )
        .join("");
      setStatus(`${total} results`);
    } else {
      const { rows, count } = await search(state.type, {
        q: state.q,
        channel: state.channel,
        limit: PAGE_SIZE,
        page: state.page,
      });
      if (token !== queryToken) return;
      state.count = count;
      const html = rows.map((r) => card(state.type, r)).join("");
      if (append) $results.insertAdjacentHTML("beforeend", html);
      else $results.innerHTML = rows.length ? html : emptyState(state.q);
      const shown = $results.querySelectorAll(".item").length;
      $loadMore.hidden = count == null ? rows.length < PAGE_SIZE : shown >= count;
      setStatus(count == null ? `${shown} shown` : count ? `${shown} of ${count}` : "");
    }
  } catch (err) {
    if (token !== queryToken) return;
    setStatus(`search failed: ${err.message ?? err}`);
    console.error(err);
  }
}

function loadMore() {
  if ($loadMore.hidden) return;
  state.page += 1;
  runSearch({ append: true });
}

// --- routing ----------------------------------------------------------------

async function showDetail(route) {
  $loadMore.hidden = true;
  setStatus("loading…");
  try {
    const rows = await lookup(route.type, route.channel, route.name);
    $results.innerHTML = detail(route.type, rows);
    setStatus("");
  } catch (err) {
    setStatus(`failed: ${err.message ?? err}`);
  }
}

function copyFrom(btn) {
  const pre = btn.closest(".copyblock").querySelector("[data-copy]");
  navigator.clipboard.writeText(pre.textContent.trim()).then(() => {
    const label = btn.textContent;
    btn.textContent = "copied.";
    setTimeout(() => (btn.textContent = label), 1500);
  });
}

async function toggleExpand(item) {
  const open = item.querySelector(".item-expand");
  if (open) {
    open.remove();
    item.classList.remove("expanded");
    return;
  }
  const { type, channel, name } = item.dataset;
  item.classList.add("expanded");
  const box = document.createElement("div");
  box.className = "item-expand";
  box.innerHTML = `<span class="status">loading…</span>`;
  item.appendChild(box);
  try {
    const rows = await lookup(type, channel, name);
    if (!item.contains(box)) return; // collapsed while loading
    box.innerHTML = rows.length
      ? rows.map((r) => expandBody(type, r)).join("<hr>")
      : "nothing found.";
  } catch (err) {
    box.innerHTML = `failed: ${err.message ?? err}`;
  }
}

function applyRoute(route) {
  if (route.view === "detail") {
    showDetail(route);
    return;
  }
  state.q = route.q;
  state.type = route.type in TYPES || route.type === "all" ? route.type : "all";
  state.channel = route.channel;
  syncControls();
  runSearch();
}

// --- input wiring -----------------------------------------------------------

const debouncedSearch = debounce(() => {
  state.q = $omnibox.value;
  setSearchUrl(state);
  runSearch();
}, 200);

$omnibox.addEventListener("input", debouncedSearch);

$chips.addEventListener("click", (e) => {
  const btn = e.target.closest(".chip");
  if (!btn) return;
  state.type = btn.dataset.type;
  syncControls();
  setSearchUrl(state, { replace: false });
  runSearch();
});

$channel.addEventListener("change", () => {
  state.channel = $channel.value;
  setSearchUrl(state, { replace: false });
  runSearch();
});

$loadMore.addEventListener("click", loadMore);
new IntersectionObserver((entries) => {
  if (entries.some((e) => e.isIntersecting)) loadMore();
}).observe($sentinel);

// keyboard: / focus, ↑↓ move highlight, Enter open, Esc clear
let activeIndex = -1;
function highlight(delta) {
  const items = [...$results.querySelectorAll(".item")];
  if (!items.length) return;
  activeIndex = Math.max(0, Math.min(items.length - 1, activeIndex + delta));
  items.forEach((el, i) => el.classList.toggle("kb-active", i === activeIndex));
  items[activeIndex].scrollIntoView({ block: "nearest" });
}

document.addEventListener("keydown", (e) => {
  const typing = e.target === $omnibox;
  if (e.key === "/" && !typing) {
    e.preventDefault();
    $omnibox.focus();
    $omnibox.select();
  } else if (e.key === "Escape") {
    if ($omnibox.value) {
      $omnibox.value = "";
      debouncedSearch();
    }
    $omnibox.blur();
    activeIndex = -1;
  } else if (e.key === "ArrowDown") {
    e.preventDefault();
    if (typing) $omnibox.blur();
    highlight(1);
  } else if (e.key === "ArrowUp") {
    e.preventDefault();
    highlight(-1);
  } else if (e.key === "Enter" && !typing) {
    const active = $results.querySelector(".item.kb-active");
    if (active) toggleExpand(active);
  }
});

$results.addEventListener("click", (e) => {
  const copyBtn = e.target.closest("[data-copy-btn]");
  if (copyBtn) {
    copyFrom(copyBtn);
    return;
  }
  // cards expand in place on click; real links (name, channel, chips) win
  if (e.target.closest("a")) return;
  const item = e.target.closest(".item[data-name]");
  if (item && !e.target.closest(".item-expand")) toggleExpand(item);
});

// --- boot -------------------------------------------------------------------

onRoute(applyRoute);

(async () => {
  setStatus("loading database…");
  try {
    const channels = await allChannels();
    for (const { id } of channels) {
      const opt = document.createElement("option");
      opt.value = id;
      opt.textContent = id;
      $channel.appendChild(opt);
    }
  } catch (err) {
    setStatus(`database failed to load: ${err.message ?? err}`);
    console.error(err);
    return;
  }
  applyRoute(parseRoute());
})();
