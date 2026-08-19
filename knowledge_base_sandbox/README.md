# PSPF EDMS Documentation Portal

A standalone site — UAT scripts, knowledge base, architecture reference,
technical support arrangements, and a live in-browser API sandbox for
the PSPF Electronic Document & Records Management System. Separate
codebase, separate database, separate deployment from the EDMS itself;
it talks to the EDMS purely over HTTP, the same way any other client
would.

**This has been run end-to-end against real MySQL and a real running
EDMS backend** — registration → admin approval → API key issuance →
sandbox execution (including a real file upload, encrypted and stored,
then decrypted back to its original bytes) all verified working, not
just written. See [`TESTING_NOTES.md`](./TESTING_NOTES.md) for exactly
what was checked and one real bug that testing caught and fixed.

## What's included

```
pspf-edms-docs/
├── database/
│   └── pspf_edms_docs_schema.sql   # MySQL/XAMPP-ready, separate DB from the EDMS
├── backend/
│   ├── server.js                    # serves both the API and the static frontend
│   ├── content/                     # the actual knowledge base — 15 seed .md pages
│   │   ├── 00-welcome.md
│   │   ├── 01-knowledge-base/       # the 7 requested workflows + 3 supporting pages
│   │   ├── 02-architecture/         # solution architecture, with a real diagram
│   │   └── 03-support/              # technical support arrangements, sandbox onboarding, authoring guide
│   ├── services/
│   │   ├── content.service.js       # the auto-discovery engine — the core of this whole system
│   │   ├── apiKey.service.js
│   │   └── audit.service.js
│   ├── routes/                      # auth, admin, content, media, sandbox — no controllers layer
│   ├── scripts/import-postman.js    # turns a Postman collection into the sandbox catalog
│   └── postman-source/              # the EDMS Postman collection this portal was seeded from
└── frontend/                        # static SPA: sidebar nav, markdown+mermaid renderer, sandbox UI, admin panel
```

## Quick start

```bash
cd database && mysql -u root -p < pspf_edms_docs_schema.sql
# upgrading an existing install (schema already applied)?
#   mysql -u root -p < pspf_edms_docs_migration_002_more_environments.sql
cd ../backend
npm install
cp .env.example .env    # fill in DB credentials and generate JWT secrets
npm run import:postman  # populates the sandbox catalog from postman-source/
npm run dev
```

The API this portal talks to is versioned (`/api/v1` by default) and
the Sandbox ships with four environment options out of the box (Local
XAMPP, Local Docker Compose, Staging, Production) rather than one
hardcoded `localhost` URL — see **Admin → Environments** and the
Solution Architecture page for how to point them at a real deployment.

Open `http://localhost:5000`. Sign in as `admin@pspf-docs.local` /
`ChangeMe123!` (**change this immediately** — it's a seeded demo
account) to reach **Admin**.

## How the pieces answer what was asked for

- **".md files as pages, auto-discovered"** — `content.service.js`
  walks the `content/` folder on every request; there is no page
  registry to update. See [`content/03-support/03-authoring-pages.md`](./backend/content/03-support/03-authoring-pages.md).
- **The 7 example workflows** — all present under `content/01-knowledge-base/`,
  cross-linked, each ending in a "Try it in the Sandbox" pointer to the
  matching real request.
- **Diagrams, architecture, technical support** — `content/02-architecture/01-solution-architecture.md`
  (a real Mermaid system diagram) and `content/03-support/01-technical-support-arrangements.md`.
- **Sandbox, not Postman** — `scripts/import-postman.js` turned all 68
  requests from the EDMS Postman collection into database rows, merged
  with hand-written structured documentation for every one of them
  (`scripts/endpoint-docs.js`: parameters, request body fields, example
  responses per status code — a real "Documentation" tab per endpoint,
  not just a name and a URL). The frontend's Sandbox view
  (`frontend/js/sandbox.js`) is a from-scratch request builder +
  executor with syntax-highlighted responses, "Copy as cURL", and local
  request history, backed by a server-side proxy
  (`routes/sandbox.routes.js`) that only ever calls admin-configured
  environments — verified this can't be pointed at an arbitrary host.
- **Registration → admin approval → API key** — `routes/auth.routes.js`
  (register, starts `pending`) + `routes/admin.routes.js` (approve,
  issue key). Verified live: a real developer account was registered,
  approved, and issued a key, and that exact key was then used to
  execute real sandbox calls.
- **Admin uploads docs, images, video** — `routes/content.routes.js`
  (page authoring) + `routes/media.routes.js` (file upload), both
  admin-gated, both exercised live.
