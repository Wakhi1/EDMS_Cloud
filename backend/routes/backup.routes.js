/**
 * routes/backup.routes.js
 * Backup & Disaster Recovery. Deliberately hard-gated to System
 * Administrator via allowRoles — NOT the configurable role_module_permissions
 * matrix — given the blast radius of /:id/restore (see backup.service.js).
 */
const express = require('express');
const { body, validationResult } = require('express-validator');

const { pool } = require('../config/db');
const { ok, fail } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');
const { authenticate } = require('../middleware/auth.middleware');
const { allowRoles } = require('../middleware/rbac.middleware');
const { runBackup, restoreBackup } = require('../services/backup.service');

const router = express.Router();
router.use(authenticate);
router.use(allowRoles('System Administrator'));

/** GET /api/backup — backup history. */
router.get('/', asyncHandler(async (req, res) => {
  const [rows] = await pool.query(
    `SELECT b.id, b.file_key, b.size_bytes, b.storage_provider, b.status, b.error_message,
            b.created_at, b.completed_at, u.full_name AS created_by
     FROM backups b LEFT JOIN users u ON u.id = b.created_by
     ORDER BY b.id DESC LIMIT 200`
  );
  return ok(res, rows);
}));

/** POST /api/backup/run — trigger a backup now. Runs synchronously; a full DB dump for this app's demo dataset is small. */
router.post('/run', asyncHandler(async (req, res) => {
  const backupId = await runBackup({ createdBy: req.user.id, ip: req.ip });
  return ok(res, { id: backupId }, 'Backup completed', 201);
}));

/**
 * POST /api/backup/:id/restore — { confirmationPhrase } must exactly match
 * the target backup's file_key (shown in the UI as "type the filename to
 * confirm"). Genuinely overwrites the live database.
 */
router.post(
  '/:id/restore',
  [body('confirmationPhrase').trim().notEmpty()],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    try {
      const result = await restoreBackup({
        backupId: req.params.id,
        confirmationPhrase: req.body.confirmationPhrase,
        performedBy: req.user.id,
        ip: req.ip,
      });
      return ok(res, result, 'Restore completed');
    } catch (err) {
      return fail(res, err.message, 400);
    }
  })
);

module.exports = router;
