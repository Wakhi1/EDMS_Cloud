/**
 * middleware/upload.middleware.js
 * Buffers incoming files in memory so they can be encrypted before ever
 * touching disk or cloud storage. 50 MB cap per file (tune as needed).
 */
const multer = require('multer');

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 50 * 1024 * 1024 },
});

module.exports = upload;
