---
title: Authoring Pages
description: How to add or edit documentation — for admins.
category: Support
---

# Authoring Pages

This site has no page-registration step. Every `.md` file under the
server's `content/` folder becomes a page automatically, the moment
it's saved — the navigation tree is rebuilt from disk on every
request.

## Adding a page through the Admin panel

1. **Admin → Pages → New Page**.
2. Choose (or type) a **folder** — this becomes a nav section, or
   nests inside an existing one if you reuse a name.
3. Choose a **file name** — prefix it with a number (`01-`, `02-`, ...)
   to control its order within that folder; otherwise pages sort
   alphabetically.
4. Write the page in Markdown. Optional **frontmatter** at the top
   lets you set an exact title, description, and category without
   depending on the filename:
   ```
   ---
   title: My Page Title
   description: One line shown in search results and link previews.
   category: Knowledge Base
   ---
   ```
5. Save. The page is live immediately — check the nav.

## Adding a page by editing the server directly

Exactly equivalent to the above: create or edit a `.md` file anywhere
under `content/` (via SSH, SFTP, or your deployment's file system) and
it appears on next page load. This is useful for bulk-importing
existing documentation, or scripting content updates as part of a
release.

## Diagrams

Fenced code blocks tagged `mermaid` render as diagrams automatically
— flowcharts, sequence diagrams, state diagrams, etc. See the
[Solution Architecture](/page/architecture/solution-architecture)
page for a working example, or the
[Mermaid documentation](https://mermaid.js.org/intro/) for syntax.

## Images and video demos

1. **Admin → Media Library → Upload**.
2. Reference the uploaded file from any page using its returned URL:
   ```
   ![Alt text](/api/media/file/<stored-name>)
   ```
   or, for video:
   ```html
   <video controls src="/api/media/file/<stored-name>" style="max-width:100%"></video>
   ```

## What NOT to put in a page

Anything that should update automatically without an edit — sandbox
endpoint definitions, developer account status, API keys — lives in
the database, not in Markdown. Pages are for durable, human-written
explanation; the Sandbox catalog updates itself from the Postman
importer instead (see
[Solution Architecture](/page/architecture/solution-architecture)).
