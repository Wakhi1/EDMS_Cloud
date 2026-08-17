/**
 * services/reports.service.js
 * Shared WHERE-clause builder for every document-based report endpoint in
 * reports.routes.js (by-status, by-department, by-category, by-folder,
 * by-classification, captured-over-time, retention-status) — avoids
 * duplicating the same six-condition filter logic in each handler.
 */

/**
 * @param {object} filters
 * @param {string} [filters.from] - ISO date, inclusive lower bound on d.created_at
 * @param {string} [filters.to] - ISO date, inclusive upper bound on d.created_at
 * @param {string|number} [filters.departmentId]
 * @param {string|number} [filters.documentTypeId]
 * @param {string|number} [filters.folderId]
 * @param {string} [filters.classification]
 * @returns {{where: string, params: any[]}}
 */
function buildDocumentFilters({ from, to, departmentId, documentTypeId, folderId, classification }) {
  const clauses = [];
  const params = [];
  if (from) { clauses.push('d.created_at >= ?'); params.push(from); }
  if (to) { clauses.push('d.created_at <= ?'); params.push(to); }
  if (departmentId) { clauses.push('d.department_id = ?'); params.push(departmentId); }
  if (documentTypeId) { clauses.push('d.document_type_id = ?'); params.push(documentTypeId); }
  if (folderId) { clauses.push('d.folder_id = ?'); params.push(folderId); }
  if (classification) { clauses.push('d.classification = ?'); params.push(classification); }
  return { where: clauses.length ? `WHERE ${clauses.join(' AND ')}` : '', params };
}

module.exports = { buildDocumentFilters };
