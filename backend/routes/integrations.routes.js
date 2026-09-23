/**
 * routes/integrations.routes.js
 * Full CRUD over connected systems (Active Directory, HRIS, SMTP, SMS, the
 * four storage providers, and the three automated capture-intake
 * connectors), real connection testing dispatched to each provider/
 * connector's own module, the live "active storage provider" switch that
 * services/storage/storage.service.js actually reads, and folder
 * browse/create for storage-type connectors. Capture-batch data itself
 * (list/detail/upload/export) lives in routes/capture.routes.js, not here.
 *
 * Route order matters: literal paths (/storage-location, /storage-options)
 * must be registered before the /:id-shaped routes below them, or Express
 * matches the generic pattern first (bit us once already in
 * permissions.routes.js — same discipline applies here).
 */
const express = require('express');
const { pool } = require('../config/db');
const { ok, fail } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');
const { authenticate } = require('../middleware/auth.middleware');
const { requireModuleAccess, allowRoles } = require('../middleware/rbac.middleware');
const { logAudit } = require('../services/audit.service');
const { providers: STORAGE_PROVIDERS } = require('../services/storage/storage.service');
const emailService = require('../services/email.service');
const adService = require('../services/ad.service');
const smsService = require('../services/sms.service');
const { CONNECTORS: INTAKE_CONNECTORS, rescheduleConnector, parseConfig } = require('../services/capture/scheduler');
const { PUSH_CONNECTORS, reschedulePushConnector } = require('../services/push/scheduler');
const { importFromStorage, isImportable, registeredKeys } = require('../services/import.service');

const { PERMISSION_LEVELS, PRINCIPAL_TYPES } = require('../config/constants');

// Top-level areas this app writes its own (encrypted) objects into.
const SYSTEM_STORAGE_FOLDERS = ['documents', 'system-backups'];
const MAX_REGISTER_DEPTH = 8;

const router = express.Router();
router.use(authenticate);

const STORAGE_IDS = Object.keys(STORAGE_PROVIDERS);

/** Which config_json field(s) each integration treats as secret — see PUT /:id's blank-preserves-current merge below. */
const SECRET_FIELDS = {
  ftp: ['password'],
  email_intake: ['password'],
  smtp: ['password'],
  aws_s3: ['secretAccessKey'],
  azure_blob: ['connectionString'],
  gcp_storage: ['serviceAccountJson'],
  webhook: ['authToken'],
};

function testerFor(id) {
  if (STORAGE_PROVIDERS[id]) return () => STORAGE_PROVIDERS[id].testConnection();
  if (INTAKE_CONNECTORS[id]) return (config) => INTAKE_CONNECTORS[id].testConnection(config || {});
  if (PUSH_CONNECTORS[id]) return (config) => PUSH_CONNECTORS[id].testConnection(config || {});
  if (id === 'smtp') return emailService.verifyTransport;
  if (id === 'ad') return (config) => adService.testConnection(config || {});
  if (id === 'sms') return smsService.testConnection;
  return null;
}

/** GET /api/integrations/storage-location — the provider new uploads go to. */
router.get('/storage-location', requireModuleAccess('capture'), asyncHandler(async (req, res) => {
  const [[row]] = await pool.query("SELECT setting_value FROM system_settings WHERE setting_key = 'active_storage_provider'");
  return ok(res, { provider: row?.setting_value || process.env.ACTIVE_STORAGE_PROVIDER || 'local' });
}));

/**
 * GET /api/integrations/storage-options — id+name only for the four
 * storage-type connectors, deliberately narrower than GET / (which
 * includes config_json/endpoint — not safe to expose beyond
 * System Administrator). Lets Smart Upload's storage-location picker show
 * real integration names without broadening access to sensitive config.
 */
router.get('/storage-options', requireModuleAccess('capture'), asyncHandler(async (req, res) => {
  const [rows] = await pool.query(
    `SELECT id, name FROM integrations WHERE id IN (?) ORDER BY name`,
    [STORAGE_IDS]
  );
  return ok(res, rows);
}));

