/**
 * services/license/scheduler.js
 * Re-verifies this deployment's license against docsecure-platform-
 * provider — once, synchronously, at server startup (server.js awaits
 * runInitialCheck() before it starts accepting connections, so "the
 * server is up" and "the license has been checked with DocSecure" are
 * the same moment, not a background race), then again every hour after
 * that (startScheduler) to catch a revoke/suspend/renewal issued
 * centrally. There's nothing to write locally on a tick — the check
 * itself (services/license.service.js's checkDeploymentLicense) is the
 * whole point; login enforces it live on every request regardless.
 */
const logger = require('../../config/logger');
const { checkDeploymentLicense } = require('../license.service');

const CHECK_INTERVAL_MS = 60 * 60 * 1000;

let timer = null;

/**
 * Awaited once, directly in server.js's startup sequence, before
 * app.listen() — this is the literal "when it starts, it connects to
 * the docsecure-platform-provider engine to verify the license" step.
 * A provider outage here doesn't crash the boot — the server still
 * comes up either way, and every login attempt re-checks live anyway —
 * but the result is logged before the server is considered ready.
 */
async function runInitialCheck() {
  logger.info('Verifying license with DocSecure platform-provider...', { baseUrl: process.env.PLATFORM_PROVIDER_BASE_URL || '(not configured)' });
  const result = await checkDeploymentLicense('scheduled_check');
  logger.info('Initial license verification complete', { active: result.ok, reason: result.reason });
}

function startScheduler() {
  if (timer) return;
  timer = setInterval(() => {
    checkDeploymentLicense('scheduled_check')
      .then((result) => logger.info('License scheduler tick complete', { active: result.ok, reason: result.reason }))
      .catch((err) => logger.error('License scheduler tick failed', { error: err.message }));
  }, CHECK_INTERVAL_MS);
  logger.info('License scheduler started', { checkIntervalMs: CHECK_INTERVAL_MS });
}

module.exports = { runInitialCheck, startScheduler };
