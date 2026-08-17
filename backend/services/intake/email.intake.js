/**
 * services/intake/email.intake.js
 * Polls a mailbox for unseen messages with attachments via imapflow +
 * mailparser. Real connector, same standard as the FTP/watched-folder
 * intake — connects for real once IMAP credentials are configured, fails
 * cleanly until then. Also the landing point for a physical scanner's
 * "scan to email" feature — an attachment arriving here is captured on the
 * next poll like any other. The password is read from
 * IMAP_INTAKE_PASSWORD in .env (this app's existing SMTP config is
 * outbound-only and cannot be reused for inbound polling).
 *
 * "Don't reprocess" strategy: each parsed message is flagged \Seen
 * immediately after its attachments are extracted, before the caller
 * attempts registration — see watchedFolder.intake.js's doc comment for
 * why this tradeoff is acceptable for a demo-scope poller.
 */
const { ImapFlow } = require('imapflow');
const { simpleParser } = require('mailparser');
const { mimeFromExtension } = require('../../utils/mimeType');

function buildClient(config) {
  return new ImapFlow({
    host: config.host,
    port: config.port || 993,
    secure: true,
    auth: { user: config.user, pass: process.env.IMAP_INTAKE_PASSWORD || '' },
    logger: false,
  });
}

async function testConnection(config) {
  if (!config.host) return { ok: false, message: 'No IMAP host configured' };
  const client = buildClient(config);
  try {
    await client.connect();
    return { ok: true, message: `Connected to ${config.host}` };
  } catch (err) {
    return { ok: false, message: err.message };
  } finally {
    try { await client.logout(); } catch { /* already disconnected */ }
  }
}

async function poll(config) {
  if (!config.host) return []; // not configured yet — nothing to do, not an error
  const client = buildClient(config);
  const files = [];
  await client.connect();
  try {
    const lock = await client.getMailboxLock(config.mailbox || 'INBOX');
    try {
      for await (const message of client.fetch({ seen: false }, { source: true, uid: true })) {
        const parsed = await simpleParser(message.source);
        for (const attachment of parsed.attachments || []) {
          const fileName = attachment.filename || `email-attachment-${message.uid}`;
          files.push({
            fileName,
            buffer: attachment.content,
            mimeType: attachment.contentType || mimeFromExtension(fileName),
          });
        }
        await client.messageFlagsAdd(message.uid, ['\\Seen'], { uid: true });
      }
    } finally {
      lock.release();
    }
  } finally {
    await client.logout();
  }
  return files;
}

module.exports = { poll, testConnection };
