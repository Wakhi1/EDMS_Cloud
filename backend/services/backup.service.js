/**
 * services/backup.service.js
 * Real database backup/restore, reusing this app's existing envelope-
 * encryption (crypto.service, same AES-256-GCM scheme as documents) and
 * storage abstraction (storage.service, so the archive lands on whatever
 * cloud provider is currently active) rather than inventing a parallel
 * pipeline.
 *
 * mysqldump/mysql are shelled out via spawn() with argument arrays (never
 * a shell string) and the DB password passed through the MYSQL_PWD env var
 * — never as a CLI argument, so it never appears in a process listing.
 * The plaintext SQL dump only ever touches a local temp file for as long
 * as it takes to encrypt it, then is deleted immediately.
 */
const fs = require('fs');
const fsp = require('fs/promises');
const path = require('path');
const { spawn } = require('child_process');

const { pool } = require('../config/db');
const logger = require('../config/logger');
const { logAudit } = require('./audit.service');
const { envelopeEncryptFile, envelopeDecryptFile, sha256 } = require('./crypto.service');
const storageService = require('./storage/storage.service');
const { notifyDepartment } = require('./notifications.service');

const TMP_DIR = process.env.BACKUP_TMP_DIR || './backup-tmp';
const MYSQLDUMP_PATH = process.env.MYSQLDUMP_PATH || 'mysqldump';
const MYSQL_CLI_PATH = process.env.MYSQL_CLI_PATH || 'mysql';

const DB_ARGS = () => [
  `--host=${process.env.DB_HOST || '127.0.0.1'}`,
  `--port=${process.env.DB_PORT || 3306}`,
  `--user=${process.env.DB_USER || 'root'}`,
];

function runToFile(cmd, args, outFilePath) {
  return new Promise((resolve, reject) => {
    const out = fs.createWriteStream(outFilePath);
    const child = spawn(cmd, args, {
      env: { ...process.env, MYSQL_PWD: process.env.DB_PASSWORD || '' },
    });
    let stderr = '';
    child.stdout.pipe(out);
    child.stderr.on('data', (d) => { stderr += d.toString(); });
    child.on('error', reject);
    child.on('close', (code) => {
      out.close();
      if (code === 0) resolve();
      else reject(new Error(`${path.basename(cmd)} exited with code ${code}: ${stderr.slice(0, 500)}`));
    });
  });
}

function runFromFile(cmd, args, inFilePath) {
  return new Promise((resolve, reject) => {
    const input = fs.createReadStream(inFilePath);
    const child = spawn(cmd, args, {
      env: { ...process.env, MYSQL_PWD: process.env.DB_PASSWORD || '' },
    });
    let stderr = '';
    input.pipe(child.stdin);
    child.stderr.on('data', (d) => { stderr += d.toString(); });
    child.on('error', reject);
    child.on('close', (code) => {
      if (code === 0) resolve();
      else reject(new Error(`${path.basename(cmd)} exited with code ${code}: ${stderr.slice(0, 500)}`));
    });
  });
}

/**
 * Dumps the whole database, encrypts it, uploads it to the active storage
 * provider under `system-backups/`, records a `backups` row, and notifies
 * ICT. Returns the backups row id.
 */
async function runBackup({ createdBy, ip }) {
  await fsp.mkdir(TMP_DIR, { recursive: true });
  const dbName = process.env.DB_NAME || 'pspf_edms';
  const stamp = new Date().toISOString().replace(/[:.]/g, '-');
  const tmpFile = path.join(TMP_DIR, `${dbName}-${stamp}.sql`);
  const fileKey = `system-backups/${dbName}-${stamp}.sql.enc`;

  const [insertResult] = await pool.query(
    `INSERT INTO backups (file_key, storage_provider, status, created_by) VALUES (?, 'pending', 'running', ?)`,
    [fileKey, createdBy || null]
  );
  const backupId = insertResult.insertId;

  try {
    await runToFile(
      MYSQLDUMP_PATH,
      [
        ...DB_ARGS(), '--single-transaction', '--routines', '--triggers',
        // `backups` and `audit_log` are operational bookkeeping, not
        // records data — excluding them means a restore can never wipe out
        // the audit trail or the safety-backup row that makes the restore
        // itself undoable (see restoreBackup below).
        `--ignore-table=${dbName}.backups`, `--ignore-table=${dbName}.audit_log`,
        dbName,
      ],
      tmpFile
    );

    const plaintext = await fsp.readFile(tmpFile);
    const enc = envelopeEncryptFile(plaintext);
    const uploadResult = await storageService.uploadEncrypted(fileKey, enc.encryptedFile, 'application/sql');

    await pool.query(
      `UPDATE backups SET
         status = 'completed', size_bytes = ?, storage_provider = ?, completed_at = NOW(),
         wrapped_dek = ?, dek_iv = ?, dek_auth_tag = ?, file_iv = ?, file_auth_tag = ?, checksum_sha256 = ?
       WHERE id = ?`,
      [plaintext.length, uploadResult.provider, enc.wrappedDek, enc.dekIv, enc.dekAuthTag,
       enc.fileIv, enc.fileAuthTag, enc.checksumSha256, backupId]
    );

    await logAudit({ userId: createdBy, action: 'Backup', recordType: 'backup', recordId: backupId, detail: `${fileKey} (${plaintext.length} bytes, ${uploadResult.provider})`, ip });
    await notifyDepartment('ICT', {
      type: 'backup_completed',
      title: 'Database backup completed',
      body: `A new encrypted backup (${fileKey}) was created and pushed to ${uploadResult.provider}.`,
      relatedRecordType: 'backup',
      relatedRecordId: backupId,
    });

    return backupId;
  } catch (err) {
    logger.error('Backup failed', { error: err.message, backupId });
    await pool.query('UPDATE backups SET status = "failed", error_message = ? WHERE id = ?', [err.message.slice(0, 500), backupId]);
    await logAudit({ userId: createdBy, action: 'Backup', recordType: 'backup', recordId: backupId, detail: `FAILED: ${err.message}`, ip });
    await notifyDepartment('ICT', {
      type: 'backup_failed',
      title: 'Database backup failed',
      body: err.message.slice(0, 400),
      relatedRecordType: 'backup',
      relatedRecordId: backupId,
    });
    throw err;
  } finally {
    await fsp.rm(tmpFile, { force: true });
  }
}

