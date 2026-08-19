/**
 * js/docs.js — the documentation view: builds the left nav tree from
 * GET /content/tree, renders a page's markdown, wires up the right-hand
 * TOC with scrollspy, and handles the global search box.
 */
const Docs = (() => {
  let tree = null;

  async function loadTree() {
    if (!tree) tree = await Api.get('/content/tree');
    return tree;
  }

  function flattenFirstPageSlug(nodes) {
    for (const n of nodes) {
      if (n.type === 'page') return n.slug;
      const found = flattenFirstPageSlug(n.children);
      if (found) return found;
    }
    return null;
  }

  async function renderSidebar(activeSlug) {
    const nodes = await loadTree();
    const container = document.getElementById('nav-tree');
    container.innerHTML = renderNodes(nodes, activeSlug);
    container.querySelectorAll('.nav-item').forEach((el) => {
      el.onclick = (e) => {
        e.preventDefault();
        location.hash = `#/page/${el.dataset.slug}`;
        document.getElementById('sidebar').classList.remove('open');
        document.getElementById('sidebar-scrim').classList.add('hidden');
      };
    });
  }

  function renderNodes(nodes, activeSlug) {
    return nodes.map((n) => {
      if (n.type === 'section') {
        return `<div class="nav-section">
          <div class="nav-section-title">${Render.escapeHtml(n.title)}</div>
          <div class="nav-children">${renderNodes(n.children, activeSlug)}</div>
        </div>`;
      }
      const active = n.slug === activeSlug ? 'active' : '';
      return `<a href="#/page/${n.slug}" class="nav-item ${active}" data-slug="${n.slug}">${Render.escapeHtml(n.title)}</a>`;
    }).join('');
  }

  async function renderPage(slug) {
    const view = document.getElementById('view');
    view.innerHTML = '<p style="color:var(--ink3)">Loading…</p>';

    let page;
    try {
      page = await Api.get(`/content/page/${slug}`);
    } catch (err) {
      view.innerHTML = `<div class="alert error">Page not found: ${Render.escapeHtml(slug)}</div>`;
      document.getElementById('page-toc').innerHTML = '';
      return;
    }

    view.innerHTML = `
      <div class="page-meta">${page.category ? Render.escapeHtml(page.category) + ' · ' : ''}Updated ${new Date(page.updatedAt).toLocaleDateString()}</div>
      <div id="page-body"></div>`;
    const body = document.getElementById('page-body');
    const toc = await Render.renderMarkdown(page.markdown, body);

    renderToc(toc);
    await renderSidebar(slug);
    document.title = `${page.title} — PSPF EDMS Docs`;
  }

  function renderToc(toc) {
    const el = document.getElementById('page-toc');
    if (!toc.length) { el.innerHTML = ''; return; }
    el.innerHTML = `<div class="toc-title">On this page</div>` +
      toc.map((t) => `<a href="#${t.id}" class="toc-link lvl-${t.level}" data-id="${t.id}">${Render.escapeHtml(t.text)}</a>`).join('');

    el.querySelectorAll('a').forEach((a) => {
      a.onclick = (e) => {
        e.preventDefault();
        document.getElementById(a.dataset.id).scrollIntoView({ behavior: 'smooth', block: 'start' });
      };
    });

    // Scrollspy
    const links = [...el.querySelectorAll('a')];
    window.onscroll = () => {
      let currentId = null;
      for (const link of links) {
        const heading = document.getElementById(link.dataset.id);
        if (heading && heading.getBoundingClientRect().top < 120) currentId = link.dataset.id;
      }
      links.forEach((l) => l.classList.toggle('active', l.dataset.id === currentId));
    };
  }

  function wireSearch() {
    const input = document.getElementById('global-search');
    const resultsBox = document.getElementById('search-results');
    let debounceTimer = null;

    input.addEventListener('input', () => {
      clearTimeout(debounceTimer);
      const q = input.value.trim();
      if (q.length < 2) { resultsBox.classList.add('hidden'); return; }
      debounceTimer = setTimeout(async () => {
        const results = await Api.get(`/content/search?q=${encodeURIComponent(q)}`);
        if (!results.length) {
          resultsBox.innerHTML = `<div style="padding:14px;color:var(--ink3);font-size:13px;">No matches.</div>`;
        } else {
          resultsBox.innerHTML = results.map((r) => `
            <a href="#/page/${r.slug}">
              <div class="sr-title">${Render.escapeHtml(r.title)}</div>
              <div class="sr-snippet">${Render.escapeHtml(r.snippet)}</div>
            </a>`).join('');
        }
        resultsBox.classList.remove('hidden');
      }, 220);
    });

    document.addEventListener('click', (e) => {
      if (!resultsBox.contains(e.target) && e.target !== input) resultsBox.classList.add('hidden');
    });
  }

  return { loadTree, renderSidebar, renderPage, flattenFirstPageSlug, wireSearch };
})();
