/**
 * services/capture/batch.service.js
 * Turns a set of raw files (from a manual bulk upload or an automated
 * intake connector's poll()) into real, registered documents, tracking
 * every file's outcome in capture_batches / capture_batch_items. Both
 * services/capture/scheduler.js (automated) and
 * routes/capture.routes.js (manual/device upload) go through this —
 * neither path talks to document.service.js directly.
 */
const { pool } = require('../../config/db');
const { registerDocument, DuplicateRecordNoError, DuplicateContentError } = require('../document.service');
const { suggestDocumentTypeCode, suggestMemberNumber, resolveDocumentTypeId } = require('../classification.service');
const { logAudit } = require('../audit.service');
const { autoTriggerWorkflow } = require('../workflow.service');
const logger = require('../../config/logger');

function generateRecordNo(typeCode) {
  const year = new Date().getFullYear();
  const suffix = Math.floor(Math.random() * 10000).toString().padStart(4, '0');
  return `${typeCode}-${year}-${suffix}`;
}

async function createBatch({ source, createdBy }) {
  const batchNo = `BATCH-${Date.now()}`;
  // createdBy is always a real user id by the time this is called (a
  // signed-in user for manual capture, or SYSTEM_INTAKE_USER_ID for
  // automated intake — see runBatch below) — derive the batch's company
  // from them rather than threading req.user.companyId through every
  // caller, since the automated scheduler path has no request at all.
  const [[user]] = await pool.query('SELECT company_id FROM users WHERE id = ?', [createdBy]);
  const companyId = user ? user.company_id : null;

  const [result] = await pool.query(
    `INSERT INTO capture_batches (company_id, batch_no, source, status, created_by, started_at) VALUES (?, ?, ?, 'running', ?, NOW())`,
    [companyId, batchNo, source, createdBy || null]
  );
  return { id: result.insertId, batchNo, companyId };
}

/**
 * Registers one captured file against a batch, auto-classifying it (no
 * human reviews automated/bulk intake the way Smart Upload's review table
 * lets a human review a single-session upload). [defaultFolderId] comes
 * from the connector's config_json (or a request field for manual
 * uploads); [ocrOverride] lets a caller that already ran OCR (batch
 * processing shouldn't run it twice) skip re-extraction — currently unused
 * since registerDocument always re-extracts, kept simple for now.
 * Never throws — always resolves, recording success/failure as a
 * capture_batch_items row either way.
 */
async function processFile(batchId, { buffer, fileName, mimeType, defaultFolderId, createdBy, companyId, ip }) {
  try {
    // Peek at extracted text via a throwaway OCR pass is wasteful (registerDocument
    // already runs it) — classify from the file name as a cheap first guess instead;
    // registerDocument's own OCR result isn't available until after registration, so
    // batch items are classified best-effort up front, same spirit as Smart Upload's
    // suggestion (not a human-verified guarantee).
    const suggestedCode = suggestDocumentTypeCode(fileName) || suggestDocumentTypeCode(mimeType);
    const documentTypeId = await resolveDocumentTypeId(suggestedCode);
    if (!documentTypeId) throw new Error('No document types configured — cannot auto-classify batch intake');
    if (!defaultFolderId) throw new Error('No default folder configured for this batch/connector');

    const typeCode = suggestedCode || 'CS';
    let attempt = 0;
    let result;
    // eslint-disable-next-line no-constant-condition
    while (true) {
      attempt += 1;
      const recordNo = generateRecordNo(typeCode);
      try {
        result = await registerDocument({
          buffer, originalName: fileName, mimeType,
          recordNo, title: fileName, documentTypeId, folderId: defaultFolderId,
          memberNumber: suggestMemberNumber(fileName), classification: 'internal',
          userId: createdBy, ip,
        });
        break;
      } catch (err) {
        if (err instanceof DuplicateRecordNoError && attempt < 5) continue;
        throw err;
      }
    }

    await pool.query(
      `INSERT INTO capture_batch_items (company_id, batch_id, source_file_name, status, document_id) VALUES (?, ?, ?, 'succeeded', ?)`,
      [companyId, batchId, fileName, result.id]
    );

    // Auto-route into a matching workflow, if one's configured — never let
    // a routing failure undo a registration that already succeeded.
    autoTriggerWorkflow({ documentId: result.id, documentTypeId, folderId: defaultFolderId, ip })
      .catch((err) => logger.error('Auto-trigger workflow failed', { error: err.message, documentId: result.id }));

    return { ok: true, documentId: result.id, recordNo: result.recordNo };
  } catch (err) {
    if (err instanceof DuplicateContentError) {
      logger.info('Batch item is a duplicate', { batchId, fileName, existing: err.existing });
      await pool.query(
        `INSERT INTO capture_batch_items (company_id, batch_id, source_file_name, status, document_id, error_message) VALUES (?, ?, ?, 'duplicate', ?, ?)`,
        [companyId, batchId, fileName, err.existing.id, `Duplicate of ${err.existing.recordNo} (${err.existing.title})`.slice(0, 500)]
      );
      return { ok: false, duplicate: true, error: err.message };
    }
    logger.warn('Batch item failed', { batchId, fileName, error: err.message });
    await pool.query(
      `INSERT INTO capture_batch_items (company_id, batch_id, source_file_name, status, error_message) VALUES (?, ?, ?, 'failed', ?)`,
      [companyId, batchId, fileName, err.message.slice(0, 500)]
    );
    return { ok: false, error: err.message };
  }
}

