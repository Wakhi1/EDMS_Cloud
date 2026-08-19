/**
 * scripts/endpoint-docs.js
 * Structured API reference for every EDMS endpoint, keyed by
 * "METHOD /path" (path exactly as extracted from the Postman
 * collection — including {{variable}} placeholders, since that's
 * what's stored in sandbox_requests.path). Consumed by
 * import-postman.js, which writes this into sandbox_requests.doc_json.
 *
 * This is what turns the Sandbox from "a request runner" into "a
 * request runner with real documentation attached" — every entry
 * covers: a one-line summary, path/query parameters (name, type,
 * required, description), request body fields, and realistic example
 * responses per status code actually returned by that route.
 *
 * Shared shapes (kept as constants below so 68 entries don't each
 * hand-roll the same auth/validation-error responses):
 */
const AUTH_401 = { status: 401, description: 'Missing, invalid, or expired token.', example: { success: false, message: 'Invalid or expired token', errors: null } };
const FORBIDDEN_403 = { status: 403, description: 'Signed in, but the account\'s role does not permit this action.', example: { success: false, message: 'You do not have permission to perform this action', errors: null } };
const VALIDATION_422 = { status: 422, description: 'Request body failed validation.', example: { success: false, message: 'Validation failed', errors: [{ type: 'field', msg: 'Invalid value', path: 'email', location: 'body' }] } };
const NOT_FOUND_404 = (thing) => ({ status: 404, description: `${thing} not found.`, example: { success: false, message: `${thing} not found`, errors: null } });