/** PUT /api/integrations/storage-location — switch which provider new uploads go to. */
router.put('/storage-location', allowRoles('System Administrator'), asyncHandler(async (req, res) => {
  const { provider } = req.body;
  if (!STORAGE_IDS.includes(provider)) return fail(res, `Invalid storage provider "${provider}"`, 400);

  const [[row]] = await pool.query('SELECT id FROM integrations WHERE id = ?', [provider]);
  if (!row) return fail(res, 'Integration not found', 404);

  await pool.query(
    `INSERT INTO system_settings (company_id, setting_key, setting_value) VALUES (?, 'active_storage_provider', ?)
     ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value)`,
    [req.user.companyId, provider]
  );
  await logAudit({ userId: req.user.id, action: 'Integration', recordType: 'integration', recordId: provider, detail: 'Set as active storage provider', ip: req.ip });
  return ok(res, { provider }, 'Storage location updated');
}));

/** GET /api/integrations */
router.get('/', requireModuleAccess('integrations'), asyncHandler(async (req, res) => {
  const [rows] = await pool.query('SELECT * FROM integrations ORDER BY name');
  return ok(res, rows);
}));

/** POST /api/integrations — register a new integration entry. */
router.post('/', allowRoles('System Administrator'), asyncHandler(async (req, res) => {
  const { id, name, description, endpoint, status } = req.body;
  if (!id || !name) return fail(res, 'id and name are required', 400);

  const [[existing]] = await pool.query('SELECT id FROM integrations WHERE id = ?', [id]);
  if (existing) return fail(res, `Integration "${id}" already exists`, 409);

  await pool.query(
    'INSERT INTO integrations (company_id, id, name, description, endpoint, status) VALUES (?, ?, ?, ?, ?, ?)',
    [req.user.companyId, id, name, description || null, endpoint || null, status || 'disconnected']
  );
  await logAudit({ userId: req.user.id, action: 'Integration', recordType: 'integration', recordId: id, detail: 'Created', ip: req.ip });
  return ok(res, { id }, 'Integration created', 201);
}));

/**
 * PUT /api/integrations/:id — System Administrator toggles/reconfigures an
 * integration. If it's one of the automated intake connectors and
 * config_json changed, its poller is restarted immediately with the new
 * settings/interval/enabled flag — no server restart needed.
 */
router.put('/:id', allowRoles('System Administrator'), asyncHandler(async (req, res) => {
  const { name, description, status, endpoint } = req.body;
  let { configJson } = req.body;

  // Every secret-bearing field across these integrations is edited via a
  // blank-by-default "leave blank to keep the current value" TextField, and
  // the client OMITS that key entirely from configJson when the field was
  // left untouched (see edit_integration_dialog.dart's _buildXConfigJson
  // methods) — so the merge below only fires when the key is genuinely
  // *absent*. Checking falsiness instead of absence was a real bug: a
  // caller that explicitly sends an empty string meaning "clear this
  // secret" would have had the old value silently re-merged back in,
  // making a stored secret permanently un-clearable through this route —
  // confirmed live when a placeholder AWS secretAccessKey survived an
  // explicit clear attempt and broke the real (env-configured) S3 access
  // until fixed directly in the DB. Every other configJson key still gets
  // a full replace, same as before.
  const secretFields = SECRET_FIELDS[req.params.id] || [];
  if (configJson && secretFields.some((field) => configJson[field] === undefined)) {
    const [[existing]] = await pool.query('SELECT config_json FROM integrations WHERE id = ?', [req.params.id]);
    if (existing && existing.config_json) {
      const existingConfig = typeof existing.config_json === 'object' ? existing.config_json : JSON.parse(existing.config_json);
      for (const field of secretFields) {
        if (configJson[field] === undefined && existingConfig[field]) configJson = { ...configJson, [field]: existingConfig[field] };
      }
    }
  }

  const [result] = await pool.query(
    `UPDATE integrations SET
       name = COALESCE(?, name), description = COALESCE(?, description),
       status = COALESCE(?, status), endpoint = COALESCE(?, endpoint),
       config_json = COALESCE(?, config_json), last_sync_at = NOW()
     WHERE id = ?`,
    [name || null, description || null, status || null, endpoint || null, configJson ? JSON.stringify(configJson) : null, req.params.id]
  );
  if (!result.affectedRows) return fail(res, 'Integration not found', 404);

  if (configJson && INTAKE_CONNECTORS[req.params.id]) {
    await rescheduleConnector(req.params.id);
  }
  if (configJson && PUSH_CONNECTORS[req.params.id]) {
    await reschedulePushConnector(req.params.id);
  }

  await logAudit({ userId: req.user.id, action: 'Integration', recordType: 'integration', recordId: req.params.id, detail: status, ip: req.ip });
  return ok(res, null, 'Integration updated');
}));

