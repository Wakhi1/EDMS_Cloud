/**
 * services/license.service.js
 * Licensing is owned entirely by docsecure-platform-provider now:
 * companies, license terms, status, and history all live there. This
 * deployment keeps exactly one thing locally — the license key it was
 * activated with (system_settings, key 'license_key') — and verifies
 * it against the provider live, on every check. There is no local
 * `licenses`/`license_validation_log` table, no cached status, and no
 * resilience to a provider outage: if the provider can't be reached,
 * the check fails, on purpose (see checkDeploymentLicense).
 */
const { pool } = require('../config/db');
const logger = require('../config/logger');

const LICENSE_KEY_SETTING = 'license_key';

/** This deployment is single-tenant — every row still tagged with a company_id (users, documents, ...) uses this fixed value. */
const HOME_COMPANY_ID = 1;

async function getStoredLicenseKey() {
  const [[row]] = await pool.query(`SELECT setting_value FROM system_settings WHERE setting_key = ?`, [LICENSE_KEY_SETTING]);
  return row?.setting_value || null;
}

async function storeLicenseKey(licenseKey) {
  await pool.query(
    `INSERT INTO system_settings (setting_key, company_id, setting_value, description)
     VALUES (?, ?, ?, 'The license key this deployment was activated with — verified live against DocSecure''s licensing platform on every check')
     ON DUPLICATE KEY UPDATE setting_value = ?`,
    [LICENSE_KEY_SETTING, HOME_COMPANY_ID, licenseKey, licenseKey]
  );
}

/** "3d 4h" / "6h" / "expired" — for logging/display of a license's remaining time. */
function formatCountdown(expiresAt) {
  const ms = new Date(expiresAt).getTime() - Date.now();
  if (ms <= 0) return 'expired';
  const days = Math.floor(ms / 86400000);
  const hours = Math.floor((ms % 86400000) / 3600000);
  return days > 0 ? `${days}d ${hours}h remaining` : `${hours}h remaining`;
}

/**
 * Calls docsecure-platform-provider's GET /verify/:licenseKey — the one
 * and only way this deployment ever learns whether it's licensed, used
 * both by activation (a fresh key an admin was just emailed) and by
 * every ongoing check (the previously-stored key). Never throws;
 * network/malformed-response failures come back as
 * { valid: false, reason: 'provider_unreachable' }.
 */
async function verifyLicenseKeyWithProvider(licenseKey) {
  const baseUrl = process.env.PLATFORM_PROVIDER_BASE_URL;
  if (!baseUrl) return { valid: false, reason: 'not_configured' };

  try {
    const response = await fetch(`${baseUrl}/verify/${encodeURIComponent(licenseKey)}`);
    if (!response.ok) return { valid: false, reason: 'provider_unreachable' };
    const payload = await response.json();
    if (!payload.valid) return { valid: false, reason: payload.result || 'invalid' };
    return {
      valid: true,
      companyCode: payload.companyCode,
      companyName: payload.companyName,
      licenseType: payload.licenseType,
      expiresAt: payload.expiresAt,
    };
  } catch (err) {
    logger.error('License key verification request failed', { error: err.message });
    return { valid: false, reason: 'provider_unreachable' };
  }
}

/**
 * The actual enforcement point — called from POST /api/auth/login, the
 * federated sign-in tail, GET /api/license/status, and the startup/
 * hourly scheduler. Reads the stored key and re-verifies it against the
 * provider live every time; there's no local cache to fall back on, so
 * a provider outage fails the check rather than silently passing.
 */
async function checkDeploymentLicense(source = 'login') {
  const licenseKey = await getStoredLicenseKey();
  if (!licenseKey) return { ok: false, reason: 'not_activated' };

  const verification = await verifyLicenseKeyWithProvider(licenseKey);
  if (!verification.valid) {
    logger.warn('License check failed', { source, reason: verification.reason });
    return { ok: false, reason: verification.reason };
  }
  return { ok: true, ...verification };
}

/** Verifies a fresh key against the provider and, if valid, stores it as this deployment's license. */
async function activateLicense(licenseKey) {
  const verification = await verifyLicenseKeyWithProvider(licenseKey);
  if (!verification.valid) return { activated: false, reason: verification.reason };

  await storeLicenseKey(licenseKey);
  logger.info('License activated', { companyCode: verification.companyCode, licenseType: verification.licenseType });
  return { activated: true, ...verification };
}

module.exports = {
  HOME_COMPANY_ID,
  getStoredLicenseKey,
  checkDeploymentLicense,
  verifyLicenseKeyWithProvider,
  activateLicense,
  formatCountdown,
};
