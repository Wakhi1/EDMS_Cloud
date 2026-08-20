/**
 * middleware/rbac.middleware.js
 * Role-based module gate + generic role allow-list guard, mirroring the
 * prototype's per-module "Permitted roles" concept.
 */
const { pool } = require('../config/db');
const { fail } = require('../utils/apiResponse');
const { logAudit } = require('../services/audit.service');

/** Restrict a route to an explicit list of role names. */
function allowRoles(...roles) {
  return (req, res, next) => {
    if (!req.user || !roles.includes(req.user.role)) {
      logAudit({
        userId: req.user ? req.user.id : null,
        action: 'Permission',
        recordType: 'route',
        recordId: req.originalUrl,
        detail: `Denied — role ${req.user ? req.user.role : 'anonymous'} not in [${roles.join(', ')}]`,
        ip: req.ip,
      });
      return fail(res, 'You do not have permission to perform this action', 403);
    }
    return next();
  };
}

/** Restrict a route to a named module, checked against role_module_permissions. */
function requireModuleAccess(moduleName, needsEdit = false) {
  return async (req, res, next) => {
    try {
      const [rows] = await pool.query(
        `SELECT can_view, can_edit FROM role_module_permissions WHERE company_id = ? AND role_id = ? AND module = ? LIMIT 1`,
        [req.user.companyId, req.user.roleId, moduleName]
      );
      const perm = rows[0];
      const allowed = perm && (needsEdit ? perm.can_edit : perm.can_view);
      if (!allowed) {
        await logAudit({
          userId: req.user.id,
          action: 'Permission',
          recordType: 'module',
          recordId: moduleName,
          detail: `Denied access to module "${moduleName}"`,
          ip: req.ip,
        });
        return fail(res, `Your role is not permitted to open ${moduleName}`, 403);
      }
      return next();
    } catch (err) {
      return next(err);
    }
  };
}

module.exports = { allowRoles, requireModuleAccess };
