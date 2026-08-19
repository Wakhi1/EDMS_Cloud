/**
 * js/app.js — tiny hash-based router. Routes:
 *   #/                      -> redirects to the first page in the nav tree
 *   #/page/<slug...>        -> Docs.renderPage(slug)
 *   #/sandbox                -> Sandbox.render()
 *   #/admin                  -> Admin.render() (admin only)
 */
const App = (() => {
  async function route() {
    const hash = location.hash.replace(/^#/, '') || '/';
    document.getElementById('page-toc').innerHTML = '';

    if (hash === '/' || hash === '') {
      const tree = await Docs.loadTree();
      const first = Docs.flattenFirstPageSlug(tree);
      if (first) { location.hash = `#/page/${first}`; return; }
      document.getElementById('view').innerHTML = '<p>No documentation pages found yet.</p>';
      return;
    }

    if (hash.startsWith('/page/')) {
      const slug = decodeURIComponent(hash.slice('/page/'.length));
      await restoreDocsNav();
      await Docs.renderPage(slug);
      return;
    }

    if (hash === '/sandbox') {
      if (!Auth.isApprovedDeveloper()) {
        document.getElementById('view').innerHTML = `<div class="alert error">Sign in with an approved developer account to use the Sandbox. See <a href="#/page/support/getting-sandbox-access">Getting Sandbox Access</a>.</div>`;
        document.getElementById('nav-tree').innerHTML = '';
        return;
      }
      await Sandbox.render();
      return;
    }

    if (hash === '/admin') {
      if (!Auth.isAdmin()) {
        document.getElementById('view').innerHTML = `<div class="alert error">Admin access required.</div>`;
        return;
      }
      await Admin.render();
      return;
    }

    document.getElementById('view').innerHTML = '<p>Not found.</p>';
  }

  async function restoreDocsNav() {
    // Sandbox/Admin views replace #nav-tree's content; coming back to a
    // docs page should show the real tree again.
    const tree = await Docs.loadTree();
    const activeSlug = location.hash.startsWith('#/page/') ? decodeURIComponent(location.hash.slice('#/page/'.length)) : null;
    await Docs.renderSidebar(activeSlug);
  }

  function wireChrome() {
    document.querySelector('.brand').onclick = () => { location.hash = '#/'; };
    document.getElementById('hamburger').onclick = () => {
      document.getElementById('sidebar').classList.toggle('open');
      document.getElementById('sidebar-scrim').classList.toggle('hidden');
    };
    document.getElementById('sidebar-scrim').onclick = () => {
      document.getElementById('sidebar').classList.remove('open');
      document.getElementById('sidebar-scrim').classList.add('hidden');
    };
    Docs.wireSearch();
  }

  async function init() {
    wireChrome();
    await Auth.bootstrap();
    Auth.renderTopbarWidget();
    Auth.onChange(() => Auth.renderTopbarWidget());
    window.addEventListener('hashchange', route);
    await route();
  }

  return { init };
})();

document.addEventListener('DOMContentLoaded', App.init);
