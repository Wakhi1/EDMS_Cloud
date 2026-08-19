/**
 * services/content.service.js
 * Auto-discovery markdown engine. This is THE mechanism behind "drop a
 * new .md file in and it just becomes a page" — there is no database
 * table of pages, no build step, and no manual registration anywhere.
 * Every request that needs the nav tree or a page's content re-walks
 * (a lightly cached view of) the content directory from disk.
 *
 * Filesystem convention:
 *   content/
 *     00-welcome.md                        <- top-level page
 *     01-knowledge-base/                   <- a section (folder)
 *       01-create-and-save-a-document.md   <- a page within it
 *       02-search-and-retrieve-a-document.md
 *       nested-folder/                     <- sections can nest arbitrarily
 *         01-sub-page.md
 *
 * - Leading "NN-" numeric prefixes control sort order and are stripped
 *   from the display title (falls back to alphabetical if absent).
 * - Each file's frontmatter (YAML between --- markers) can override
 *   title/description/category/order explicitly; anything not in
 *   frontmatter falls back to filename-derived values, so a page with
 *   NO frontmatter at all still works — genuinely zero-config.
 * - `category` frontmatter (free text, e.g. "Knowledge Base", "UAT",
 *   "Testing", "Architecture", "Support") is surfaced to the frontend
 *   as a filter facet; it does not have to match the folder name.
 */
const fs = require('fs');
const path = require('path');
const matter = require('gray-matter');

const CONTENT_DIR = path.resolve(process.env.CONTENT_DIR || './content');

function stripOrderPrefix(name) {
  return name.replace(/^\d+[-_.]?\s*/, '');
}

function titleCase(slugLike) {
  return stripOrderPrefix(slugLike)
    .replace(/\.md$/i, '')
    .replace(/[-_]+/g, ' ')
    .replace(/\b\w/g, (ch) => ch.toUpperCase());
}

function orderOf(name) {
  const match = name.match(/^(\d+)/);
  return match ? Number(match[1]) : 999;
}

function slugFor(relPath) {
  return relPath
    .split(path.sep)
    .map((seg) => stripOrderPrefix(seg).replace(/\.md$/i, ''))
    .join('/')
    .toLowerCase()
    .replace(/\s+/g, '-');
}