/** DELETE /api/integrations/:id */
router.delete('/:id', allowRoles('System Administrator'), asyncHandler(async (req, res) => {
  const [[setting]] = await pool.query("SELECT setting_value FROM system_settings WHERE setting_key = 'active_storage_provider'");
  const activeProvider = setting?.setting_value || process.env.ACTIVE_STORAGE_PROVIDER || 'local';
  if (req.params.id === activeProvider) {
    return fail(res, 'Cannot delete the integration that is currently the active storage provider', 400);
  }

  const [result] = await pool.query('DELETE FROM integrations WHERE id = ?', [req.params.id]);
  if (!result.affectedRows) return fail(res, 'Integration not found', 404);

  await logAudit({ userId: req.user.id, action: 'Integration', recordType: 'integration', recordId: req.params.id, detail: 'Deleted', ip: req.ip });
  return ok(res, null, 'Integration deleted');
}));

/** POST /api/integrations/:id/test — real connection check, persists the result. */
router.post('/:id/test', allowRoles('System Administrator'), asyncHandler(async (req, res) => {
  const [[row]] = await pool.query('SELECT id, config_json FROM integrations WHERE id = ?', [req.params.id]);
  if (!row) return fail(res, 'Integration not found', 404);

  const tester = testerFor(req.params.id);
  if (!tester) {
    return ok(res, { ok: false, message: 'No live connection test available for this connector yet.' });
  }

  const result = await tester(parseConfig(row.config_json));
  await pool.query(
    'UPDATE integrations SET status = ?, last_sync_at = NOW() WHERE id = ?',
    [result.ok ? 'connected' : 'error', req.params.id]
  );
  await logAudit({ userId: req.user.id, action: 'Integration', recordType: 'integration', recordId: req.params.id, detail: `Test connection: ${result.message}`, ip: req.ip });
  return ok(res, result);
}));

/**
 * GET /api/integrations/:id/browse?prefix= — list folders/files for a
 * storage-type connector. Gated on 'capture' rather than 'integrations':
 * this only ever returns folder *names* within the storage backend (no
 * document content), and Smart Upload needs it to let a Records Officer
 * pick/create a folder to upload into — the same role that can already
 * upload documents. System Administrator keeps access either way (it
 * already has 'capture').
 */
router.get('/:id/browse', requireModuleAccess('capture'), asyncHandler(async (req, res) => {
  const provider = STORAGE_PROVIDERS[req.params.id];
  if (!provider) return fail(res, `"${req.params.id}" is not a browsable storage connector`, 400);

  const prefix = (req.query.prefix || '').replace(/\/+$/, '');
  const listing = await provider.list(prefix);
  // Hide placeholders and this app's own encrypted objects; flag the app's
  // system areas at the root so they aren't mistaken for foreign content.
  const files = listing.files.filter(isImportable);
  const keyFor = (name) => (prefix ? `${prefix}/${name}` : name);
  const registered = await registeredKeys(req.params.id, files.map(keyFor));
  const [folderRows] = await pool.query(
    'SELECT id, path, storage_prefix FROM folders WHERE company_id = ? AND storage_provider_id = ? AND storage_prefix IS NOT NULL',
    [req.user.companyId, req.params.id]
  );
  const folderByPrefix = new Map(folderRows.map((f) => [f.storage_prefix.replace(/\/+$/, ''), f]));

  return ok(res, {
    folders: listing.folders,
    files,
    systemFolders: prefix ? [] : listing.folders.filter((f) => SYSTEM_STORAGE_FOLDERS.includes(f)),
    registeredFiles: files
      .filter((name) => registered.has(keyFor(name)))
      .map((name) => ({ name, ...registered.get(keyFor(name)) })),
    registeredFolders: listing.folders
      .filter((name) => folderByPrefix.has(keyFor(name)))
      .map((name) => ({ name, folderId: folderByPrefix.get(keyFor(name)).id, path: folderByPrefix.get(keyFor(name)).path })),
    currentFolder: folderByPrefix.has(prefix) ? { folderId: folderByPrefix.get(prefix).id, path: folderByPrefix.get(prefix).path } : null,
  });
}));

