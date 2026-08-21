/**
 * routes/sharing.routes.js
 * Expiring, revocable public links for a document's current version.
 * Two audiences in one file: authenticated EDMS users create/list/revoke
 * their own company's links (requires edit access to the document, same
 * gate as delete); the public/:token routes below need no EDMS account at
 * all — the token itself, not-expired and not-revoked, is the credential
 * a recipient presents (same reasoning as license.service.js's license
 * keys: the token's unguessability is what protects it, not a login).
 */
const express = require('express');
const crypto = require('crypto');
const { body, validationResult } = require('express-validator');

const { pool } = require('../config/db');
const { ok, fail } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');
const { authenticate } = require('../middleware/auth.middleware');
const { requireModuleAccess } = require('../middleware/rbac.middleware');
const { logAudit } = require('../services/audit.service');
const aclService = require('../services/acl.service');
const { envelopeDecryptFile } = require('../services/crypto.service');
const storageService = require('../services/storage/storage.service');
const { watermarkPdf } = require('../services/watermark.service');

const router = express.Router();

function makeToken() {
  return crypto.randomBytes(32).toString('base64url');
}

/** GET /api/sharing — this company's share links, most recent first. */
router.get('/', authenticate, requireModuleAccess('repository'), asyncHandler(async (req, res) => {
  const [rows] = await pool.query(
    `SELECT sl.id, sl.token, sl.expires_at, sl.revoked_at, sl.access_count, sl.last_accessed_at, sl.created_at,
            d.id AS document_id, d.record_no, d.title, u.full_name AS created_by_name
     FROM document_share_links sl
     JOIN documents d ON d.id = sl.document_id
     JOIN users u ON u.id = sl.created_by
     ORDER BY sl.created_at DESC LIMIT 200`
  );
  return ok(res, rows);
}));

/** POST /api/sharing — { documentId, expiresInHours } → { token, expiresAt }. Requires edit access to the document (same as Delete). */
router.post(
  '/',
  authenticate,
  requireModuleAccess('repository', true),
  [body('documentId').isInt(), body('expiresInHours').isInt({ min: 1, max: 24 * 90 })],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    const { documentId, expiresInHours } = req.body;
    const [[doc]] = await pool.query('SELECT id, record_no, status FROM documents WHERE id = ?', [documentId]);
    if (!doc) return fail(res, 'Record not found', 404);
    if (doc.status === 'archived' || doc.status === 'disposed') return fail(res, 'Cannot share a record that is archived or disposed', 409);
    if (!await aclService.hasAccess(req.user.id, req.user.role, 'document', doc.id, 'edit')) {
      return fail(res, 'You do not have access to this record', 403);
    }

    const token = makeToken();
    const [result] = await pool.query(
      `INSERT INTO document_share_links (company_id, document_id, token, created_by, expires_at)
       VALUES (?, ?, ?, ?, DATE_ADD(NOW(), INTERVAL ? HOUR))`,
      [req.user.companyId, documentId, token, req.user.id, expiresInHours]
    );
    const [[row]] = await pool.query('SELECT expires_at FROM document_share_links WHERE id = ?', [result.insertId]);

    await logAudit({ userId: req.user.id, action: 'Permission', recordType: 'document', recordId: documentId, detail: `${doc.record_no} shared, link expires ${row.expires_at}`, ip: req.ip });
    return ok(res, { id: result.insertId, token, expiresAt: row.expires_at }, 'Share link created', 201);
  })
);

