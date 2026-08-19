/**
 * js/render.js — markdown -> HTML (marked.js), diagrams (mermaid),
 * syntax highlighting (highlight.js), and the "on this page" TOC
 * builder. Shared by any view that needs to show a .md page.
 */
const Render = (() => {
  marked.setOptions({
    highlight: (code, lang) => {
      if (lang && hljs.getLanguage(lang)) {
        try { return hljs.highlight(code, { language: lang }).value; } catch { /* fall through */ }
      }
      return hljs.highlightAuto(code).value;
    },
  });

  let mermaidInitialised = false;
  function ensureMermaid() {
    if (mermaidInitialised) return;
    mermaid.initialize({ startOnLoad: false, theme: 'neutral', securityLevel: 'strict' });
    mermaidInitialised = true;
  }

  /** Renders markdown into `container`, then post-processes mermaid code blocks + headings for TOC. */
  async function renderMarkdown(markdown, container) {
    // Pull out ```mermaid blocks before marked touches them, render separately.
    const mermaidBlocks = [];
    const withoutMermaid = markdown.replace(/```mermaid\n([\s\S]*?)```/g, (_, code) => {
      const token = `@@MERMAID_${mermaidBlocks.length}@@`;
      mermaidBlocks.push(code);
      return `<div class="mermaid-placeholder" data-index="${mermaidBlocks.length - 1}"></div>\n\n${token}`;
    });

    let html = marked.parse(withoutMermaid);
    // Remove the stray token paragraphs marked.js wraps around our placeholder markers.
    html = html.replace(/<p>@@MERMAID_\d+@@<\/p>/g, '');

    container.innerHTML = html;
    container.classList.add('markdown-body');

    // Render each mermaid block into its placeholder.
    if (mermaidBlocks.length) {
      ensureMermaid();
      const placeholders = container.querySelectorAll('.mermaid-placeholder');
      for (const el of placeholders) {
        const idx = Number(el.dataset.index);
        const id = `mermaid-${Date.now()}-${idx}`;
        try {
          const { svg } = await mermaid.render(id, mermaidBlocks[idx]);
          const wrap = document.createElement('div');
          wrap.className = 'mermaid';
          wrap.innerHTML = svg;
          el.replaceWith(wrap);
        } catch (err) {
          el.outerHTML = `<pre class="mermaid-error">Diagram failed to render: ${err.message}</pre>`;
        }
      }
    }

    return buildToc(container);
  }

  /** Adds ids to h2/h3 and returns [{ id, text, level }] for a right-hand TOC. */
  function buildToc(container) {
    const headings = container.querySelectorAll('h2, h3');
    const toc = [];
    headings.forEach((h, i) => {
      const id = h.id || `sec-${i}-${h.textContent.trim().toLowerCase().replace(/[^a-z0-9]+/g, '-').slice(0, 60)}`;
      h.id = id;
      toc.push({ id, text: h.textContent, level: h.tagName === 'H2' ? 2 : 3 });
    });
    return toc;
  }

  function escapeHtml(str) {
    return String(str).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  }

  return { renderMarkdown, escapeHtml };
})();
