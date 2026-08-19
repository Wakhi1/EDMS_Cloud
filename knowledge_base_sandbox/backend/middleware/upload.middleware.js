const multer = require('multer');
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: (Number(process.env.MAX_UPLOAD_MB) || 200) * 1024 * 1024 } });
module.exports = upload;
