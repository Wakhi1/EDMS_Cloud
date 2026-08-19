---
title: Search and Retrieve a Document
description: Find a record by folder, member number, or free text, and open a decrypted copy.
category: Knowledge Base
---

# Search and Retrieve a Document

## Searching

1. Open **Repository** or **Search** from the side navigation.
2. Enter any of: a **member number**, a **record number**, or **free
   text** from the title.
3. Optionally narrow by folder, department, document type, or status.

Search matches the record title (full-text) plus exact/partial matches
on record number and member number.

## Opening a record

1. Click the record in the results list — this opens the **Document
   Viewer**.
2. If the record is marked **confidential**, you'll be asked to state
   a reason before it opens. This is recorded in the audit trail
   alongside the view itself.
3. The file you see is decrypted on the fly: the server fetches the
   encrypted bytes from cloud storage, unwraps the stored key,
   decrypts in memory, verifies the file's checksum hasn't changed
   since it was saved, and streams the result to your browser. Nothing
   unencrypted is ever written to disk on the server.

## If you can't find a record

- Check you have **view access** to the folder it's in — search only
  returns records you're allowed to see.
- Confirm the record hasn't been **archived** or **disposed** — see
  [Archive a Document](/page/knowledge-base/archive-a-document) for how
  those states affect visibility.
- Try searching by **member number** instead of title if the exact
  wording is uncertain.

## Try it in the Sandbox

Sandbox → **Documents** folder → **List / Search Documents** (filter
by `q`, `folderId`, or `status`) and **Get Decrypted Content**.
