# What was actually tested, and how

Everything below was run against a real MySQL server and real running
Node processes in the build environment — not just read for
correctness. This document is here so you know exactly what's been
verified versus what's implemented-but-unexercised.

## Environment

- MariaDB 10.11, both `pspf_edms` and `pspf_edms_docs` databases created
  from their schema files, plus the EDMS's seed data and MFA migration.
- The actual `pspf-edms` Node backend running on port 4000.
- This docs portal's Node backend running on port 5000.
- The Postman-to-sandbox importer run against the real
  `PSPF_EDMS_API.postman_collection.json`.

## Verified end-to-end flows

1. **Schema imports** — all four SQL files (EDMS schema, EDMS seed
   data, EDMS MFA migration, docs portal schema) import cleanly with
   zero errors.
2. **Postman → sandbox catalog import** — all 15 folders / 68 requests
   imported correctly on the first structurally-correct attempt; one
   real bug found and fixed (below).
3. **Content auto-discovery** — the nav tree builds correctly from the
   15 seed `.md` files; all 17 internal cross-links between pages were
   checked programmatically and all resolve.
4. **Developer registration → admin approval → API key issuance** —
   registered a real account, logged in as the seeded admin, listed
   pending developers, approved the account, issued an API key, and
   confirmed the plaintext key is only ever returned once.
5. **Sandbox proxy — the core mechanism** — using the developer's
   session token + the freshly issued API key:
   - Executed a real `POST /auth/login` against the real EDMS backend
     for a seeded no-MFA account (`records.officer@pspf.co.sz`) and
     got back a genuine JWT.
   - Used that JWT for a real bearer-authenticated call
     (`GET /documents`).
   - Confirmed a **wrong password** correctly proxies through as a
     real `401` with the EDMS's own error message, not swallowed or
     mishandled.
   - Confirmed an **invalid API key** and a **missing API key** are
     both rejected before the request ever reaches the EDMS backend.
   - Confirmed usage is logged: `sandbox_request_logs` picked up the
     call with correct user, key, status code, and duration.
6. **File upload through the proxy — the hardest path** — created a
   folder and registered a document with a real file attached, sent as
   multipart through the sandbox's `POST /sandbox/execute`, forwarded
   by the docs portal to the EDMS backend, which:
   - encrypted it (confirmed the file on disk is opaque binary, not
     the original text),
   - stored the correct checksum,
   - and decrypted it back to **byte-for-byte the original content**
     on retrieval.
7. **Admin page authoring** — created a page via the API, confirmed it
   appeared in the nav tree on the very next request (no restart), and
   confirmed the file really exists on disk at the expected path.
8. **Media upload** — uploaded a file as admin, confirmed it appears
   in the media list with the correct stored name and URL.
9. **Content search** — confirmed free-text search matches across
   multiple real pages by content, not just title.

## One real bug found by this testing, and fixed

**Symptom:** creating a new page via `PUT /content/page/knowledge-base/...`
with `folder: "knowledge-base"` created a **second**, duplicate
"Knowledge Base" nav section instead of adding the page to the
existing one (whose real directory on disk is `01-knowledge-base`,
numeric-prefixed for ordering).

**Root cause:** the page-authoring endpoint used whatever folder name
the caller typed as a literal disk path, with no attempt to match it
against an existing section.

**Fix:** `content.service.js` gained `resolveFolderPath()`, which
matches a typed folder slug (`"knowledge-base"`) against real
directories on disk the same way page slugs already resolve
(stripping numeric prefixes, case/space normalising) — so typing the
display name of an existing section now correctly appends to it, and
only a genuinely new name creates a new section. Verified by
re-running the exact same request and confirming exactly one
"Knowledge Base" section with the new page appended in the right
order.

## Also caught by testing (schema-level)

`sandbox_folders.description` and `sandbox_requests.description` were
originally `VARCHAR(500)` / `VARCHAR(1000)` — too small for the MFA
folder's real description text copied from the Postman collection,
which caused `Data too long for column` on that specific folder during
import. Widened both to `TEXT` in the schema before this was shipped.

## Follow-up: API keys emailed to the developer (verified with a real SMTP send)

Added `services/email.service.js` and wired it into
`POST /admin/developers/:id/api-keys` — issuing a key now emails it
directly to the developer, with the key still also returned to the
admin's screen as a fallback (shown in a proper modal now, not a
plain `alert()`, with the email delivery status made explicit).

Tested both branches for real:

- **SMTP not configured** — issuing a key returns
  `emailSent: false` with a clear `emailError`, key issuance still
  succeeds, and the admin UI explains delivery wasn't available and to
  copy the key manually. Nothing silently swallowed.
