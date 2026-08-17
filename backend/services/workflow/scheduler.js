/**
 * services/workflow/scheduler.js
 * SLA-breach escalation — same in-process, no-durable-queue pattern as
 * services/capture/scheduler.js and services/backup/scheduler.js. Every 5
 * minutes, plus once immediately at boot, finds pending approvals that
 * have outlived their step's sla_days and haven't been escalated yet, and
 * notifies the step's escalation role (falling back to Records Manager)
 * plus the original approver.
 */
const { pool } = require('../../config/db');
const logger = require('../../config/logger');
const { logAudit } = require('../audit.service');
const { createNotification, notifyRole } = require('../notifications.service');

const CHECK_INTERVAL_MS = 5 * 60 * 1000;
const DEFAULT_ESCALATION_ROLE = 'Records Manager';

let timer = null;

async function checkAndEscalate() {
  try {
    const [rows] = await pool.query(
      `SELECT wa.id AS approval_id, wa.approver_id, ws.step_name, r.name AS escalation_role_name,
              d.id AS document_id, d.record_no, d.title
       FROM workflow_approvals wa
       JOIN workflow_steps ws ON ws.id = wa.step_id
       JOIN document_workflow_instances dwi ON dwi.id = wa.instance_id
       JOIN documents d ON d.id = dwi.document_id
       LEFT JOIN roles r ON r.id = ws.escalation_role_id
       WHERE wa.decision = 'pending' AND wa.escalated_at IS NULL
         AND wa.created_at < NOW() - INTERVAL ws.sla_days DAY`
    );

    for (const row of rows) {
      // eslint-disable-next-line no-await-in-loop
      await pool.query('UPDATE workflow_approvals SET escalated_at = NOW() WHERE id = ?', [row.approval_id]);

      const escalationRole = row.escalation_role_name || DEFAULT_ESCALATION_ROLE;
      // eslint-disable-next-line no-await-in-loop
      await notifyRole(escalationRole, {
        type: 'approval_escalated',
        title: `Escalated: ${row.record_no}`,
        body: `"${row.title}" (step "${row.step_name}") has been pending past its SLA and needs attention.`,
        relatedRecordType: 'document',
        relatedRecordId: row.document_id,
      });
      // eslint-disable-next-line no-await-in-loop
      await createNotification({
        userId: row.approver_id,
        type: 'approval_overdue',
        title: `Overdue: ${row.record_no}`,
        body: `"${row.title}" (step "${row.step_name}") is overdue and has been escalated to ${escalationRole}.`,
        relatedRecordType: 'document',
        relatedRecordId: row.document_id,
      });
      // eslint-disable-next-line no-await-in-loop
      await logAudit({
        userId: null, action: 'Approve', recordType: 'document', recordId: row.document_id,
        detail: `escalated (step "${row.step_name}" -> ${escalationRole})`, ip: null,
      });
    }

    if (rows.length) logger.info('Escalated overdue approvals', { count: rows.length });
  } catch (err) {
    logger.error('Escalation check failed', { error: err.message });
  }
}

/** Starts the 5-minute poll (plus one immediate check); called once at server boot. */
function startScheduler() {
  if (timer) return;
  timer = setInterval(checkAndEscalate, CHECK_INTERVAL_MS);
  checkAndEscalate();
  logger.info('Workflow escalation scheduler started', { checkIntervalMs: CHECK_INTERVAL_MS });
}

module.exports = { startScheduler };
