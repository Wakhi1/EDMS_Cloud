---
title: Reject a Document
description: Decline a record at an approval step, with a comment explaining why.
category: Knowledge Base
---

# Reject a Document

Any approver reviewing a record at their step can reject it instead of
approving it. Rejection **ends the workflow instance** — it does not
move to a later step or bounce back to an earlier one; the record's
status becomes **Rejected** and the person who submitted it needs to
correct it and start a new workflow instance if it should proceed.

## Steps

1. Open **Approvals**.
2. Find the record and click **Reject**.
3. Enter a **comment** explaining what needs to change. This is
   required in practice, even though the field is technically
   optional — a rejection without a reason just creates rework for
   everyone.
4. Confirm.

## What happens

- The record's status changes to **Rejected**.
- The workflow instance is marked **rejected** (not deleted — it stays
  visible in the record's history).
- An audit entry is written with your comment attached.
- No further approvers in the chain are notified — the chain stops
  here.

## After a rejection

The record owner should:
1. Review the comment.
2. Either edit the record (upload a corrected version — see
   [Version History](/page/knowledge-base/version-history)) or
   correct the underlying issue.
3. Start a **new** workflow instance once it's ready to go through
   approval again.

## Try it in the Sandbox

Sandbox → **Approvals** folder → **Reject** (needs an `approvalId`
from **My Approval Inbox** first).
