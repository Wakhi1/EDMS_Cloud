/**
 * services/platformAudit.service.js
 * Action trail for platform-admin (DocSecure staff) actions —
 * company/license/branding management. Deliberately separate from
 * services/audit.service.js: that table's user_id FKs to `users`, a
 * different (tenant-scoped) identity space than `platform_admins`. No
 * hash-chaining here (audit_log's tamper-evidence requirement is a
 * per-tenant Records Act concern, not applicable to this internal trail).
 */
const { pool } = require('../config/db');
const logger = require('../config/logger');

async function logPlatformAudit({ platformAdminId = null, action, companyId = null, detail = null, ip = null }) {
  try {
    await pool.query(
      `INSERT INTO platform_admin_audit_log (platform_admin_id, action, company_id, detail, ip_address) VALUES (?, ?, ?, ?, ?)`,
      [platformAdminId, action, companyId, detail, ip]
    );
  } catch (err) {
    logger.error('Failed to write platform_admin_audit_log entry', { error: err.message, action, companyId });
  }
}

module.exports = { logPlatformAudit };
