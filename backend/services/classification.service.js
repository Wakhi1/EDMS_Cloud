/**
 * services/classification.service.js
 * Heuristic "smart" classification — plain keyword/regex matching against
 * extracted OCR text, not ML. Shared by documents.routes.js's
 * POST /ocr-preview (suggestions a human reviews before committing) and
 * services/capture/batch.service.js (auto-classification for batch/
 * automated intake, where no human reviews each file). Keep in sync with
 * the document_types seed (database/pspf_edms_schema.sql): PC=Claim-
 * Retirement, IH=Claim-Ill Health, CS=Contribution Statement,
 * PV=Payout Voucher, MS=Member Statement.
 */
const { pool } = require('../config/db');

const MEMBER_NUMBER_PATTERN = /\b\d{2}-\d{3}-\d{4}\b/;
const TYPE_KEYWORDS = [
  { code: 'IH', keywords: ['ILL HEALTH', 'ILL-HEALTH'] },
  { code: 'PC', keywords: ['RETIREMENT'] },
  { code: 'CS', keywords: ['CONTRIBUTION'] },
  { code: 'PV', keywords: ['PAYOUT', 'VOUCHER'] },
  { code: 'MS', keywords: ['MEMBER STATEMENT'] },
];
const DEFAULT_TYPE_CODE = 'CS';

function suggestMemberNumber(text) {
  if (!text) return null;
  const match = text.match(MEMBER_NUMBER_PATTERN);
  return match ? match[0] : null;
}

function suggestDocumentTypeCode(text) {
  if (!text) return null;
  const upper = text.toUpperCase();
  const hit = TYPE_KEYWORDS.find(({ keywords }) => keywords.some((kw) => upper.includes(kw)));
  return hit ? hit.code : null;
}

/** Resolves a document_types.code to its id, falling back to DEFAULT_TYPE_CODE when unrecognised/absent. */
async function resolveDocumentTypeId(code) {
  const [[type]] = await pool.query('SELECT id FROM document_types WHERE code = ?', [code || DEFAULT_TYPE_CODE]);
  if (type) return type.id;
  const [[fallback]] = await pool.query('SELECT id FROM document_types WHERE code = ?', [DEFAULT_TYPE_CODE]);
  return fallback ? fallback.id : null;
}

module.exports = { suggestMemberNumber, suggestDocumentTypeCode, resolveDocumentTypeId };
