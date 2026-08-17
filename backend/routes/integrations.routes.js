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

const router = express.Router();
router.use(authenticate);

const STORAGE_IDS = Object.keys(STORAGE_PROVIDERS);

function testerFor(id) {
  if (STORAGE_PROVIDERS[id]) return () => STORAGE_PROVIDERS[id].testConnection();
  if (INTAKE_CONNECTORS[id]) return (config) => INTAKE_CONNECTORS[id].testConnection(config || {});
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
    `INSERT INTO system_settings (setting_key, setting_value) VALUES ('active_storage_provider', ?)
     ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value)`,
    [provider]
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
    'INSERT INTO integrations (id, name, description, endpoint, status) VALUES (?, ?, ?, ?, ?)',
    [id, name, description || null, endpoint || null, status || 'disconnected']
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
  const { name, description, status, endpoint, configJson } = req.body;
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

  const listing = await provider.list(req.query.prefix || '');
  return ok(res, listing);
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

module.exports = router;
