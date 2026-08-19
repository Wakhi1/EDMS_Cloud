/**
 * routes/sandbox.routes.js
 * The Postman replacement. Three concerns:
 *   1. Catalog  — GET the folder/request tree imported from the EDMS
 *      Postman collection (see scripts/import-postman.js). Any signed-in
 *      approved user can browse it.
 *   2. Variables — a small per-user key/value store (baseUrl override,
 *      accessToken, documentId, ...). The BROWSER does {{substitution}}
 *      before sending — the server never evaluates arbitrary script,
 *      unlike a Postman "test script", which keeps this safe to expose
 *      to untrusted developer accounts.
 *   3. Execute — the actual proxy. Requires a valid, admin-issued
 *      X-Api-Key (see apiKey.middleware). The destination host is NEVER
 *      taken from the client — only `environmentId` is, which is
 *      resolved server-side against admin-managed sandbox_environments
 *      rows. That's what stops this from being an open proxy.
 */
const express = require('express');
const { body, validationResult } = require('express-validator');

const { pool } = require('../config/db');
const { ok, fail } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');
const { authenticate, requireApprovedDeveloper } = require('../middleware/auth.middleware');
const { requireApiKey } = require('../middleware/apiKey.middleware');
const upload = require('../middleware/upload.middleware');
const logger = require('../config/logger');

const router = express.Router();
router.use(authenticate, requireApprovedDeveloper);

/** GET /api/sandbox/catalog */
router.get('/catalog', asyncHandler(async (req, res) => {
  const [folders] = await pool.query('SELECT * FROM sandbox_folders ORDER BY sort_order, name');
  const [requests] = await pool.query('SELECT * FROM sandbox_requests ORDER BY sort_order, name');

  const grouped = folders.map((f) => ({
    ...f,
    requests: requests.filter((r) => r.folder_id === f.id),
  }));
  return ok(res, grouped);
}));

/** GET /api/sandbox/environments */
router.get('/environments', asyncHandler(async (req, res) => {
  const [rows] = await pool.query('SELECT id, name, base_url, is_default FROM sandbox_environments ORDER BY is_default DESC, name');
  return ok(res, rows);
}));

/** GET /api/sandbox/variables */
router.get('/variables', asyncHandler(async (req, res) => {
  const [rows] = await pool.query('SELECT var_key, var_value FROM sandbox_user_variables WHERE user_id = ?', [req.user.id]);
  const map = Object.fromEntries(rows.map((r) => [r.var_key, r.var_value]));
  return ok(res, map);
}));

/** PUT /api/sandbox/variables — body: { key, value } (upsert one at a time, simplest for autosave-on-blur UX). */
router.put(
  '/variables',
  [body('key').trim().notEmpty()],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    const { key, value } = req.body;
    await pool.query(
      `INSERT INTO sandbox_user_variables (user_id, var_key, var_value) VALUES (?, ?, ?)
       ON DUPLICATE KEY UPDATE var_value = VALUES(var_value)`,
      [req.user.id, key, value ?? null]
    );
    return ok(res, null, 'Saved');
  })
);

/**
 * POST /api/sandbox/execute
 * multipart/form-data with:
 *   meta = JSON.stringify({ environmentId, method, path, headers, query, body, sandboxRequestId })
 *   file = optional binary (for requests like "Register Document")
 * `path`, `headers` values, and `body` values must already have
 * {{variables}} substituted by the caller (the frontend does this).
 */
router.post('/execute', requireApiKey, upload.single('file'), asyncHandler(async (req, res) => {
  let meta;
  try {
    meta = JSON.parse(req.body.meta || '{}');
  } catch {
    return fail(res, 'meta must be valid JSON', 400);
  }

  const { environmentId, method = 'GET', path: targetPath, headers = {}, query = {}, body = null, sandboxRequestId = null, fileFieldName = 'file' } = meta;
  if (!environmentId || !targetPath) return fail(res, 'environmentId and path are required', 400);

  const [[environment]] = await pool.query('SELECT * FROM sandbox_environments WHERE id = ?', [environmentId]);
  if (!environment) return fail(res, 'Unknown sandbox environment', 400);
  if (!targetPath.startsWith('/')) return fail(res, 'path must be relative (e.g. /auth/login)', 400);

  const url = new URL(environment.base_url.replace(/\/$/, '') + targetPath);
  for (const [k, v] of Object.entries(query)) {
    if (v !== undefined && v !== null && v !== '') url.searchParams.set(k, v);
  }

  const outgoingHeaders = { ...headers };
  delete outgoingHeaders['host'];
  delete outgoingHeaders['Host'];
  delete outgoingHeaders['content-length'];

  const fetchOptions = { method, headers: outgoingHeaders };

  if (req.file) {
    const form = new FormData();
    if (body && typeof body === 'object') {
      for (const [k, v] of Object.entries(body)) form.append(k, v === undefined || v === null ? '' : String(v));
    }
    form.append(fileFieldName, new Blob([req.file.buffer], { type: req.file.mimetype }), req.file.originalname);
    fetchOptions.body = form;
    // Let fetch set the correct multipart boundary Content-Type itself.
    delete outgoingHeaders['content-type'];
    delete outgoingHeaders['Content-Type'];
  } else if (body !== null && method !== 'GET' && method !== 'HEAD') {
    fetchOptions.body = JSON.stringify(body);
    if (!outgoingHeaders['Content-Type'] && !outgoingHeaders['content-type']) {
      outgoingHeaders['Content-Type'] = 'application/json';
    }
  }

  const startedAt = Date.now();
  let statusCode = null;
  let responseBody = null;
  let responseHeaders = {};

  try {
    const upstream = await fetch(url.toString(), fetchOptions);
    statusCode = upstream.status;
    upstream.headers.forEach((value, key) => { responseHeaders[key] = value; });

    const text = await upstream.text();
    try {
      responseBody = JSON.parse(text);
    } catch {
      responseBody = text;
    }
  } catch (err) {
    logger.error('Sandbox proxy request failed', { error: err.message, url: url.toString() });
    return fail(res, `Could not reach ${environment.name} (${environment.base_url}) — is that server running?`, 502);
  } finally {
    const durationMs = Date.now() - startedAt;
    await pool.query(
      `INSERT INTO sandbox_request_logs (user_id, api_key_id, environment_id, sandbox_request_id, method, path, status_code, duration_ms)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [req.user.id, req.apiKey.id, environmentId, sandboxRequestId, method, targetPath, statusCode, durationMs]
    );
  }

  return ok(res, {
    status: statusCode,
    headers: responseHeaders,
    body: responseBody,
    request: { method, url: url.toString() },
  });
}));

module.exports = router;
