/**
 * routes/notifications.routes.js
 */
const express = require('express');
const { pool } = require('../config/db');
const { ok } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');
const { authenticate } = require('../middleware/auth.middleware');

const router = express.Router();
router.use(authenticate);

/** GET /api/notifications */
router.get('/', asyncHandler(async (req, res) => {
  const [rows] = await pool.query(
    'SELECT * FROM notifications WHERE user_id = ? ORDER BY created_at DESC LIMIT 100',
    [req.user.id]
  );
  return ok(res, rows);
}));

/** PUT /api/notifications/:id/read */
router.put('/:id/read', asyncHandler(async (req, res) => {
  await pool.query('UPDATE notifications SET is_read = 1 WHERE id = ? AND user_id = ?', [req.params.id, req.user.id]);
  return ok(res, null, 'Marked read');
}));

/** PUT /api/notifications/read-all */
router.put('/read-all', asyncHandler(async (req, res) => {
  await pool.query('UPDATE notifications SET is_read = 1 WHERE user_id = ? AND is_read = 0', [req.user.id]);
  return ok(res, null, 'All notifications marked read');
}));

module.exports = router;
