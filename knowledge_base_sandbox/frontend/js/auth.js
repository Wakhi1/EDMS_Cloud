/**
 * js/auth.js — session state, login/register modals, and the top-bar
 * auth widget (sign in / user chip + sign out).
 */
const Auth = (() => {
  let currentUser = null;
  const listeners = [];

  function onChange(fn) { listeners.push(fn); }
  function notify() { listeners.forEach((fn) => fn(currentUser)); }

  async function bootstrap() {
    if (!Api.getAccessToken()) { currentUser = null; notify(); return; }
    try {
      currentUser = await Api.get('/auth/me');
    } catch {
      Api.clearTokens();
      currentUser = null;
    }
    notify();
  }

  function isAdmin() { return currentUser && currentUser.role === 'admin'; }
  function isApprovedDeveloper() { return currentUser && (currentUser.role === 'admin' || currentUser.status === 'approved'); }

  function renderTopbarWidget() {
    const el = document.getElementById('auth-actions');
    const adminWrap = document.getElementById('admin-link-wrap');
    adminWrap.classList.toggle('hidden', !isAdmin());

    if (!currentUser) {
      el.innerHTML = `<button class="ghost-btn" id="btn-login">Sign in</button><button id="btn-register">Sign up</button>`;
      document.getElementById('btn-login').onclick = () => openAuthModal('login');
      document.getElementById('btn-register').onclick = () => openAuthModal('register');
      return;
    }

    const statusNote = currentUser.role === 'developer' && currentUser.status !== 'approved'
      ? ` (${currentUser.status})` : '';

    el.innerHTML = `
      <div class="user-chip">
        <div class="who"><div class="name">${Render.escapeHtml(currentUser.full_name || currentUser.fullName)}</div>
        <div class="role">${currentUser.role}${statusNote}</div></div>
        <button class="ghost-btn" id="btn-logout">Sign out</button>
      </div>`;
    document.getElementById('btn-logout').onclick = async () => {
      try { await Api.post('/auth/logout', { refreshToken: Api.getRefreshToken() }); } catch { /* ignore */ }
      Api.clearTokens();
      currentUser = null;
      notify();
      renderTopbarWidget();
      location.hash = '#/';
    };
  }

  function openAuthModal(mode) {
    const root = document.getElementById('modal-root');
    const isRegister = mode === 'register';

    root.innerHTML = `
      <div class="modal-backdrop" id="modal-backdrop">
        <div class="modal">
          <h2>${isRegister ? 'Create a developer account' : 'Sign in'}</h2>
          <div id="modal-alert"></div>
          <form id="auth-form">
            ${isRegister ? `
              <div class="form-row"><label>Full name</label><input name="fullName" required></div>
              <div class="form-row"><label>Company / Team</label><input name="company"></div>
            ` : ''}
            <div class="form-row"><label>Email</label><input name="email" type="email" required></div>
            <div class="form-row"><label>Password</label><input name="password" type="password" required minlength="10"></div>
            ${isRegister ? `<div class="form-row"><label>What are you building / testing?</label><textarea name="reason" rows="2"></textarea></div>` : ''}
            <div class="modal-actions">
              <button type="button" class="btn secondary" id="modal-cancel">Cancel</button>
              <button type="submit" class="btn">${isRegister ? 'Create account' : 'Sign in'}</button>
            </div>
          </form>
          ${isRegister
            ? `<p style="font-size:12.5px;color:var(--ink3);margin-top:14px;">Already have an account? <a href="#" id="switch-to-login">Sign in</a></p>`
            : `<p style="font-size:12.5px;color:var(--ink3);margin-top:14px;">Need sandbox access? <a href="#" id="switch-to-register">Create a developer account</a></p>`}
        </div>
      </div>`;

    document.getElementById('modal-cancel').onclick = closeModal;
    document.getElementById('modal-backdrop').onclick = (e) => { if (e.target.id === 'modal-backdrop') closeModal(); };
    const switchLink = document.getElementById(isRegister ? 'switch-to-login' : 'switch-to-register');
    if (switchLink) switchLink.onclick = (e) => { e.preventDefault(); openAuthModal(isRegister ? 'login' : 'register'); };

    document.getElementById('auth-form').onsubmit = async (e) => {
      e.preventDefault();
      const form = new FormData(e.target);
      const alertBox = document.getElementById('modal-alert');
      alertBox.innerHTML = '';
      try {
        if (isRegister) {
          await Api.post('/auth/register', {
            fullName: form.get('fullName'), email: form.get('email'), password: form.get('password'),
            company: form.get('company'), reason: form.get('reason'),
          });
          alertBox.innerHTML = `<div class="alert ok">Account created. An administrator needs to approve it — you'll be able to sign in once they do.</div>`;
          setTimeout(closeModal, 2200);
        } else {
          const data = await Api.post('/auth/login', { email: form.get('email'), password: form.get('password') });
          Api.setTokens(data.accessToken, data.refreshToken);
          currentUser = data.user;
          notify();
          renderTopbarWidget();
          closeModal();
        }
      } catch (err) {
        alertBox.innerHTML = `<div class="alert error">${Render.escapeHtml(err.message)}</div>`;
      }
    };
  }

  function closeModal() { document.getElementById('modal-root').innerHTML = ''; }

  return { bootstrap, onChange, renderTopbarWidget, isAdmin, isApprovedDeveloper, get user() { return currentUser; } };
})();
