/**
 * services/intake/ftp.intake.js
 * Polls a remote FTP directory for new files via basic-ftp (promise-based,
 * no native bindings). Real connector, same as the AWS S3/SMTP integrations
 * already in this app — will genuinely connect once real credentials are
 * configured, and fail cleanly (not crash) until then. The password is set
 * via the Integrations screen (config.password), with FTP_INTAKE_PASSWORD
 * in .env kept as a fallback for existing .env-only deployments — same
 * precedence as storage.service.js#activeProvider().
 */
const { Client } = require('basic-ftp');
const { Writable } = require('stream');
const { posix } = require('path');
const { mimeFromExtension } = require('../../utils/mimeType');

async function withClient(config, fn) {
  const client = new Client();
  try {
    await client.access({
      host: config.host,
      port: config.port || 21,
      user: config.user,
      password: config.password || process.env.FTP_INTAKE_PASSWORD || '',
      // Explicit FTPS (AUTH TLS) — what cPanel offers on port 21. Shared
      // hosts often present the server's own certificate rather than one for
      // the domain, hence the opt-in allowSelfSigned.
      secure: config.secure === true,
      secureOptions: config.secure === true && config.allowSelfSigned === true ? { rejectUnauthorized: false } : undefined,
    });
    return await fn(client);
  } finally {
    client.close();
  }
}

async function testConnection(config) {
  if (!config.host) return { ok: false, message: 'No FTP host configured' };
  try {
    await withClient(config, async (client) => {
      await client.list(config.path || '/');
    });
    return { ok: true, message: `Connected to ${config.host}` };
  } catch (err) {
    return { ok: false, message: err.message };
  }
}

/**
 * Downloads every file directly under config.path, moving each into a
 * processed/ subfolder on the FTP server as part of the same pass — see
 * watchedFolder.intake.js's doc comment for why this "mark before
 * registration confirms" tradeoff is acceptable here.
 */
async function poll(config) {
  if (!config.host) return []; // not configured yet — nothing to do, not an error
  const remoteDir = config.path || '/';
  return withClient(config, async (client) => {
    const listing = await client.list(remoteDir);
    const files = [];
    for (const item of listing) {
      if (!item.isFile) continue;
      const chunks = [];
      const sink = new Writable({ write(chunk, _enc, cb) { chunks.push(chunk); cb(); } });
      await client.downloadTo(sink, posix.join(remoteDir, item.name));
      const buffer = Buffer.concat(chunks);

      await client.ensureDir(posix.join(remoteDir, 'processed'));
      await client.cd('/'); // ensureDir leaves the client's cwd changed — reset before rename
      await client.rename(posix.join(remoteDir, item.name), posix.join(remoteDir, 'processed', item.name));

      files.push({ fileName: item.name, buffer, mimeType: mimeFromExtension(item.name) });
    }
    return files;
  });
}

module.exports = { poll, testConnection };
