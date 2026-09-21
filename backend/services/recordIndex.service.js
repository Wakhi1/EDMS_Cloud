/**
 * services/recordIndex.service.js
 * Admin-issued "record indexes" (record_indexes table) — the pool every
 * upload path now claims a record_no from, instead of inventing/free-typing
 * one. Claiming is a simple atomic compare-and-set (`UPDATE ... WHERE
 * status='available'`), not a SELECT...FOR UPDATE/transaction — consistent
 * with this codebase's existing lightweight-concurrency style (e.g. the
 * retry-on-duplicate loops this replaces in batch.service.js/import.service.js).
 *
 * Lifecycle: claim (flips 'available' -> 'used', reserving the slot) happens
 * BEFORE the caller's own document insert, since registerDocument/import's
 * own transaction has no knowledge of this table. If that insert then fails,
 * the caller must call releaseIndex() to give the slot back — callers own
 * that responsibility, this service does not swallow their errors.
 */
const { pool } = require('../config/db');

class NoAvailableIndexError extends Error {
  constructor(typeName) {
    super(`No available record index for "${typeName}" — ask an admin to add more in Settings → Indexing.`);
    this.code = 'NO_AVAILABLE_INDEX';
  }
}

class IndexUnavailableError extends Error {
  constructor() {
    super('That record index is no longer available — pick another.');
    this.code = 'INDEX_UNAVAILABLE';
  }
}

/** Produces `count` unique candidate "TYPECODE-YEAR-NNNN" strings, checked against both record_indexes and legacy documents.record_no. */
async function generateIndexValues(typeCode, count) {
  const year = new Date().getFullYear();
  const values = [];
  let attempts = 0;
  while (values.length < count && attempts < count * 20) {
    attempts += 1;
    const suffix = String(Math.floor(Math.random() * 10000)).padStart(4, '0');
    const candidate = `${typeCode}-${year}-${suffix}`;
    if (values.includes(candidate)) continue; // eslint-disable-line no-continue
    // eslint-disable-next-line no-await-in-loop
    const [[existingIndex]] = await pool.query('SELECT id FROM record_indexes WHERE index_value = ?', [candidate]);
    if (existingIndex) continue; // eslint-disable-line no-continue
    // eslint-disable-next-line no-await-in-loop
    const [[existingDoc]] = await pool.query('SELECT id FROM documents WHERE record_no = ?', [candidate]);
    if (existingDoc) continue; // eslint-disable-line no-continue
    values.push(candidate);
  }
  if (values.length < count) throw new Error(`Could only generate ${values.length}/${count} unique index values — try a smaller count`);
  return values;
}

/** Claims one specific index row by id. Throws IndexUnavailableError if it's not there/available/matching. */
async function claimSpecificIndex({ recordIndexId, documentTypeId, companyId }) {
  const [result] = await pool.query(
    `UPDATE record_indexes SET status = 'used' WHERE id = ? AND company_id = ? AND document_type_id = ? AND status = 'available'`,
    [recordIndexId, companyId, documentTypeId]
  );
  if (result.affectedRows !== 1) throw new IndexUnavailableError();

  const [[row]] = await pool.query('SELECT id, index_value AS indexValue FROM record_indexes WHERE id = ?', [recordIndexId]);
  return row;
}

/** Claims the oldest available index for a type — for unattended paths (Capture & Scan batch, Import) with no human picker. */
async function claimNextAvailable({ documentTypeId, companyId }) {
  for (let attempt = 0; attempt < 5; attempt += 1) {
    // eslint-disable-next-line no-await-in-loop
    const [[candidate]] = await pool.query(
      `SELECT id FROM record_indexes WHERE company_id = ? AND document_type_id = ? AND status = 'available' ORDER BY id LIMIT 1`,
      [companyId, documentTypeId]
    );
    if (!candidate) {
      // eslint-disable-next-line no-await-in-loop
      const [[type]] = await pool.query('SELECT name FROM document_types WHERE id = ?', [documentTypeId]);
      throw new NoAvailableIndexError(type ? type.name : `type #${documentTypeId}`);
    }
    try {
      // eslint-disable-next-line no-await-in-loop
      return await claimSpecificIndex({ recordIndexId: candidate.id, documentTypeId, companyId });
    } catch (err) {
      if (err instanceof IndexUnavailableError) continue; // eslint-disable-line no-continue -- lost a race, try the next one
      throw err;
    }
  }
  throw new IndexUnavailableError();
}

/** Gives a claimed index back to the pool — call from a catch block whenever the downstream document write fails after claiming. */
async function releaseIndex(recordIndexId) {
  if (!recordIndexId) return;
  await pool.query(
    `UPDATE record_indexes SET status = 'available', used_by_document_id = NULL, used_at = NULL WHERE id = ?`,
    [recordIndexId]
  );
}

/** Links a claimed index to the document it ended up on, once that document's row actually exists. */
async function linkIndexToDocument(recordIndexId, documentId) {
  await pool.query(
    `UPDATE record_indexes SET used_by_document_id = ?, used_at = NOW() WHERE id = ?`,
    [documentId, recordIndexId]
  );
}

module.exports = {
  NoAvailableIndexError,
  IndexUnavailableError,
  generateIndexValues,
  claimSpecificIndex,
  claimNextAvailable,
  releaseIndex,
  linkIndexToDocument,
};
