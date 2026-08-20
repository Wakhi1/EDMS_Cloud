/**
 * routes/platform-admin/index.js
 * Mounts every platform-admin (DocSecore staff) route under
 * /api/platform-admin/*. Fully separate identity space from the rest of
 * routes/index.js — see middleware/platformAuth.middleware.js.
 */
const express = require('express');

const router = express.Router();

router.use('/auth', require('./platform-admin-auth.routes'));
router.use('/companies', require('./companies.routes'));
router.use('/licenses', require('./licenses.routes'));

module.exports = router;
