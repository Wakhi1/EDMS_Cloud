/**
 * routes/branding.routes.js
 * Public (unauthenticated) — this deployment's own company branding,
 * read live from docsecure-platform-provider and proxied through here
 * rather than fetched directly by the frontend, for two reasons: the
 * provider's base URL stays backend-only config (never shipped to the
 * browser), and the provider's asset server sends no CORS headers (this
 * one already does, via server.js's cors() middleware, since the
 * frontend origin is already trusted to call this API).
 */
const express = require("express");

const { ok } = require("../utils/apiResponse");
const asyncHandler = require("../utils/asyncHandler");
const {
  getStoredLicenseKey,
  verifyLicenseKeyWithProvider,
} = require("../services/license.service");
const {
  fetchCompanyBranding,
  fetchCompanyBrandingAsset,
} = require("../services/branding.service");

const router = express.Router();

const FALLBACK = {
  companyCode: null,
  name: "Docsecure EDMS",
  theme: {},
  hasLogo: false,
  hasFavicon: false,
  customDomain: null,
};

/** No local companies table anymore — the company this deployment brands as is whichever one its stored license key verifies to, live. */
async function homeCompanyCode() {
  const licenseKey = await getStoredLicenseKey();
  if (!licenseKey) return null;
  const verification = await verifyLicenseKeyWithProvider(licenseKey);
  return verification.valid ? verification.companyCode : null;
}

/** GET /api/branding — name, theme colors, and whether a logo/favicon exist (image bytes are separate proxied requests below). */
router.get(
  "/",
  asyncHandler(async (req, res) => {
    const companyCode = await homeCompanyCode();
    const branding = companyCode
      ? await fetchCompanyBranding(companyCode)
      : null;
    if (!branding) return ok(res, FALLBACK);

    return ok(res, {
      companyCode: branding.companyCode,
      name: branding.name,
      theme: branding.theme || {},
      hasLogo: Boolean(branding.logoUrl),
      hasFavicon: Boolean(branding.faviconUrl),
      customDomain: branding.customDomain || null,
    });
  }),
);

async function serveAsset(field, res) {
  const companyCode = await homeCompanyCode();
  const asset = companyCode
    ? await fetchCompanyBrandingAsset(companyCode, field)
    : null;
  if (!asset) return res.status(404).end();
  res.type(asset.contentType);
  res.set("Cache-Control", "private, max-age=300"); // branding rarely changes; avoid re-proxying on every paint
  return res.send(asset.buffer);
}

router.get(
  "/logo",
  asyncHandler(async (req, res) => serveAsset("logo", res)),
);
router.get(
  "/favicon",
  asyncHandler(async (req, res) => serveAsset("favicon", res)),
);

module.exports = router;
