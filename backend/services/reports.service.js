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

/**
 * Canonical registry of every KPI/graph section the Reports screen can
 * show — the same keys drive the on-screen "Customize" section picker,
 * saved report_templates.sections, and GET /api/reports/export's
 * ?sections= filter, so all three always agree on what a given key means
 * and an export can never drift from what's selected on screen.
 */
const REPORT_SECTIONS = [
  { key: 'by-status', title: 'Records by status' },
  { key: 'by-department', title: 'Records by department' },
  { key: 'by-category', title: 'Records by category' },
  { key: 'by-folder', title: 'Records by folder (top 15)' },
  { key: 'by-classification', title: 'Records by classification' },
  { key: 'capacity', title: 'Storage capacity' },
  { key: 'captured-over-time', title: 'Records captured over time' },
  { key: 'capture-by-source', title: 'Capture success by source' },
  { key: 'claim-turnaround', title: 'Claim turnaround (avg days)' },
  { key: 'retention-status', title: 'Retention & disposal status' },
  { key: 'overdue-retention', title: 'Overdue for disposal' },
  { key: 'audit-actions', title: 'Audit actions breakdown' },
  { key: 'top-users', title: 'Top audit actors' },
];
const REPORT_SECTION_KEYS = REPORT_SECTIONS.map((s) => s.key);

module.exports = { buildDocumentFilters, REPORT_SECTIONS, REPORT_SECTION_KEYS };
