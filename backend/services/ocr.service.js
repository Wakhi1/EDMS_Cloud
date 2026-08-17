/**
 * services/ocr.service.js
 * Extracts searchable text from an uploaded file before it's encrypted,
 * so `document_versions.ocr_text` (MEDIUMTEXT, FULLTEXT-indexed — see
 * database/pspf_edms_schema.sql) can be populated. Dispatches by mimetype:
 *
 *   image/*                                              -> Tesseract.js OCR (also yields a confidence score)
 *   application/pdf                                       -> pdf-parse (native text layer only — scanned/
 *                                                            image-only PDFs will NOT get text; that needs
 *                                                            page rasterization, which this does not do)
 *   .docx (wordprocessingml.document)                     -> mammoth (native text)
 *   .xlsx / .xls (spreadsheetml.sheet, ms-excel)           -> xlsx/SheetJS (cell text, all sheets)
 *   anything else                                         -> no extraction, text stays null
 *
 * Extraction must never block document registration: every extractor is
 * wrapped so a failure logs a warning and resolves to `{ text: null,
 * confidence: null }` rather than throwing.
 */
const path = require('path');
const { createWorker } = require('tesseract.js');
const { PDFParse } = require('pdf-parse');
const mammoth = require('mammoth');
const XLSX = require('xlsx');
const logger = require('../config/logger');

const TESSDATA_CACHE_PATH = path.join(__dirname, '..', 'tessdata');

const DOCX_MIME = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
const XLSX_MIME = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
const XLS_MIME = 'application/vnd.ms-excel';

async function ocrImage(buffer) {
  const worker = await createWorker('eng', 1, { cachePath: TESSDATA_CACHE_PATH });
  try {
    const { data } = await worker.recognize(buffer);
    return { text: data.text || null, confidence: typeof data.confidence === 'number' ? data.confidence : null };
  } finally {
    await worker.terminate();
  }
}

async function extractPdfText(buffer) {
  const parser = new PDFParse({ data: buffer });
  try {
    const result = await parser.getText();
    const text = (result.text || '').trim();
    return { text: text || null, confidence: null };
  } finally {
    await parser.destroy();
  }
}

async function extractDocxText(buffer) {
  const result = await mammoth.extractRawText({ buffer });
  const text = (result.value || '').trim();
  return { text: text || null, confidence: null };
}

async function extractXlsxText(buffer) {
  const workbook = XLSX.read(buffer, { type: 'buffer' });
  const parts = workbook.SheetNames.map((name) => XLSX.utils.sheet_to_csv(workbook.Sheets[name]));
  const text = parts.join('\n').trim();
  return { text: text || null, confidence: null };
}

/**
 * @returns {Promise<{text: string|null, confidence: number|null}>}
 */
async function extractText(buffer, mimetype, originalname) {
  try {
    if (mimetype && mimetype.startsWith('image/')) {
      return await ocrImage(buffer);
    }
    if (mimetype === 'application/pdf') {
      return await extractPdfText(buffer);
    }
    if (mimetype === DOCX_MIME) {
      return await extractDocxText(buffer);
    }
    if (mimetype === XLSX_MIME || mimetype === XLS_MIME) {
      return await extractXlsxText(buffer);
    }
    if (mimetype === 'text/plain') {
      const text = buffer.toString('utf8').trim();
      return { text: text || null, confidence: null };
    }
    return { text: null, confidence: null };
  } catch (err) {
    logger.warn('Text extraction failed', { originalname, mimetype, error: err.message });
    return { text: null, confidence: null };
  }
}

module.exports = { extractText };