module.exports = {

  /* ============================== AUTH ============================== */

  'POST /auth/register': {
    summary: 'Create a password-based account.',
    parameters: [],
    requestBody: { fields: [
      { name: 'fullName', type: 'string', required: true, description: 'Full display name.' },
      { name: 'email', type: 'string', required: true, description: 'Must be unique across all accounts.' },
      { name: 'password', type: 'string', required: true, description: 'Minimum 10 characters.' },
      { name: 'roleId', type: 'integer', required: true, description: 'FK to roles.id — see the roles seeded in the EDMS schema (Records Officer, Approving Manager, etc.).' },
      { name: 'departmentId', type: 'integer', required: false, description: 'FK to departments.id.' },
      { name: 'phoneNumber', type: 'string', required: false, description: 'E.164 format, e.g. +26876000000. Needed later for SMS MFA.' },
    ] },
    responses: [
      { status: 201, description: 'Account created.', example: { success: true, message: 'Account created', data: { userId: 7 } } },
      { status: 409, description: 'Email already registered.', example: { success: false, message: 'An account with this email already exists', errors: null } },
      VALIDATION_422,
    ],
  },

  'POST /auth/login': {
    summary: 'Password sign-in. Returns tokens directly, or an MFA challenge if the role requires a second factor.',
    parameters: [],
    requestBody: { fields: [
      { name: 'email', type: 'string', required: true, description: '' },
      { name: 'password', type: 'string', required: true, description: '' },
    ] },
    responses: [
      { status: 200, description: 'Signed in — no MFA required for this account.', example: { success: true, message: 'Logged in', data: { accessToken: '<jwt>', refreshToken: '<jwt>', user: { id: 3, fullName: 'Thabo Simelane', email: 'records.officer@pspf.co.sz', role: 'Records Officer' } } } },
      { status: 200, description: 'MFA required — continue with the MFA folder, not this response\'s tokens (there are none yet).', example: { success: true, message: 'MFA verification required', data: { mfaRequired: true, mfaEnrollmentRequired: false, availableMethods: ['totp', 'email'], mfaToken: '<short-lived jwt>' } } },
      { status: 401, description: 'Wrong email or password.', example: { success: false, message: 'Invalid email or password', errors: null } },
      { status: 423, description: 'Account is locked.', example: { success: false, message: 'Account is locked — contact your System Administrator', errors: null } },
    ],
  },

  'POST /auth/refresh': {
    summary: 'Exchange a refresh token for a new access token.',
    parameters: [],
    requestBody: { fields: [{ name: 'refreshToken', type: 'string', required: true, description: 'From a prior login/MFA response.' }] },
    responses: [
      { status: 200, description: 'New access token issued.', example: { success: true, message: 'Token refreshed', data: { accessToken: '<jwt>' } } },
      { status: 401, description: 'Refresh token invalid, expired, or the session was revoked (e.g. by logout).', example: { success: false, message: 'Session not found or revoked', errors: null } },
    ],
  },

  'GET /auth/me': {
    summary: 'The currently signed-in user\'s profile.',
    parameters: [],
    responses: [
      { status: 200, description: '', example: { success: true, message: 'OK', data: { id: 3, fullName: 'Thabo Simelane', email: 'records.officer@pspf.co.sz', role: 'Records Officer', roleId: 1, mfaSatisfied: false } } },
      AUTH_401,
    ],
  },

  'POST /auth/logout': {
    summary: 'Revoke the refresh session tied to the given refresh token.',
    parameters: [],
    requestBody: { fields: [{ name: 'refreshToken', type: 'string', required: false, description: 'If omitted, nothing is revoked but the call still succeeds — clear tokens client-side regardless.' }] },
    responses: [{ status: 200, description: '', example: { success: true, message: 'Logged out', data: null } }],
  },

  'POST /auth/google': {
    summary: 'Sign in with a Google-issued ID token. The account must already exist (created by an admin) and be matched by email on first use — this endpoint never auto-creates an account.',
    parameters: [],
    requestBody: { fields: [{ name: 'idToken', type: 'string', required: true, description: 'A real ID token from Google Identity Services on a frontend — cannot be hand-typed or faked; the backend verifies it against Google.' }] },
    responses: [
      { status: 200, description: 'Same shape as POST /auth/login (tokens, or an MFA challenge).', example: { success: true, message: 'Logged in', data: { accessToken: '<jwt>', refreshToken: '<jwt>', user: { id: 3, fullName: 'Thabo Simelane', email: 'records.officer@pspf.co.sz', role: 'Records Officer' } } } },
      { status: 403, description: 'No EDMS account exists for this Google identity yet.', example: { success: false, message: 'No PSPF EDMS account exists for this identity. Ask a System Administrator to provision one.', errors: null } },
      { status: 401, description: 'Google could not verify the token, or its email is unverified.', example: { success: false, message: 'Email on the identity provider is not verified', errors: null } },
    ],
  },

  'POST /auth/microsoft': {
    summary: 'Sign in with a Microsoft/Entra ID-issued ID token. Same account-provisioning rule as Google Sign-In.',
    parameters: [],
    requestBody: { fields: [{ name: 'idToken', type: 'string', required: true, description: 'A real ID token from MSAL.js on a frontend.' }] },
    responses: [
      { status: 200, description: 'Same shape as POST /auth/login.', example: { success: true, message: 'Logged in', data: { accessToken: '<jwt>', refreshToken: '<jwt>', user: { id: 3, fullName: 'Thabo Simelane', email: 'records.officer@pspf.co.sz', role: 'Records Officer' } } } },
      { status: 403, description: 'No EDMS account exists for this Microsoft identity yet.', example: { success: false, message: 'No PSPF EDMS account exists for this identity. Ask a System Administrator to provision one.', errors: null } },
    ],
  },

  'POST /auth/active-directory': {
    summary: 'On-prem SSO via LDAPS bind. Currently a documented stub — see the response below.',
    parameters: [],
    requestBody: { fields: [
      { name: 'username', type: 'string', required: true, description: 'Domain\\username, e.g. PSPF\\s.nkambo.' },
      { name: 'password', type: 'string', required: true, description: '' },
    ] },
    responses: [
      { status: 501, description: 'Not implemented on this server — this is the real, current response, not a placeholder you need to work around.', example: { success: false, message: 'Active Directory sign-in is not configured on this server. Implement services/ad.service.js (LDAPS bind) and wire it in here.', errors: null } },
    ],
  },

  'POST /auth/password-reset/request': {
    summary: 'Request a password reset email. Always returns 200 regardless of whether the email exists, to avoid leaking which accounts are registered.',
    parameters: [],
    requestBody: { fields: [{ name: 'email', type: 'string', required: true, description: '' }] },
    responses: [{ status: 200, description: '', example: { success: true, message: 'If that account exists, a reset link has been sent', data: null } }],
  },

  'POST /auth/password-reset/confirm': {
    summary: 'Complete a password reset using the token from the emailed link.',
    parameters: [],
    requestBody: { fields: [
      { name: 'token', type: 'string', required: true, description: 'From the reset email link, valid 30 minutes.' },
      { name: 'newPassword', type: 'string', required: true, description: 'Minimum 10 characters.' },
    ] },
    responses: [
      { status: 200, description: 'Password changed — all existing sessions for this account are revoked.', example: { success: true, message: 'Password updated — please sign in again', data: null } },
      { status: 400, description: 'Token invalid, expired, or already used.', example: { success: false, message: 'Reset link is invalid or expired', errors: null } },
    ],
  },

  /* =============================== MFA =============================== */

  'POST /mfa/enroll/totp/start': {
    summary: 'First-time TOTP enrolment, step 1 of 2 — generates a secret and returns a QR code to scan. Uses the interim mfaToken from Login, not a full accessToken (the account can\'t have one yet).',
    parameters: [{ name: 'Authorization', in: 'header', type: 'string', required: true, description: 'Bearer {{mfaToken}} — from a Login response with mfaRequired: true.' }],
    responses: [
      { status: 200, description: '', example: { success: true, message: 'Scan the QR code in your authenticator app, then confirm with the 6-digit code', data: { qrDataUrl: 'data:image/png;base64,iVBORw0KG...', base32Secret: 'JBSWY3DPEHPK3PXP' } } },
      AUTH_401,
    ],
  },

  'POST /mfa/enroll/totp/confirm': {
    summary: 'First-time TOTP enrolment, step 2 of 2 — confirms the 6-digit code and, on success, completes sign-in (returns full tokens).',
    parameters: [{ name: 'Authorization', in: 'header', type: 'string', required: true, description: 'Bearer {{mfaToken}}' }],
    requestBody: { fields: [{ name: 'token', type: 'string', required: true, description: 'Current 6-digit code from the authenticator app.' }] },
    responses: [
      { status: 200, description: 'Enrolled and signed in.', example: { success: true, message: 'Logged in', data: { accessToken: '<jwt>', refreshToken: '<jwt>', user: { id: 1, fullName: 'Sipho Nkambo', email: 'admin@pspf.co.sz', role: 'System Administrator' } } } },
      { status: 400, description: 'Wrong code, or Start was never called.', example: { success: false, message: 'Incorrect code', errors: null } },
    ],
  },

  'POST /mfa/totp/enroll': {
    summary: 'Add/replace an authenticator for an account that\'s ALREADY signed in (e.g. a new phone). Different from the pair above: needs a full accessToken.',
    parameters: [],
    responses: [{ status: 200, description: '', example: { success: true, message: 'Scan the QR code, then confirm with /api/mfa/totp/confirm', data: { qrDataUrl: 'data:image/png;base64,...', base32Secret: 'JBSWY3DPEHPK3PXP' } } }, AUTH_401],
  },

  'POST /mfa/totp/confirm': {
    summary: 'Confirms the authenticated re-enrolment started by POST /mfa/totp/enroll.',
    parameters: [],
    requestBody: { fields: [{ name: 'token', type: 'string', required: true, description: '' }] },
    responses: [{ status: 200, description: '', example: { success: true, message: 'Authenticator app confirmed', data: null } }, { status: 400, description: 'Wrong code.', example: { success: false, message: 'Incorrect code', errors: null } }],
  },

  'POST /mfa/backup-codes/generate': {
    summary: 'Generates 8 one-time backup codes, replacing any existing set. Plaintext codes are returned exactly once.',
    parameters: [],
    responses: [{ status: 200, description: '', example: { success: true, message: 'Store these codes securely — they will not be shown again', data: { codes: ['a1b2c3d4e5', 'f6a7b8c9d0', '...6 more'] } } }, AUTH_401],
  },

  'POST /mfa/challenge/sms/send': {
    summary: 'Sends a 6-digit OTP by SMS to the phone number on file. Requires the backend\'s Twilio credentials configured and reachable.',
    parameters: [{ name: 'Authorization', in: 'header', type: 'string', required: true, description: 'Bearer {{mfaToken}}' }],
    responses: [
      { status: 200, description: '', example: { success: true, message: 'Code sent by SMS', data: null } },
      { status: 400, description: 'No phone number on file for this account.', example: { success: false, message: 'No phone number on file for SMS MFA', errors: null } },
    ],
  },

  'POST /mfa/challenge/email/send': {
    summary: 'Sends a 6-digit OTP by email. Requires the backend\'s SMTP configured and reachable.',
    parameters: [{ name: 'Authorization', in: 'header', type: 'string', required: true, description: 'Bearer {{mfaToken}}' }],
    responses: [{ status: 200, description: '', example: { success: true, message: 'Code sent by email', data: null } }],
  },

  'POST /mfa/verify/totp': {
    summary: 'Verifies a TOTP code from an ALREADY-enrolled authenticator and completes sign-in. If nothing is enrolled yet, use the Enroll TOTP (login) pair instead — this endpoint cannot enrol one.',
    parameters: [{ name: 'Authorization', in: 'header', type: 'string', required: true, description: 'Bearer {{mfaToken}}' }],
    requestBody: { fields: [{ name: 'token', type: 'string', required: true, description: '' }] },
    responses: [
      { status: 200, description: 'Signed in.', example: { success: true, message: 'Logged in', data: { accessToken: '<jwt>', refreshToken: '<jwt>', user: { id: 1, fullName: 'Sipho Nkambo', email: 'admin@pspf.co.sz', role: 'System Administrator' } } } },
      { status: 400, description: 'No verified TOTP method exists for this account yet — enrol first.', example: { success: false, message: 'TOTP is not enrolled for this account', errors: null } },
    ],
  },

  'POST /mfa/verify/otp': {
    summary: 'Verifies an SMS or email OTP (same endpoint for both — the code lookup doesn\'t care which channel it was sent on) and completes sign-in.',
    parameters: [{ name: 'Authorization', in: 'header', type: 'string', required: true, description: 'Bearer {{mfaToken}}' }],
    requestBody: { fields: [{ name: 'code', type: 'string', required: true, description: '6-digit code from SMS or email.' }] },
    responses: [
      { status: 200, description: 'Signed in.', example: { success: true, message: 'Logged in', data: { accessToken: '<jwt>', refreshToken: '<jwt>', user: { id: 1, fullName: 'Sipho Nkambo', email: 'admin@pspf.co.sz', role: 'System Administrator' } } } },
      { status: 400, description: 'Wrong code, or it expired (5 minute window).', example: { success: false, message: 'Code is incorrect or has expired', errors: null } },
    ],
  },

  'POST /mfa/verify/backup-code': {
    summary: 'Verifies a one-time backup code and completes sign-in. The code is consumed and can\'t be reused.',
    parameters: [{ name: 'Authorization', in: 'header', type: 'string', required: true, description: 'Bearer {{mfaToken}}' }],
    requestBody: { fields: [{ name: 'code', type: 'string', required: true, description: '' }] },
    responses: [
      { status: 200, description: 'Signed in.', example: { success: true, message: 'Logged in', data: { accessToken: '<jwt>', refreshToken: '<jwt>', user: { id: 1, fullName: 'Sipho Nkambo', email: 'admin@pspf.co.sz', role: 'System Administrator' } } } },
      { status: 400, description: 'Code invalid or already used.', example: { success: false, message: 'Backup code is invalid or already used', errors: null } },
    ],
  },

  /* ========================= USERS & GROUPS ========================== */

  'GET /users': {
    summary: 'List all users — System Administrator / Records Manager only.',
    parameters: [],
    responses: [{ status: 200, description: '', example: { success: true, message: 'OK', data: [{ id: 3, full_name: 'Thabo Simelane', email: 'records.officer@pspf.co.sz', role_name: 'Records Officer', department_name: 'Benefits', is_active: 1, is_locked: 0, mfa_enabled: 0 }] } }, FORBIDDEN_403],
  },

  'PUT /users/{{userId}}/role': {
    summary: 'Change a user\'s role — System Administrator only.',
    parameters: [{ name: 'userId', in: 'path', type: 'integer', required: true, description: '' }],
    requestBody: { fields: [{ name: 'roleId', type: 'integer', required: true, description: 'FK to roles.id.' }] },
    responses: [{ status: 200, description: '', example: { success: true, message: 'Role updated', data: null } }, FORBIDDEN_403],
  },

  'PUT /users/{{userId}}/lock': {
    summary: 'Lock or unlock a user\'s account — System Administrator only.',
    parameters: [{ name: 'userId', in: 'path', type: 'integer', required: true, description: '' }],
    requestBody: { fields: [{ name: 'locked', type: 'boolean', required: true, description: '' }] },
    responses: [{ status: 200, description: '', example: { success: true, message: 'Account updated', data: null } }],
  },

  'GET /users/groups/all': {
    summary: 'List groups with their members.',
    parameters: [],
    responses: [{ status: 200, description: '', example: { success: true, message: 'OK', data: [{ id: 1, name: 'Benefits Team', description: 'All Benefits department staff', members: [{ id: 3, full_name: 'Thabo Simelane' }] }] } }],
  },

  'POST /users/groups/{{groupId}}/members': {
    summary: 'Add a user to a group.',
    parameters: [{ name: 'groupId', in: 'path', type: 'integer', required: true, description: '' }],
    requestBody: { fields: [{ name: 'userId', type: 'integer', required: true, description: '' }] },
    responses: [{ status: 200, description: '', example: { success: true, message: 'Member added', data: null } }],
  },

  'PUT /users/me': {
    summary: 'Self-service profile update (name, phone) for the signed-in user.',
    parameters: [],
    requestBody: { fields: [
      { name: 'fullName', type: 'string', required: false, description: '' },
      { name: 'phoneNumber', type: 'string', required: false, description: '' },
    ] },
    responses: [{ status: 200, description: '', example: { success: true, message: 'Profile updated', data: null } }],
  },

  'PUT /users/me/password': {
    summary: 'Self-service password change — requires the current password.',
    parameters: [],
    requestBody: { fields: [
      { name: 'currentPassword', type: 'string', required: true, description: '' },
      { name: 'newPassword', type: 'string', required: true, description: 'Minimum 10 characters.' },
    ] },
    responses: [
      { status: 200, description: '', example: { success: true, message: 'Password changed', data: null } },
      { status: 401, description: 'currentPassword is wrong.', example: { success: false, message: 'Current password is incorrect', errors: null } },
    ],
  },

  /* ============================= FOLDERS ============================= */

  'GET /folders': {
    summary: 'Flat list of every folder — the client builds the tree from parent_id.',
    parameters: [],
    responses: [{ status: 200, description: '', example: { success: true, message: 'OK', data: [{ id: 1, parent_id: null, name: 'Pension Claims', path: 'Pension Claims', retention_class_name: 'Pension claim records' }] } }],
  },

  'POST /folders': {
    summary: 'Create a folder, optionally nested under a parent.',
    parameters: [],
    requestBody: { fields: [
      { name: 'name', type: 'string', required: true, description: '' },
      { name: 'parentId', type: 'integer', required: false, description: 'Omit or null for a top-level folder.' },
      { name: 'departmentId', type: 'integer', required: false, description: '' },
      { name: 'retentionClassId', type: 'integer', required: false, description: 'Inherited by every document placed in this folder unless overridden.' },
    ] },
    responses: [{ status: 201, description: '', example: { success: true, message: 'Folder created', data: { id: 5, path: 'Pension Claims / 2026 / Retirement' } } }],
  },

  /* ============================ DOCUMENTS ============================ */

  'GET /documents': {
    summary: 'Search/list records. Full-text on title plus exact/partial match on record number and member number.',
    parameters: [
      { name: 'q', in: 'query', type: 'string', required: false, description: 'Free text — title, record number, or member number.' },
      { name: 'folderId', in: 'query', type: 'integer', required: false, description: '' },
      { name: 'departmentId', in: 'query', type: 'integer', required: false, description: '' },
      { name: 'status', in: 'query', type: 'string', required: false, description: 'draft | pending_approval | approved | rejected | declared_final | archived | disposed' },
      { name: 'documentTypeId', in: 'query', type: 'integer', required: false, description: '' },
    ],
    responses: [{ status: 200, description: 'Up to 200 results, newest first.', example: { success: true, message: 'OK', data: [{ id: 1, record_no: 'PC-2026-0433', title: 'Application for Retirement Benefit — DLAMINI T.M.', status: 'draft', document_type: 'Claim — Retirement', department: 'Benefits', folder_path: 'Pension Claims', current_version_no: 1, owner_name: 'Thabo Simelane' }] } }],
  },

  'GET /documents/{{documentId}}': {
    summary: 'Full metadata for one record (not its file content — see Get Decrypted Content for that).',
    parameters: [{ name: 'documentId', in: 'path', type: 'integer', required: true, description: '' }],
    responses: [{ status: 200, description: '', example: { success: true, message: 'OK', data: { id: 1, record_no: 'PC-2026-0433', title: 'Application for Retirement Benefit', status: 'draft', classification: 'restricted', document_type: 'Claim — Retirement', folder_path: 'Pension Claims', owner_name: 'Thabo Simelane' } } }, NOT_FOUND_404('Record')],
  },

  'POST /documents': {
    summary: 'Register a new record: encrypts the uploaded file (AES-256-GCM, fresh key per version) and uploads it to the active cloud storage provider before writing any database rows.',
    parameters: [],
    requestBody: { fields: [
      { name: 'file', type: 'file', required: true, description: 'multipart/form-data field.' },
      { name: 'recordNo', type: 'string', required: true, description: 'Must be unique, e.g. PC-2026-0433.' },
      { name: 'title', type: 'string', required: true, description: '' },
      { name: 'documentTypeId', type: 'integer', required: true, description: '' },
      { name: 'folderId', type: 'integer', required: true, description: '' },
      { name: 'departmentId', type: 'integer', required: false, description: '' },
      { name: 'memberNumber', type: 'string', required: false, description: '' },
      { name: 'memberName', type: 'string', required: false, description: '' },
      { name: 'classification', type: 'string', required: false, description: 'public | internal | restricted | confidential — defaults to internal.' },
      { name: 'retentionClassId', type: 'integer', required: false, description: 'Overrides the folder\'s retention class for this record specifically.' },
    ] },
    responses: [
      { status: 201, description: '', example: { success: true, message: 'Record registered', data: { id: 12, recordNo: 'PC-2026-0433', versionId: 1 } } },
      { status: 409, description: 'recordNo already exists.', example: { success: false, message: 'A record with this number already exists', errors: null } },
      VALIDATION_422,
    ],
  },

  'GET /documents/{{documentId}}/content': {
    summary: 'Streams the DECRYPTED current version. The server fetches ciphertext from cloud storage, unwraps the stored key, decrypts in memory, verifies the checksum, and streams the result — plaintext never touches server disk.',
    parameters: [
      { name: 'documentId', in: 'path', type: 'integer', required: true, description: '' },
      { name: 'reason', in: 'query', type: 'string', required: false, description: 'Required if the record\'s classification is "confidential" — omitting it on a confidential record returns 400.' },
    ],
    responses: [
      { status: 200, description: 'The decrypted file, with the correct Content-Type and Content-Disposition.', example: '<binary file content>' },
      { status: 400, description: 'Confidential record opened without ?reason=.', example: { success: false, message: 'Confidential records require a stated reason to open (pass ?reason=...)', errors: null } },
      { status: 500, description: 'Decrypted bytes don\'t match the stored checksum — a genuine integrity failure, not something to retry blindly.', example: { success: false, message: 'Integrity check failed — decrypted content does not match the stored checksum', errors: null } },
    ],
  },

  'POST /documents/{{documentId}}/declare-final': {
    summary: 'Marks a record Declared Final and starts its retention clock (retention_due_at = now + the record\'s retention class period).',
    parameters: [{ name: 'documentId', in: 'path', type: 'integer', required: true, description: '' }],
    responses: [{ status: 200, description: '', example: { success: true, message: 'Record declared final — retention clock started', data: null } }, NOT_FOUND_404('Record')],
  },

  /* ============================= VERSIONS ============================= */

  'GET /versions/document/{{documentId}}': {
    summary: 'Version history for a record, newest first.',
    parameters: [{ name: 'documentId', in: 'path', type: 'integer', required: true, description: '' }],
    responses: [{ status: 200, description: '', example: { success: true, message: 'OK', data: [{ id: 1, version_no: 1, file_name: 'claim.pdf', size_bytes: 204800, is_current: 1, created_by: 'Thabo Simelane', created_at: '2026-06-01 09:12:00' }] } }],
  },

  'POST /versions/document/{{documentId}}': {
    summary: 'Upload a new version. The previous version is kept, never overwritten — this just adds a new one and marks it current.',
    parameters: [{ name: 'documentId', in: 'path', type: 'integer', required: true, description: '' }],
    requestBody: { fields: [{ name: 'file', type: 'file', required: true, description: 'multipart/form-data field.' }] },
    responses: [{ status: 201, description: '', example: { success: true, message: 'New version uploaded', data: { versionId: 2, versionNo: 2 } } }, NOT_FOUND_404('Record')],
  },

  'POST /versions/{{versionId}}/restore': {
    summary: 'Promotes an older version to current. This writes a pointer update, not a new file — nothing is deleted.',
    parameters: [{ name: 'versionId', in: 'path', type: 'integer', required: true, description: '' }],
    responses: [{ status: 200, description: '', example: { success: true, message: 'Version 1 promoted to current', data: null } }, NOT_FOUND_404('Version')],
  },

  /* =========================== PERMISSIONS ============================ */

  'GET /permissions/folder/{{folderId}}': {
    summary: 'ACL entries on a folder — own grants only (folders have nothing to inherit from).',
    parameters: [{ name: 'folderId', in: 'path', type: 'integer', required: true, description: '' }],
    responses: [{ status: 200, description: '', example: { success: true, message: 'OK', data: { own: [{ id: 1, principal_type: 'user', principal_name: 'Thabo Simelane', permission_level: 'edit' }], inherited: [] } } }],
  },

  'GET /permissions/document/{{documentId}}': {
    summary: 'ACL entries on a document — its own grants plus what it inherits from its parent folder.',
    parameters: [{ name: 'documentId', in: 'path', type: 'integer', required: true, description: '' }],
    responses: [{ status: 200, description: '', example: { success: true, message: 'OK', data: { own: [], inherited: [{ id: 1, principal_type: 'group', principal_name: 'Benefits Team', permission_level: 'view' }] } } }],
  },

  'POST /permissions/folder/{{folderId}}': {
    summary: 'Grant access on a folder — inherited by every document inside it.',
    parameters: [{ name: 'folderId', in: 'path', type: 'integer', required: true, description: '' }],
    requestBody: { fields: [
      { name: 'principalType', type: 'string', required: true, description: 'user | group' },
      { name: 'principalId', type: 'integer', required: true, description: '' },
      { name: 'permissionLevel', type: 'string', required: true, description: 'view | comment | edit | approve | full_control' },
    ] },
    responses: [{ status: 201, description: '', example: { success: true, message: 'Access granted', data: { id: 4 } } }],
  },

  'DELETE /permissions/{{aclId}}': {
    summary: 'Revoke one ACL entry, by its own id (not the folder/document id).',
    parameters: [{ name: 'aclId', in: 'path', type: 'integer', required: true, description: 'The id returned when the grant was created.' }],
    responses: [{ status: 200, description: '', example: { success: true, message: 'Access revoked', data: null } }, NOT_FOUND_404('ACL entry')],
  },

  'GET /permissions/matrix/all': {
    summary: 'The full role × module permission matrix — System Administrator only.',
    parameters: [],
    responses: [{ status: 200, description: '', example: { success: true, message: 'OK', data: [{ role_id: 5, role_name: 'System Administrator', module: 'repository', can_view: 1, can_edit: 1 }] } }, FORBIDDEN_403],
  },

  'PUT /permissions/matrix': {
    summary: 'Upsert one role/module permission cell — System Administrator only.',
    parameters: [],
    requestBody: { fields: [
      { name: 'roleId', type: 'integer', required: true, description: '' },
      { name: 'module', type: 'string', required: true, description: 'e.g. repository, viewer, capture, versions, permissions, workflow, audit, retention, integrations, reports, approvals.' },
      { name: 'canView', type: 'boolean', required: false, description: '' },
      { name: 'canEdit', type: 'boolean', required: false, description: '' },
    ] },
    responses: [{ status: 200, description: '', example: { success: true, message: 'Permission matrix updated', data: null } }, FORBIDDEN_403],
  },

  /* ============================= APPROVALS ============================= */

  'GET /approvals': {
    summary: 'Items currently awaiting approval by the signed-in user\'s role.',
    parameters: [],
    responses: [{ status: 200, description: '', example: { success: true, message: 'OK', data: [{ approval_id: 1, instance_id: 1, document_id: 12, record_no: 'PC-2026-0433', title: 'Application for Retirement Benefit', step_name: 'Manager authorisation', sla_days: 3 }] } }],
  },

  'POST /approvals/{{approvalId}}/approve': {
    summary: 'Approve — advances the workflow to its next step, or to Approved if this was the last one.',
    parameters: [{ name: 'approvalId', in: 'path', type: 'integer', required: true, description: '' }],
    requestBody: { fields: [{ name: 'comment', type: 'string', required: false, description: '' }] },
    responses: [{ status: 200, description: '', example: { success: true, message: 'Item approved', data: null } }, { status: 409, description: 'Already decided.', example: { success: false, message: 'This item has already been decided', errors: null } }],
  },

  'POST /approvals/{{approvalId}}/reject': {
    summary: 'Reject — ends the workflow instance. Does not move to any other step.',
    parameters: [{ name: 'approvalId', in: 'path', type: 'integer', required: true, description: '' }],
    requestBody: { fields: [{ name: 'comment', type: 'string', required: false, description: 'Required in practice even though technically optional.' }] },
    responses: [{ status: 200, description: '', example: { success: true, message: 'Item rejected', data: null } }],
  },

  /* ============================== WORKFLOW ============================== */

  'GET /workflow': {
    summary: 'List all configured workflows with their ordered steps.',
    parameters: [],
    responses: [{ status: 200, description: '', example: { success: true, message: 'OK', data: [{ id: 1, name: 'Retirement Claim Assessment', is_active: 1, steps: [{ step_order: 1, step_name: 'Records check', role_name: 'Records Officer', sla_days: 2 }] }] } }],
  },

  'POST /workflow': {
    summary: 'Create a workflow: a name plus an ordered array of role-based steps with SLAs.',
    parameters: [],
    requestBody: { fields: [
      { name: 'name', type: 'string', required: true, description: '' },
      { name: 'triggerDocTypeId', type: 'integer', required: false, description: '' },
      { name: 'triggerFolderId', type: 'integer', required: false, description: '' },
      { name: 'steps', type: 'array', required: true, description: 'Array of { stepName, roleId, slaDays } — at least one required, in the order they should run.' },
    ] },
    responses: [{ status: 201, description: '', example: { success: true, message: 'Workflow saved', data: { id: 1 } } }, VALIDATION_422],
  },

  'POST /workflow/{{workflowId}}/start/{{documentId}}': {
    summary: 'Start an instance of a workflow against a specific record, at step 1.',
    parameters: [
      { name: 'workflowId', in: 'path', type: 'integer', required: true, description: '' },
      { name: 'documentId', in: 'path', type: 'integer', required: true, description: '' },
    ],
    responses: [{ status: 201, description: '', example: { success: true, message: 'Workflow started', data: { instanceId: 1 } } }, { status: 400, description: 'The workflow has no steps configured.', example: { success: false, message: 'Workflow has no steps configured', errors: null } }],
  },

  /* =============================== AUDIT =============================== */

  'GET /audit': {
    summary: 'Filterable audit trail — up to 500 most recent entries.',
    parameters: [
      { name: 'action', in: 'query', type: 'string', required: false, description: 'e.g. View, Edit, Approve, Capture, Download, Permission, Login, "Login failed", Integration, "Declare record", Disposal, Create, Delete, MFA, Logout.' },
      { name: 'q', in: 'query', type: 'string', required: false, description: 'Matches user name, record id, detail text, or IP address.' },
      { name: 'from', in: 'query', type: 'string', required: false, description: 'ISO date/datetime, inclusive.' },
      { name: 'to', in: 'query', type: 'string', required: false, description: 'ISO date/datetime, inclusive.' },
    ],
    responses: [{ status: 200, description: '', example: { success: true, message: 'OK', data: [{ id: 401, created_at: '2026-06-01 09:12:00', user_name: 'Thabo Simelane', action: 'Capture', record_type: 'document', record_id: '12', detail: 'PC-2026-0433 registered (local)', ip_address: '10.0.0.5' }] } }, FORBIDDEN_403],
  },

  'GET /audit/export.csv': {
    summary: 'Downloads up to 50,000 recent entries as CSV. This download is itself logged (auditing the audit log is intentional).',
    parameters: [],
    responses: [{ status: 200, description: 'text/csv attachment.', example: 'id,created_at,user_name,action,record_type,record_id,detail,ip_address\\n401,"2026-06-01 09:12:00","Thabo Simelane","Capture",...' }],
  },

  'GET /audit/verify-chain': {
    summary: 'Walks the entire hash-chained audit log and confirms no entry has been tampered with or deleted.',
    parameters: [],
    responses: [
      { status: 200, description: 'Chain intact.', example: { success: true, message: 'Hash chain verified — no gaps', data: { valid: true, brokenAtId: null, entries: 4021 } } },
      { status: 200, description: 'Chain broken — investigate starting at brokenAtId.', example: { success: true, message: 'Hash chain broken', data: { valid: false, brokenAtId: 1774, entries: 4021 } } },
    ],
  },

  /* ============================= RETENTION ============================= */

  'GET /retention/classes': {
    summary: 'List retention classes (e.g. "Pension claim records — 7 years").',
    parameters: [],
    responses: [{ status: 200, description: '', example: { success: true, message: 'OK', data: [{ id: 1, code: 'RC-CLAIM-7', name: 'Pension claim records', retention_years: 7, disposal_action: 'transfer_to_national_archives' }] } }],
  },

  'PUT /retention/classes/{{retentionClassId}}': {
    summary: 'Update a retention class — Records Manager / System Administrator only.',
    parameters: [{ name: 'retentionClassId', in: 'path', type: 'integer', required: true, description: '' }],
    requestBody: { fields: [
      { name: 'retentionYears', type: 'integer', required: false, description: '' },
      { name: 'disposalAction', type: 'string', required: false, description: 'destroy | archive | transfer_to_national_archives | review' },
      { name: 'name', type: 'string', required: false, description: '' },
    ] },
    responses: [{ status: 200, description: '', example: { success: true, message: 'Retention schedule updated', data: null } }, FORBIDDEN_403],
  },

  'GET /retention/due': {
    summary: 'Records whose retention_due_at has passed and are eligible for disposal review.',
    parameters: [],
    responses: [{ status: 200, description: '', example: { success: true, message: 'OK', data: [{ id: 12, record_no: 'PC-2019-0091', title: 'Retirement claim — archived member', retention_due_at: '2026-05-01 00:00:00', disposal_action: 'transfer_to_national_archives', retention_class_name: 'Pension claim records' }] } }],
  },

  'POST /retention/{{documentId}}/dispose': {
    summary: 'Confirm disposal of a due record — Records Manager / System Administrator only.',
    parameters: [{ name: 'documentId', in: 'path', type: 'integer', required: true, description: '' }],
    responses: [{ status: 200, description: '', example: { success: true, message: 'Record marked disposed', data: null } }, FORBIDDEN_403],
  },

  /* =========================== NOTIFICATIONS ============================ */

  'GET /notifications': {
    summary: 'The signed-in user\'s notifications, newest first (up to 100).',
    parameters: [],
    responses: [{ status: 200, description: '', example: { success: true, message: 'OK', data: [{ id: 9, type: 'approval_pending', title: 'Approval required: PC-2026-0433', is_read: 0, created_at: '2026-06-01 09:13:00' }] } }],
  },

  'PUT /notifications/1/read': {
    summary: 'Mark one notification read. The "1" in this sample request is a literal id — replace it with a real notification id from GET /notifications.',
    parameters: [{ name: 'id', in: 'path', type: 'integer', required: true, description: 'Shown as a literal "1" in this catalog entry — edit the path to a real id before sending.' }],
    responses: [{ status: 200, description: '', example: { success: true, message: 'Marked read', data: null } }],
  },

  'PUT /notifications/read-all': {
    summary: 'Mark every unread notification for the signed-in user as read.',
    parameters: [],
    responses: [{ status: 200, description: '', example: { success: true, message: 'All notifications marked read', data: null } }],
  },

  /* ======================== INTEGRATIONS & CAPTURE ======================== */

  'GET /integrations': {
    summary: 'Status of every configured integration (Active Directory, HRIS, SMTP, SMS, and the three cloud storage providers).',
    parameters: [],
    responses: [{ status: 200, description: '', example: { success: true, message: 'OK', data: [{ id: 'aws_s3', name: 'AWS S3', status: 'disconnected', last_sync_at: null }, { id: 'smtp', name: 'E-mail & notifications', status: 'connected', endpoint: 'smtp.pspf.co.sz:587' }] } }],
  },

  'PUT /integrations/aws_s3': {
    summary: 'Update an integration\'s status/config — System Administrator only. Path segment is the integration id (ad, hris, smtp, sms, aws_s3, azure_blob, gcp_storage) — this sample targets aws_s3, edit it to target another.',
    parameters: [{ name: 'id', in: 'path', type: 'string', required: true, description: 'One of: ad, hris, smtp, sms, aws_s3, azure_blob, gcp_storage.' }],
    requestBody: { fields: [
      { name: 'status', type: 'string', required: false, description: 'connected | disconnected | error' },
      { name: 'endpoint', type: 'string', required: false, description: '' },
      { name: 'configJson', type: 'object', required: false, description: 'Non-secret config only — actual credentials stay in .env, never in this table.' },
    ] },
    responses: [{ status: 200, description: '', example: { success: true, message: 'Integration updated', data: null } }, FORBIDDEN_403],
  },

  'GET /integrations/capture-batches/summary': {
    summary: 'Throughput per intake source (scanner, watched folder, email intake, device upload).',
    parameters: [],
    responses: [{ status: 200, description: '', example: { success: true, message: 'OK', data: [{ source: 'watched_folder', batches: 14, total_pages: 1880, total_documents: 610, avg_success_rate: 98.1 }] } }],
  },

  'POST /integrations/capture-batches': {
    summary: 'Record a completed capture batch\'s stats.',
    parameters: [],
    requestBody: { fields: [
      { name: 'batchNo', type: 'string', required: true, description: 'Must be unique, e.g. B-2026-0044.' },
      { name: 'source', type: 'string', required: true, description: 'network_scanner | watched_folder | email_intake | device_upload' },
      { name: 'pages', type: 'integer', required: false, description: '' },
      { name: 'documents', type: 'integer', required: false, description: '' },
      { name: 'successRate', type: 'number', required: false, description: 'Percentage, e.g. 98.1.' },
    ] },
    responses: [{ status: 201, description: '', example: { success: true, message: 'Batch recorded', data: { id: 15 } } }],
  },

  /* =============================== REPORTS =============================== */

  'GET /reports/by-status': {
    summary: 'Record counts grouped by status.',
    parameters: [],
    responses: [{ status: 200, description: '', example: { success: true, message: 'OK', data: [{ status: 'approved', total: 214 }, { status: 'pending_approval', total: 18 }] } }, FORBIDDEN_403],
  },

  'GET /reports/by-department': {
    summary: 'Record counts grouped by owning department.',
    parameters: [],
    responses: [{ status: 200, description: '', example: { success: true, message: 'OK', data: [{ department: 'Benefits', total: 340 }, { department: 'Finance', total: 92 }] } }],
  },

  'GET /reports/claim-turnaround': {
    summary: 'Average days from a workflow starting to its first decision, grouped by month.',
    parameters: [],
    responses: [{ status: 200, description: '', example: { success: true, message: 'OK', data: [{ month: '2026-05', avg_days_to_first_decision: 3.2 }, { month: '2026-06', avg_days_to_first_decision: 2.8 }] } }],
  },

  'GET /reports/audit-actions': {
    summary: 'Count of audit log entries per action type, most frequent first.',
    parameters: [],
    responses: [{ status: 200, description: '', example: { success: true, message: 'OK', data: [{ action: 'View', total: 5210 }, { action: 'Download', total: 890 }] } }],
  },

  /* =============================== HEALTH =============================== */

  'GET http://localhost:4000/health': {
    summary: 'Liveness check — deliberately unversioned and un-authenticated, so a load balancer or uptime monitor never needs API credentials or to know the current API version.',
    parameters: [],
    responses: [{ status: 200, description: '', example: { status: 'ok', service: 'pspf-edms-api', apiPrefix: '/api/v1', time: '2026-08-16T21:13:27.000Z' } }],
  },
};
