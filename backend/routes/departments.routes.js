/**
 * routes/departments.routes.js
 * Department administration — used for folder/document assignment, user
 * assignment, and Backup & DR's "notify all ICT users" targeting.
 */
const express = require('express');
const { body, validationResult } = require('express-validator');

const { pool } = require('../config/db');
const { ok, fail } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');
const { authenticate } = require('../middleware/auth.middleware');
const { requireModuleAccess } = require('../middleware/rbac.middleware');
const { logAudit } = require('../services/audit.service');

const router = express.Router();
router.use(authenticate);

/** GET /api/departments */
router.get('/', requireModuleAccess('departments'), asyncHandler(async (req, res) => {
  const [rows] = await pool.query('SELECT * FROM departments ORDER BY name');
  return ok(res, rows);
}));

/** POST /api/departments — { name, description } */
router.post(
  '/',
  requireModuleAccess('departments', true),
  [body('name').trim().notEmpty()],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    const { name, description } = req.body;
    const [existing] = await pool.query('SELECT id FROM departments WHERE name = ?', [name]);
    if (existing.length) return fail(res, 'A department with this name already exists', 409);

    const [result] = await pool.query('INSERT INTO departments (name, description) VALUES (?, ?)', [name, description || null]);
    await logAudit({ userId: req.user.id, action: 'Create', recordType: 'department', recordId: result.insertId, detail: name, ip: req.ip });
    return ok(res, { id: result.insertId }, 'Department created', 201);
  })
);

/** PUT /api/departments/:id — { name?, description?, isActive? } */
router.put(
  '/:id',
  requireModuleAccess('departments', true),
  [body('name').optional().trim().notEmpty()],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    const [[dept]] = await pool.query('SELECT id FROM departments WHERE id = ?', [req.params.id]);
    if (!dept) return fail(res, 'Department not found', 404);

    const { name, description, isActive } = req.body;
    await pool.query(
      `UPDATE departments SET
         name = COALESCE(?, name),
         description = COALESCE(?, description),
         is_active = COALESCE(?, is_active)
       WHERE id = ?`,
      [name || null, description !== undefined ? description : null, isActive !== undefined ? (isActive ? 1 : 0) : null, req.params.id]
    );
    await logAudit({ userId: req.user.id, action: 'Edit', recordType: 'department', recordId: req.params.id, ip: req.ip });
    return ok(res, null, 'Department updated');
  })
);

/** DELETE /api/departments/:id — refuses if still referenced by users, folders, or documents. */
router.delete('/:id', requireModuleAccess('departments', true), asyncHandler(async (req, res) => {
  const [[dept]] = await pool.query('SELECT id, name FROM departments WHERE id = ?', [req.params.id]);
  if (!dept) return fail(res, 'Department not found', 404);

  const [[{ userCount }]] = await pool.query('SELECT COUNT(*) AS userCount FROM users WHERE department_id = ?', [req.params.id]);
  if (userCount > 0) return fail(res, 'Cannot delete a department with assigned users', 409);

  const [[{ folderCount }]] = await pool.query('SELECT COUNT(*) AS folderCount FROM folders WHERE department_id = ?', [req.params.id]);
  if (folderCount > 0) return fail(res, 'Cannot delete a department with assigned folders', 409);

  await pool.query('DELETE FROM departments WHERE id = ?', [req.params.id]);
  await logAudit({ userId: req.user.id, action: 'Delete', recordType: 'department', recordId: req.params.id, detail: dept.name, ip: req.ip });
  return ok(res, null, 'Department deleted');
}));

module.exports = router;
