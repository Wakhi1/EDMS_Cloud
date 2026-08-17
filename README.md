# PSPF EDMS — Database + Backend API

Matches the PSPF EDMS prototype (folders, records, versions, approvals,
workflow designer, audit trail with hash chain, retention & disposal,
permissions, security & MFA, integrations, capture, reports).

## 1. File structure

```
pspf-edms/
├── database/
│   └── pspf_edms_schema.sql      # MySQL/XAMPP-compatible schema (import via phpMyAdmin)
└── backend/
    ├── server.js                 # entry point (security, rate limiting, route mounting)
    ├── package.json
    ├── .env.example               # copy to .env and fill in
    ├── config/
    │   ├── db.js                 # MySQL pool (mysql2/promise)
    │   ├── logger.js             # Winston logger (rotating file logs)
    │   └── constants.js          # shared enums
    ├── middleware/
    │   ├── auth.middleware.js         # JWT verification + MFA gate
    │   ├── rbac.middleware.js         # role & module-level access control
    │   ├── upload.middleware.js       # multer (in-memory, for encryption before storage)
    │   ├── requestLogger.middleware.js
    │   └── errorHandler.middleware.js
    ├── services/
    │   ├── crypto.service.js          # envelope encryption (AES-256-GCM DEK wrapped by KEK)
    │   ├── mfa.service.js             # TOTP, SMS/email OTP, backup codes, WebAuthn stub
    │   ├── socialAuth.service.js      # Google + Microsoft ID token verification
    │   ├── email.service.js           # SMTP via nodemailer
    │   ├── sms.service.js             # Twilio SMS
    │   ├── audit.service.js           # hash-chained audit log writer/verifier
    │   └── storage/
    │       ├── storage.service.js     # provider-agnostic facade (routes call only this)
    │       ├── aws.provider.js        # AWS S3
    │       ├── azure.provider.js      # Azure Blob Storage
    │       ├── gcp.provider.js        # Google Cloud Storage
    │       └── local.provider.js      # filesystem fallback for local dev
    ├── routes/                    # ALL business logic lives here (no controllers layer)
    │   ├── index.js
    │   ├── auth.routes.js          # register/login/refresh/logout, Google & Microsoft sign-in
    │   ├── mfa.routes.js           # enrol + verify TOTP/SMS/email/backup codes
    │   ├── users.routes.js         # users & groups administration
    │   ├── folders.routes.js
    │   ├── documents.routes.js     # register, list, view, encrypted download, declare final
    │   ├── versions.routes.js      # version history, new version upload, restore
    │   ├── permissions.routes.js   # folder/document ACLs + role x module matrix
    │   ├── approvals.routes.js     # approval inbox + approve/reject
    │   ├── workflow.routes.js      # workflow designer + start instance
    │   ├── audit.routes.js         # audit trail, CSV export, hash-chain verification
    │   ├── retention.routes.js     # retention classes + disposal queue
    │   ├── notifications.routes.js
    │   ├── integrations.routes.js  # AD/HRIS/SMTP/SMS/cloud status + capture batches
    │   └── reports.routes.js
    └── utils/
        ├── apiResponse.js          # ok()/fail() response envelope
        └── asyncHandler.js         # wraps async routes for the error handler
```

## 2. Database setup (XAMPP)

1. Start Apache + MySQL in the XAMPP control panel.
2. Open phpMyAdmin → Import → select `database/pspf_edms_schema.sql` → Go.
   (Or from a terminal: `mysql -u root -p < database/pspf_edms_schema.sql`)
3. This creates the `pspf_edms` database, all tables, and seed data
   (departments, roles, document types, retention classes, an active KEK
   row, and default integration rows for AWS S3 / Azure Blob / GCS).

## 3. Backend setup

```bash
cd backend
npm install
cp .env.example .env
node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"   # paste into MASTER_KEK_BASE64
npm run dev      # nodemon, or: npm start
```

