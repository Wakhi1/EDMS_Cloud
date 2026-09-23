/**
 * scripts/migrate-page-count.js
 * One-off, idempotent migration for a database created before page counts
 * existed: adds document_versions.page_count, then backfills it for every
 * version already stored (download -> decrypt -> count, in memory only).
 * Safe to re-run — it only touches versions whose page_count is still NULL
 * and whose file type can be counted (see services/pageCount.service.js).
 *
 * A fresh install doesn't need the ALTER — database/pspf_edms_schema.sql
 * already declares the column — but the backfill step is harmless there.
 * Run manually:
 *   node scripts/migrate-page-count.js
 * Pass --recount-estimated to also re-count versions whose stored figure is
 * only an estimate (e.g. after pageCount.service.js learns a new format).
 */
require('dotenv').config();
const { pool } = require('../config/db');
const logger = require('../config/logger');
const { envelopeDecryptFile } = require('../services/crypto.service');
const storageService = require('../services/storage/storage.service');
const { countPages, isCountable } = require('../services/pageCount.service');

const RECOUNT_ESTIMATED = process.argv.includes('--recount-estimated');

async function columnExists(table, column) {
  const [[row]] = await pool.query(
    `SELECT COUNT(*) AS n FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?`,
    [table, column]
  );
  return row.n > 0;
}

async function backfill() {
  const [versions] = await pool.query(
    `SELECT dv.id, dv.file_name, dv.mime_type, dso.provider, dso.object_key, dso.is_encrypted,
            dek.wrapped_dek, dek.dek_iv, dek.dek_auth_tag, dek.file_iv, dek.file_auth_tag
     FROM document_versions dv
     JOIN document_storage_objects dso ON dso.id = dv.storage_object_id
     LEFT JOIN document_encryption_keys dek ON dek.document_version_id = dv.id
     WHERE dv.page_count IS NULL${RECOUNT_ESTIMATED ? ' OR dv.page_count_estimated = 1' : ''}`
  );

  let counted = 0;
  let skipped = 0;
  let failed = 0;
  for (const v of versions) {
    if (!isCountable(v.mime_type, v.file_name)) { skipped += 1; continue; } // eslint-disable-line no-continue
    try {
      // eslint-disable-next-line no-await-in-loop
      const fetched = await storageService.downloadEncrypted(v);
      const plaintext = v.is_encrypted
        ? envelopeDecryptFile({
            encryptedFile: fetched,
            fileIv: v.file_iv,
            fileAuthTag: v.file_auth_tag,
            wrappedDek: v.wrapped_dek,
            dekIv: v.dek_iv,
            dekAuthTag: v.dek_auth_tag,
          })
        : fetched;
      // eslint-disable-next-line no-await-in-loop
      const pages = await countPages(plaintext, v.mime_type, v.file_name);
      if (pages.count == null) { failed += 1; continue; } // eslint-disable-line no-continue
      // eslint-disable-next-line no-await-in-loop
      await pool.query('UPDATE document_versions SET page_count = ?, page_count_estimated = ? WHERE id = ?', [pages.count, pages.estimated ? 1 : 0, v.id]);
      counted += 1;
    } catch (err) {
      failed += 1;
      logger.warn('Page-count backfill failed for a version', { versionId: v.id, fileName: v.file_name, error: err.message });
    }
  }
  logger.info('Page-count backfill finished', { total: versions.length, counted, skippedUncountableType: skipped, failed });
}

async function run() {
  if (!(await columnExists('document_versions', 'page_count'))) {
    await pool.query('ALTER TABLE document_versions ADD COLUMN page_count INT UNSIGNED NULL AFTER size_bytes');
    logger.info('Added document_versions.page_count');
  }
  if (!(await columnExists('document_versions', 'page_count_estimated'))) {
    await pool.query('ALTER TABLE document_versions ADD COLUMN page_count_estimated TINYINT(1) NOT NULL DEFAULT 0 AFTER page_count');
    logger.info('Added document_versions.page_count_estimated');
  }

  await backfill();

  logger.info('migrate-page-count: done');
  process.exit(0);
}

run().catch((err) => {
  logger.error('migrate-page-count failed', { error: err.message });
  process.exit(1);
});
