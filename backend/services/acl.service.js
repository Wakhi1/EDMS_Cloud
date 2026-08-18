/**
 * services/acl.service.js
 * Enforces the per-folder/per-document ACL (document_acl) that
 * routes/permissions.routes.js lets a System Administrator grant/revoke —
 * previously write-only, never consulted by any route that actually lists
 * or serves folder/document data.
 *
 * Default-allow, ACL-narrows-role: callers must already pass the coarse
 * role x module gate (requireModuleAccess) — this only narrows further,
 * and only for targets that actually have an applicable ACL row somewhere
 * in their chain. A folder/document with zero ACL rows (its own, or any
 * ancestor folder's) stays visible to anyone with role access, matching
 * pre-enforcement behaviour.
 */
const { pool } = require('../config/db');

const LEVEL_RANK = { view: 1, comment: 2, edit: 3, approve: 4, full_control: 5 };

async function groupIdsFor(userId) {
  const [rows] = await pool.query('SELECT group_id FROM group_members WHERE user_id = ?', [userId]);
  return rows.map((r) => r.group_id);
}

/** A folder's own id plus every ancestor's, via the materialised `path` column. */
async function folderChainIds(folderId) {
  const [[folder]] = await pool.query('SELECT id, path FROM folders WHERE id = ?', [folderId]);
  if (!folder) return [];
  const [ancestors] = await pool.query(
    `SELECT id FROM folders WHERE ? LIKE CONCAT(path, ' / %')`,
    [folder.path]
  );
  return [folder.id, ...ancestors.map((a) => a.id)];
}

/** Every document_acl row that could apply to this target: its own, plus (for a document) its folder chain's. */
async function applicableAclRows(targetType, targetId) {
  if (targetType === 'folder') {
    const chain = await folderChainIds(targetId);
    if (!chain.length) return [];
    const [rows] = await pool.query(
      `SELECT * FROM document_acl WHERE target_type = 'folder' AND target_id IN (?)`,
      [chain]
    );
    return rows;
  }

  const [[doc]] = await pool.query('SELECT folder_id FROM documents WHERE id = ?', [targetId]);
  const folderChain = doc ? await folderChainIds(doc.folder_id) : [];
  const [rows] = await pool.query(
    `SELECT * FROM document_acl
     WHERE (target_type = 'document' AND target_id = ?)
        OR (target_type = 'folder' AND target_id IN (?))`,
    [targetId, folderChain.length ? folderChain : [0]]
  );
  return rows;
}

/**
 * Does this user meet at least `minLevel` on this target? System
 * Administrator always bypasses (never locked out of records it
 * administers/audits). Does NOT check role/module access — that's still
 * requireModuleAccess()'s job upstream of this.
 */
async function hasAccess(userId, userRole, targetType, targetId, minLevel = 'view') {
  if (userRole === 'System Administrator') return true;

  const rows = await applicableAclRows(targetType, targetId);
  if (!rows.length) return true;

  const groupIds = await groupIdsFor(userId);
  const minRank = LEVEL_RANK[minLevel];
  return rows.some((r) => {
    const isPrincipal = (r.principal_type === 'user' && r.principal_id === userId)
      || (r.principal_type === 'group' && groupIds.includes(r.principal_id));
    return isPrincipal && LEVEL_RANK[r.permission_level] >= minRank;
  });
}

/** Filters a list of rows (each with an `idField` holding the target's id) down to what the user can view. */
async function filterAccessible(userId, userRole, targetType, rows, idField = 'id') {
  if (userRole === 'System Administrator' || !rows.length) return rows;

  const allowed = await Promise.all(
    rows.map((row) => hasAccess(userId, userRole, targetType, row[idField], 'view'))
  );
  return rows.filter((_, i) => allowed[i]);
}

module.exports = { LEVEL_RANK, hasAccess, filterAccessible };