/** Reads one file's frontmatter only (cheap — used when building the tree). */
function readFrontmatterOnly(absPath) {
  try {
    const raw = fs.readFileSync(absPath, 'utf8');
    const { data, content } = matter(raw);
    const firstHeading = content.match(/^#\s+(.+)$/m);
    return { data, firstHeading: firstHeading ? firstHeading[1].trim() : null };
  } catch {
    return { data: {}, firstHeading: null };
  }
}

/**
 * Recursively walks CONTENT_DIR and returns a nav tree:
 *   { type: 'section', title, slug, order, children: [...] }
 *   { type: 'page', title, slug, order, category, description, updatedAt }
 */
function buildTree(dirAbsPath = CONTENT_DIR, relPath = '') {
  const entries = fs.readdirSync(dirAbsPath, { withFileTypes: true });

  const nodes = entries
    .filter((e) => (e.isDirectory() && !e.name.startsWith('.')) || (e.isFile() && e.name.toLowerCase().endsWith('.md')))
    .map((entry) => {
      const absPath = path.join(dirAbsPath, entry.name);
      const rel = path.join(relPath, entry.name);

      if (entry.isDirectory()) {
        const children = buildTree(absPath, rel);
        if (children.length === 0) return null; // skip genuinely empty folders
        return {
          type: 'section',
          title: titleCase(entry.name),
          slug: slugFor(rel),
          order: orderOf(entry.name),
          children,
        };
      }

      const { data, firstHeading } = readFrontmatterOnly(absPath);
      const stat = fs.statSync(absPath);
      return {
        type: 'page',
        title: data.title || firstHeading || titleCase(entry.name),
        slug: slugFor(rel),
        order: typeof data.order === 'number' ? data.order : orderOf(entry.name),
        category: data.category || null,
        description: data.description || null,
        updatedAt: stat.mtime.toISOString(),
      };
    })
    .filter(Boolean);

  nodes.sort((a, b) => a.order - b.order || a.title.localeCompare(b.title));
  return nodes;
}

/** Maps every page slug -> absolute file path, by walking the tree once. */
function buildSlugIndex(nodes = buildTree(), acc = {}) {
  for (const node of nodes) {
    if (node.type === 'page') {
      acc[node.slug] = node;
    } else {
      buildSlugIndex(node.children, acc);
    }
  }
  return acc;
}

/** Resolves a slug (e.g. "knowledge-base/create-and-save-a-document") back to its file on disk. */
function resolveAbsPath(slug) {
  const parts = slug.split('/');
  // Walk the directory tree matching each segment against its
  // order-prefix-stripped, lowercased name — mirrors slugFor().
  let currentDir = CONTENT_DIR;
  for (let i = 0; i < parts.length; i += 1) {
    const isLast = i === parts.length - 1;
    const entries = fs.readdirSync(currentDir, { withFileTypes: true });
    const match = entries.find((e) => {
      const bareName = isLast ? e.name.replace(/\.md$/i, '') : e.name;
      return stripOrderPrefix(bareName).toLowerCase().replace(/\s+/g, '-') === parts[i] && (isLast ? e.isFile() : e.isDirectory());
    });
    if (!match) return null;
    currentDir = path.join(currentDir, match.name);
  }
  return currentDir;
}

function getPage(slug) {
  const absPath = resolveAbsPath(slug);
  if (!absPath || !fs.existsSync(absPath)) return null;

  const raw = fs.readFileSync(absPath, 'utf8');
  const { data, content } = matter(raw);
  const stat = fs.statSync(absPath);
  const firstHeading = content.match(/^#\s+(.+)$/m);

  return {
    slug,
    title: data.title || (firstHeading ? firstHeading[1].trim() : titleCase(path.basename(absPath))),
    description: data.description || null,
    category: data.category || null,
    frontmatter: data,
    markdown: content,
    updatedAt: stat.mtime.toISOString(),
  };
}

/** Naive full-text search across every page's raw markdown + frontmatter title. */
function search(query) {
  if (!query || query.trim().length < 2) return [];
  const q = query.trim().toLowerCase();
  const index = buildSlugIndex();
  const results = [];

  for (const slug of Object.keys(index)) {
    const page = getPage(slug);
    if (!page) continue;
    const haystack = `${page.title}\n${page.description || ''}\n${page.markdown}`.toLowerCase();
    const at = haystack.indexOf(q);
    if (at === -1) continue;

    const snippetStart = Math.max(0, at - 60);
    const snippet = haystack.slice(snippetStart, at + q.length + 60).replace(/\s+/g, ' ').trim();

    results.push({ slug: page.slug, title: page.title, category: page.category, snippet: `…${snippet}…` });
  }
  return results.slice(0, 30);
}

/** Resolves a folder slug (e.g. "knowledge-base") to its real relative
 * path on disk (e.g. "01-knowledge-base"), so the admin "new page" form
 * can target an EXISTING section by its display slug instead of
 * requiring the numeric-prefixed directory name. Returns null if no
 * matching folder exists yet (caller then creates one at that exact path). */
function resolveFolderPath(folderSlug) {
  if (!folderSlug) return null;
  const parts = folderSlug.split('/').filter(Boolean);
  let currentDir = CONTENT_DIR;
  for (const part of parts) {
    if (!fs.existsSync(currentDir)) return null;
    const entries = fs.readdirSync(currentDir, { withFileTypes: true });
    const match = entries.find((e) => e.isDirectory() && stripOrderPrefix(e.name).toLowerCase().replace(/\s+/g, '-') === part);
    if (!match) return null;
    currentDir = path.join(currentDir, match.name);
  }
  return path.relative(CONTENT_DIR, currentDir);
}

module.exports = { buildTree, getPage, search, resolveFolderPath, CONTENT_DIR };