- **SMTP configured** — stood up a real local SMTP listener (Python's
  `aiosmtpd`), pointed the portal at it, issued a key, and confirmed
  the actual email arrived: correct recipient, correct subject, the
  real key, and a correctly resolved link back to the portal's sandbox
  page. `emailSent: true` in the response, and a second audit log
  entry (`Email API key`) recorded separately from the `Issue API key`
  entry.

One dependency gap this caught: `nodemailer` was used in
`email.service.js` but never added to `package.json` — added now (a
fresh `npm install` would have failed on this without the fix).

## Follow-up: API versioning + multiple sandbox environments (all tested live)

- **EDMS backend now mounts everything under `/api/v1`** (configurable
  via `API_PREFIX`). Verified live: `POST /api/v1/auth/login` succeeds,
  the old unversioned `POST /api/auth/login` now correctly 404s, and
  `/health` reports the active prefix.
- **Sandbox catalog paths are unaffected** — they're stored relative
  (e.g. `/auth/login`), with the version segment living entirely in
  each environment's `base_url`. Re-ran the Postman importer against
  the updated collection and confirmed the stored paths are unchanged
  while the environment's `base_url` now carries `/api/v1`.
- **Sandbox environments expanded from one hardcoded row to a real
  admin-managed feature.** Added `PUT`/`DELETE` routes (only `POST`
  existed before) and a full **Admin → Environments** tab (there was
  no frontend UI for this at all previously — the POST route existed
  but nothing called it). Tested live: listed the 4 seeded
  environments, added a 5th, set it as default, confirmed a malformed
  URL is rejected before it's stored, deleted it, deleted down to a
  single remaining environment, and confirmed deleting the *last* one
  is blocked (`409`) so the Sandbox can never end up with nowhere to
  point.
- **Deleting the current default auto-promotes another environment to
  default** rather than leaving the system with no default — tested
  by deleting a default environment and confirming exactly one other
  row picked it up.

## Follow-up: professional Sandbox UI + full API reference documentation

**Structured docs for all 68 endpoints.** Added `sandbox_requests.doc_json`
(migration 003) and `scripts/endpoint-docs.js` — a hand-written
documentation manifest covering every single endpoint: summary,
parameters (path/query, typed, required/optional, described),
request body fields, and realistic example responses per status code
actually returned by that route (not just the 200 case — auth
failures, validation errors, 404s, 409s, etc., where relevant).
`import-postman.js` merges this into the catalog at import time.

Verified by direct cross-reference, not by eye: wrote a script that
extracts every method+path from the real Postman collection and
confirms each one has exactly one matching manifest entry — **0
missing, 0 orphaned** on the first complete pass.

**A real bug this caught along the way:** `extractPath()` in the
importer wasn't stripping query strings from Postman's raw URLs, so
`GET /documents?q=&folderId={{folderId}}&status=` (the URL as
Postman literally stores it) was landing in the `path` column
verbatim — meaning the query-parameter editor in the Sandbox had no
effect on those specific requests, since the query was already baked
into a path string it was supposedly separate from. Confirmed via a
live query before the fix (`/documents?q=&folderId=...` sitting in
the `path` column) and after (clean `/documents`), then re-verified
the fixed path executes correctly end-to-end through the real proxy
against the real EDMS backend (`GET /documents` → `200`, resolved URL
`http://localhost:4000/api/v1/documents`, correct headers and body).

**Also caught:** a `mysql` CLI display artifact that looked exactly
like real UTF-8 corruption of em-dash characters in stored
descriptions (`\udc97` lone surrogates) when piped through `python3
-m json.tool`. Traced it by reading the same value back through the
actual application stack (Node + mysql2, and separately
`--default-character-set=utf8mb4` on the CLI) and confirmed the data
is stored and served correctly — the corruption was in my test
command, not the system. Worth recording so it doesn't get
misdiagnosed as a real bug later.

**UI rebuild** (`frontend/js/sandbox.js`, fully rewritten,
`frontend/css/styles.css` sandbox section replaced): a "Documentation"
tab per endpoint (parameters/body/response tables, syntax-highlighted
examples) alongside "Try it"; response viewer with Body/Headers tabs
and real JSON syntax highlighting (highlight.js, already loaded for
markdown pages — fixed a light-theme-on-dark-background mismatch this
introduced before shipping it); "Copy as cURL" generating a
ready-to-paste command that targets the real environment directly
(not through this portal's proxy); a catalog search/filter box; and
local (browser-only, never uploaded) request history with one-click
replay — documented in-UI why it's client-side only (request/response
bodies can contain tokens and member data; the server's own
`sandbox_request_logs` deliberately never stores bodies, only
method/path/status/duration for admin usage review).

## Not independently re-tested after later edits

Some later small edits (docs README wording, minor CSS) were not
re-run through the live servers after being written, since they don't
touch executable logic. If you want a belt-and-braces check, `npm run
dev` in `backend/` and click through Admin → Developers → Sandbox
yourself — the flow above is exactly what to expect.
