/**
 * js/admin.js — the admin panel: developer approvals + API key
 * issuance, media library uploads, page authoring, sandbox usage, and
 * the portal's own audit log. Every view here assumes Auth.isAdmin()
 * is already true (App.js gates the /admin route).
 */
const Admin = (() => {
  const TABS = ['developers', 'environments', 'media', 'pages', 'usage', 'audit'];
  let activeTab = 'developers';

  async function render() {
    document.getElementById('nav-tree').innerHTML = '<div class="nav-loading">Admin mode — docs nav hidden</div>';
    document.getElementById('page-toc').innerHTML = '';
    const view = document.getElementById('view');

    view.innerHTML = `
      <h1>Admin</h1>
      <div class="tag-tabs">
        ${TABS.map((t) => `<button class="tag-tab ${t === activeTab ? 'active' : ''}" data-tab="${t}">${label(t)}</button>`).join('')}
      </div>
      <div id="admin-tab-body"></div>`;

    view.querySelectorAll('.tag-tab').forEach((btn) => {
      btn.onclick = () => { activeTab = btn.dataset.tab; render(); };
    });

    const body = document.getElementById('admin-tab-body');
    if (activeTab === 'developers') return renderDevelopers(body);
    if (activeTab === 'environments') return renderEnvironments(body);
    if (activeTab === 'media') return renderMedia(body);
    if (activeTab === 'pages') return renderPages(body);
    if (activeTab === 'usage') return renderUsage(body);
    if (activeTab === 'audit') return renderAudit(body);
  }

  function label(t) {
    return { developers: 'Developers', environments: 'Environments', media: 'Media Library', pages: 'Pages', usage: 'Sandbox Usage', audit: 'Audit Log' }[t];
  }

  /* ---------------- Developers ---------------- */
  async function renderDevelopers(body) {
    body.innerHTML = '<p style="color:var(--ink3)">Loading…</p>';
    const developers = await Api.get('/admin/developers');
    body.innerHTML = `
      <table class="table">
        <thead><tr><th>Name</th><th>Email</th><th>Company</th><th>Status</th><th>Active keys</th><th>Requested</th><th></th></tr></thead>
        <tbody>
          ${developers.map((d) => `
            <tr>
              <td>${Render.escapeHtml(d.full_name)}</td>
              <td>${Render.escapeHtml(d.email)}</td>
              <td>${Render.escapeHtml(d.company || '—')}</td>
              <td><span class="badge ${d.status}">${d.status}</span></td>
              <td>${d.active_keys}</td>
              <td>${new Date(d.created_at).toLocaleDateString()}</td>
              <td class="dev-actions" data-id="${d.id}" data-status="${d.status}"></td>
            </tr>`).join('')}
        </tbody>
      </table>
      ${developers.length === 0 ? '<div class="empty-state">No developer registrations yet.</div>' : ''}
    `;

    body.querySelectorAll('.dev-actions').forEach((cell) => {
      const id = cell.dataset.id;
      const status = cell.dataset.status;
      const actions = [];
      if (status === 'pending') {
        actions.push(`<button class="btn secondary" data-act="approve" data-id="${id}">Approve</button>`);
        actions.push(`<button class="btn danger" data-act="reject" data-id="${id}">Reject</button>`);
      }
      if (status === 'approved') {
        actions.push(`<button class="btn secondary" data-act="issue-key" data-id="${id}">Issue API key</button>`);
        actions.push(`<button class="btn danger" data-act="suspend" data-id="${id}">Suspend</button>`);
      }
      cell.innerHTML = actions.join(' ');
    });

    body.querySelectorAll('[data-act]').forEach((btn) => {
      btn.onclick = () => handleDeveloperAction(btn.dataset.act, btn.dataset.id);
    });
  }

  async function handleDeveloperAction(act, id) {
    try {
      if (act === 'approve') { await Api.put(`/admin/developers/${id}/approve`, {}); return render(); }
      if (act === 'reject') { await Api.put(`/admin/developers/${id}/reject`, {}); return render(); }
      if (act === 'suspend') { await Api.put(`/admin/developers/${id}/suspend`, {}); return render(); }
      if (act === 'issue-key') {
        const label = prompt('Label for this key (e.g. "Laptop", "CI pipeline"):', 'Sandbox key') || 'Sandbox key';
        const result = await Api.post(`/admin/developers/${id}/api-keys`, { label });
        showApiKeyModal(result);
        return render();
      }
    } catch (err) {
      alert(err.message);
    }
  }

  /** Shown right after issuing a key — the key itself, plus whether it was also emailed. */
  function showApiKeyModal(result) {
    const root = document.getElementById('modal-root');
    root.innerHTML = `
      <div class="modal-backdrop" id="key-modal-backdrop">
        <div class="modal">
          <h2>API key issued</h2>
          ${result.emailSent
            ? `<div class="alert ok">Emailed to <strong>${Render.escapeHtml(result.email)}</strong>.</div>`
            : `<div class="alert error">Could not email this key${result.emailError ? `: ${Render.escapeHtml(result.emailError)}` : ''}. Copy it below and send it to <strong>${Render.escapeHtml(result.email)}</strong> yourself.</div>`}
          <p style="font-size:12.5px;color:var(--ink3);">Shown only once — it cannot be retrieved again after you close this.</p>
          <div style="display:flex;gap:8px;align-items:center;margin:14px 0;">
            <input id="issued-key-field" readonly value="${Render.escapeHtml(result.apiKey)}" style="flex:1;font-family:monospace;font-size:12.5px;padding:8px;">
            <button class="btn secondary" id="copy-key-btn">Copy</button>
          </div>
          <div class="modal-actions">
            <button class="btn" id="key-modal-close">Done</button>
          </div>
        </div>
      </div>`;

    document.getElementById('copy-key-btn').onclick = () => {
      const field = document.getElementById('issued-key-field');
      field.select();
      navigator.clipboard.writeText(field.value).catch(() => document.execCommand('copy'));
    };
    const close = () => { root.innerHTML = ''; };
    document.getElementById('key-modal-close').onclick = close;
    document.getElementById('key-modal-backdrop').onclick = (e) => { if (e.target.id === 'key-modal-backdrop') close(); };
  }

  /* ---------------- Environments ---------------- */
  async function renderEnvironments(body) {
    body.innerHTML = '<p style="color:var(--ink3)">Loading…</p>';
    const envs = await Api.get('/admin/sandbox-environments');
    body.innerHTML = `
      <p style="font-size:12.5px;color:var(--ink3);max-width:640px;">
        These are the only hosts the Sandbox is allowed to send requests to — a developer
        picks one from a dropdown, they can never type a custom URL. Add one per real
        deployment (staging, production, a colleague's local machine) as you stand them up;
        "localhost" only ever makes sense for whoever is running this docs portal itself.
        See <a href="#/page/architecture/solution-architecture">Solution Architecture</a> for why.
      </p>
      <div class="card">
        <h3>Add environment</h3>
        <div class="form-row"><label>Name</label><input id="env-name" placeholder="e.g. Production"></div>
        <div class="form-row"><label>Base URL (include the API version, e.g. /api/v1)</label><input id="env-base-url" placeholder="https://api.pspf.co.sz/api/v1"></div>
        <div class="form-row" style="flex-direction:row;align-items:center;gap:8px;">
          <input type="checkbox" id="env-is-default" style="width:auto;"> <label style="margin:0;">Set as default</label>
        </div>
        <button class="btn" id="add-env-btn">Add</button>
        <div id="env-add-result"></div>
      </div>
      <table class="table">
        <thead><tr><th>Name</th><th>Base URL</th><th>Default</th><th></th></tr></thead>
        <tbody>
          ${envs.map((e) => `
            <tr data-id="${e.id}">
              <td class="env-name-cell">${Render.escapeHtml(e.name)}</td>
              <td class="env-url-cell"><code>${Render.escapeHtml(e.base_url)}</code></td>
              <td>${e.is_default ? '<span class="badge approved">default</span>' : ''}</td>
              <td>
                <button class="btn secondary" data-edit="${e.id}">Edit</button>
                ${!e.is_default ? `<button class="btn secondary" data-set-default="${e.id}">Set default</button>` : ''}
                <button class="btn danger" data-del-env="${e.id}">Delete</button>
              </td>
            </tr>`).join('')}
        </tbody>
      </table>
      ${envs.length === 0 ? '<div class="empty-state">No environments configured — the Sandbox has nothing to call until you add one.</div>' : ''}
    `;

    document.getElementById('add-env-btn').onclick = async () => {
      const name = document.getElementById('env-name').value.trim();
      const baseUrl = document.getElementById('env-base-url').value.trim();
      const isDefault = document.getElementById('env-is-default').checked;
      const resultBox = document.getElementById('env-add-result');
      try {
        await Api.post('/admin/sandbox-environments', { name, baseUrl, isDefault });
        renderEnvironments(body);
      } catch (err) {
        resultBox.innerHTML = `<div class="alert error">${Render.escapeHtml(err.message)}</div>`;
      }
    };

    body.querySelectorAll('[data-set-default]').forEach((btn) => {
      btn.onclick = async () => {
        await Api.put(`/admin/sandbox-environments/${btn.dataset.setDefault}`, { isDefault: true });
        renderEnvironments(body);
      };
    });

    body.querySelectorAll('[data-del-env]').forEach((btn) => {
      btn.onclick = async () => {
        if (!confirm('Remove this environment? The Sandbox will no longer be able to call it.')) return;
        try {
          await Api.del(`/admin/sandbox-environments/${btn.dataset.delEnv}`);
          renderEnvironments(body);
        } catch (err) {
          alert(err.message);
        }
      };
    });

    body.querySelectorAll('[data-edit]').forEach((btn) => {
      btn.onclick = () => {
        const row = btn.closest('tr');
        const id = btn.dataset.edit;
        const nameCell = row.querySelector('.env-name-cell');
        const urlCell = row.querySelector('.env-url-cell');
        const currentName = nameCell.textContent;
        const currentUrl = row.querySelector('code').textContent;

        nameCell.innerHTML = `<input class="edit-name" value="${Render.escapeHtml(currentName)}" style="width:140px;">`;
        urlCell.innerHTML = `<input class="edit-url" value="${Render.escapeHtml(currentUrl)}" style="width:100%;">`;
        btn.outerHTML = `<button class="btn" data-save="${id}">Save</button> <button class="btn secondary" data-cancel-edit>Cancel</button>`;

        row.querySelector('[data-save]').onclick = async () => {
          const name = row.querySelector('.edit-name').value.trim();
          const baseUrl = row.querySelector('.edit-url').value.trim();
          try {
            await Api.put(`/admin/sandbox-environments/${id}`, { name, baseUrl });
            renderEnvironments(body);
          } catch (err) {
            alert(err.message);
          }
        };
        row.querySelector('[data-cancel-edit]').onclick = () => renderEnvironments(body);
      };
    });
  }

  /* ---------------- Media Library ---------------- */
  async function renderMedia(body) {
    body.innerHTML = '<p style="color:var(--ink3)">Loading…</p>';
    const assets = await Api.get('/media');
    body.innerHTML = `
      <div class="card">
        <h3>Upload</h3>
        <form id="media-form">
          <div class="form-row"><label>File (image, video, or document)</label><input type="file" id="media-file" required></div>
          <div class="form-row"><label>Alt text / caption</label><input id="media-alt"></div>
          <button class="btn" type="submit">Upload</button>
        </form>
      </div>
      <table class="table">
        <thead><tr><th>File</th><th>Type</th><th>Size</th><th>URL</th><th></th></tr></thead>
        <tbody>
          ${assets.map((a) => `
            <tr>
              <td>${Render.escapeHtml(a.original_name)}</td>
              <td>${a.kind}</td>
              <td>${(a.size_bytes / 1024).toFixed(0)} KB</td>
              <td><code>/api/media/file/${a.stored_name}</code></td>
              <td><button class="btn danger" data-del="${a.id}">Delete</button></td>
            </tr>`).join('')}
        </tbody>
      </table>
      ${assets.length === 0 ? '<div class="empty-state">No media uploaded yet.</div>' : ''}
    `;

    document.getElementById('media-form').onsubmit = async (e) => {
      e.preventDefault();
      const fileInput = document.getElementById('media-file');
      if (!fileInput.files[0]) return;
      const form = new FormData();
      form.append('file', fileInput.files[0]);
      form.append('altText', document.getElementById('media-alt').value);
      try {
        const res = await fetch('/api/media', { method: 'POST', headers: { Authorization: `Bearer ${Api.getAccessToken()}` }, body: form });
        const json = await res.json();
        if (!json.success) throw new Error(json.message);
        renderMedia(body);
      } catch (err) { alert(err.message); }
    };

    body.querySelectorAll('[data-del]').forEach((btn) => {
      btn.onclick = async () => {
        if (!confirm('Delete this file?')) return;
        await Api.del(`/media/${btn.dataset.del}`);
        renderMedia(body);
      };
    });
  }

  /* ---------------- Pages ---------------- */
  async function renderPages(body) {
    body.innerHTML = `
      <div class="card">
        <h3>New / replace a page</h3>
        <p style="font-size:12.5px;color:var(--ink3);">Same effect as dropping a .md file into <code>content/&lt;folder&gt;/&lt;file&gt;.md</code> on the server — appears in the nav immediately.</p>
        <div class="form-row"><label>Folder (e.g. knowledge-base, or a new name to create a section)</label><input id="page-folder" placeholder="knowledge-base"></div>
        <div class="form-row"><label>File name (e.g. 08-my-new-page.md)</label><input id="page-filename" placeholder="08-my-new-page.md"></div>
        <div class="form-row"><label>Markdown content</label><textarea id="page-markdown" rows="14" placeholder="---&#10;title: My Page&#10;description: One line.&#10;category: Knowledge Base&#10;---&#10;&#10;# My Page&#10;..."></textarea></div>
        <button class="btn" id="save-page-btn">Save page</button>
        <div id="page-save-result"></div>
      </div>`;

    document.getElementById('save-page-btn').onclick = async () => {
      const folder = document.getElementById('page-folder').value.trim();
      const fileName = document.getElementById('page-filename').value.trim();
      const markdown = document.getElementById('page-markdown').value;
      const resultBox = document.getElementById('page-save-result');
      if (!folder || !fileName || !markdown) { resultBox.innerHTML = `<div class="alert error">Folder, file name, and content are all required.</div>`; return; }
      try {
        await Api.put(`/content/page/${folder}/${fileName.replace(/\.md$/, '')}`, { markdown, folder, fileName: fileName.endsWith('.md') ? fileName : `${fileName}.md` });
        resultBox.innerHTML = `<div class="alert ok">Saved. <a href="#/page/${folder}/${fileName.replace(/\.md$/, '')}">View it</a></div>`;
      } catch (err) {
        resultBox.innerHTML = `<div class="alert error">${Render.escapeHtml(err.message)}</div>`;
      }
    };
  }

  /* ---------------- Sandbox usage ---------------- */
  async function renderUsage(body) {
    body.innerHTML = '<p style="color:var(--ink3)">Loading…</p>';
    const rows = await Api.get('/admin/sandbox-usage');
    body.innerHTML = `
      <table class="table">
        <thead><tr><th>When</th><th>Developer</th><th>Key</th><th>Method</th><th>Path</th><th>Status</th><th>ms</th></tr></thead>
        <tbody>
          ${rows.map((r) => `
            <tr>
              <td>${new Date(r.created_at).toLocaleString()}</td>
              <td>${Render.escapeHtml(r.full_name)}</td>
              <td>${Render.escapeHtml(r.key_prefix)}…</td>
              <td>${r.method}</td>
              <td><code>${Render.escapeHtml(r.path)}</code></td>
              <td>${r.status_code ?? '—'}</td>
              <td>${r.duration_ms ?? '—'}</td>
            </tr>`).join('')}
        </tbody>
      </table>
      ${rows.length === 0 ? '<div class="empty-state">No sandbox activity yet.</div>' : ''}
    `;
  }

  /* ---------------- Audit log ---------------- */
  async function renderAudit(body) {
    body.innerHTML = '<p style="color:var(--ink3)">Loading…</p>';
    const rows = await Api.get('/admin/audit-log');
    body.innerHTML = `
      <table class="table">
        <thead><tr><th>When</th><th>Actor</th><th>Action</th><th>Record</th><th>Detail</th></tr></thead>
        <tbody>
          ${rows.map((r) => `
            <tr>
              <td>${new Date(r.created_at).toLocaleString()}</td>
              <td>${Render.escapeHtml(r.actor_name || 'system')}</td>
              <td>${Render.escapeHtml(r.action)}</td>
              <td>${Render.escapeHtml(r.record_type || '')} ${Render.escapeHtml(r.record_id || '')}</td>
              <td>${Render.escapeHtml(r.detail || '')}</td>
            </tr>`).join('')}
        </tbody>
      </table>
      ${rows.length === 0 ? '<div class="empty-state">Nothing logged yet.</div>' : ''}
    `;
  }

  return { render };
})();
