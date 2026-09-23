/**
 * routes/dashboard.routes.js
 * GET /api/dashboard/summary — one call behind the Dashboard's headline
 * figures, shaped by the caller's role (RBAC) rather than gated as a whole:
 *
 *   documents  (needs 'repository' view) — ACL-filtered like Repository's own
 *              list: live total, counts for every status, top document types,
 *              files (all versions), pages and bytes of current versions,
 *              records created by me / this month.
 *   folders    (needs 'repository' view) — accessible folder count, top-level
 *              and empty folders.
 *   storage    (needs 'reports' or 'settings' view) — used bytes/objects per
 *              storage location against its configured capacity
 *              (storage_capacity_bytes_<provider>; '0' = not set, local disk
 *              then falls back to the size of the disk it lives on).
 *
 * A section the role can't see comes back as null and is listed in
 * `access`, so the client hides it instead of showing an error.
 */
const express = require('express');
const fs = require('fs');
const path = require('path');
const { pool } = require('../config/db');
const { ok } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');
const { authenticate } = require('../middleware/auth.middleware');
const { getSetting, getSettingInt } = require('../services/settings.service');
const aclService = require('../services/acl.service');

const router = express.Router();
router.use(authenticate);

const STATUSES = ['draft', 'pending_approval', 'approved', 'rejected', 'declared_final', 'archived', 'disposed'];
const NOT_LIVE = new Set(['archived', 'disposed']);
const PROVIDER_NAMES = { local: 'Local disk', aws_s3: 'AWS S3', azure_blob: 'Azure Blob', gcp_storage: 'Google Cloud Storage' };

async function viewableModules(user) {
  const [rows] = await pool.query(
    'SELECT module FROM role_module_permissions WHERE company_id = ? AND role_id = ? AND can_view = 1',
    [user.companyId, user.roleId]
  );
  return new Set(rows.map((r) => r.module));
}

async function documentsSection(user) {
  const [rows] = await pool.query(
    `SELECT d.id, d.status, d.created_by, d.created_at, d.current_version_id, dt.name AS type_name
     FROM documents d JOIN document_types dt ON dt.id = d.document_type_id
     WHERE d.company_id = ?`,
    [user.companyId]
  );
  const docs = await aclService.filterAccessible(user.id, user.role, 'document', rows);

  const byStatus = new Map(STATUSES.map((s) => [s, 0]));
  const byType = new Map();
  const monthStart = new Date();
  monthStart.setDate(1);
  monthStart.setHours(0, 0, 0, 0);
  let live = 0;
  let mine = 0;
  let thisMonth = 0;
  for (const d of docs) {
    byStatus.set(d.status, (byStatus.get(d.status) || 0) + 1);
    if (NOT_LIVE.has(d.status)) continue; // eslint-disable-line no-continue
    live += 1;
    byType.set(d.type_name, (byType.get(d.type_name) || 0) + 1);
    if (d.created_by === user.id) mine += 1;
    if (new Date(d.created_at) >= monthStart) thisMonth += 1;
  }

  const files = { fileCount: 0, currentFileCount: 0, pageCount: 0, pagesEstimated: false, uncountedFiles: 0, currentBytes: 0 };
  const liveIds = docs.filter((d) => !NOT_LIVE.has(d.status)).map((d) => d.id);
  if (docs.length) {
    const [[all]] = await pool.query('SELECT COUNT(*) AS n FROM document_versions WHERE document_id IN (?)', [docs.map((d) => d.id)]);
    files.fileCount = Number(all.n);
  }
  if (liveIds.length) {
    const [[cur]] = await pool.query(
      `SELECT COUNT(*) AS n, COALESCE(SUM(dv.page_count), 0) AS pages, COALESCE(SUM(dv.size_bytes), 0) AS bytes,
              SUM(dv.page_count IS NULL) AS uncounted, MAX(dv.page_count_estimated) AS estimated
       FROM documents d JOIN document_versions dv ON dv.id = d.current_version_id
       WHERE d.id IN (?)`,
      [liveIds]
    );
    Object.assign(files, {
      currentFileCount: Number(cur.n),
      pageCount: Number(cur.pages),
      currentBytes: Number(cur.bytes),
      uncountedFiles: Number(cur.uncounted || 0),
      pagesEstimated: Boolean(Number(cur.estimated || 0)),
    });
  }

  return {
    total: docs.length,
    live,
    mine,
    createdThisMonth: thisMonth,
    byStatus: [...byStatus.entries()].map(([status, total]) => ({ status, total })),
    byType: [...byType.entries()].map(([label, total]) => ({ label, total })).sort((a, b) => b.total - a.total).slice(0, 8),
    ...files,
  };
}

