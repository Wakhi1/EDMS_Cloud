/**
 * routes/content.routes.js
 * Read-only for everyone (docs are public — no login needed to browse
 * the knowledge base, matching a normal docs site); writing is
 * filesystem-based (admin uploads a .md via the upload endpoint below,
 * or an admin edits the content/ folder directly on the server — both
 * are picked up automatically, no restart needed, because
 * content.service walks the disk fresh on every request).
 */
const express = require('express');
const fs = require('fs');
const path = require('path');
const { body, validationResult } = require('express-validator');

const { ok, fail } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');
const { authenticate, requireAdmin } = require('../middleware/auth.middleware');
const { buildTree, getPage, search, resolveFolderPath, CONTENT_DIR } = require('../services/content.service');
const { logAudit } = require('../services/audit.service');

const router = express.Router();

/** GET /api/content/tree — the full nav tree, auto-built from disk. */
router.get('/tree', asyncHandler(async (req, res) => ok(res, buildTree())));

/** GET /api/content/page/:slug(*) — one page's raw markdown + frontmatter. */
router.get('/page/*', asyncHandler(async (req, res) => {
  const slug = req.params[0];
  const page = getPage(slug);
  if (!page) return fail(res, 'Page not found', 404);
  return ok(res, page);
}));

/** GET /api/content/search?q=... */
router.get('/search', asyncHandler(async (req, res) => ok(res, search(req.query.q || ''))));

/**
 * PUT /api/content/page/:slug(*)
 * Admin authoring endpoint: creates or overwrites a .md file at the
 * given slug (e.g. "knowledge-base/07-archive-a-document") — this is
 * literally the same action as an admin dragging a new file into the
 * content/ folder, just done through the UI instead of a file manager.
 * The slug's folder segments are created as needed.
 */
router.put(
  '/page/*',
  authenticate,
  requireAdmin,
  [body('markdown').isString(), body('folder').optional().isString(), body('fileName').optional().isString()],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    const slug = req.params[0]; // used only as a fallback file path if folder/fileName aren't given
    const { markdown, folder, fileName } = req.body;

    // Resolve "knowledge-base" -> the real "01-knowledge-base" on disk if
    // that section already exists, so this appends to it instead of
    // silently creating a second, duplicate "Knowledge Base" section.
    const resolvedFolder = folder ? (resolveFolderPath(folder) || folder) : folder;
    const relativePath = resolvedFolder && fileName ? path.join(resolvedFolder, fileName) : `${slug}.md`;
    const safeRelative = path.normalize(relativePath).replace(/^(\.\.[/\\])+/, ''); // no path traversal
    const absPath = path.join(CONTENT_DIR, safeRelative);

    if (!absPath.startsWith(CONTENT_DIR)) return fail(res, 'Invalid path', 400);

    fs.mkdirSync(path.dirname(absPath), { recursive: true });
    fs.writeFileSync(absPath, markdown, 'utf8');

    await logAudit({ actorUserId: req.user.id, action: 'Upload page', recordType: 'content', recordId: safeRelative, ip: req.ip });
    return ok(res, { path: safeRelative }, 'Page saved — it will appear in the nav immediately', 201);
  })
);

/** DELETE /api/content/page/:slug(*) */
router.delete('/page/*', authenticate, requireAdmin, asyncHandler(async (req, res) => {
  const slug = req.params[0];
  const page = getPage(slug);
  if (!page) return fail(res, 'Page not found', 404);

  const fsPath = path.join(CONTENT_DIR, ...slug.split('/'));
  const candidate = fs.existsSync(`${fsPath}.md`) ? `${fsPath}.md` : null;
  if (!candidate) return fail(res, 'Could not resolve file on disk for this slug', 404);

  fs.unlinkSync(candidate);
  await logAudit({ actorUserId: req.user.id, action: 'Delete page', recordType: 'content', recordId: slug, ip: req.ip });
  return ok(res, null, 'Page deleted');
}));

module.exports = router;
