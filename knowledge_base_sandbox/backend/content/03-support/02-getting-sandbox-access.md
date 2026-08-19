---
title: Getting Sandbox Access
description: How developer registration, admin approval, and API key issuance works on this portal.
category: Support
---

# Getting Sandbox Access

The API Sandbox lets you test every EDMS endpoint from this site
directly — no Postman installation required. Access is gated in two
steps, matching how a production API key programme normally works.

## Step 1 — Register

1. Click **Sign Up** (top right).
2. Fill in your name, email, password, company/team, and a short note
   on what you're building or testing.
3. Submit. Your account is created in **pending** status — nothing
   works yet.

## Step 2 — Wait for admin approval

An administrator reviews pending registrations under **Admin →
Developers**. They'll either:

- **Approve** — your account becomes active, and they'll issue you an
  **API key** (a string starting `pdk_...`). The portal emails it to
  you directly the moment it's issued; it's also shown to the admin
  once on-screen as a fallback in case mail delivery isn't set up in
  your environment. Either way, it's shown/sent exactly once — if you
  lose it, ask the admin to revoke it and issue a new one; keys can't
  be re-displayed or re-sent.
- **Reject** — you'll need to reach out via
  [Technical Support](/page/support/technical-support-arrangements)
  to understand why.

## Step 3 — Use the Sandbox

1. Log in.
2. Open **Sandbox**.
3. Paste your API key into the **API Key** field in the top bar (kept
   only in your browser session — never stored by this site outside
   of the one-time issuance record).
4. Browse the catalog (organised exactly like the EDMS Postman
   collection: Auth, MFA, Documents, Approvals, ...), pick a request,
   fill in any variables, and **Send**.

## Why two separate credentials?

Your **login** gets you into the documentation site and lets you
browse the sandbox catalog. Your **API key** is what actually
authorises a sandbox call to execute against a real EDMS environment
— matching how you'd use this system in production, where "being
logged into a developer portal" and "having a live API credential"
are deliberately different things.
