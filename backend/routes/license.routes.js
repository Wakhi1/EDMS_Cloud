/**
 * routes/license.routes.js
 * Public (unauthenticated) — this deployment's own license status and
 * activation, checked/entered before anyone can even reach the login
 * screen. docsecure-platform-provider owns companies and licenses
 * outright; this is just the local gate that records the one key this
 * deployment was activated with and re-verifies it live on every check
 * — see services/license.service.js.
 */
const express = require('express');
const { body, validationResult } = require('express-validator');

const { ok, fail } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');
const { checkDeploymentLicense, activateLicense, formatCountdown } = require('../services/license.service');

const router = express.Router();

function statusPayload(result) {
  if (!result.ok) return { active: false, reason: result.reason };
  return {
    active: true,
    licenseType: result.licenseType,
    expiresAt: result.expiresAt,
    countdown: formatCountdown(result.expiresAt),
  };
}

const ERROR_MESSAGES = {
  not_configured: 'This deployment is not configured to reach DocSecure’s licensing platform.',
  provider_unreachable: 'Could not reach DocSecure’s licensing platform. Try again shortly.',
  not_found: 'That license key was not recognized.',
  expired: 'That license has expired.',
  suspended: 'That license is suspended. Contact DocSecure.',
  revoked: 'That license has been revoked.',
  company_suspended: 'This organization\'s account is suspended. Contact DocSecure.',
};

/** GET /api/license/status — does this deployment currently hold a valid license? */
router.get(
  '/status',
  asyncHandler(async (req, res) => {
    const result = await checkDeploymentLicense('status_check');
    return ok(res, statusPayload(result));
  })
);

/**
 * POST /api/license/activate — { licenseKey }. Verifies the key against
 * docsecure-platform-provider and, if valid, stores it as this
 * deployment's license — no local company record to match against
 * anymore, the key itself is the entire activation.
 */
router.post(
  '/activate',
  [body('licenseKey').trim().notEmpty().withMessage('License key is required')],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    const result = await activateLicense(req.body.licenseKey);
    if (!result.activated) {
      return fail(res, ERROR_MESSAGES[result.reason] || `License key invalid: ${result.reason}`, 400);
    }

    return ok(res, statusPayload({ ok: true, ...result }), 'License activated');
  })
);

module.exports = router;
