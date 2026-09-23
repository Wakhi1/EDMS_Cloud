/**
 * services/pageCount.service.js
 * Works out how many pages a file has, from its plaintext bytes, so
 * `document_versions.page_count` / `page_count_estimated` can be stored at
 * registration time.
 *
 * The file's real format is sniffed from its magic bytes first (agents and
 * browsers often label files application/octet-stream, drop the extension,
 * or save RTF as ".doc"), then the mimetype/extension is used for formats
 * with no signature (plain text).
 *
 *   EXACT
 *   PDF                 -> pdf-lib page tree, then pdf-parse (pdf.js), then a raw /Type /Page scan (estimated)
 *   TIFF / BigTIFF      -> counts the IFD chain (multi-page scans)
 *   any other image     -> 1
 *   .docx / .pptx       -> the Pages / Slides figure the authoring app wrote to docProps/app.xml
 *                          (pptx falls back to counting its slide parts)
 *   .doc / .ppt (OLE)   -> PIDSI_PAGECOUNT / PIDDSI_SLIDECOUNT from the summary-information streams
 *   .rtf                -> \nofpages from the {\info} group
 *   .xlsx / .xls / .ods -> worksheet count (a spreadsheet has no fixed page layout)
 *   .odt / .odp         -> meta:page-count from meta.xml
 *
 *   ESTIMATED (flagged, shown as "~N" in the UI — there is no fixed layout to count)
 *   text/*, .txt/.csv/.md/.log/.json/.xml, .html -> laid out at 90 columns x 46 lines per page
 *   .docx with no Pages figure -> max(explicit page breaks + 1, ~500 words per page)
 *   .doc with no page-count property -> character count from the Word FIB at ~3000 chars per page
 *   .rtf with no \nofpages -> its plain text, laid out as above
 *
 *   anything else (audio/video, unknown binaries) -> { count: null }, shown as "—"
 *
 * Like ocr.service.js this must never block registration: every counter is
 * wrapped so a failure logs a warning and resolves to { count: null }.
 */
const path = require('path');
const CFB = require('cfb');
const JSZip = require('jszip');
const XLSX = require('xlsx');
const mammoth = require('mammoth');
const { PDFDocument } = require('pdf-lib');
const { PDFParse } = require('pdf-parse');
const logger = require('../config/logger');

const MAX_TIFF_PAGES = 100000; // guards against a corrupt/looping IFD chain
const TEXT_COLUMNS = 90;
const TEXT_LINES_PER_PAGE = 46;
const WORDS_PER_PAGE = 500;
const CHARS_PER_PAGE = 3000;
const TEXT_EXTENSIONS = new Set(['.txt', '.csv', '.md', '.log', '.json', '.xml', '.tsv', '.ini', '.yaml', '.yml']);
const HTML_EXTENSIONS = new Set(['.html', '.htm']);
const IMAGE_EXTENSIONS = new Set(['.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp', '.heic', '.heif', '.jfif', '.svg']);

const exact = (count) => ({ count: count > 0 ? count : null, estimated: false });
const estimate = (count) => ({ count: count > 0 ? count : null, estimated: true });

// ---- PDF -------------------------------------------------------------------

/** Last resort for damaged PDFs: counts page objects in the raw bytes (misses pages inside compressed object streams). */
function scanPdfPageObjects(buffer) {
  const matches = buffer.toString('latin1').match(/\/Type\s*\/Page(?![a-zA-Z])/g);
  return estimate(matches ? matches.length : 0);
}

async function countPdfPages(buffer) {
  try {
    const pdf = await PDFDocument.load(buffer, { ignoreEncryption: true, updateMetadata: false, throwOnInvalidObject: false });
    const n = pdf.getPageCount();
    if (n > 0) return exact(n);
  } catch {
    // fall through to pdf-parse below
  }
  try {
    const parser = new PDFParse({ data: buffer });
    try {
      const info = await parser.getInfo();
      if (info.total > 0) return exact(info.total);
    } finally {
      await parser.destroy();
    }
  } catch {
    // fall through to the raw scan below
  }
  return scanPdfPageObjects(buffer);
}

// ---- TIFF ------------------------------------------------------------------

