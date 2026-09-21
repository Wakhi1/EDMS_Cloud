/**
 * routes/signature.routes.js
 * One saved signature per user (Settings -> My Signature) — self-service,
 * no module-access gate, same shape as settings.routes.js's
 * /me/preferences. Business logic lives in services/signature.service.js.
 */
const express = require('express');

const { ok, fail } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');
const { authenticate } = require('../middleware/auth.middleware');
const upload = require('../middleware/upload.middleware');
const signatureService = require('../services/signature.service');

const router = express.Router();
router.use(authenticate);

/** GET /api/signature/me — { hasSignature, updatedAt } */
router.get('/me', asyncHandler(async (req, res) => {
  const meta = await signatureService.getSignatureMeta(req.user.id);
  return ok(res, meta);
}));

/** GET /api/signature/me/image — raw image bytes, 404 if none saved. */
router.get('/me/image', asyncHandler(async (req, res) => {
  const image = await signatureService.getSignatureImage(req.user.id);
  if (!image) return fail(res, 'No signature saved', 404);
  res.set('Content-Type', image.contentType);
  res.set('Cache-Control', 'no-store');
  return res.send(image.buffer);
}));

/** PUT /api/signature/me — multipart `file`, PNG only. Creates or replaces. */
router.put('/me', upload.single('file'), asyncHandler(async (req, res) => {
  if (!req.file) return fail(res, 'file is required', 400);
  if (req.file.mimetype !== 'image/png') return fail(res, 'Signature must be a PNG image', 422);

  await signatureService.upsertSignature(req.user.id, req.user.companyId, req.file.buffer, req.file.mimetype);
  return ok(res, null, 'Signature saved');
}));

/** DELETE /api/signature/me */
router.delete('/me', asyncHandler(async (req, res) => {
  await signatureService.deleteSignature(req.user.id);
  return ok(res, null, 'Signature removed');
}));

module.exports = router;