/** Rolls up capture_batch_items into the batch's aggregate stats and closes it out. */
async function completeBatch(batchId) {
  const [[counts]] = await pool.query(
    `SELECT COUNT(*) AS total, SUM(status = 'succeeded') AS succeeded FROM capture_batch_items WHERE batch_id = ?`,
    [batchId]
  );
  // mysql2 returns SUM()/COUNT() as strings, not numbers — coerce before
  // comparing (a recurring bug class in this codebase; see project memory).
  const total = Number(counts.total) || 0;
  const succeeded = Number(counts.succeeded) || 0;
  const status = total === 0 ? 'completed' : succeeded === total ? 'completed' : succeeded === 0 ? 'failed' : 'completed_with_errors';
  const successRate = total === 0 ? 0 : (succeeded / total) * 100;

  await pool.query(
    `UPDATE capture_batches SET status = ?, documents = ?, pages = ?, success_rate = ?, completed_at = NOW() WHERE id = ?`,
    [status, succeeded, total, successRate.toFixed(2), batchId]
  );
  return { total, succeeded, status };
}

/**
 * Runs every file returned by an intake connector's poll() through
 * processFile, then completes the batch. Used by both the scheduler
 * (automated — no human [createdBy], falls back to the SYSTEM_INTAKE_USER_ID
 * service account) and manual "run now"/bulk-upload triggers (a real
 * signed-in user).
 */
async function runBatch({ source, files, defaultFolderId, createdBy, ip }) {
  const effectiveCreatedBy = createdBy || Number(process.env.SYSTEM_INTAKE_USER_ID);
  const effectiveFolderId = defaultFolderId || Number(process.env.CAPTURE_DEFAULT_FOLDER_ID);
  const batch = await createBatch({ source, createdBy: effectiveCreatedBy });
  for (const file of files) {
    // eslint-disable-next-line no-await-in-loop
    await processFile(batch.id, { ...file, defaultFolderId: effectiveFolderId, createdBy: effectiveCreatedBy, companyId: batch.companyId, ip });
  }
  const summary = await completeBatch(batch.id);
  await logAudit({
    userId: effectiveCreatedBy, action: 'Capture', recordType: 'capture_batch', recordId: batch.id,
    detail: `${source}: ${summary.succeeded}/${summary.total} captured`, ip,
  });
  return { batchId: batch.id, batchNo: batch.batchNo, ...summary };
}

module.exports = { createBatch, processFile, completeBatch, runBatch };
