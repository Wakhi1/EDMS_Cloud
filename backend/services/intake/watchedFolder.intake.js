/**
 * services/intake/watchedFolder.intake.js
 * Auto-captures files dropped into a local directory — zero external
 * credentials needed, so this is the one intake channel fully demoable
 * without real infrastructure. Also the landing point for a physical
 * network scanner's "scan to folder" feature: point the scanner at this
 * same directory and it's picked up on the next poll, same as any other
 * file.
 *
 * "Don't reprocess" strategy: a captured file is moved into a `processed/`
 * (or `failed/`) subdirectory as part of poll() itself, before the caller
 * even attempts registration — see services/capture/batch.service.js for
 * why this simpler-but-non-durable tradeoff is acceptable here.
 */
const fs = require('fs/promises');
const path = require('path');
const { mimeFromExtension } = require('../../utils/mimeType');

function root() {
  return path.resolve(process.env.WATCHED_INTAKE_ROOT || './watched-intake');
}

/** Resolves config.path under the intake root, rejecting any attempt to escape it. */
function inboxDir(config) {
  const base = root();
  const resolved = path.resolve(base, config.path || '');
  if (resolved !== base && !resolved.startsWith(base + path.sep)) {
    throw new Error('Invalid watched-folder path');
  }
  return resolved;
}

async function ensureDirs(config) {
  const dir = inboxDir(config);
  await fs.mkdir(dir, { recursive: true });
  await fs.mkdir(path.join(dir, 'processed'), { recursive: true });
  await fs.mkdir(path.join(dir, 'failed'), { recursive: true });
  return dir;
}

async function testConnection(config) {
  try {
    const dir = await ensureDirs(config || {});
    return { ok: true, message: `Watching ${dir}` };
  } catch (err) {
    return { ok: false, message: err.message };
  }
}

/**
 * Reads every file directly under the inbox dir (subdirectories like
 * processed/failed are naturally excluded since readdir + isFile() only
 * returns direct file entries), moves each into processed/ immediately,
 * and returns their bytes. A file that later fails registration still
 * shows up as a failed capture_batch_item — just not auto-retried.
 */
async function poll(config) {
  const dir = await ensureDirs(config);
  const entries = await fs.readdir(dir, { withFileTypes: true });
  const files = [];
  for (const entry of entries) {
    if (!entry.isFile()) continue;
    const filePath = path.join(dir, entry.name);
    const buffer = await fs.readFile(filePath);
    await fs.rename(filePath, path.join(dir, 'processed', entry.name));
    files.push({ fileName: entry.name, buffer, mimeType: mimeFromExtension(entry.name) });
  }
  return files;
}

module.exports = { poll, testConnection };
