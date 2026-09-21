/**
 * services/push/webhook.push.js
 * The opposite direction of every other integration in this app: instead
 * of pulling documents in (capture intake) or storing them (storage
 * providers), this POSTs a document-count summary and recent-activity
 * metadata OUT to an admin-configured URL on a schedule. Deliberately
 * metadata-only — never pushes decrypted file content, encryption keys, or
 * anything else sensitive to an arbitrary external endpoint.
 */
const logger = require('../../config/logger');
const { pool } = require('../../config/db');
const { HOME_COMPANY_ID } = require('../license.service');

/**
 * Direct, unfiltered aggregate — this runs as a background job with no
 * acting user, so (unlike reports.routes.js's per-request endpoints) there
 * is no per-row ACL to apply.
 */
async function buildPayload() {
  const [byStatus] = await pool.query(
    'SELECT status, COUNT(*) AS total FROM documents WHERE company_id = ? GROUP BY status',
    [HOME_COMPANY_ID]
  );
  const [byType] = await pool.query(
    `SELECT dt.name AS documentType, COUNT(*) AS total FROM documents d
     JOIN document_types dt ON dt.id = d.document_type_id
     WHERE d.company_id = ? GROUP BY dt.name`,
    [HOME_COMPANY_ID]
  );
  const [recentDocuments] = await pool.query(
    `SELECT d.record_no AS recordNo, d.title, dt.name AS documentType, d.status, d.updated_at AS updatedAt
     FROM documents d JOIN document_types dt ON dt.id = d.document_type_id
     WHERE d.company_id = ? ORDER BY d.updated_at DESC LIMIT 20`,
    [HOME_COMPANY_ID]
  );
  return {
    timestamp: new Date().toISOString(),
    // mysql2 returns COUNT(*) as a string, not a number — coerce before
    // handing it to an external consumer (recurring gotcha in this codebase).
    documentCounts: {
      byStatus: Object.fromEntries(byStatus.map((r) => [r.status, Number(r.total)])),
      byType: Object.fromEntries(byType.map((r) => [r.documentType, Number(r.total)])),
    },
    recentDocuments,
  };
}

function authHeaders(config) {
  return config.authToken ? { Authorization: `Bearer ${config.authToken}` } : {};
}

async function postJson(url, body, config) {
  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', ...authHeaders(config) },
    body: JSON.stringify(body),
  });
  if (!response.ok) {
    const text = await response.text().catch(() => '');
    throw new Error(`Webhook responded ${response.status}${text ? `: ${text.slice(0, 200)}` : ''}`);
  }
  return response;
}

async function push(config) {
  if (!config.url) return { ok: false, message: 'No webhook URL configured' };
  const payload = await buildPayload();
  await postJson(config.url, payload, config);
  return { ok: true, message: `Pushed ${payload.recentDocuments.length} recent record(s) to ${config.url}` };
}

/** "Test connection" — a minimal ping so an admin can verify the URL/auth work without waiting for the real schedule. */
async function testConnection(config) {
  if (!config.url) return { ok: false, message: 'No webhook URL configured' };
  try {
    await postJson(config.url, { test: true, timestamp: new Date().toISOString() }, config);
    return { ok: true, message: `Reached ${config.url}` };
  } catch (err) {
    logger.warn('Webhook test connection failed', { url: config.url, error: err.message });
    return { ok: false, message: err.message };
  }
}

module.exports = { buildPayload, push, testConnection };
