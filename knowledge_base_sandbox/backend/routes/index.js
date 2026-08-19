const express = require('express');
const router = express.Router();

router.use('/auth', require('./auth.routes'));
router.use('/admin', require('./admin.routes'));
router.use('/content', require('./content.routes'));
router.use('/media', require('./media.routes'));
router.use('/sandbox', require('./sandbox.routes'));

module.exports = router;
