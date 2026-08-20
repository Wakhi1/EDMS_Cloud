/**
 * routes/access-requests.routes.js
 * Self-service "I don't have access, please grant it" flow — a user who
 * lacks access to a folder/document asks for it here instead of needing
 * someone to notice unprompted. Whoever can already grant/revoke ACL
 * entries on the target (requireModuleAccess('permissions', true) — same
 * gate as permissions.routes.js's own grant/revoke) can also review and
 * decide the request; approving inserts the same document_acl row the
 * grant endpoint would.
 */
const express = require('express');
const { body, validationResult } = require('express-validator');

const { pool } = require('../config/db');
const { ok, fail } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');
const { authenticate } = require('../middleware/auth.middleware');
const { requireModuleAccess } = require('../middleware/rbac.middleware');
const { logAudit } = require('../services/audit.service');
const { createNotification, notifyModuleEditors } = require('../services/notifications.service');
const { PERMISSION_LEVELS, TARGET_TYPES } = require('../config/constants');

const router = express.Router();
router.use(authenticate);

/** Human-readable label for a target, for notification text — best-effort, never blocks the request. */
async function labelFor(targetType, targetId) {
  if (targetType === 'folder') {
    const [[row]] = await pool.query('SELECT path FROM folders WHERE id = ?', [targetId]);
    return row ? row.path : `folder #${targetId}`;
  }
  const [[row]] = await pool.query('SELECT record_no, title FROM documents WHERE id = ?', [targetId]);
  return row ? `${row.record_no} — ${row.title}` : `document #${targetId}`;
}

/** GET /api/access-requests/mine — the current user's own submitted requests, any status. */
router.get('/mine', asyncHandler(async (req, res) => {
  const [rows] = await pool.query(
    `SELECT ar.*, u2.full_name AS decided_by_name
     FROM access_requests ar
     LEFT JOIN users u2 ON u2.id = ar.decided_by
     WHERE ar.requester_id = ? ORDER BY ar.created_at DESC`,
    [req.user.id]
  );
  return ok(res, rows);
}));

/** GET /api/access-requests?status=pending — the review queue (defaults to pending only). */
router.get('/', requireModuleAccess('permissions', true), asyncHandler(async (req, res) => {
  const status = req.query.status || 'pending';
  const clause = status === 'all' ? '' : 'WHERE ar.status = ?';
  const params = status === 'all' ? [] : [status];
  const [rows] = await pool.query(
    `SELECT ar.*, u.full_name AS requester_name, u2.full_name AS decided_by_name
     FROM access_requests ar
     JOIN users u ON u.id = ar.requester_id
     LEFT JOIN users u2 ON u2.id = ar.decided_by
     ${clause} ORDER BY ar.created_at DESC`,
    params
  );
  return ok(res, rows);
}));

/** POST /api/access-requests — { targetType, targetId, requestedLevel?, reason? }. Any authenticated user. */
router.post(
  '/',
  [
    body('targetType').isIn(TARGET_TYPES),
    body('targetId').isInt(),
    body('requestedLevel').optional().isIn(PERMISSION_LEVELS),
  ],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    const { targetType, targetId, reason } = req.body;
    const requestedLevel = req.body.requestedLevel || 'view';

    const [existing] = await pool.query(
      `SELECT id FROM access_requests WHERE target_type = ? AND target_id = ? AND requester_id = ? AND status = 'pending'`,
      [targetType, targetId, req.user.id]
    );
    if (existing.length) return fail(res, 'You already have a pending request for this record', 409);

    const [result] = await pool.query(
      `INSERT INTO access_requests (company_id, target_type, target_id, requested_level, reason, requester_id)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [req.user.companyId, targetType, targetId, requestedLevel, reason || null, req.user.id]
    );

    const label = await labelFor(targetType, targetId);
    await notifyModuleEditors('permissions', {
      type: 'access_requested',
      title: `${req.user.fullName || 'A user'} requested ${requestedLevel} access`,
      body: label,
      relatedRecordType: targetType,
      relatedRecordId: targetId,
    });
    await logAudit({ userId: req.user.id, action: 'Permission', recordType: targetType, recordId: targetId, detail: `Requested ${requestedLevel} access`, ip: req.ip });

    return ok(res, { id: result.insertId }, 'Access request submitted', 201);
  })
);

/** POST /api/access-requests/:id/approve — { note? }. Grants the requested ACL level. */
router.post(
  '/:id/approve',
  requireModuleAccess('permissions', true),
  asyncHandler(async (req, res) => {
    const [[reqRow]] = await pool.query('SELECT * FROM access_requests WHERE id = ?', [req.params.id]);
    if (!reqRow) return fail(res, 'Request not found', 404);
    if (reqRow.status !== 'pending') return fail(res, 'This request has already been decided', 409);

    const conn = await pool.getConnection();
    try {
      await conn.beginTransaction();
      await conn.query(
        `INSERT INTO document_acl (company_id, target_type, target_id, principal_type, principal_id, permission_level, granted_by)
         VALUES (?, ?, ?, 'user', ?, ?, ?)`,
        [reqRow.company_id, reqRow.target_type, reqRow.target_id, reqRow.requester_id, reqRow.requested_level, req.user.id]
      );
      await conn.query(
        `UPDATE access_requests SET status = 'approved', decided_by = ?, decided_at = NOW(), decision_note = ? WHERE id = ?`,
        [req.user.id, req.body.note || null, req.params.id]
      );
      await conn.commit();
    } catch (err) {
      await conn.rollback();
      throw err;
    } finally {
      conn.release();
    }

    const label = await labelFor(reqRow.target_type, reqRow.target_id);
    await createNotification({
      userId: reqRow.requester_id,
      type: 'access_request_approved',
      title: `Your access request was approved`,
      body: label,
      relatedRecordType: reqRow.target_type,
      relatedRecordId: reqRow.target_id,
    });
    await logAudit({ userId: req.user.id, action: 'Permission', recordType: reqRow.target_type, recordId: reqRow.target_id, detail: `Approved access request #${req.params.id}`, ip: req.ip });

    return ok(res, null, 'Request approved');
  })
);

/** POST /api/access-requests/:id/deny — { note? }. */
router.post(
  '/:id/deny',
  requireModuleAccess('permissions', true),
  asyncHandler(async (req, res) => {
    const [[reqRow]] = await pool.query('SELECT * FROM access_requests WHERE id = ?', [req.params.id]);
    if (!reqRow) return fail(res, 'Request not found', 404);
    if (reqRow.status !== 'pending') return fail(res, 'This request has already been decided', 409);

    await pool.query(
      `UPDATE access_requests SET status = 'denied', decided_by = ?, decided_at = NOW(), decision_note = ? WHERE id = ?`,
      [req.user.id, req.body.note || null, req.params.id]
    );

    const label = await labelFor(reqRow.target_type, reqRow.target_id);
    await createNotification({
      userId: reqRow.requester_id,
      type: 'access_request_denied',
      title: `Your access request was denied`,
      body: req.body.note ? `${label} — ${req.body.note}` : label,
      relatedRecordType: reqRow.target_type,
      relatedRecordId: reqRow.target_id,
    });
    await logAudit({ userId: req.user.id, action: 'Permission', recordType: reqRow.target_type, recordId: reqRow.target_id, detail: `Denied access request #${req.params.id}`, ip: req.ip });

    return ok(res, null, 'Request denied');
  })
);

module.exports = router;
