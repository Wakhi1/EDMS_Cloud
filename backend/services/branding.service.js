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

module.exports = { fetchCompanyBranding, fetchCompanyBrandingAsset };
