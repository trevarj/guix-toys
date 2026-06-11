import { esc, splitField, parseLicenses, parseOrigin } from "./util.js";
import { detailHash, searchHash } from "./router.js";

function tag(text, cls = "") {
  return `<span class="tag ${cls}">${esc(text)}</span>`;
}

function channelTag(channel) {
  return `<a class="tag tag-channel" href="${detailHash("channels", "", channel)}">${esc(channel)}</a>`;
}

function inputChips(names) {
  if (!names.length) return "";
  // inputs are stored as name@version; search names have no version
  return `<div class="chips-inline">${names
    .map((n) => `<a class="chip-mini" href="${searchHash({ q: `"${n.split("@")[0]}"`, type: "packages" })}">${esc(n)}</a>`)
    .join("")}</div>`;
}

function originText(origin) {
  // uri is {url, commit} for git-fetch, [url, ...] for url-fetch
  const u = origin?.uri;
  const url = Array.isArray(u) ? u[0] : (u?.url ?? u);
  if (typeof url !== "string") return "";
  const commit = !Array.isArray(u) && u?.commit ? ` @ ${u.commit}` : "";
  return `<code>${esc(url + commit)}</code>`;
}

function licenseLinks(licenses) {
  return licenses
    .map((l) => (l.uri ? `<a href="${esc(l.uri)}" rel="noopener">${esc(l.name)}</a>` : esc(l.name)))
    .join(", ");
}

// --- result cards ---------------------------------------------------------

export function card(type, row) {
  const href =
    type === "channels"
      ? detailHash("channels", "", row.name)
      : detailHash(type, row.channel, row.name);
  const attrs = `data-href="${href}" data-type="${type}" data-channel="${esc(type === "channels" ? "" : row.channel)}" data-name="${esc(row.name)}"`;
  const head = `<a class="item-name" href="${href}">${esc(row.name)}</a>`;

  switch (type) {
    case "packages":
      return `<article class="item" ${attrs}>
        <header>${head}${tag(row.version, "tag-version")}${channelTag(row.channel)}</header>
        <p class="item-sub">${esc(row.synopsis || "")}</p>
      </article>`;
    case "services":
      return `<article class="item" ${attrs}>
        <header>${head}${channelTag(row.channel)}</header>
        <p class="item-sub">${esc((row.description || "").slice(0, 200))}</p>
      </article>`;
    case "symbols":
      return `<article class="item" ${attrs}>
        <header>${head}${channelTag(row.channel)}</header>
        <p class="item-sub mono">${esc(row.signature || row.module || "")}</p>
      </article>`;
    case "channels":
      return `<article class="item" ${attrs}>
        <header>${head}${tag(`${row.packagesCount} pkgs`, "tag-count")}${tag(`${row.servicesCount} svcs`, "tag-count")}</header>
        <p class="item-sub">${esc(row.synopsis || row.url || "")}</p>
      </article>`;
  }
}

// --- detail views ----------------------------------------------------------

function detailRow(label, html) {
  return html ? `<div class="d-row"><span class="d-label">${label}</span><span class="d-value">${html}</span></div>` : "";
}

function sourceLink(row) {
  return row.url ? `<a href="${esc(row.url)}" rel="noopener">${esc(row.file || row.url)}</a>` : "";
}

export function detail(type, rows) {
  if (!rows.length) {
    return `<div class="empty"><p>NOTHING HERE.</p></div>`;
  }
  return rows.map((row) => detailOne(type, row)).join("");
}

function copyBlock(text, label = "copy") {
  return `<div class="copyblock">
    <pre class="d-code" data-copy>${esc(text)}</pre>
    <button class="copy-btn" data-copy-btn>${label}</button>
  </div>`;
}

function grid(...rows) {
  const html = rows.filter(Boolean).join("");
  return html ? `<div class="d-grid">${html}</div>` : "";
}

