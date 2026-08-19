/**
 * services/audit.service.js — lightweight audit log for the docs
 * portal (admin approvals, key issuance/revocation, uploads). Not
 * hash-chained like the EDMS's own audit trail — this is an internal
 * ops log for the portal itself, not a records-management artifact.
 */
const { pool } = require('../config/db');
const logger = require('../config/logger');

async function logAudit({ actorUserId = null, action, recordType = null, recordId = null, detail = null, ip = null }) {
  try {
    await pool.query(
      `INSERT INTO audit_log (actor_user_id, action, record_type, record_id, detail, ip_address) VALUES (?, ?, ?, ?, ?, ?)`,
      [actorUserId, action, recordType, recordId, detail, ip]
    );
  } catch (err) {
    logger.error('Failed to write docs-portal audit entry', { error: err.message, action });
  }
}

module.exports = { logAudit };
