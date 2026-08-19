/**
 * services/email.service.js
 * SMTP mailer (nodemailer) — same pattern as the EDMS backend's own
 * email.service.js. Used here specifically for sending a newly-issued
 * sandbox API key directly to the developer, so the admin doesn't have
 * to relay it manually.
 *
 * If SMTP isn't configured/reachable (e.g. working offline, no mail
 * server set up yet), sends fail loudly to the caller but never throw
 * past it in a way that blocks key issuance — see admin.routes.js,
 * which still shows the key on-screen as a fallback either way.
 */
const nodemailer = require('nodemailer');
const logger = require('../config/logger');

let transporter = null;

function getTransporter() {
  if (transporter) return transporter;
  transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: Number(process.env.SMTP_PORT) || 587,
    secure: process.env.SMTP_SECURE === 'true',
    auth: process.env.SMTP_USER
      ? { user: process.env.SMTP_USER, pass: process.env.SMTP_PASSWORD }
      : undefined,
  });
  return transporter;
}

async function sendEmail({ to, subject, text, html }) {
  if (!process.env.SMTP_HOST) {
    logger.warn('Email not sent — SMTP not configured', { to, subject });
    const err = new Error('SMTP is not configured on this server (SMTP_HOST is empty)');
    err.code = 'SMTP_NOT_CONFIGURED';
    throw err;
  }
  const info = await getTransporter().sendMail({
    from: process.env.SMTP_FROM || 'PSPF EDMS Docs Portal <no-reply@pspf.co.sz>',
    to, subject, text, html,
  });
  logger.info('Email sent', { to, subject, messageId: info.messageId });
  return info;
}

/** Sends a newly-issued sandbox API key to the developer it belongs to. */
async function sendApiKeyEmail({ to, fullName, apiKey, label, portalUrl }) {
  const subject = 'Your PSPF EDMS Sandbox API key';
  const text = [
    `Hi ${fullName},`,
    '',
    `Your developer account has been approved and a sandbox API key has been issued: "${label}".`,
    '',
    apiKey,
    '',
    'This key is shown in full only in this email and once in the portal at the moment it was issued — it cannot be retrieved again later. If you lose it, ask an administrator to revoke it and issue a new one.',
    '',
    `Paste it into the API Key field on the Sandbox page${portalUrl ? ` (${portalUrl}/#/sandbox)` : ''} to start making calls.`,
    '',
    'Keep this key private — anyone with it can execute API calls under your account and it will be logged against your name.',
  ].join('\n');

  return sendEmail({ to, subject, text });
}

module.exports = { sendEmail, sendApiKeyEmail };
