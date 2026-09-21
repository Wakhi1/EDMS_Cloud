/**
 * services/workflow/schedule_scheduler.js
 * Time-based workflow triggers — a third trigger mechanism alongside
 * trigger_doc_type_id/trigger_folder_id (workflow.service.js's
 * autoTriggerWorkflow). Same in-process, no-durable-queue polling pattern
 * as services/workflow/scheduler.js (SLA escalation): every minute, plus
 * once immediately at boot, finds workflows whose schedule_next_run_at has
 * arrived and re-routes their configured target document through the
 * workflow again, then advances (or disables) that workflow's schedule.
 *
 * Deliberately poll-everything-every-tick rather than a per-row timer
 * (contrast services/capture/scheduler.js) — simpler, and restart-safe by
 * construction since schedule_next_run_at is read fresh from the DB on
 * every tick rather than reconstructed from an in-memory timer.
 */
const { pool } = require('../../config/db');
const logger = require('../../config/logger');
const { startWorkflowInstance } = require('../workflow.service');

const CHECK_INTERVAL_MS = 60 * 1000;

const RECURRENCE_INTERVAL_SQL = {
  daily: 'INTERVAL 1 DAY',
  weekly: 'INTERVAL 1 WEEK',
  monthly: 'INTERVAL 1 MONTH',
  yearly: 'INTERVAL 1 YEAR',
};

let timer = null;

async function checkAndFire() {
  try {
    const [rows] = await pool.query(
      `SELECT w.id AS workflow_id, w.schedule_target_document_id, w.schedule_recurrence,
              w.schedule_end_at, w.schedule_next_run_at, d.status AS document_status
       FROM workflows w
       LEFT JOIN documents d ON d.id = w.schedule_target_document_id
       WHERE w.schedule_enabled = 1 AND w.schedule_next_run_at <= NOW()`
    );

    for (const row of rows) {
      // eslint-disable-next-line no-await-in-loop
      await processDueWorkflow(row);
    }

    if (rows.length) logger.info('Fired scheduled workflows', { count: rows.length });
  } catch (err) {
    logger.error('Scheduled-workflow check failed', { error: err.message });
  }
}

async function processDueWorkflow(row) {
  // Target document deleted/missing — nothing left to reschedule against.
  if (!row.schedule_target_document_id || !row.document_status) {
    await pool.query('UPDATE workflows SET schedule_enabled = 0, schedule_next_run_at = NULL WHERE id = ?', [row.workflow_id]);
    logger.warn('Disabled schedule: target document missing', { workflowId: row.workflow_id });
    return;
  }

  if (row.document_status === 'disposed') {
    logger.info('Skipped scheduled workflow fire: target document disposed', { workflowId: row.workflow_id });
  } else {
    try {
      await startWorkflowInstance({
        workflowId: row.workflow_id, documentId: row.schedule_target_document_id, userId: null, ip: null,
      });
    } catch (err) {
      logger.error('Scheduled workflow failed to start', { workflowId: row.workflow_id, error: err.message });
    }
  }

  if (row.schedule_recurrence === 'once') {
    await pool.query('UPDATE workflows SET schedule_enabled = 0 WHERE id = ?', [row.workflow_id]);
    return;
  }

  const interval = RECURRENCE_INTERVAL_SQL[row.schedule_recurrence];
  // Advances from the occurrence that just fired (not NOW()) so a
  // "1st of every month at 09:00" schedule doesn't drift just because a
  // given tick landed a few seconds late.
  const [[{ next }]] = await pool.query(`SELECT DATE_ADD(?, ${interval}) AS next`, [row.schedule_next_run_at]);

  if (row.schedule_end_at && next > row.schedule_end_at) {
    await pool.query('UPDATE workflows SET schedule_enabled = 0 WHERE id = ?', [row.workflow_id]);
  } else {
    await pool.query('UPDATE workflows SET schedule_next_run_at = ? WHERE id = ?', [next, row.workflow_id]);
  }
}

/** Starts the 1-minute poll (plus one immediate check); called once at server boot. */
function startScheduler() {
  if (timer) return;
  timer = setInterval(checkAndFire, CHECK_INTERVAL_MS);
  checkAndFire();
  logger.info('Workflow schedule scheduler started', { checkIntervalMs: CHECK_INTERVAL_MS });
}

module.exports = { startScheduler };
