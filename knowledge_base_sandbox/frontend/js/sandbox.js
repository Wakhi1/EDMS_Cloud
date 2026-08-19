/**
 * js/sandbox.js — the Postman replacement, now a proper API workbench:
 *   - Catalog with search/filter, grouped by folder, method-colour-coded.
 *   - Per-endpoint "Documentation" tab — parameters, request body
 *     fields, and example responses per status code (from doc_json,
 *     populated by scripts/import-postman.js + scripts/endpoint-docs.js).
 *   - "Try it" tab — the actual request builder + Send.
 *   - Response viewer with Body/Headers tabs and real JSON syntax
 *     highlighting (highlight.js, already loaded for markdown pages).
 *   - "Copy as cURL" — a ready-to-paste command hitting the real
 *     environment directly (not through this portal's proxy), for
 *     taking a call from the sandbox into a script or terminal.
 *   - Local request history (browser-only, never sent to the server —
 *     see note in renderHistory()) with one-click replay.
 *
 * {{variable}} substitution happens client-side, same as before — no
 * server-side script execution, ever (see the file's original header
 * note preserved below for why).
 */
const Sandbox = (() => {
  let catalog = [];
  let environments = [];
  let vars = {};
  let currentEnvironmentId = null;
  let activeRequest = null;
  let apiKey = localStorage.getItem('docs_sandbox_api_key') || '';
  let apiKeyVisible = false;
  let catalogFilter = '';
  let requestTab = 'try'; // 'try' | 'docs'
  let responseTab = 'body'; // 'body' | 'headers'
  let rightPanelTab = 'vars'; // 'vars' | 'history'

  const HISTORY_KEY = 'docs_sandbox_history';
  const HISTORY_LIMIT = 40;

  function substitute(str) {
    if (typeof str !== 'string') return str;
    return str.replace(/\{\{(\w+)\}\}/g, (m, key) => (vars[key] !== undefined && vars[key] !== null ? vars[key] : m));
  }
  function substituteObj(obj) {
    if (!obj || typeof obj !== 'object') return obj;
    const out = {};
    for (const [k, v] of Object.entries(obj)) out[k] = substitute(v);
    return out;
  }

  function currentEnvironment() {
    return environments.find((e) => e.id === currentEnvironmentId) || null;
  }

  async function loadAll() {
    [catalog, environments, vars] = await Promise.all([
      Api.get('/sandbox/catalog'),
      Api.get('/sandbox/environments'),
      Api.get('/sandbox/variables'),
    ]);
    const def = environments.find((e) => e.is_default) || environments[0];
    currentEnvironmentId = def ? def.id : null;
  }

  async function saveVariable(key, value) {
    vars[key] = value;
    try { await Api.put('/sandbox/variables', { key, value }); } catch { /* best-effort */ }
  }

  /* ============================== RENDER ROOT ============================== */

  async function render() {
    const view = document.getElementById('view');
    document.getElementById('page-toc').innerHTML = '';
    document.getElementById('nav-tree').innerHTML = '<div class="nav-loading">Sandbox mode — docs nav hidden</div>';

    view.innerHTML = `<p style="color:var(--ink3)">Loading sandbox…</p>`;
    try {
      await loadAll();
    } catch (err) {
      view.innerHTML = `<div class="alert error">Could not load the sandbox: ${Render.escapeHtml(err.message)}</div>`;
      return;
    }

    view.innerHTML = `
      <div class="sandbox-shell">
        <div class="sandbox-toolbar">
          <div class="sandbox-toolbar-group">
            <label>API Key</label>
            <div class="api-key-input-wrap">
              <input id="api-key-input" type="${apiKeyVisible ? 'text' : 'password'}" placeholder="pdk_..." value="${Render.escapeHtml(apiKey)}">
              <button class="toggle-visibility" id="toggle-key-visibility" title="Show/hide">${apiKeyVisible ? '🙈' : '👁'}</button>
            </div>
            <span id="key-status"><span class="key-status-dot unknown"></span>unsaved</span>
          </div>
          <div class="sandbox-toolbar-group">
            <label>Environment</label>
            <select id="env-select" class="sandbox-env-select">
              ${environments.map((e) => `<option value="${e.id}" ${e.id === currentEnvironmentId ? 'selected' : ''}>${Render.escapeHtml(e.name)} — ${Render.escapeHtml(e.base_url)}</option>`).join('')}
            </select>
          </div>
          <div class="sandbox-toolbar-group" style="margin-left:auto;">
            <span style="color:var(--ink3);">${catalog.reduce((n, f) => n + f.requests.length, 0)} endpoints, fully documented</span>
          </div>
        </div>
        <div class="sandbox-layout">
          <div class="sandbox-catalog" id="sandbox-catalog"></div>
          <div class="sandbox-main" id="sandbox-main">
            <div style="padding:40px 22px;color:var(--ink3);text-align:center;">
              Pick an endpoint on the left. Every one has a <strong>Documentation</strong> tab (parameters, request fields, example responses) alongside <strong>Try it</strong>.
            </div>
          </div>
          <div class="sandbox-vars" id="sandbox-vars"></div>
        </div>
      </div>`;

    document.getElementById('api-key-input').oninput = (e) => { apiKey = e.target.value; updateKeyStatus('unsaved'); };
    document.getElementById('toggle-key-visibility').onclick = () => { apiKeyVisible = !apiKeyVisible; render(); };
    document.getElementById('env-select').onchange = (e) => { currentEnvironmentId = Number(e.target.value); };
    document.getElementById('api-key-input').onblur = () => {
      if (apiKey) { localStorage.setItem('docs_sandbox_api_key', apiKey); updateKeyStatus('ok'); }
    };
    if (apiKey) updateKeyStatus('ok');

    renderCatalog();
    renderRightPanel();
  }

  function updateKeyStatus(state) {
    const el = document.getElementById('key-status');
    if (!el) return;
    const label = state === 'ok' ? 'saved locally' : state === 'bad' ? 'rejected by server' : 'unsaved';
    el.innerHTML = `<span class="key-status-dot ${state}"></span>${label}`;
  }

  function toastInline(msg, isError) {
    const box = document.getElementById('sandbox-main');
    if (!box) return;
    const prev = box.querySelector('.inline-flash');
    if (prev) prev.remove();
    const div = document.createElement('div');
    div.className = `alert ${isError ? 'error' : 'ok'} inline-flash`;
    div.textContent = msg;
    box.prepend(div);
    setTimeout(() => div.remove(), 2600);
  }

  /* =============================== CATALOG =============================== */

  function renderCatalog() {
    const el = document.getElementById('sandbox-catalog');
    const q = catalogFilter.trim().toLowerCase();

    const filtered = catalog.map((folder) => ({
      ...folder,
      requests: folder.requests.filter((r) => !q || r.name.toLowerCase().includes(q) || r.path.toLowerCase().includes(q) || r.method.toLowerCase().includes(q)),
    })).filter((f) => f.requests.length > 0);

    el.innerHTML = `
      <div class="sandbox-catalog-search">
        <input id="catalog-filter" type="search" placeholder="Filter endpoints…" value="${Render.escapeHtml(catalogFilter)}">
      </div>
      ${filtered.length === 0
        ? `<div class="sandbox-empty-catalog">No endpoints match "${Render.escapeHtml(catalogFilter)}".</div>`
        : filtered.map((folder) => `
            <div class="sandbox-folder">
              <div class="sandbox-folder-title"><span>${Render.escapeHtml(folder.name)}</span><span class="sandbox-folder-count">${folder.requests.length}</span></div>
              ${folder.requests.map((r) => `
                <div class="sandbox-req-item ${activeRequest && activeRequest.id === r.id ? 'active' : ''}" data-id="${r.id}">
                  <span class="method-chip method-${r.method}">${r.method}</span>
                  <span class="sandbox-req-name">${Render.escapeHtml(r.name)}</span>
                </div>`).join('')}
            </div>`).join('')}
    `;

    document.getElementById('catalog-filter').oninput = (e) => { catalogFilter = e.target.value; renderCatalog(); };
    el.querySelectorAll('.sandbox-req-item').forEach((item) => {
      item.onclick = () => {
        const id = Number(item.dataset.id);
        const req = catalog.flatMap((f) => f.requests).find((r) => r.id === id);
        requestTab = 'try';
        responseTab = 'body';
        openRequest(req);
        renderCatalog();
      };
    });
  }

  /* ========================= REQUEST DETAIL / TABS ========================= */

  function openRequest(req) {
    activeRequest = req;
    const main = document.getElementById('sandbox-main');
    const doc = req.doc_json ? (typeof req.doc_json === 'string' ? JSON.parse(req.doc_json) : req.doc_json) : null;

    main.innerHTML = `
      <div class="sandbox-request-header">
        <div class="sandbox-request-title-row">
          <span class="method-chip method-${req.method}">${req.method}</span>
          <h3>${Render.escapeHtml(req.name)}</h3>
        </div>
        <div class="sandbox-request-path">${Render.escapeHtml(substitute(req.path))}</div>
        ${doc && doc.summary ? `<p class="sandbox-request-summary">${Render.escapeHtml(doc.summary)}</p>` : req.description ? `<p class="sandbox-request-summary">${Render.escapeHtml(req.description)}</p>` : ''}
        ${req.auth_type !== 'none' ? `<div class="sandbox-auth-note">🔒 Requires <code>Authorization: Bearer ${req.auth_type === 'bearer' ? '{{accessToken}}' : '{{mfaToken}}'}</code> — added automatically.</div>` : ''}
      </div>
      <div class="sandbox-tabs">
        <button class="sandbox-tab ${requestTab === 'try' ? 'active' : ''}" data-tab="try">Try it</button>
        <button class="sandbox-tab ${requestTab === 'docs' ? 'active' : ''}" data-tab="docs">Documentation</button>
      </div>
      <div id="sandbox-tab-panel" class="sandbox-tab-panel"></div>
    `;

    main.querySelectorAll('.sandbox-tab').forEach((btn) => {
      btn.onclick = () => { requestTab = btn.dataset.tab; openRequest(req); };
    });

    const panel = document.getElementById('sandbox-tab-panel');
    if (requestTab === 'docs') {
      panel.innerHTML = renderDocsPanel(doc);
    } else {
      panel.innerHTML = renderTryItPanel(req);
      wireTryItPanel(req);
    }
  }

  /* ------------------------------ Documentation tab ------------------------------ */

  function renderDocsPanel(doc) {
    if (!doc) {
      return `<p style="color:var(--ink3);font-style:italic;">No structured documentation on file for this endpoint yet.</p>`;
    }
    const params = doc.parameters || [];
    const bodyFields = doc.requestBody && doc.requestBody.fields ? doc.requestBody.fields : [];
    const responses = doc.responses || [];

    return `
      ${params.length ? `
        <div class="doc-section">
          <h4>Parameters</h4>
          <table class="doc-table">
            <thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead>
            <tbody>
              ${params.map((p) => `
                <tr>
                  <td><code>${Render.escapeHtml(p.name)}</code>${p.in ? `<span class="doc-param-in">${Render.escapeHtml(p.in)}</span>` : ''}</td>
                  <td>${Render.escapeHtml(p.type || 'string')}</td>
                  <td>${p.required ? '<span class="doc-required">required</span>' : '<span class="doc-optional">optional</span>'}</td>
                  <td>${Render.escapeHtml(p.description || '')}</td>
                </tr>`).join('')}
            </tbody>
          </table>
        </div>` : ''}

      ${bodyFields.length ? `
        <div class="doc-section">
          <h4>Request body</h4>
          <table class="doc-table">
            <thead><tr><th>Field</th><th>Type</th><th>Required</th><th>Description</th></tr></thead>
            <tbody>
              ${bodyFields.map((f) => `
                <tr>
                  <td><code>${Render.escapeHtml(f.name)}</code></td>
                  <td>${Render.escapeHtml(f.type || 'string')}</td>
                  <td>${f.required ? '<span class="doc-required">required</span>' : '<span class="doc-optional">optional</span>'}</td>
                  <td>${Render.escapeHtml(f.description || '')}</td>
                </tr>`).join('')}
            </tbody>
          </table>
        </div>` : ''}

      ${responses.length ? `
        <div class="doc-section">
          <h4>Responses</h4>
          ${responses.map((r) => `
            <div class="doc-response-block">
              <div class="doc-response-header">
                <span class="status-pill ${statusClass(r.status)}">${r.status}</span>
                <span>${Render.escapeHtml(r.description || '')}</span>
              </div>
              ${r.example !== undefined ? `<pre class="doc-example">${highlightJson(r.example)}</pre>` : ''}
            </div>`).join('')}
        </div>` : ''}

      ${!params.length && !bodyFields.length && !responses.length ? `<p style="color:var(--ink3);font-style:italic;">This endpoint takes no parameters or body.</p>` : ''}
    `;
  }

  function statusClass(status) {
    return status >= 500 ? 'status-5xx' : status >= 400 ? 'status-4xx' : 'status-2xx';
  }

  function highlightJson(value) {
    const text = typeof value === 'string' ? value : JSON.stringify(value, null, 2);
    try {
      return hljs.highlight(text, { language: 'json' }).value;
    } catch {
      return Render.escapeHtml(text);
    }
  }

  /* ------------------------------ Try it tab ------------------------------ */

  function renderTryItPanel(req) {
    const headers = JSON.parse(req.default_headers_json || '{}');
    const query = JSON.parse(req.default_query_json || '{}');
    const body = JSON.parse(req.default_body_json || 'null');

    return `
      <div class="sandbox-field-group">
        <div class="sandbox-field-group-header"><label>Query parameters</label></div>
        <textarea id="req-query" class="json-editor" rows="2">${Render.escapeHtml(JSON.stringify(query, null, 2))}</textarea>
        <div class="field-hint">JSON object — sent as ?key=value pairs.</div>
      </div>
      <div class="sandbox-field-group">
        <div class="sandbox-field-group-header"><label>Headers (extra — auth header is automatic)</label></div>
        <textarea id="req-headers" class="json-editor" rows="2">${Render.escapeHtml(JSON.stringify(headers, null, 2))}</textarea>
      </div>
      ${body !== null ? `
        <div class="sandbox-field-group">
          <div class="sandbox-field-group-header"><label>Body</label></div>
          <textarea id="req-body" class="json-editor" rows="9">${Render.escapeHtml(JSON.stringify(body, null, 2))}</textarea>
        </div>` : ''}
      ${req.has_file_upload ? `
        <div class="sandbox-field-group">
          <div class="sandbox-field-group-header"><label>File</label></div>
          <input type="file" id="req-file">
        </div>` : ''}

      <div class="sandbox-send-row">
        <button class="btn" id="send-btn">Send</button>
        <button class="btn secondary copy-curl-btn" id="copy-curl-btn">Copy as cURL</button>
      </div>
      <div id="response-area" class="response-panel"></div>
    `;
  }

  function wireTryItPanel(req) {
    document.getElementById('send-btn').onclick = () => sendActiveRequest();
    document.getElementById('copy-curl-btn').onclick = () => copyAsCurl(req);
    ['req-query', 'req-headers', 'req-body'].forEach((id) => {
      const el = document.getElementById(id);
      if (!el) return;
      el.oninput = () => {
        try { JSON.parse(el.value || 'null'); el.classList.remove('invalid'); }
        catch { el.classList.add('invalid'); }
      };
    });
  }

  function readEditorState() {
    const query = JSON.parse(document.getElementById('req-query').value || '{}');
    const headers = JSON.parse(document.getElementById('req-headers').value || '{}');
    const bodyEl = document.getElementById('req-body');
    const body = bodyEl ? JSON.parse(bodyEl.value || 'null') : null;
    return { query, headers, body };
  }

  /* ------------------------------ Send ------------------------------ */

  async function sendActiveRequest() {
    const req = activeRequest;
    if (!req) return;
    if (!apiKey) { toastInline('Set an API key in the toolbar first.', true); return; }

    const responseArea = document.getElementById('response-area');
    responseArea.innerHTML = `<p style="color:var(--ink3)">Sending…</p>`;

    let query, headers, body;
    try {
      ({ query, headers, body } = readEditorState());
    } catch (e) {
      responseArea.innerHTML = `<div class="alert error">Query/Headers/Body must be valid JSON: ${Render.escapeHtml(e.message)}</div>`;
      return;
    }

    if (req.auth_type === 'bearer') headers['Authorization'] = 'Bearer {{accessToken}}';
    if (req.auth_type === 'mfa_token') headers['Authorization'] = 'Bearer {{mfaToken}}';

    const fileInput = document.getElementById('req-file');
    const file = fileInput && fileInput.files[0] ? fileInput.files[0] : null;

    const meta = {
      environmentId: currentEnvironmentId,
      method: req.method,
      path: substitute(req.path),
      headers: substituteObj(headers),
      query: substituteObj(query),
      body: body ? substituteObj(body) : null,
      sandboxRequestId: req.id,
    };

    const form = new FormData();
    form.append('meta', JSON.stringify(meta));
    if (file) form.append('file', file);

    const startedAt = performance.now();
    try {
      const res = await fetch('/api/sandbox/execute', {
        method: 'POST',
        headers: {
          ...(Api.getAccessToken() ? { Authorization: `Bearer ${Api.getAccessToken()}` } : {}),
          'X-Api-Key': apiKey,
        },
        body: form,
      });
      const json = await res.json();
      const elapsed = Math.round(performance.now() - startedAt);

      if (!json.success) {
        if (res.status === 401) updateKeyStatus('bad');
        responseArea.innerHTML = `<div class="alert error">${Render.escapeHtml(json.message)}</div>`;
        return;
      }
      updateKeyStatus('ok');
      renderResponse(json.data, elapsed);
      pushHistory({ req, meta, result: json.data, elapsedMs: elapsed });
    } catch (err) {
      responseArea.innerHTML = `<div class="alert error">${Render.escapeHtml(err.message)}</div>`;
    }
  }

  const AUTO_SAVE_FIELDS = ['accessToken', 'refreshToken', 'mfaToken'];

  function renderResponse(result, elapsedMs) {
    const responseArea = document.getElementById('response-area');
    const cls = statusClass(result.status || 0);
    const sizeBytes = new Blob([JSON.stringify(result.body)]).size;

    const flatData = result.body && result.body.data ? result.body.data : result.body;
    const autoSaved = [];
    if (flatData && typeof flatData === 'object') {
      for (const field of AUTO_SAVE_FIELDS) {
        if (typeof flatData[field] === 'string') { saveVariable(field, flatData[field]); autoSaved.push(field); }
      }
    }

    responseArea.innerHTML = `
      <div class="response-meta-row">
        <span class="status-pill ${cls}">${result.status || 'ERR'}</span>
        <span class="meta-item">${elapsedMs} ms</span>
        <span class="meta-item">${(sizeBytes / 1024).toFixed(sizeBytes > 1024 ? 1 : 0)} ${sizeBytes > 1024 ? 'KB' : 'B'}</span>
        ${autoSaved.length ? `<span class="meta-item" style="color:var(--ok);">Saved: ${autoSaved.join(', ')}</span>` : ''}
      </div>
      <div class="response-tabs">
        <button class="response-tab ${responseTab === 'body' ? 'active' : ''}" data-rtab="body">Body</button>
        <button class="response-tab ${responseTab === 'headers' ? 'active' : ''}" data-rtab="headers">Headers</button>
      </div>
      <div id="response-tab-body"></div>
      ${renderQuickSaveButtons(flatData)}
    `;

    renderResponseTabContent(result);
    responseArea.querySelectorAll('.response-tab').forEach((btn) => {
      btn.onclick = () => { responseTab = btn.dataset.rtab; renderResponseTabContent(result); responseArea.querySelectorAll('.response-tab').forEach((b) => b.classList.toggle('active', b === btn)); };
    });

    renderRightPanel();
  }

  function renderResponseTabContent(result) {
    const el = document.getElementById('response-tab-body');
    if (!el) return;
    if (responseTab === 'headers') {
      const headers = result.headers || {};
      el.innerHTML = `<table class="response-headers-table">${Object.entries(headers).map(([k, v]) => `<tr><td>${Render.escapeHtml(k)}</td><td>${Render.escapeHtml(v)}</td></tr>`).join('')}</table>`;
    } else {
      el.innerHTML = `<pre class="response-box"><code class="hljs language-json">${highlightJson(result.body)}</code></pre>`;
    }
  }

  function renderQuickSaveButtons(flatData) {
    if (!flatData || typeof flatData !== 'object') return '';
    const candidates = Object.entries(flatData).filter(([k, v]) => (typeof v === 'string' || typeof v === 'number') && !AUTO_SAVE_FIELDS.includes(k));
    if (!candidates.length) return '';
    return `<div class="quick-save-row">
      <div style="font-size:11.5px;color:var(--ink3);margin-bottom:6px;">Save a field as a variable:</div>
      ${candidates.map(([k, v]) => `<button class="btn secondary quick-save-btn quick-save" data-key="${Render.escapeHtml(k)}" data-value="${Render.escapeHtml(String(v))}">${Render.escapeHtml(k)} → {{${Render.escapeHtml(k)}}}</button>`).join('')}
    </div>`;
  }

  document.addEventListener('click', (e) => {
    const btn = e.target.closest('.quick-save');
    if (!btn) return;
    saveVariable(btn.dataset.key, btn.dataset.value);
    renderRightPanel();
    toastInline(`Saved {{${btn.dataset.key}}}`);
  });

  /* ------------------------------ Copy as cURL ------------------------------ */

  function copyAsCurl(req) {
    let query, headers, body;
    try {
      ({ query, headers, body } = readEditorState());
    } catch {
      toastInline('Fix the invalid JSON before copying.', true);
      return;
    }
    if (req.auth_type === 'bearer') headers['Authorization'] = 'Bearer {{accessToken}}';
    if (req.auth_type === 'mfa_token') headers['Authorization'] = 'Bearer {{mfaToken}}';

    const env = currentEnvironment();
    const base = env ? env.base_url.replace(/\/$/, '') : '';
    const resolvedPath = substitute(req.path);
    const resolvedQuery = substituteObj(query);
    const qs = Object.keys(resolvedQuery).length ? '?' + new URLSearchParams(resolvedQuery).toString() : '';
    const url = `${base}${resolvedPath}${qs}`;

    let cmd = `curl -X ${req.method} '${url}'`;
    for (const [k, v] of Object.entries(substituteObj(headers))) {
      cmd += ` \\\n  -H '${k}: ${v}'`;
    }
    if (req.has_file_upload) {
      cmd += ` \\\n  -F 'file=@/path/to/your/file'`;
      for (const [k, v] of Object.entries(substituteObj(body) || {})) {
        cmd += ` \\\n  -F '${k}=${v}'`;
      }
    } else if (body) {
      cmd += ` \\\n  -H 'Content-Type: application/json' \\\n  -d '${JSON.stringify(substituteObj(body))}'`;
    }

    navigator.clipboard.writeText(cmd).then(
      () => toastInline('cURL command copied — targets the real environment directly, not this portal\'s proxy.'),
      () => toastInline('Could not copy — clipboard access was blocked.', true)
    );
  }

  /* =============================== RIGHT PANEL =============================== */

  function renderRightPanel() {
    const el = document.getElementById('sandbox-vars');
    if (!el) return;
    el.innerHTML = `
      <div class="tag-tabs" style="margin-bottom:14px;">
        <button class="tag-tab ${rightPanelTab === 'vars' ? 'active' : ''}" data-rp="vars" style="font-size:11px;padding:5px 10px;">Variables</button>
        <button class="tag-tab ${rightPanelTab === 'history' ? 'active' : ''}" data-rp="history" style="font-size:11px;padding:5px 10px;">History</button>
      </div>
      <div id="right-panel-body"></div>
    `;
    el.querySelectorAll('[data-rp]').forEach((btn) => {
      btn.onclick = () => { rightPanelTab = btn.dataset.rp; renderRightPanel(); };
    });
    if (rightPanelTab === 'history') renderHistoryPanel(); else renderVarsPanel();
  }

  function renderVarsPanel() {
    const body = document.getElementById('right-panel-body');
    const entries = Object.entries(vars);
    body.innerHTML = `
      <p class="hint">Use <code>{{name}}</code> in any field. accessToken / refreshToken / mfaToken auto-fill after a successful call.</p>
      <div id="var-rows">${entries.map(([k, v]) => varRowHtml(k, v)).join('')}</div>
      <button class="btn secondary" id="add-var-btn" style="margin-top:8px;font-size:11.5px;">+ Add variable</button>`;
    wireVarRows();
    document.getElementById('add-var-btn').onclick = () => {
      document.getElementById('var-rows').insertAdjacentHTML('beforeend', varRowHtml('', ''));
      wireVarRows();
    };
  }

  function varRowHtml(key, value) {
    return `<div class="var-row">
      <input class="var-key" placeholder="key" value="${Render.escapeHtml(key)}">
      <input class="var-value" placeholder="value" value="${Render.escapeHtml(value ?? '')}">
      <button class="var-remove" title="Remove">×</button>
    </div>`;
  }

  function wireVarRows() {
    document.querySelectorAll('#var-rows .var-row').forEach((row) => {
      const keyInput = row.querySelector('.var-key');
      const valInput = row.querySelector('.var-value');
      const commit = () => { if (keyInput.value.trim()) saveVariable(keyInput.value.trim(), valInput.value); };
      keyInput.onblur = commit;
      valInput.onblur = commit;
      row.querySelector('.var-remove').onclick = async () => {
        if (keyInput.value.trim()) { delete vars[keyInput.value.trim()]; await saveVariable(keyInput.value.trim(), null); }
        row.remove();
      };
    });
  }

  /* ------------------------------ History (client-side only) ------------------------------
   * Stored in this browser's localStorage — never sent to or persisted
   * by the server. The server already keeps its own record of sandbox
   * activity for admins (sandbox_request_logs: who, when, method, path,
   * status, duration — see Admin -> Sandbox Usage), but deliberately
   * does NOT store full request/response bodies there, since those can
   * contain tokens and member data. This is purely a per-developer,
   * per-browser convenience. */

  function loadHistory() {
    try { return JSON.parse(localStorage.getItem(HISTORY_KEY) || '[]'); } catch { return []; }
  }

  function pushHistory({ req, meta, result, elapsedMs }) {
    const history = loadHistory();
    history.unshift({
      id: `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
      name: req.name,
      method: meta.method,
      path: meta.path,
      status: result.status,
      elapsedMs,
      timestamp: new Date().toISOString(),
      requestSnapshot: meta,
      responseSnapshot: result,
    });
    localStorage.setItem(HISTORY_KEY, JSON.stringify(history.slice(0, HISTORY_LIMIT)));
  }

  function renderHistoryPanel() {
    const body = document.getElementById('right-panel-body');
    const history = loadHistory();
    body.innerHTML = `
      <p class="hint">Kept only in this browser — never uploaded. Admins can see usage counts (not bodies) under Admin → Sandbox Usage.</p>
      ${history.length === 0 ? '<p style="color:var(--ink3);font-size:12px;font-style:italic;">No requests sent yet this session.</p>' : ''}
      <div class="history-list">
        ${history.map((h) => `
          <div class="history-item" data-id="${h.id}">
            <div class="hist-top">
              <span class="method-chip method-${h.method}" style="font-size:9px;min-width:38px;">${h.method}</span>
              <span class="status-pill ${statusClass(h.status || 0)}" style="font-size:9.5px;padding:1px 6px;">${h.status || 'ERR'}</span>
              <span class="hist-time">${new Date(h.timestamp).toLocaleTimeString()}</span>
            </div>
            <div class="hist-path">${Render.escapeHtml(h.path)}</div>
          </div>`).join('')}
      </div>
      ${history.length ? `<button class="btn secondary" id="clear-history-btn" style="margin-top:10px;font-size:11px;">Clear history</button>` : ''}
    `;

    body.querySelectorAll('.history-item').forEach((item) => {
      item.onclick = () => replayFromHistory(history.find((h) => h.id === item.dataset.id));
    });
    const clearBtn = document.getElementById('clear-history-btn');
    if (clearBtn) clearBtn.onclick = () => { localStorage.removeItem(HISTORY_KEY); renderHistoryPanel(); };
  }

  function replayFromHistory(entry) {
    if (!entry) return;
    const req = catalog.flatMap((f) => f.requests).find((r) => r.id === entry.requestSnapshot.sandboxRequestId);
    if (req) {
      requestTab = 'try';
      openRequest(req);
      // Re-populate the editors with exactly what was sent last time.
      const queryEl = document.getElementById('req-query');
      const headersEl = document.getElementById('req-headers');
      const bodyEl = document.getElementById('req-body');
      if (queryEl) queryEl.value = JSON.stringify(entry.requestSnapshot.query || {}, null, 2);
      if (headersEl) headersEl.value = JSON.stringify(entry.requestSnapshot.headers || {}, null, 2);
      if (bodyEl && entry.requestSnapshot.body) bodyEl.value = JSON.stringify(entry.requestSnapshot.body, null, 2);
      renderResponse(entry.responseSnapshot, entry.elapsedMs);
      renderCatalog();
    } else {
      // The catalog request no longer exists (e.g. catalog was re-imported) — show the raw response anyway.
      const main = document.getElementById('sandbox-main');
      main.innerHTML = `
        <div style="padding:22px;">
          <h3 style="margin-top:0;">${Render.escapeHtml(entry.method)} ${Render.escapeHtml(entry.path)}</h3>
          <p style="color:var(--ink3);font-size:12.5px;">This endpoint is no longer in the current catalog — showing the saved response only.</p>
          <div id="response-area" class="response-panel"></div>
        </div>`;
      renderResponse(entry.responseSnapshot, entry.elapsedMs);
    }
  }

  return { render };
})();
