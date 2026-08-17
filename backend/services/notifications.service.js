/**
 * services/notifications.service.js
 * Writes in-app notification rows. Mirrors audit.service.js's safety
 * contract: a notification-write failure must never break the mutating
 * request that triggered it, so every error is caught and logged here,
 * never thrown to the caller.
 */
const { pool } = require('../config/db');
const logger = require('../config/logger');

async function createNotification({ userId, type, title, body = null, relatedRecordType = null, relatedRecordId = null }) {
  if (!userId) return; // e.g. no approver resolved for a role — nothing to notify
  try {
    await pool.query(
      `INSERT INTO notifications (user_id, type, title, body, related_record_type, related_record_id)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [userId, type, title, body, relatedRecordType, relatedRecordId]
    );
  } catch (err) {
    logger.error('Failed to write notification', { error: err.message, userId, type });
  }
}

/**
 * Notify every active user in a named department (e.g. 'ICT' for
 * backup/restore events) — reuses createNotification per user rather than
 * a bulk-insert variant, since volume here is always small (one
 * department's staff).
 */
async function notifyDepartment(departmentName, { type, title, body = null, relatedRecordType = null, relatedRecordId = null }) {
  try {
    const [users] = await pool.query(
      `SELECT u.id FROM users u JOIN departments d ON d.id = u.department_id
       WHERE d.name = ? AND u.is_active = 1`,
      [departmentName]
    );
    await Promise.all(users.map((u) => createNotification({ userId: u.id, type, title, body, relatedRecordType, relatedRecordId })));
  } catch (err) {
    logger.error('Failed to notify department', { error: err.message, departmentName, type });
  }
}

/**
 * Notify every active user holding a named role (e.g. 'Records Manager' for
 * escalations) — mirrors notifyDepartment exactly, just joining roles
 * instead of departments.
 */
async function notifyRole(roleName, { type, title, body = null, relatedRecordType = null, relatedRecordId = null }) {
  try {
    const [users] = await pool.query(
      `SELECT u.id FROM users u JOIN roles r ON r.id = u.role_id
       WHERE r.name = ? AND u.is_active = 1`,
      [roleName]
    );
    await Promise.all(users.map((u) => createNotification({ userId: u.id, type, title, body, relatedRecordType, relatedRecordId })));
  } catch (err) {
    logger.error('Failed to notify role', { error: err.message, roleName, type });
  }
}

module.exports = { createNotification, notifyDepartment, notifyRole };
