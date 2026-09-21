#!/usr/bin/env node
/**
 * local-agent/agent.js
 * Watches a folder on THIS machine and uploads any files dropped into it
 * to a deployed PSPF EDMS instance, via POST /api/agent/upload — the piece
 * that makes "watched folder" intake work again now that the backend is
 * deployed somewhere else and can no longer see a folder on your PC the
 * way services/intake/watchedFolder.intake.js does for a folder on the
 * server itself.
 *
 * Single-shot by design: one run scans the folder once, uploads whatever
 * it finds, and exits. Schedule it with Windows Task Scheduler (see
 * run.ps1 and README.md in this folder) to run every few minutes, rather
 * than leaving a process running continuously.
 *
 * Requires Node.js 18 or later (uses the built-in fetch/FormData/Blob —
 * no npm install needed).
 *
 * Configure via a `.env` file next to this script (copy .env.example) or
 * environment variables:
 *   API_BASE_URL   e.g. https://edms.example.gov
 *   API_KEY        generated in the deployed app: Integrations ->
 *                  "Local watched-folder agent" -> Generate key
 *   WATCH_FOLDER   absolute path to the folder to watch, e.g. C:\Scans
 *   FOLDER_ID      (optional) numeric id of the EDMS folder new records
 *                  should land in — ask your Records Administrator
 */
const fs = require('fs/promises');
const path = require('path');

async function main() {
  await loadDotEnv(path.join(__dirname, '.env'));

  const apiBaseUrl = process.env.API_BASE_URL;
  const apiKey = process.env.API_KEY;
  const watchFolder = process.env.WATCH_FOLDER;
  const folderId = process.env.FOLDER_ID;

  if (!apiBaseUrl || !apiKey || !watchFolder) {
    console.error('Missing required config. Set API_BASE_URL, API_KEY, and WATCH_FOLDER (see .env.example).');
    process.exitCode = 1;
    return;
  }

  const processedDir = path.join(watchFolder, 'processed');
  const failedDir = path.join(watchFolder, 'failed');
  await fs.mkdir(processedDir, { recursive: true });
  await fs.mkdir(failedDir, { recursive: true });

  const entries = await fs.readdir(watchFolder, { withFileTypes: true });
  const files = entries.filter((e) => e.isFile());
  if (files.length === 0) {
    console.log(`[${new Date().toISOString()}] No new files in ${watchFolder}.`);
    return;
  }

  console.log(`[${new Date().toISOString()}] Found ${files.length} file(s) in ${watchFolder}. Uploading...`);

  const form = new FormData();
  if (folderId) form.append('folderId', folderId);
  const names = [];
  for (const entry of files) {
    const filePath = path.join(watchFolder, entry.name);
    // eslint-disable-next-line no-await-in-loop
    const buffer = await fs.readFile(filePath);
    form.append('files', new Blob([buffer]), entry.name);
    names.push(entry.name);
  }

  try {
    const response = await fetch(`${apiBaseUrl.replace(/\/$/, '')}/api/agent/upload`, {
      method: 'POST',
      headers: { 'X-Api-Key': apiKey },
      body: form,
    });
    const body = await response.json().catch(() => null);
    if (!response.ok) {
      throw new Error((body && body.message) || `HTTP ${response.status}`);
    }

    // The server tells us per-file success/failure via the batch's items;
    // without inspecting those here, treat a 2xx as "delivered" and move
    // everything to processed/ — same non-durable tradeoff the server-side
    // watched-folder intake makes, documented there.
    for (const name of names) {
      // eslint-disable-next-line no-await-in-loop
      await fs.rename(path.join(watchFolder, name), path.join(processedDir, name));
    }
    console.log(`[${new Date().toISOString()}] Uploaded batch ${body && body.data ? body.data.batchNo : ''}: ${names.join(', ')}`);
  } catch (err) {
    console.error(`[${new Date().toISOString()}] Upload failed: ${err.message}`);
    for (const name of names) {
      // eslint-disable-next-line no-await-in-loop
      await fs.rename(path.join(watchFolder, name), path.join(failedDir, name)).catch(() => {});
    }
    process.exitCode = 1;
  }
}

async function loadDotEnv(file) {
  try {
    const text = await fs.readFile(file, 'utf8');
    for (const line of text.split(/\r?\n/)) {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith('#')) continue;
      const eq = trimmed.indexOf('=');
      if (eq === -1) continue;
      const key = trimmed.slice(0, eq).trim();
      const value = trimmed.slice(eq + 1).trim().replace(/^"(.*)"$/, '$1');
      if (!(key in process.env)) process.env[key] = value;
    }
  } catch {
    // No .env file — fine, rely on real environment variables instead.
  }
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
