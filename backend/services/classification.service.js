/**
 * services/classification.service.js
 * Heuristic "smart" classification — keyword scoring, not ML. Shared by
 * documents.routes.js's POST /ocr-preview (suggestions a human reviews
 * before committing) and services/capture/batch.service.js (auto-
 * classification for batch/automated intake, where no human reviews each
 * file).
 *
 * Every document type configured in the database is a candidate, not just
 * the seeded ones: each type is scored on its own name and code, plus the
 * extra keywords below for the seeded pension types (PC=Claim-Retirement,
 * IH=Claim-Ill Health, CS=Contribution Statement, PV=Payout Voucher,
 * MS=Member Statement). Matches in the file name count for more than
 * matches in the extracted text, since operators usually name files
 * deliberately and OCR text is noisy.
 */
const { pool } = require('../config/db');

const MEMBER_NUMBER_PATTERN = /\b\d{2}-\d{3}-\d{4}\b/;
const EXTRA_KEYWORDS = {
  IH: ['ILL HEALTH', 'ILL-HEALTH', 'MEDICAL BOARD', 'INCAPACITY'],
  PC: ['RETIREMENT', 'PENSION CLAIM', 'RETIREE'],
  CS: ['CONTRIBUTION', 'CONTRIBUTIONS'],
  PV: ['PAYOUT', 'VOUCHER', 'PAYMENT VOUCHER'],
  MS: ['MEMBER STATEMENT', 'BENEFIT STATEMENT'],
};
// Words in a type's name too generic to identify it on their own.
const STOP_WORDS = new Set(['AND', 'THE', 'FOR', 'OF', 'FORM', 'DOCUMENT', 'DOCUMENTS', 'RECORD', 'RECORDS', 'FILE', 'OTHER', 'GENERAL', 'TYPE']);
const UNCLASSIFIED_CODES = ['IMP'];
const DEFAULT_TYPE_CODE = 'CS';
const FILE_NAME_WEIGHT = 3;
const TEXT_WEIGHT = 1;

function suggestMemberNumber(text) {
  if (!text) return null;
  const match = text.match(MEMBER_NUMBER_PATTERN);
  return match ? match[0] : null;
}

/** Upper-cases and turns separators (_ - . /) into spaces so "payout_voucher-01.pdf" reads as words. */
function normalise(text) {
  return ` ${String(text || '').toUpperCase().replace(/[_\-./\\()[\]]+/g, ' ').replace(/\s+/g, ' ')} `;
}

function phraseHits(haystack, phrase) {
  const needle = normalise(phrase).trim();
  if (!needle) return 0;
  const escaped = needle.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  return (haystack.match(new RegExp(`(?<![A-Z0-9])${escaped}(?![A-Z0-9])`, 'g')) || []).length;
}

/** The keyword phrases that identify a document type. */
function keywordsFor(type) {
  const name = normalise(type.name).trim();
  const words = name.split(' ').filter((w) => w.length >= 4 && !STOP_WORDS.has(w));
  return { name, words, extra: EXTRA_KEYWORDS[String(type.code).toUpperCase()] || [] };
}

function scoreType(type, fileName, text) {
  const { name, words, extra } = keywordsFor(type);
  let score = 0;
  for (const [haystack, weight] of [[fileName, FILE_NAME_WEIGHT], [text, TEXT_WEIGHT]]) {
    if (!haystack.trim()) continue; // eslint-disable-line no-continue
    score += weight * 5 * Math.min(phraseHits(haystack, name), 3);
    score += weight * 3 * extra.reduce((sum, kw) => sum + Math.min(phraseHits(haystack, kw), 3), 0);
    score += weight * words.reduce((sum, w) => sum + Math.min(phraseHits(haystack, w), 3), 0);
  }
  // A type code as its own token in the file name (e.g. "PV_2026_0042.pdf").
  if (String(type.code).length >= 2 && phraseHits(fileName, type.code)) score += FILE_NAME_WEIGHT * 4;
  return score;
}

async function loadTypes(companyId) {
  const [types] = companyId
    ? await pool.query('SELECT id, code, name FROM document_types WHERE company_id = ? ORDER BY id', [companyId])
    : await pool.query('SELECT id, code, name FROM document_types ORDER BY id');
  return types;
}

/**
 * Best-matching document type for a file, scored on its name and extracted
 * text. Falls back to the "Imported / Unclassified" type when nothing
 * matches, so an upload is never left without a type.
 * @returns {Promise<{id: number, code: string, name: string, matched: boolean}|null>}
 */
async function suggestDocumentType({ text, fileName, companyId }) {
  const types = await loadTypes(companyId);
  if (!types.length) return null;
  const nameHaystack = normalise(fileName);
  const textHaystack = normalise(text);

  let best = null;
  let bestScore = 0;
  for (const type of types) {
    if (UNCLASSIFIED_CODES.includes(String(type.code).toUpperCase())) continue; // eslint-disable-line no-continue
    const score = scoreType(type, nameHaystack, textHaystack);
    if (score > bestScore) { best = type; bestScore = score; }
  }
  if (best) return { ...best, matched: true };

  const fallback = types.find((t) => UNCLASSIFIED_CODES.includes(String(t.code).toUpperCase()));
  return fallback ? { ...fallback, matched: false } : null;
}

/** Legacy code-only matcher, kept for callers that only have a code-shaped hint. */
function suggestDocumentTypeCode(text) {
  if (!text) return null;
  const haystack = normalise(text);
  const hit = Object.entries(EXTRA_KEYWORDS).find(([, keywords]) => keywords.some((kw) => phraseHits(haystack, kw)));
  return hit ? hit[0] : null;
}

/** Resolves a document_types.code to its id, falling back to DEFAULT_TYPE_CODE when unrecognised/absent. */
async function resolveDocumentTypeId(code) {
  const [[type]] = await pool.query('SELECT id FROM document_types WHERE code = ?', [code || DEFAULT_TYPE_CODE]);
  if (type) return type.id;
  const [[fallback]] = await pool.query('SELECT id FROM document_types WHERE code = ?', [DEFAULT_TYPE_CODE]);
  return fallback ? fallback.id : null;
}

module.exports = { suggestMemberNumber, suggestDocumentType, suggestDocumentTypeCode, resolveDocumentTypeId };