// Body shared by the full detail view and inline card expansion.
// The install command only appears on full detail pages.
export function expandBody(type, row, { install = false } = {}) {
  switch (type) {
    case "packages": {
      const licenses = licenseLinks(parseLicenses(row.licenses));
      const origin = parseOrigin(row.origin);
      return `${install ? copyBlock(`guix install ${row.name}`) : ""}
        ${row.description ? `<p class="d-desc">${esc(row.description)}</p>` : ""}
        ${grid(
          detailRow("home page", row.homepage ? `<a href="${esc(row.homepage)}" rel="noopener">${esc(row.homepage)}</a>` : ""),
          detailRow("licenses", licenses),
          detailRow("build system", row.buildSystem ? `<code>${esc(row.buildSystem)}</code>` : ""),
          detailRow("module", row.module ? `<code>${esc(row.module)}</code>` : ""),
          detailRow("source", sourceLink(row)),
          detailRow("origin", originText(origin))
        )}
        ${grid(
          detailRow("inputs", inputChips(splitField(row.inputs))),
          detailRow("propagated", inputChips(splitField(row.propagatedInputs)))
        )}`;
    }
    case "services":
      return `${row.description ? `<p class="d-desc">${esc(row.description)}</p>` : ""}
        ${grid(
          detailRow("module", row.module ? `<code>${esc(row.module)}</code>` : ""),
          detailRow("source", sourceLink(row))
        )}`;
    case "symbols":
      return `${row.signature ? `<pre class="d-code">${esc(row.signature)}</pre>` : ""}
        ${row.doc ? `<p class="d-desc">${esc(row.doc)}</p>` : ""}
        ${grid(
          detailRow("module", row.module ? `<code>${esc(row.module)}</code>` : ""),
          detailRow("source", sourceLink(row))
        )}`;
    case "channels":
      return `${grid(
          detailRow("url", `<a href="${esc(row.url)}" rel="noopener">${esc(row.url)}</a>`),
          detailRow("branch", `<code>${esc(row.branch)}</code>`),
          detailRow("commit", row.commit ? `<code>${esc(row.commit)}</code>` : ""),
          detailRow("browse", `<a href="${searchHash({ type: "packages", channel: row.name })}">packages in this channel</a>`)
        )}
        ${row.subscriptionSnippet ? `
          <div class="d-row d-row-wide"><span class="d-label">subscribe</span></div>
          ${copyBlock(row.subscriptionSnippet, "copy snippet")}` : ""}`;
  }
}

function detailOne(type, row) {
  switch (type) {
    case "packages":
      return `<article class="detail">
        <header class="d-head">
          <h1>${esc(row.name)}</h1>${tag(row.version, "tag-version")}${channelTag(row.channel)}
        </header>
        <p class="d-synopsis">${esc(row.synopsis || "")}</p>
        ${expandBody(type, row, { install: true })}
      </article>`;
    case "services":
    case "symbols":
      return `<article class="detail">
        <header class="d-head"><h1>${esc(row.name)}</h1>${channelTag(row.channel)}</header>
        ${expandBody(type, row)}
      </article>`;
    case "channels":
      return `<article class="detail">
        <header class="d-head">
          <h1>${esc(row.name)}</h1>
          ${tag(`${row.packagesCount} packages`, "tag-count")}${tag(`${row.servicesCount} services`, "tag-count")}
        </header>
        ${row.synopsis ? `<p class="d-synopsis">${esc(row.synopsis)}</p>` : ""}
        ${expandBody(type, row)}
      </article>`;
  }
}

export function groupSection(type, label, rows, count, state) {
  const moreHash = searchHash({ ...state, type });
  const shownCount = count ?? `${rows.length}+`;
  const hasMore = count == null ? true : count > rows.length;
  return `<section class="group" data-group="${type}">
    <h2 class="group-title">${esc(label)} <span class="group-count">${shownCount}</span>
      ${hasMore ? `<a class="group-more" href="${moreHash}">all ${shownCount} →</a>` : ""}
    </h2>
    ${rows.map((r) => card(type, r)).join("")}
  </section>`;
}

export function emptyState(q) {
  return `<div class="empty">
    <img src="img/mascot.svg" alt="" class="empty-mascot">
    <p>NOTHING${q ? ` FOR “${esc(q)}”` : ""}. TRY FEWER LETTERS.</p>
  </div>`;
}
