/**
 * routes/folders.routes.js
 * Folder tree (Pension Claims / 2026 / Retirement, Contributions,
 * Statements, Payouts, Governance ...).
 */
const express = require('express');
const { body, validationResult } = require('express-validator');

const { pool } = require('../config/db');
const { ok, fail } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');
const { authenticate } = require('../middleware/auth.middleware');
const { requireModuleAccess } = require('../middleware/rbac.middleware');
const { logAudit } = require('../services/audit.service');
const aclService = require('../services/acl.service');

const router = express.Router();
router.use(authenticate);

/** GET /api/folders?departmentId=&retentionClassId= — flat list (client builds the tree from parent_id). */
router.get('/', requireModuleAccess('repository'), asyncHandler(async (req, res) => {
  const { departmentId, retentionClassId } = req.query;
  const clauses = [];
  const params = [];
  if (departmentId) { clauses.push('f.department_id = ?'); params.push(departmentId); }
  if (retentionClassId) { clauses.push('f.retention_class_id = ?'); params.push(retentionClassId); }
  const where = clauses.length ? `WHERE ${clauses.join(' AND ')}` : '';

  const [rows] = await pool.query(
    `SELECT f.*, rc.name AS retention_class_name
     FROM folders f LEFT JOIN retention_classes rc ON rc.id = f.retention_class_id
     ${where} ORDER BY f.path`,
    params
  );
  const accessible = await aclService.filterAccessible(req.user.id, req.user.role, 'folder', rows);
  return ok(res, accessible);
}));

/** POST /api/folders */
router.post(
  '/',
  requireModuleAccess('repository', true),
  [body('name').trim().notEmpty()],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    const { name, parentId, departmentId, retentionClassId } = req.body;
    let path = name;
    if (parentId) {
      const [[parent]] = await pool.query('SELECT path FROM folders WHERE id = ?', [parentId]);
      if (!parent) return fail(res, 'Parent folder not found', 404);
      path = `${parent.path} / ${name}`;
    }

    const [result] = await pool.query(
      `INSERT INTO folders (company_id, parent_id, name, path, department_id, retention_class_id, created_by)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [req.user.companyId, parentId || null, name, path, departmentId || null, retentionClassId || null, req.user.id]
    );

    await logAudit({ userId: req.user.id, action: 'Create', recordType: 'folder', recordId: result.insertId, detail: path, ip: req.ip });
    return ok(res, { id: result.insertId, path }, 'Folder created', 201);
  })
);

/** PUT /api/folders/:id — rename and/or reassign department/retention class. Moving to a new parent recomputes path for the folder and all descendants. */
router.put(
  '/:id',
  requireModuleAccess('repository', true),
  [body('name').optional().trim().notEmpty()],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    const [[folder]] = await pool.query('SELECT * FROM folders WHERE id = ?', [req.params.id]);
    if (!folder) return fail(res, 'Folder not found', 404);
    if (!await aclService.hasAccess(req.user.id, req.user.role, 'folder', folder.id, 'edit')) {
      return fail(res, 'You do not have access to this folder', 403);
    }

    const { name, parentId, departmentId, retentionClassId } = req.body;
    const newName = name !== undefined ? name : folder.name;
    const newParentId = parentId !== undefined ? (parentId || null) : folder.parent_id;

    let newPath = newName;
    if (newParentId) {
      if (Number(newParentId) === folder.id) return fail(res, 'A folder cannot be its own parent', 400);
      const [[parent]] = await pool.query('SELECT path FROM folders WHERE id = ?', [newParentId]);
      if (!parent) return fail(res, 'Parent folder not found', 404);
      newPath = `${parent.path} / ${newName}`;
    }

    const conn = await pool.getConnection();
    try {
      await conn.beginTransaction();
      const oldPath = folder.path;
      await conn.query(
        `UPDATE folders SET name = ?, path = ?, parent_id = ?, department_id = COALESCE(?, department_id), retention_class_id = ?
         WHERE id = ?`,
        [newName, newPath, newParentId, departmentId !== undefined ? departmentId : null, retentionClassId !== undefined ? (retentionClassId || null) : folder.retention_class_id, folder.id]
      );
      if (oldPath !== newPath) {
        // Re-prefix every descendant's materialised path.
        await conn.query(
          `UPDATE folders SET path = CONCAT(?, SUBSTRING(path, ?)) WHERE path LIKE ?`,
          [newPath, oldPath.length + 1, `${oldPath} / %`]
        );
      }
      await conn.commit();
    } catch (err) {
      await conn.rollback();
      throw err;
    } finally {
      conn.release();
    }

    await logAudit({ userId: req.user.id, action: 'Edit', recordType: 'folder', recordId: req.params.id, detail: newPath, ip: req.ip });
    return ok(res, { path: newPath }, 'Folder updated');
  })
);

/** DELETE /api/folders/:id — refuses if the folder has documents or subfolders. */
router.delete('/:id', requireModuleAccess('repository', true), asyncHandler(async (req, res) => {
  const [[folder]] = await pool.query('SELECT id, path FROM folders WHERE id = ?', [req.params.id]);
  if (!folder) return fail(res, 'Folder not found', 404);
  if (!await aclService.hasAccess(req.user.id, req.user.role, 'folder', folder.id, 'edit')) {
    return fail(res, 'You do not have access to this folder', 403);
  }

  const [[{ childCount }]] = await pool.query('SELECT COUNT(*) AS childCount FROM folders WHERE parent_id = ?', [req.params.id]);
  if (childCount > 0) return fail(res, 'Cannot delete a folder that contains subfolders', 409);

  const [[{ docCount }]] = await pool.query('SELECT COUNT(*) AS docCount FROM documents WHERE folder_id = ?', [req.params.id]);
  if (docCount > 0) return fail(res, 'Cannot delete a folder that contains documents', 409);

  await pool.query('DELETE FROM folders WHERE id = ?', [req.params.id]);
  await logAudit({ userId: req.user.id, action: 'Delete', recordType: 'folder', recordId: req.params.id, detail: folder.path, ip: req.ip });
  return ok(res, null, 'Folder deleted');
}));

module.exports = router;
