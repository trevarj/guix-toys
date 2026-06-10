// Hash routes:
//   #/?q=…&type=…&channel=…           search state (shareable)
//   #/package/<channel>/<name>        detail views
//   #/service/<channel>/<name>
//   #/symbol/<channel>/<name>
//   #/channel/<name>
const DETAIL = { package: "packages", service: "services", symbol: "symbols", channel: "channels" };

export function parseRoute() {
  const hash = location.hash.slice(1) || "/";
  const [path, qs = ""] = hash.split("?");
  const parts = path.split("/").filter(Boolean);

  if (parts.length && DETAIL[parts[0]]) {
    const kind = parts[0];
    if (kind === "channel") {
      return { view: "detail", type: "channels", channel: "", name: decodeURIComponent(parts[1] ?? "") };
    }
    return {
      view: "detail",
      type: DETAIL[kind],
      channel: decodeURIComponent(parts[1] ?? ""),
      name: decodeURIComponent(parts[2] ?? ""),
    };
  }

  const params = new URLSearchParams(qs);
  return {
    view: "search",
    q: params.get("q") ?? "",
    type: params.get("type") ?? "all",
    channel: params.get("channel") ?? "",
  };
}

export function searchHash({ q, type, channel }) {
  const params = new URLSearchParams();
  if (q) params.set("q", q);
  if (type && type !== "all") params.set("type", type);
  if (channel) params.set("channel", channel);
  const qs = params.toString();
  return "#/" + (qs ? `?${qs}` : "");
}

export function detailHash(type, channel, name) {
  const kind = { packages: "package", services: "service", symbols: "symbol", channels: "channel" }[type];
  return kind === "channel"
    ? `#/channel/${encodeURIComponent(name)}`
    : `#/${kind}/${encodeURIComponent(channel)}/${encodeURIComponent(name)}`;
}

// Replace (not push) while typing so history isn't spammed.
export function setSearchUrl(state, { replace = true } = {}) {
  const hash = searchHash(state);
  if (location.hash === hash) return;
  if (replace) history.replaceState(null, "", hash);
  else location.hash = hash;
}

export function onRoute(handler) {
  window.addEventListener("hashchange", () => handler(parseRoute()));
}
