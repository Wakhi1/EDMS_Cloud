---
title: Technical Support Arrangements
description: Support tiers, contact channels, response times, and escalation path for the EDMS.
category: Support
---

# Technical Support Arrangements

## Support tiers

| Tier | Handles | Typical response time |
|---|---|---|
| **Tier 1 — Service Desk** | Password resets, account lockouts, "how do I..." questions, MFA re-enrolment | 4 business hours |
| **Tier 2 — ICT Department** | Integration issues (AD, HRIS, SMTP, SMS), permission/role configuration, capture batch failures | 1 business day |
| **Tier 3 — Systems Administrator / Vendor** | API errors, data integrity issues, encryption/key problems, outages | 4 hours (business-critical), 2 business days (non-critical) |

## Contact channels

- **Service Desk**: `servicedesk@pspf.co.sz` / internal extension 2200
- **ICT Department**: `ict-support@pspf.co.sz`
- **Emergency (system down)**: escalate directly to the on-call System
  Administrator via the number listed on the internal ICT wiki.

## What to include in a support request

To avoid a round-trip asking for basics, include:

1. Your **name, role, and department**
2. The **record number** or **URL** involved, if applicable
3. **What you expected** to happen vs. **what actually happened**
4. A **screenshot**, if it's a visual issue
5. The approximate **time** it occurred (helps us find the right audit
   log / error log entries fast)

## Severity definitions

- **Critical** — system unavailable for all users, or data
  integrity/security is at risk. Immediate escalation to Tier 3.
- **High** — a core function (capture, approval, retrieval) is broken
  for a group of users, no workaround.
- **Medium** — a function is broken but a workaround exists, or it
  affects a small number of users.
- **Low** — cosmetic issues, enhancement requests, documentation gaps.

## Maintenance windows

Scheduled maintenance is announced at least 5 business days in advance
via the in-app **Notifications** module and email to all active
accounts. Emergency maintenance (security patches) may occur with
shorter notice.