function countTiffPages(buffer) {
  if (buffer.length < 8) return exact(0);
  const order = buffer.toString('latin1', 0, 2);
  if (order !== 'II' && order !== 'MM') return exact(0);
  const le = order === 'II';
  const u16 = (o) => (le ? buffer.readUInt16LE(o) : buffer.readUInt16BE(o));
  const u32 = (o) => (le ? buffer.readUInt32LE(o) : buffer.readUInt32BE(o));
  const u64 = (o) => Number(le ? buffer.readBigUInt64LE(o) : buffer.readBigUInt64BE(o));

  const version = u16(2);
  if (version !== 42 && version !== 43) return exact(0);
  const big = version === 43; // BigTIFF: 8-byte counts/offsets, 20-byte entries
  if (big && buffer.length < 16) return exact(0);

  let offset = big ? u64(8) : u32(4);
  let pages = 0;
  const seen = new Set();
  const countSize = big ? 8 : 2;
  const entrySize = big ? 20 : 12;
  const pointerSize = big ? 8 : 4;
  while (offset > 0 && offset + countSize <= buffer.length && !seen.has(offset) && pages < MAX_TIFF_PAGES) {
    seen.add(offset);
    const entries = big ? u64(offset) : u16(offset);
    const nextPointer = offset + countSize + entries * entrySize;
    if (nextPointer + pointerSize > buffer.length) break;
    pages += 1;
    offset = big ? u64(nextPointer) : u32(nextPointer);
  }
  return exact(pages);
}

// ---- Plain text / HTML / RTF ----------------------------------------------

function layoutTextPages(text) {
  if (!text || !text.trim()) return estimate(0);
  const lines = text.split(/\r\n|\r|\n/).reduce((sum, line) => sum + Math.max(1, Math.ceil(line.length / TEXT_COLUMNS)), 0);
  return estimate(Math.ceil(lines / TEXT_LINES_PER_PAGE));
}

function countTextPages(buffer) {
  return layoutTextPages(buffer.toString('utf8'));
}

function countHtmlPages(buffer) {
  const text = buffer.toString('utf8')
    .replace(/<(script|style)[\s\S]*?<\/\1>/gi, '')
    .replace(/<(br|\/p|\/div|\/li|\/tr|\/h\d)[^>]*>/gi, '\n')
    .replace(/<[^>]+>/g, '')
    .replace(/&nbsp;/g, ' ');
  return layoutTextPages(text);
}

function countRtfPages(buffer) {
  const raw = buffer.toString('latin1');
  const match = /\\nofpages(\d+)/.exec(raw);
  if (match && Number(match[1]) > 0) return exact(Number(match[1]));

  const text = raw
    .replace(/\{\\\*[^{}]*\}/g, '') // ignorable destinations
    .replace(/\{\\(fonttbl|colortbl|stylesheet|info|pict)[\s\S]*?\}\}?/g, '')
    .replace(/\\(par|line)\b ?/g, '\n')
    .replace(/\\page\b ?/g, '\f')
    .replace(/\\'[0-9a-f]{2}/gi, 'x')
    .replace(/\\[a-z]+-?\d* ?/gi, '')
    .replace(/[{}]/g, '');
  const explicitPages = (text.match(/\f/g) || []).length + 1;
  const laidOut = layoutTextPages(text.replace(/\f/g, '\n'));
  return estimate(Math.max(explicitPages, laidOut.count || 0));
}

// ---- OOXML / ODF (zip) ------------------------------------------------------

async function readZipText(zip, entryName) {
  const entry = zip.file(entryName);
  return entry ? entry.async('string') : null;
}

async function countDocxPages(buffer, zip) {
  const archive = zip || await JSZip.loadAsync(buffer);
  const xml = await readZipText(archive, 'docProps/app.xml');
  const match = xml && /<Pages>(\d+)<\/Pages>/.exec(xml);
  if (match && Number(match[1]) > 0) return exact(Number(match[1]));

  // No Pages figure (generated by a library rather than Word): take the larger
  // of the explicit page/section breaks and a words-per-page estimate.
  const body = (await readZipText(archive, 'word/document.xml')) || '';
  const breaks = (body.match(/<w:br [^>]*w:type="page"/g) || []).length
    + (body.match(/<w:pageBreakBefore(?! w:val="(0|false)")/g) || []).length
    + (body.match(/<w:type w:val="(nextPage|oddPage|evenPage)"/g) || []).length;
  let words = 0;
  try {
    const { value } = await mammoth.extractRawText({ buffer });
    words = (value || '').split(/\s+/).filter(Boolean).length;
  } catch {
    // unusual package layout mammoth can't read — the break count still stands
  }
  return estimate(Math.max(breaks + 1, Math.ceil(words / WORDS_PER_PAGE)));
}

