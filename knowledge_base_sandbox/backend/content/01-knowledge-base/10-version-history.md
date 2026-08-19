---
title: Version History
description: Upload a new version of a record without losing the old one, and restore an earlier version if needed.
category: Knowledge Base
---

# Version History

The EDMS never overwrites a stored file. Every upload against an
existing record — whether it's a correction after a
[rejection](/page/knowledge-base/reject-a-document) or a routine
update — creates a **new version**, encrypted independently, sitting
alongside every version before it.

## Uploading a new version

1. Open the record and go to **Version History**.
2. Click **Upload New Version**, choose the file.
3. The new version becomes **current**; the previous one is kept, not
   deleted.

## Restoring an older version

1. In **Version History**, find the version you want.
2. Click **Restore**.
3. This doesn't delete anything either — it simply marks that version
   as current again (writing a pointer update, not a new file), and is
   logged like any other edit.

## Try it in the Sandbox

Sandbox → **Versions** folder → **List Versions for Document**,
**Upload New Version**, **Restore Version**.