async function foldersSection(user) {
  const [rows] = await pool.query(
    `SELECT f.id, f.parent_id,
            (SELECT COUNT(*) FROM documents d WHERE d.folder_id = f.id AND d.status NOT IN ('archived','disposed')) AS docs,
            (SELECT COUNT(*) FROM folders c WHERE c.parent_id = f.id) AS children
     FROM folders f WHERE f.company_id = ?`,
    [user.companyId]
  );
  const folders = await aclService.filterAccessible(user.id, user.role, 'folder', rows);
  return {
    total: folders.length,
    topLevel: folders.filter((f) => f.parent_id == null).length,
    empty: folders.filter((f) => Number(f.docs) === 0 && Number(f.children) === 0).length,
  };
}

/** Size of the disk holding local storage, or 0 when it can't be read. */
async function localDiskBytes() {
  try {
    const stats = await fs.promises.statfs(path.resolve(process.env.LOCAL_STORAGE_PATH || './storage'));
    return Number(stats.blocks) * Number(stats.bsize);
  } catch {
    return 0;
  }
}

async function storageSection(user) {
  const [used] = await pool.query(
    `SELECT provider, COALESCE(SUM(size_bytes), 0) AS usedBytes, COUNT(*) AS objectCount
     FROM document_storage_objects WHERE company_id = ? GROUP BY provider`,
    [user.companyId]
  );
  const [integrations] = await pool.query(
    'SELECT id, name, status FROM integrations WHERE company_id = ? AND id IN (?)',
    [user.companyId, Object.keys(PROVIDER_NAMES)]
  );
  const activeProvider = (await getSetting('active_storage_provider', 'local')) || 'local';
  const usedBy = new Map(used.map((r) => [r.provider, r]));
  const integrationBy = new Map(integrations.map((r) => [r.id, r]));

  const locations = [];
  for (const provider of Object.keys(PROVIDER_NAMES)) {
    const usage = usedBy.get(provider);
    const integration = integrationBy.get(provider);
    const configured = provider === 'local' || (integration && integration.status === 'connected');
    // Only show locations that hold data, are connected, or are the active target.
    if (!usage && !configured && provider !== activeProvider) continue; // eslint-disable-line no-continue
    // eslint-disable-next-line no-await-in-loop
    let capacityBytes = await getSettingInt(`storage_capacity_bytes_${provider}`, 0);
    // eslint-disable-next-line no-await-in-loop
    if (!capacityBytes && provider === 'local') capacityBytes = await localDiskBytes();
    locations.push({
      provider,
      name: PROVIDER_NAMES[provider],
      status: provider === 'local' ? 'connected' : (integration ? integration.status : 'disconnected'),
      active: provider === activeProvider,
      usedBytes: Number(usage ? usage.usedBytes : 0),
      objectCount: Number(usage ? usage.objectCount : 0),
      capacityBytes,
    });
  }

  return {
    usedBytes: locations.reduce((s, l) => s + l.usedBytes, 0),
    objectCount: locations.reduce((s, l) => s + l.objectCount, 0),
    capacityBytes: await getSettingInt('storage_capacity_bytes', 107374182400),
    locations,
  };
}

/** GET /api/dashboard/summary */
router.get('/summary', asyncHandler(async (req, res) => {
  const isAdmin = req.user.role === 'System Administrator';
  const modules = isAdmin ? null : await viewableModules(req.user);
  const can = (...names) => isAdmin || names.some((n) => modules.has(n));

  const access = { documents: can('repository'), folders: can('repository'), storage: can('reports', 'settings') };
  const [documents, folders, storage] = await Promise.all([
    access.documents ? documentsSection(req.user) : null,
    access.folders ? foldersSection(req.user) : null,
    access.storage ? storageSection(req.user) : null,
  ]);
  return ok(res, { access, documents, folders, storage });
}));

module.exports = router;
