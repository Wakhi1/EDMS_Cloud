---
title: Configuring a Workflow
description: Define an ordered, role-based approval chain with SLAs, for an administrator setting one up.
category: Knowledge Base
---

# Configuring a Workflow

Workflows are built once by an administrator (or Records Manager) and
then reused every time a matching record needs routing — see
[Route a Document for Approval](/page/knowledge-base/route-a-document-for-approval)
for how they're used day to day.

## Steps

1. Open **Workflow Designer**.
2. Click **New Workflow** and give it a name (e.g. *"Retirement Claim
   Assessment"*).
3. Optionally, set a **trigger document type** and/or **trigger
   folder** — records matching these can have this workflow suggested
   automatically.
4. Add **steps**, in order. For each step, set:
   - a **step name** (e.g. *"Records check"*, *"Manager
     authorisation"*)
   - the **role** whose members can act on this step
   - an **SLA** in days
5. Save.

At runtime, the first available user with the step's role is assigned
each step as it becomes active.

## Try it in the Sandbox

Sandbox → **Workflow** folder → **Create Workflow**.