/** DELETE /api/sharing/:id — revoke a link early. */
router.delete('/:id', authenticate, requireModuleAccess('repository', true), asyncHandler(async (req, res) => {
  const [[link]] = await pool.query('SELECT id, document_id, revoked_at FROM document_share_links WHERE id = ?', [req.params.id]);
  if (!link) return fail(res, 'Share link not found', 404);
  if (link.revoked_at) return fail(res, 'Link is already revoked', 409);
  if (!await aclService.hasAccess(req.user.id, req.user.role, 'document', link.document_id, 'edit')) {
    return fail(res, 'You do not have access to this record', 403);
  }

  await pool.query('UPDATE document_share_links SET revoked_at = NOW() WHERE id = ?', [req.params.id]);
  await logAudit({ userId: req.user.id, action: 'Permission', recordType: 'document', recordId: link.document_id, detail: 'Share link revoked', ip: req.ip });
  return ok(res, null, 'Share link revoked');
}));

async function loadValidLink(token) {
  const [[link]] = await pool.query(
    `SELECT sl.*, d.record_no, d.title, d.status, d.classification
     FROM document_share_links sl JOIN documents d ON d.id = sl.document_id
     WHERE sl.token = ?`,
    [token]
  );
  if (!link) return { link: null, reason: 'not_found' };
  if (link.revoked_at) return { link: null, reason: 'revoked' };
  if (new Date(link.expires_at).getTime() < Date.now()) return { link: null, reason: 'expired' };
  if (link.status === 'archived' || link.status === 'disposed') return { link: null, reason: 'unavailable' };
  return { link, reason: null };
}

/** GET /api/sharing/public/:token — no auth: metadata for the recipient's landing page. */
router.get('/public/:token', asyncHandler(async (req, res) => {
  const { link, reason } = await loadValidLink(req.params.token);
  if (!link) return fail(res, { not_found: 'This link is invalid.', revoked: 'This link has been revoked.', expired: 'This link has expired.', unavailable: 'This record is no longer available.' }[reason], 404);

  return ok(res, { recordNo: link.record_no, title: link.title, classification: link.classification, expiresAt: link.expires_at });
}));

/** GET /api/sharing/public/:token/content — no auth: streams the current version, same decrypt path as documents.routes.js's content endpoint. */
router.get('/public/:token/content', asyncHandler(async (req, res) => {
  const { link, reason } = await loadValidLink(req.params.token);
  if (!link) return fail(res, { not_found: 'This link is invalid.', revoked: 'This link has been revoked.', expired: 'This link has expired.', unavailable: 'This record is no longer available.' }[reason], 404);

  const [[row]] = await pool.query(
    `SELECT dv.file_name, dv.mime_type, dso.*,
            dek.wrapped_dek, dek.dek_iv, dek.dek_auth_tag, dek.file_iv, dek.file_auth_tag
     FROM documents d
     JOIN document_versions dv ON dv.id = d.current_version_id
     JOIN document_storage_objects dso ON dso.id = dv.storage_object_id
     LEFT JOIN document_encryption_keys dek ON dek.document_version_id = dv.id
     WHERE d.id = ?`,
    [link.document_id]
  );
  if (!row) return fail(res, 'Content not found', 404);

  const fetchedFile = await storageService.downloadEncrypted(row);
  let plaintext = row.is_encrypted
    ? envelopeDecryptFile({
        encryptedFile: fetchedFile,
        fileIv: row.file_iv,
        fileAuthTag: row.file_auth_tag,
        wrappedDek: row.wrapped_dek,
        dekIv: row.dek_iv,
        dekAuthTag: row.dek_auth_tag,
      })
    : fetchedFile;

  if (row.mime_type === 'application/pdf') {
    plaintext = await watermarkPdf(plaintext, { userLabel: `Shared link (${link.record_no})` });
  }

  await pool.query('UPDATE document_share_links SET access_count = access_count + 1, last_accessed_at = NOW() WHERE id = ?', [link.id]);
  await logAudit({ action: 'Download', recordType: 'document', recordId: link.document_id, detail: `${link.record_no} downloaded via share link`, ip: req.ip });

  res.setHeader('Content-Type', row.mime_type);
  res.setHeader('Content-Disposition', `inline; filename="${row.file_name}"`);
  return res.send(plaintext);
}));

module.exports = router;