async function countPptxSlides(buffer, zip) {
  const archive = zip || await JSZip.loadAsync(buffer);
  const xml = await readZipText(archive, 'docProps/app.xml');
  const match = xml && /<Slides>(\d+)<\/Slides>/.exec(xml);
  if (match && Number(match[1]) > 0) return exact(Number(match[1]));
  return exact(archive.file(/^ppt\/slides\/slide\d+\.xml$/).length);
}

async function countOdfPages(buffer, attribute, zip) {
  const archive = zip || await JSZip.loadAsync(buffer);
  const xml = await readZipText(archive, 'meta.xml');
  const match = xml && new RegExp(`${attribute}="(\\d+)"`).exec(xml);
  return exact(match ? Number(match[1]) : 0);
}

function countSheets(buffer) {
  const workbook = XLSX.read(buffer, { type: 'buffer', bookSheets: true });
  return exact(workbook.SheetNames.length);
}

/** Works out which OOXML/ODF format a zip is from its parts, not its name. */
async function countZipPages(buffer, ext) {
  const zip = await JSZip.loadAsync(buffer);
  if (zip.file('word/document.xml')) return countDocxPages(buffer, zip);
  if (zip.file('ppt/presentation.xml')) return countPptxSlides(buffer, zip);
  if (zip.file('xl/workbook.xml')) return countSheets(buffer);
  const mimetype = (await readZipText(zip, 'mimetype')) || '';
  if (mimetype.includes('opendocument.text')) return countOdfPages(buffer, 'meta:page-count', zip);
  if (mimetype.includes('opendocument.presentation')) return countOdfPages(buffer, 'meta:page-count', zip);
  if (mimetype.includes('opendocument.spreadsheet')) return countOdfPages(buffer, 'meta:table-count', zip);
  logger.debug('Zip file is not a recognised office format', { ext });
  return exact(0);
}

// ---- Legacy OLE (.doc / .ppt / .xls) ---------------------------------------

/** Reads one integer property out of an OLE property-set stream (MS-OLEPS). */
function readPropertySetInt(stream, propertyId) {
  if (!stream) return null;
  const buf = Buffer.from(stream);
  if (buf.length < 48) return null;
  const sectionOffset = buf.readUInt32LE(44);
  if (sectionOffset + 8 > buf.length) return null;
  const count = buf.readUInt32LE(sectionOffset + 4);
  for (let i = 0; i < count; i += 1) {
    const entry = sectionOffset + 8 + i * 8;
    if (entry + 8 > buf.length) break;
    if (buf.readUInt32LE(entry) === propertyId) {
      const valueAt = sectionOffset + buf.readUInt32LE(entry + 4);
      if (valueAt + 8 > buf.length) return null;
      const type = buf.readUInt16LE(valueAt);
      if (type === 3) return buf.readInt32LE(valueAt + 4); // VT_I4
      if (type === 2) return buf.readInt16LE(valueAt + 4); // VT_I2
      return null;
    }
  }
  return null;
}

function countOlePages(buffer) {
  const cfb = CFB.read(buffer, { type: 'buffer' });
  const stream = (name) => {
    const entry = CFB.find(cfb, name);
    return entry && entry.content ? entry.content : null;
  };

  const word = stream('WordDocument');
  if (word) {
    const pages = readPropertySetInt(stream('\u0005SummaryInformation'), 14); // PIDSI_PAGECOUNT
    if (pages > 0) return exact(pages);
    const fib = Buffer.from(word);
    const ccpText = fib.length >= 80 ? fib.readInt32LE(0x4c) : 0; // FibRgLw97.ccpText — characters in the main story
    return estimate(Math.ceil(ccpText / CHARS_PER_PAGE));
  }
  if (stream('PowerPoint Document')) {
    return exact(readPropertySetInt(stream('\u0005DocumentSummaryInformation'), 7) || 0); // PIDDSI_SLIDECOUNT
  }
  if (stream('Workbook') || stream('Book')) return countSheets(buffer);
  return exact(0);
}

