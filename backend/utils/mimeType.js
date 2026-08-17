/**
 * utils/mimeType.js
 * Filesystem/FTP/email intake sources have no browser-supplied
 * Content-Type header (unlike multipart uploads), so infer one from the
 * file extension — covers exactly the types services/ocr.service.js knows
 * how to extract text from, plus a safe binary-octet-stream fallback.
 */
const EXTENSION_MIME_MAP = {
  pdf: 'application/pdf',
  docx: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  xlsx: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  xls: 'application/vnd.ms-excel',
  txt: 'text/plain',
  png: 'image/png',
  jpg: 'image/jpeg',
  jpeg: 'image/jpeg',
  tif: 'image/tiff',
  tiff: 'image/tiff',
};

function mimeFromExtension(fileName) {
  const ext = (fileName.split('.').pop() || '').toLowerCase();
  return EXTENSION_MIME_MAP[ext] || 'application/octet-stream';
}

module.exports = { mimeFromExtension };