/**
 * POST /api/integrations/:id/register — makes an existing storage folder
 * appear in the Repository: creates (or reuses) a Repository folder named
 * after it, linked to that storage location, and imports its files with
 * auto-detected document types. With `recursive`, subfolders become
 * subfolders the same way. System-Administrator-only, like /import.
 * Body: { prefix, parentFolderId?, recursive?, documentTypeId?, classification? }
 */
router.post('/:id/register', allowRoles('System Administrator'), asyncHandler(async (req, res) => {
  const provider = STORAGE_PROVIDERS[req.params.id];
  if (!provider) return fail(res, `"${req.params.id}" is not a browsable storage connector`, 400);

  const { parentFolderId, recursive, documentTypeId, classification } = req.body;
  const rootPrefix = String(req.body.prefix || '').replace(/^\/+|\/+$/g, '');
  if (!rootPrefix) return fail(res, 'Choose a folder inside the storage location to register', 400);

  let parentPath = null;
  if (parentFolderId) {
    const [[parent]] = await pool.query('SELECT path FROM folders WHERE id = ? AND company_id = ?', [parentFolderId, req.user.companyId]);
    if (!parent) return fail(res, 'Parent folder not found', 404);
    parentPath = parent.path;
  }

  const summary = { folders: [], imported: 0, skipped: [] };

  async function registerOne(prefix, parentId, parentFolderPath, depth) {
    const name = prefix.split('/').pop();
    const path = parentFolderPath ? `${parentFolderPath} / ${name}` : name;
    const [[existing]] = await pool.query('SELECT id FROM folders WHERE company_id = ? AND path = ?', [req.user.companyId, path]);
    let folderId;
    if (existing) {
      folderId = existing.id;
      await pool.query('UPDATE folders SET storage_provider_id = ?, storage_prefix = ? WHERE id = ?', [req.params.id, prefix, folderId]);
    } else {
      const [result] = await pool.query(
        `INSERT INTO folders (company_id, parent_id, name, path, storage_provider_id, storage_prefix, created_by)
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [req.user.companyId, parentId || null, name, path, req.params.id, prefix, req.user.id]
      );
      folderId = result.insertId;
      await logAudit({ userId: req.user.id, action: 'Create', recordType: 'folder', recordId: folderId, detail: `${path} (registered from ${req.params.id}:${prefix})`, ip: req.ip });
    }
    summary.folders.push({ folderId, path, prefix });

    const { imported, skipped } = await importFromStorage({
      providerId: req.params.id, prefix, folderId, documentTypeId: documentTypeId || null, classification,
      userId: req.user.id, ip: req.ip,
    });
    summary.imported += imported.length;
    summary.skipped.push(...skipped.map((s) => ({ ...s, folder: path })));

    if (recursive && depth < MAX_REGISTER_DEPTH) {
      const { folders } = await provider.list(prefix);
      for (const child of folders) {
        // eslint-disable-next-line no-await-in-loop
        await registerOne(`${prefix}/${child}`, folderId, path, depth + 1);
      }
    }
  }

  await registerOne(rootPrefix, parentFolderId || null, parentPath, 0);
  await logAudit({
    userId: req.user.id, action: 'Integration', recordType: 'integration', recordId: req.params.id,
    detail: `Registered ${req.params.id}:${rootPrefix} — ${summary.folders.length} folder(s), ${summary.imported} file(s)`, ip: req.ip,
  });
  return ok(res, summary, `Registered ${summary.folders.length} folder(s) and ${summary.imported} file(s)`, 201);
}));

/** POST /api/integrations/:id/folders — create a folder for a storage-type connector. See GET /browse above for the RBAC rationale. */
router.post('/:id/folders', requireModuleAccess('capture', true), asyncHandler(async (req, res) => {
  const provider = STORAGE_PROVIDERS[req.params.id];
  if (!provider) return fail(res, `"${req.params.id}" is not a browsable storage connector`, 400);

  const { prefix, name } = req.body;
  if (!name || !name.trim()) return fail(res, 'Folder name is required', 400);

  const fullPrefix = prefix ? `${prefix.replace(/\/+$/, '')}/${name.trim()}` : name.trim();
  await provider.createFolder(fullPrefix);
  await logAudit({ userId: req.user.id, action: 'Integration', recordType: 'integration', recordId: req.params.id, detail: `Created folder: ${fullPrefix}`, ip: req.ip });
  return ok(res, { prefix: fullPrefix }, 'Folder created', 201);
}));

/**
 * POST /api/integrations/:id/import — brings content that already exists
 * in a storage-type connector (never uploaded through this app) into the
 * Repository: real documents.folders rows, OCR'd and checksummed, so
 * Search/filters/document_acl all apply exactly like any uploaded record.
 * Non-recursive — only files directly under `prefix`; subfolders need a
 * separate import call. System-Administrator-only (unlike GET /browse and
 * POST /folders above): this is the action that decides default
 * classification and default access for a whole batch of records at once,
 * a governance decision, not a day-to-day upload one.
 */
router.post('/:id/import', allowRoles('System Administrator'), asyncHandler(async (req, res) => {
  const provider = STORAGE_PROVIDERS[req.params.id];
  if (!provider) return fail(res, `"${req.params.id}" is not a browsable storage connector`, 400);

  const {
    prefix, folderId, documentTypeId, classification, departmentId, retentionClassId, defaultAccess,
  } = req.body;
  if (!folderId) return fail(res, 'folderId is required', 400);
  if (!documentTypeId) return fail(res, 'documentTypeId is required', 400);

  const [[folder]] = await pool.query('SELECT id FROM folders WHERE id = ?', [folderId]);
  if (!folder) return fail(res, 'Unknown destination folder', 400);

  const { imported, skipped } = await importFromStorage({
    providerId: req.params.id,
    prefix: prefix || '',
    folderId,
    documentTypeId,
    classification,
    departmentId,
    retentionClassId,
    userId: req.user.id,
    ip: req.ip,
  });

  if (defaultAccess?.restricted && Array.isArray(defaultAccess.grants) && defaultAccess.grants.length) {
    for (const grant of defaultAccess.grants) {
      if (!PRINCIPAL_TYPES.includes(grant.principalType) || !PERMISSION_LEVELS.includes(grant.permissionLevel) || !grant.principalId) {
        continue; // eslint-disable-line no-continue
      }
      // eslint-disable-next-line no-await-in-loop
      await pool.query(
        `INSERT INTO document_acl (company_id, target_type, target_id, principal_type, principal_id, permission_level, granted_by)
         VALUES (?, 'folder', ?, ?, ?, ?, ?)`,
        [req.user.companyId, folderId, grant.principalType, grant.principalId, grant.permissionLevel, req.user.id]
      );
    }
    await logAudit({
      userId: req.user.id, action: 'Permission', recordType: 'folder', recordId: folderId,
      detail: `Default access restricted on import (${defaultAccess.grants.length} grant(s))`, ip: req.ip,
    });
  }

  await logAudit({
    userId: req.user.id, action: 'Integration', recordType: 'integration', recordId: req.params.id,
    detail: `Imported ${imported.length} file(s) from ${prefix || '(root)'} into folder #${folderId}`, ip: req.ip,
  });

  return ok(res, { imported, skipped }, `Imported ${imported.length} of ${imported.length + skipped.length} file(s)`, 201);
}));

module.exports = router;