// ---- Dispatch ---------------------------------------------------------------

const startsWith = (buffer, bytes, at = 0) => bytes.every((b, i) => buffer[at + i] === b);

/** The counter for a file's real format, judged from its first bytes; null when unrecognised. */
function sniffCounter(buffer, ext) {
  if (!buffer || buffer.length < 4) return null;
  if (buffer.subarray(0, 1024).includes('%PDF-')) return countPdfPages;
  if (startsWith(buffer, [0x49, 0x49, 0x2a, 0x00]) || startsWith(buffer, [0x4d, 0x4d, 0x00, 0x2a])
    || startsWith(buffer, [0x49, 0x49, 0x2b, 0x00]) || startsWith(buffer, [0x4d, 0x4d, 0x00, 0x2b])) return countTiffPages;
  if (startsWith(buffer, [0x89, 0x50, 0x4e, 0x47]) || startsWith(buffer, [0xff, 0xd8, 0xff])
    || startsWith(buffer, [0x47, 0x49, 0x46, 0x38]) || startsWith(buffer, [0x42, 0x4d])
    || (startsWith(buffer, [0x52, 0x49, 0x46, 0x46]) && buffer.toString('latin1', 8, 12) === 'WEBP')) return () => exact(1);
  if (startsWith(buffer, [0x50, 0x4b, 0x03, 0x04])) return (b) => countZipPages(b, ext);
  if (startsWith(buffer, [0xd0, 0xcf, 0x11, 0xe0, 0xa1, 0xb1, 0x1a, 0xe1])) return countOlePages;
  if (buffer.toString('latin1', 0, 5) === '{\\rtf') return countRtfPages;
  return null;
}

/** The counter implied by mimetype/extension alone, or null when the type isn't one we can count. */
function pickCounter(mimetype, originalname) {
  const ext = path.extname(originalname || '').toLowerCase();
  const mime = mimetype || '';
  if (mime === 'application/pdf' || ext === '.pdf') return countPdfPages;
  if (mime === 'image/tiff' || ext === '.tif' || ext === '.tiff') return countTiffPages;
  if (mime.startsWith('image/') || IMAGE_EXTENSIONS.has(ext)) return () => exact(1);
  if (ext === '.docx' || ext === '.docm') return (b) => countDocxPages(b);
  if (ext === '.pptx' || ext === '.ppsx') return (b) => countPptxSlides(b);
  if (ext === '.xlsx' || ext === '.xls' || ext === '.xlsm') return countSheets;
  if (ext === '.odt' || ext === '.odp') return (b) => countOdfPages(b, 'meta:page-count');
  if (ext === '.ods') return (b) => countOdfPages(b, 'meta:table-count');
  if (ext === '.doc' || ext === '.ppt' || ext === '.pps') return countOlePages;
  if (ext === '.rtf' || mime === 'application/rtf' || mime === 'text/rtf') return countRtfPages;
  if (mime === 'text/html' || HTML_EXTENSIONS.has(ext)) return countHtmlPages;
  if (mime.startsWith('text/') || TEXT_EXTENSIONS.has(ext)) return countTextPages;
  return null;
}

/**
 * Whether countPages could return a number for this type — lets a backfill
 * skip downloading the rest. Unknown/generic types are worth downloading
 * because the bytes themselves may be sniffed as a countable format.
 */
function isCountable(mimetype) {
  const mime = mimetype || '';
  return !mime.startsWith('audio/') && !mime.startsWith('video/');
}

/**
 * @returns {Promise<{count: number|null, estimated: boolean}>} count is null when it can't be determined
 */
async function countPages(buffer, mimetype, originalname) {
  const ext = path.extname(originalname || '').toLowerCase();
  const counters = [sniffCounter(buffer, ext), pickCounter(mimetype, originalname)].filter(Boolean);
  for (const counter of new Set(counters)) {
    try {
      // eslint-disable-next-line no-await-in-loop
      const result = await counter(buffer);
      if (result && result.count) return result;
    } catch (err) {
      logger.warn('Page count failed', { originalname, mimetype, error: err.message });
    }
  }
  return { count: null, estimated: false };
}

module.exports = { countPages, isCountable };
