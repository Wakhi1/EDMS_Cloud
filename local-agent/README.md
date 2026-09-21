# Local watched-folder agent

Since the EDMS backend is deployed remotely, it can no longer watch a folder
on your own PC the way it can watch a folder on the server itself. This
script bridges that gap: it scans a folder on **this machine** and uploads
whatever it finds to the deployed EDMS, using the same intake pipeline as
Capture & Scan's manual bulk upload (auto-classification, duplicate
detection, workflow auto-routing).

It's single-shot — one run scans once and exits — so it's meant to be run
on a schedule (Windows Task Scheduler), not left running in the background.

## Requirements

- Node.js 18 or later on the PC that will watch the folder (nothing else —
  no npm install needed).
- An API key generated in the deployed app: **Administration / Integrations
  → Local watched-folder agent → Generate key**. Copy it immediately; it's
  only shown once.

## Setup

1. Copy this whole `local-agent` folder to the PC that has the folder you
   want watched (e.g. next to the scanner's save location).
2. Copy `.env.example` to `.env` and fill in `API_BASE_URL`, `API_KEY`, and
   `WATCH_FOLDER`. Ask your Records Administrator for `FOLDER_ID` if you
   want uploads pre-filed into a specific EDMS folder.
3. Test it once by hand: `node agent.js` — it should report either "No new
   files" or a successful upload. Uploaded files move into a `processed`
   subfolder; anything that fails to upload moves into `failed`.
4. Register it in Task Scheduler to run on a repeating interval:
   - Action → Start a program
   - Program/script: `powershell.exe`
   - Add arguments: `-NoProfile -ExecutionPolicy Bypass -File "<full path to>\run.ps1"`
   - Trigger: repeat every 5 minutes (or whatever cadence suits your
     scanning volume), indefinitely

## Notes

- Files are matched into a document type and (optionally) a folder the
  same way any other Capture & Scan intake is — see the app's
  Capture & Scan → Connector status view for a live per-connector picture,
  and the batch's item list for per-file success/failure once uploaded.
- A file that fails to upload (network error, expired/revoked key) is
  moved to `failed/` and left there for a person to look at — it's not
  retried automatically.
- Revoking the API key (Integrations screen) immediately stops this agent
  from being able to upload; generate a new one and update `.env` to
  resume.
