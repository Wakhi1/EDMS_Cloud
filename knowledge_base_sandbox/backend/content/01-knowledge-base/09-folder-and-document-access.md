---
title: Folder & Document Access
description: Grant or revoke view/edit/approve access on a folder or an individual document.
category: Knowledge Base
---

# Folder & Document Access

Access can be granted at the **folder** level (inherited by every
document inside it) or on an **individual document** (an exception on
top of whatever the folder grants).

## Granting access

1. Open **Folder & Document Access**.
2. Select the folder or document.
3. Click **Grant Access**, choose a **user or group**, and a
   **permission level**: `view`, `comment`, `edit`, `approve`, or
   `full_control`.
4. Save.

## Checking why someone can (or can't) see something

The access panel for any folder or document shows two lists: its
**own** grants, and what it **inherits** from its parent folder. If
someone should have access and doesn't, check both — a document-level
grant only ever *adds* access, it never removes what the folder
already grants.

## Try it in the Sandbox

Sandbox → **Permissions** folder → **Get ACL for Folder** / **Get ACL
for Document**, **Grant ACL on Folder**, **Revoke ACL Entry**.
