/**
 * routes/media.routes.js
 * Admin-only media library — images, video demos, and reference
 * documents referenced from .md pages via normal markdown syntax:
 *   ![Solution architecture](/api/media/file/<stored_name>)
 *   <video controls src="/api/media/file/<stored_name>"></video>
 * Listing is public read (GET) so pages can render for anyone; upload/
 * delete are admin-only.
 */
const express = require('express');
const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

const { pool } = require('../config/db');
const { ok, fail } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');
const { authenticate, requireAdmin } = require('../middleware/auth.middleware');
const upload = require('../middleware/upload.middleware');
const { logAudit } = require('../services/audit.service');

const router = express.Router();
const UPLOADS_DIR = path.resolve(process.env.UPLOADS_DIR || './uploads');

function kindFor(mimeType) {
  if (mimeType.startsWith('image/')) return 'image';
  if (mimeType.startsWith('video/')) return 'video';
  if (mimeType === 'application/pdf' || mimeType.includes('word') || mimeType.includes('sheet')) return 'document';
  return 'other';
}

/** GET /api/media — list, newest first. */
router.get('/', asyncHandler(async (req, res) => {
  const [rows] = await pool.query(
    `SELECT m.*, u.full_name AS uploaded_by_name FROM media_assets m JOIN users u ON u.id = m.uploaded_by ORDER BY m.uploaded_at DESC`
  );
  return ok(res, rows);
}));

/** GET /api/media/file/:storedName — streams the actual file (public — used directly in <img>/<video> tags). */
router.get('/file/:storedName', asyncHandler(async (req, res) => {
  const safeName = path.basename(req.params.storedName); // strip any path components
  const filePath = path.join(UPLOADS_DIR, safeName);
  if (!fs.existsSync(filePath)) return fail(res, 'File not found', 404);
  return res.sendFile(filePath);
}));

/** POST /api/media — multipart upload, admin only. */
router.post('/', authenticate, requireAdmin, upload.single('file'), asyncHandler(async (req, res) => {
  if (!req.file) return fail(res, 'A file is required', 400);

  fs.mkdirSync(UPLOADS_DIR, { recursive: true });
  const ext = path.extname(req.file.originalname);
  const storedName = `${uuidv4()}${ext}`;
  fs.writeFileSync(path.join(UPLOADS_DIR, storedName), req.file.buffer);

  const [result] = await pool.query(
    `INSERT INTO media_assets (original_name, stored_name, mime_type, kind, size_bytes, alt_text, uploaded_by)
     VALUES (?, ?, ?, ?, ?, ?, ?)`,
    [req.file.originalname, storedName, req.file.mimetype, kindFor(req.file.mimetype), req.file.size, req.body.altText || null, req.user.id]
  );

  await logAudit({ actorUserId: req.user.id, action: 'Upload media', recordType: 'media_asset', recordId: result.insertId, detail: req.file.originalname, ip: req.ip });
  return ok(res, { id: result.insertId, storedName, url: `/api/media/file/${storedName}` }, 'Uploaded', 201);
}));

/** DELETE /api/media/:id */
router.delete('/:id', authenticate, requireAdmin, asyncHandler(async (req, res) => {
  const [[asset]] = await pool.query('SELECT * FROM media_assets WHERE id = ?', [req.params.id]);
  if (!asset) return fail(res, 'Not found', 404);

  fs.rmSync(path.join(UPLOADS_DIR, asset.stored_name), { force: true });
  await pool.query('DELETE FROM media_assets WHERE id = ?', [req.params.id]);
  await logAudit({ actorUserId: req.user.id, action: 'Delete media', recordType: 'media_asset', recordId: req.params.id, ip: req.ip });
  return ok(res, null, 'Deleted');
}));

module.exports = router;
