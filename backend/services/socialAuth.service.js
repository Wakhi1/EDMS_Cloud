/**
 * services/socialAuth.service.js
 * Verifies identity tokens from Google and Microsoft (Azure AD) so the
 * frontend can use either provider's official sign-in SDK and hand the
 * resulting ID token to POST /api/auth/google or /api/auth/microsoft.
 */
const { OAuth2Client } = require('google-auth-library');
const jwt = require('jsonwebtoken');
const logger = require('../config/logger');

const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

/** Verifies a Google ID token and returns the normalised profile. */
async function verifyGoogleIdToken(idToken) {
  const ticket = await googleClient.verifyIdToken({
    idToken,
    audience: process.env.GOOGLE_CLIENT_ID,
  });
  const payload = ticket.getPayload();
  return {
    provider: 'google',
    providerUserId: payload.sub,
    email: payload.email,
    fullName: payload.name,
    emailVerified: payload.email_verified,
    raw: payload,
  };
}

/**
 * Verifies a Microsoft/Azure AD ID token. Full production verification
 * should fetch and cache Microsoft's JWKS (via jwks-rsa) and check the
 * signature, issuer and audience; this decodes and performs basic claim
 * checks so the route layer works out of the box, with the signature
 * step clearly marked for hardening before go-live.
 */
async function verifyMicrosoftIdToken(idToken) {
  const decoded = jwt.decode(idToken, { complete: true });
  if (!decoded) throw new Error('Invalid Microsoft ID token');

  // TODO (production hardening): verify signature against Microsoft's
  // JWKS endpoint for the configured tenant, e.g. via the `jwks-rsa`
  // package, before trusting these claims.
  const { payload } = decoded;
  if (payload.aud !== process.env.MICROSOFT_CLIENT_ID) {
    throw new Error('Microsoft token audience mismatch');
  }

  return {
    provider: 'microsoft',
    providerUserId: payload.oid || payload.sub,
    email: payload.preferred_username || payload.email,
    fullName: payload.name,
    emailVerified: true,
    raw: payload,
  };
}

module.exports = { verifyGoogleIdToken, verifyMicrosoftIdToken };