/**
 * Genuinely destructive: overwrites the live database with a prior
 * backup's contents. Guardrails: caller must already be gated
 * System-Administrator-only at the route level; confirmationPhrase must
 * exactly match the backup's file_key (typed confirmation, re-checked
 * server-side); an automatic safety backup of the CURRENT state is taken
 * first so the restore itself is undoable via another restore.
 */
async function restoreBackup({ backupId, confirmationPhrase, performedBy, ip }) {
  const [[backup]] = await pool.query('SELECT * FROM backups WHERE id = ?', [backupId]);
  if (!backup) throw new Error('Backup not found');
  if (backup.status !== 'completed') throw new Error('Only a completed backup can be restored');
  if (confirmationPhrase !== backup.file_key) throw new Error('Confirmation phrase does not match this backup\'s file name');

  const [[{ rowsBefore }]] = await pool.query('SELECT COUNT(*) AS rowsBefore FROM documents');

  await logAudit({ userId: performedBy, action: 'Restore', recordType: 'backup', recordId: backupId, detail: `Restore started (safety backup follows)`, ip });
  const safetyBackupId = await runBackup({ createdBy: performedBy, ip });

  await fsp.mkdir(TMP_DIR, { recursive: true });
  const tmpFile = path.join(TMP_DIR, `restore-${Date.now()}.sql`);

  try {
    const encryptedFile = await storageService.downloadEncrypted({ provider: backup.storage_provider, object_key: backup.file_key });
    const plaintext = envelopeDecryptFile({
      encryptedFile,
      fileIv: backup.file_iv,
      fileAuthTag: backup.file_auth_tag,
      wrappedDek: backup.wrapped_dek,
      dekIv: backup.dek_iv,
      dekAuthTag: backup.dek_auth_tag,
    });
    if (sha256(plaintext) !== backup.checksum_sha256) {
      throw new Error('Integrity check failed — decrypted backup does not match its stored checksum');
    }

    await fsp.writeFile(tmpFile, plaintext);
    await runFromFile(MYSQL_CLI_PATH, [...DB_ARGS(), process.env.DB_NAME || 'pspf_edms'], tmpFile);

    const [[{ rowsAfter }]] = await pool.query('SELECT COUNT(*) AS rowsAfter FROM documents');

    await logAudit({
      userId: performedBy, action: 'Restore', recordType: 'backup', recordId: backupId,
      detail: `Restored ${backup.file_key}. documents rows: ${rowsBefore} -> ${rowsAfter}. Safety backup id ${safetyBackupId}.`,
      ip,
    });
    await notifyDepartment('ICT', {
      type: 'restore_completed',
      title: 'Database restore performed',
      body: `${performedBy ? `User ${performedBy}` : 'A System Administrator'} restored backup "${backup.file_key}". A safety backup (id ${safetyBackupId}) of the prior state was taken first.`,
      relatedRecordType: 'backup',
      relatedRecordId: backupId,
    });

    return { rowsBefore, rowsAfter, safetyBackupId };
  } catch (err) {
    await logAudit({ userId: performedBy, action: 'Restore', recordType: 'backup', recordId: backupId, detail: `FAILED: ${err.message}`, ip });
    throw err;
  } finally {
    await fsp.rm(tmpFile, { force: true });
  }
}

module.exports = { runBackup, restoreBackup };
