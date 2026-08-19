/**
 * routes/index.js
 * Mounts every route module under /api/*. Each file owns one resource
 * area; there is no separate controllers layer — handlers live in the
 * route files and delegate shared logic to services/.
 */
const express = require('express');

const router = express.Router();

router.use('/auth', require('./auth.routes'));
router.use('/mfa', require('./mfa.routes'));
router.use('/users', require('./users.routes'));
router.use('/roles', require('./roles.routes'));
router.use('/folders', require('./folders.routes'));
router.use('/documents', require('./documents.routes'));
router.use('/document-types', require('./document-types.routes'));
router.use('/versions', require('./versions.routes'));
router.use('/permissions', require('./permissions.routes'));
router.use('/approvals', require('./approvals.routes'));
router.use('/workflow', require('./workflow.routes'));
router.use('/audit', require('./audit.routes'));
router.use('/retention', require('./retention.routes'));
router.use('/notifications', require('./notifications.routes'));
router.use('/integrations', require('./integrations.routes'));
router.use('/reports', require('./reports.routes'));
router.use('/capture-batches', require('./capture.routes'));
router.use('/departments', require('./departments.routes'));
router.use('/settings', require('./settings.routes'));
router.use('/backup', require('./backup.routes'));

module.exports = router;
