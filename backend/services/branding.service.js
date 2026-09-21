/**
 * services/branding.service.js
 * Reads this deployment's company branding live from
 * docsecure-platform-provider (GET /companies/:code/branding) — same
 * "pull from the provider, don't self-manage it" shift as licensing
 * (see services/license.service.js). Deliberately not cached locally:
 * branding changes are rare and low-stakes to re-fetch, so there's no
 * offline-resilience case here the way there is for license enforcement.
 */
const logger = require('../config/logger');
const { getStoredLicenseKey, verifyLicenseKeyWithProvider } = require('./license.service');

const HOME_BRANDING_CACHE_MS = 5 * 60 * 1000;
let homeBrandingCache = null; // { value, expiresAt }

/** No local companies table — the company this deployment brands as is whichever one its stored license key verifies to, live. */
async function homeCompanyCode() {
  const licenseKey = await getStoredLicenseKey();
  if (!licenseKey) return null;
  const verification = await verifyLicenseKeyWithProvider(licenseKey);
  return verification.valid ? verification.companyCode : null;
}

/**
 * Cached branding (plus logo bytes) for this deployment's own company —
 * used by outgoing email templates, which would otherwise re-run a license
 * verification round trip plus two branding fetches on every single send
 * (a burst of workflow-step assignments can fire many emails at once).
 *
 * The logo is fetched here as raw bytes (for a `cid:` inline attachment)
 * rather than linked as a remote <img src>: an email client fetches
 * <img> URLs itself, over the open internet, which fails outright when
 * APP_URL is a localhost/private address (as in dev) and is unreliable
 * even in production (many clients block remote images by default,
 * exactly the "why doesn't the logo show up" symptom). An inline
 * attachment ships the bytes inside the message itself, so it renders
 * regardless of network reachability or remote-image blocking.
 */
async function getHomeBrandingWithLogo() {
  if (homeBrandingCache && homeBrandingCache.expiresAt > Date.now()) {
    return homeBrandingCache.value;
  }
  const companyCode = await homeCompanyCode();
  let branding = null;
  let logo = null;
  if (companyCode) {
    branding = await fetchCompanyBranding(companyCode);
    if (branding?.logoUrl) logo = await fetchCompanyBrandingAsset(companyCode, 'logo');
  }
  const value = { branding, logo };
  homeBrandingCache = { value, expiresAt: Date.now() + HOME_BRANDING_CACHE_MS };
  return value;
}

async function fetchCompanyBranding(companyCode) {
  const baseUrl = process.env.PLATFORM_PROVIDER_BASE_URL;
  if (!baseUrl) return null;

  try {
    const response = await fetch(`${baseUrl}/companies/${encodeURIComponent(companyCode)}/branding`);
    if (!response.ok) return null;
    return await response.json();
  } catch (err) {
    logger.error('Branding fetch from provider failed', { companyCode, error: err.message });
    return null;
  }
}

/** Streams the raw asset bytes for `field` ('logo' | 'favicon') straight through from the provider. Returns null if there's nothing to serve. */
async function fetchCompanyBrandingAsset(companyCode, field) {
  const branding = await fetchCompanyBranding(companyCode);
  const assetPath = field === 'logo' ? branding?.logoUrl : branding?.faviconUrl;
  if (!assetPath) return null;

  const baseUrl = process.env.PLATFORM_PROVIDER_BASE_URL;
  try {
    const response = await fetch(`${baseUrl}${assetPath}`);
    if (!response.ok) return null;
    const buffer = Buffer.from(await response.arrayBuffer());
    return { buffer, contentType: response.headers.get('content-type') || 'application/octet-stream' };
  } catch (err) {
    logger.error('Branding asset fetch from provider failed', { companyCode, field, error: err.message });
    return null;
  }
}

module.exports = { fetchCompanyBranding, fetchCompanyBrandingAsset, homeCompanyCode, getHomeBrandingWithLogo };
