/**
 * scripts/import-postman.js
 * One-off CLI importer: reads a Postman v2.1 collection and populates
 * sandbox_folders / sandbox_requests, so every request in the EDMS
 * Postman collection becomes runnable in the browser sandbox — this is
 * literally how "available on the sandbox, not via Postman" gets built.
 *
 * Run again any time the source collection changes — it's idempotent
 * per collection (wipes and re-imports sandbox_folders/sandbox_requests
 * only; never touches users, keys, logs, or environments).
 *
 * Usage:
 *   node scripts/import-postman.js [path/to/collection.json]
 *   (defaults to postman-source/PSPF_EDMS_API.postman_collection.json)
 */
require('dotenv').config();
const fs = require('fs');
const path = require('path');
const { pool } = require('../config/db');
const endpointDocs = require('./endpoint-docs');

const AUTH_TYPE_MAP = { bearer: 'bearer', noauth: 'none' };

function extractPath(rawUrl) {
  // Postman URLs in this collection look like "{{baseUrl}}/documents/{{documentId}}?q=&status="
  // — strip the {{baseUrl}} variable AND any query string (query params
  // are extracted separately via extractQuery() into their own field,
  // so a request's `path` should be pure path, never carry a literal
  // "?..." — otherwise the sandbox's query-parameter editor has no
  // effect, since the query it's meant to control is already baked
  // into the path string it's supposedly separate from).
  const withoutBase = rawUrl.replace(/^\{\{[^}]+\}\}/, '');
  const withoutQuery = withoutBase.split('?')[0];
  return withoutQuery || '/';
}

function detectAuthType(request) {
  if (request.auth && AUTH_TYPE_MAP[request.auth.type]) {
    if (request.auth.type === 'bearer') {
      const tokenVar = request.auth.bearer?.[0]?.value || '';
      if (tokenVar.includes('mfaToken')) return 'mfa_token';
      return 'bearer';
    }
    return AUTH_TYPE_MAP[request.auth.type];
  }
  // Some MFA requests set the header manually instead of using Postman's `auth` block.
  const headerAuth = (request.header || []).find((h) => h.key.toLowerCase() === 'authorization');
  if (headerAuth && headerAuth.value.includes('mfaToken')) return 'mfa_token';
  if (headerAuth && headerAuth.value.includes('accessToken')) return 'bearer';
  return 'none';
}

function extractHeaders(request) {
  const headers = {};
  for (const h of request.header || []) {
    if (h.disabled) continue;
    if (h.key.toLowerCase() === 'authorization') continue; // handled via auth_type, not a literal default header
    headers[h.key] = h.value;
  }
  return headers;
}

function extractQuery(request) {
  const query = {};
  const params = request.url && request.url.query ? request.url.query : [];
  for (const q of params) {
    if (q.disabled) continue;
    query[q.key] = q.value;
  }
  return query;
}

function extractBody(request) {
  if (!request.body) return { bodyJson: null, hasFileUpload: false };
  if (request.body.mode === 'raw') {
    try {
      return { bodyJson: JSON.parse(request.body.raw), hasFileUpload: false };
    } catch {
      return { bodyJson: null, hasFileUpload: false };
    }
  }
  if (request.body.mode === 'formdata') {
    const hasFileUpload = (request.body.formdata || []).some((f) => f.type === 'file');
    const bodyJson = {};
    for (const f of request.body.formdata || []) {
      if (f.type === 'file') continue;
      bodyJson[f.key] = f.value;
    }
    return { bodyJson, hasFileUpload };
  }
  return { bodyJson: null, hasFileUpload: false };
}

async function importFolder(folderItem, sortOrder) {
  const [result] = await pool.query(
    'INSERT INTO sandbox_folders (name, description, sort_order) VALUES (?, ?, ?)',
    [folderItem.name, folderItem.description || null, sortOrder]
  );
  const folderId = result.insertId;

  let reqSort = 0;
  for (const item of folderItem.item || []) {
    if (item.item) continue; // nested folders: this collection is flat (folder -> requests), skip if ever nested
    const request = item.request;
    if (!request) continue;

    const method = request.method || 'GET';
    const rawUrl = request.url && request.url.raw ? request.url.raw : '';
    const targetPath = extractPath(rawUrl);
    const { bodyJson, hasFileUpload } = extractBody(request);
    const doc = endpointDocs[`${method} ${targetPath}`] || null;
    if (!doc) console.warn(`  ! no documentation entry for ${method} ${targetPath} ("${item.name}") — add one to scripts/endpoint-docs.js`);

    await pool.query(
      `INSERT INTO sandbox_requests
         (folder_id, name, method, path, description, auth_type, default_headers_json, default_query_json, default_body_json, has_file_upload, doc_json, sort_order)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        folderId, item.name, method, targetPath, request.description || null,
        detectAuthType(request), JSON.stringify(extractHeaders(request)), JSON.stringify(extractQuery(request)),
        JSON.stringify(bodyJson), hasFileUpload ? 1 : 0, doc ? JSON.stringify(doc) : null, reqSort,
      ]
    );
    reqSort += 1;
  }
}

async function main() {
  const collectionPath = path.resolve(process.argv[2] || path.join(__dirname, '..', 'postman-source', 'PSPF_EDMS_API.postman_collection.json'));
  if (!fs.existsSync(collectionPath)) {
    console.error(`Collection not found at ${collectionPath}`);
    process.exit(1);
  }
  const collection = JSON.parse(fs.readFileSync(collectionPath, 'utf8'));

  console.log(`Importing "${collection.info.name}" from ${collectionPath} ...`);

  await pool.query('SET FOREIGN_KEY_CHECKS = 0');
  await pool.query('TRUNCATE TABLE sandbox_requests');
  await pool.query('TRUNCATE TABLE sandbox_folders');
  await pool.query('SET FOREIGN_KEY_CHECKS = 1');

  let sortOrder = 0;
  for (const folderItem of collection.item || []) {
    if (!folderItem.item) continue; // top-level loose requests (none expected in this collection) are skipped
    await importFolder(folderItem, sortOrder);
    sortOrder += 1;
    console.log(`  ✓ ${folderItem.name} (${folderItem.item.length} requests)`);
  }

  console.log('Import complete.');
  await pool.end();
}

main().catch((err) => {
  console.error('Import failed:', err);
  process.exit(1);
});