The API starts on `http://localhost:4000`. Health check: `GET /health`.

## 4. Cloud storage (choose one, or run all three configured and switch via env)

Set `ACTIVE_STORAGE_PROVIDER` in `.env` to `aws_s3`, `azure_blob`,
`gcp_storage`, or `local` (filesystem, for development without any cloud
account). Fill in the matching credential block in `.env`. All routes
call `services/storage/storage.service.js`, which never changes — only
the active provider does.

## 5. Encryption model

- **At rest:** every document version is encrypted with a fresh random
  AES-256-GCM Data Encryption Key (DEK) before it ever leaves the
  server. The DEK itself is "wrapped" (encrypted) with a Key Encryption
  Key (KEK) from `MASTER_KEK_BASE64`, and the wrapped DEK + IVs + auth
  tags are stored in `document_encryption_keys`, keyed to the version.
  The KEK itself is never stored in the database — only its version
  label (`key_encryption_keys.kek_version`), so it can be rotated. Swap
  `crypto.service.js`'s `getKek()` for an AWS KMS / Azure Key Vault /
  GCP KMS call to move key custody off the app server entirely.
- **In transit:** run the API behind TLS (a reverse proxy such as
  nginx/IIS, or Node's `https` module with a certificate) — `helmet()`'s
  HSTS header is already enabled in `server.js`. Cloud SDK calls (S3,
  Blob, GCS) use HTTPS by default.
- **Reading a document:** `GET /api/documents/:id/content` reads the
  wrapped key row from `document_encryption_keys`, unwraps the DEK with
  the KEK, fetches the ciphertext from the active cloud provider,
  decrypts it in memory, verifies its SHA-256 checksum, and streams the
  now-readable file to the authorised browser/viewer. Nothing
  unencrypted is ever written to disk.

## 6. MFA / social auth

- TOTP (authenticator apps), SMS OTP, email OTP and backup codes are
  implemented in `mfa.service.js` + `mfa.routes.js`. FIDO2/WebAuthn
  security-key support has full database columns
  (`user_mfa_methods.webauthn_*`) and a stub verify function ready for
  `@simplewebauthn/server`.
- Roles flagged `mfa_required` in the `roles` table (Approving Manager,
  Finance Officer, Records Manager, System Administrator, Internal
  Auditor by default) are forced through the MFA challenge on every
  login, matching "Roles that touch member money or personal data must
  use a second factor" in the prototype.
- Google and Microsoft sign-in verify the ID token issued by the
  provider's official frontend SDK (Google Identity Services / MSAL.js)
  — the backend never sees a password for these accounts. New accounts
  are not auto-created from social sign-in; a System Administrator must
  provision the user first, then the identity gets linked on first
  login.

## 7. Logging

`config/logger.js` (Winston) writes daily-rotated JSON logs to
`backend/logs/`: `app-*.log` (info+), `error-*.log`, plus separate
`exceptions-*.log` / `rejections-*.log`. All HTTP requests are logged
via `requestLogger.middleware.js`; every audit-relevant action
(view/download/approve/permission changes/etc.) is separately written,
hash-chained, to the `audit_log` table via `services/audit.service.js`.

## 8. Email & SMS

- `services/email.service.js` — SMTP via nodemailer (approval alerts,
  MFA codes, password resets).
- `services/sms.service.js` — Twilio (MFA codes, alerts). Swap the
  Twilio calls for another gateway without touching any route.

## 9. What's intentionally stubbed for you to finish

- WebAuthn/FIDO2 signature verification (`mfa.service.js` →
  `verifyWebAuthnAssertion`).
- Microsoft ID token signature verification against the tenant's JWKS
  (`socialAuth.service.js` — currently checks audience/claims only;
  marked with a `TODO`).
- Active Directory / LDAP bind for on-prem SSO (the `integrations` table
  has a row for it; add a `services/ad.service.js` using `ldapjs` when
  ready).
