/**
 * routes/agentUpload.routes.js
 * Upload surface for the local watched-folder agent (see /local-agent at
 * the repo root) — the piece that lets a folder on someone's own PC feed
 * this deployment now that the backend no longer shares a filesystem with
 * it (services/intake/watchedFolder.intake.js only sees paths under
 * WATCHED_INTAKE_ROOT on the server itself).
 *
 * Authenticated by a long-lived API key (middleware/apiKey.middleware.js)
 * rather than a JWT session — deliberately NOT behind auth.middleware.js's
 * authenticate, and mounted as its own router so it doesn't inherit
 * capture.routes.js's `router.use(authenticate)`. Reuses the exact same
 * registration pipeline as manual/device upload (services/capture/
 * batch.service.js), tagged with source 'watched_folder' either way.
 */
const express = require('express');

const { ok, fail } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');
const { authenticateApiKey } = require('../middleware/apiKey.middleware');
const upload = require('../middleware/upload.middleware');
const { runBatch } = require('../services/capture/batch.service');

const router = express.Router();

/** POST /api/agent/upload — multipart, multiple files, X-Api-Key header. */
router.post(
  '/upload',
  authenticateApiKey,
  upload.array('files', 50),
  asyncHandler(async (req, res) => {
    if (!req.files || req.files.length === 0) return fail(res, 'At least one file is required', 400);

    const defaultFolderId = req.body.folderId ? Number(req.body.folderId) : undefined;
    const result = await runBatch({
      source: 'watched_folder',
      files: req.files.map((f) => ({ fileName: f.originalname, buffer: f.buffer, mimeType: f.mimetype })),
      defaultFolderId,
      createdBy: req.user.id,
      ip: req.ip,
    });
    return ok(res, result, 'Batch uploaded', 201);
  })
);

module.exports = router;
