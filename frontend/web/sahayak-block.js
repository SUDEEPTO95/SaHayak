/* SaHayak pause card. One OK. Stay on this page. Reappears only if the issue remains. */
(function () {
  const COPY = {
    no_internet: { title: "The line is quiet", line: "This phone has no internet right now. You stay on this page. Nothing was sent.", ok: "OK" },
    location_denied: { title: "Location stayed off", line: "SaHayak did not get location. Pick a city instead. You stay here.", ok: "OK" },
    location_off: { title: "Location is not available", line: "Use the city list. We never follow you in the background.", ok: "OK" },
    server_quiet: { title: "SaHayak could not answer", line: "The helping-hand line is not reaching this computer. You stay on this page.", ok: "OK" },
    session_ended: { title: "Please sign in again when you are ready", line: "This session ended. You are still on this page. Nothing was posted.", ok: "OK" },
    account_paused: { title: "This account is paused", line: "Write to the owner. You stay here. We did not move you away.", ok: "OK" },
    too_many: { title: "A short pause", line: "Too many tries just now. Stay here. Wait a moment, then OK.", ok: "OK" },
    generic: { title: "A small pause", line: "Something needed a moment. You stay on this page. Nothing extra was sent.", ok: "OK" }
  };
  const DROPS = '<div class="pulse" aria-hidden="true"><span><svg class="drops" viewBox="0 0 32 28" fill="#e8c07a"><path d="M16 3.2C16 3.2 10.4 11.2 10.4 16.2a5.6 5.6 0 0 0 11.2 0C21.6 11.2 16 3.2 16 3.2z"/><path opacity=".82" d="M7.2 11C7.2 11 4.2 16 4.2 18.4a3 3 0 0 0 6 0C10.2 16 7.2 11 7.2 11z"/><path opacity=".65" d="M25.4 13C25.4 13 23.6 16.6 23.6 18.2a2.1 2.1 0 0 0 4.2 0C27.8 16.6 25.4 13 25.4 13z"/></svg></span></div>';
  let open = false, mute = false, last = "";

  function ensure() {
    let v = document.getElementById("sahayakVeil");
    if (v) return v;
    v = document.createElement("div");
    v.id = "sahayakVeil";
    v.className = "veil hidden";
    v.setAttribute("role", "dialog");
    v.setAttribute("aria-modal", "true");
    v.innerHTML = '<div class="pause">' + DROPS + '<p class="kicker">A small pause</p><h2 id="pauseTitle"></h2><p id="pauseLine"></p><p class="stay">You stay on this page</p><button type="button" class="cta trust" id="pauseOk">OK</button></div>';
    document.body.appendChild(v);
    v.querySelector("#pauseOk").onclick = hide;
    return v;
  }

  function show(codeOrBlock) {
    if (mute || open) return;
    const block = typeof codeOrBlock === "object" && codeOrBlock ? codeOrBlock : null;
    const code = (block && block.code) || codeOrBlock || "generic";
    const copy = block && block.title ? block : (COPY[code] || COPY.generic);
    last = code;
    const v = ensure();
    v.querySelector("#pauseTitle").textContent = copy.title;
    v.querySelector("#pauseLine").textContent = copy.line;
    v.querySelector("#pauseOk").textContent = copy.ok || "OK";
    v.classList.remove("hidden");
    open = true;
  }

  function hide() {
    const v = document.getElementById("sahayakVeil");
    if (v) v.classList.add("hidden");
    open = false;
    mute = true;
    setTimeout(function () { mute = false; }, 700);
  }

  function isApi(u) {
    const s = String(u || "");
    return s.indexOf("/v1/") !== -1 || s.indexOf("/health") !== -1;
  }

  window.SahayakPause = { show: show, hide: hide };

  window.addEventListener("offline", function () { show("no_internet"); });
  document.addEventListener("click", function (e) {
    if (mute || open) return;
    if (!navigator.onLine && e.target && e.target.closest && e.target.closest("button, .cta, a")) {
      show("no_internet");
    }
  }, true);

  const native = window.fetch.bind(window);
  window.fetch = async function (url, opts) {
    if (isApi(url) && typeof navigator !== "undefined" && navigator.onLine === false) {
      show("no_internet");
    }
    try {
      const r = await native(url, opts);
      if (isApi(url) && !r.ok) {
        try {
          const j = await r.clone().json();
          if (j && j.block) show(j.block);
          else if (r.status >= 500) show("server_quiet");
          else if (r.status === 401) show("session_ended");
          else if (r.status === 429) show("too_many");
        } catch (_) {
          if (r.status >= 500) show("server_quiet");
        }
      }
      return r;
    } catch (err) {
      if (isApi(url)) show(navigator.onLine ? "server_quiet" : "no_internet");
      throw err;
    }
  };
})();
