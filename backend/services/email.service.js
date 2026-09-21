/**
 * services/email.service.js
 * SMTP mailer (nodemailer) used for approval alerts, OTPs, statement
 * delivery, and password reset links. All sends are logged.
 *
 * Every template sends both html and text parts, built from
 * email_templates.js and branded with this deployment's own company
 * name/logo/colors (services/branding.service.js) — a plain-text-only or
 * unbranded message is one of the stronger signals spam filters use
 * against transactional mail, on top of just looking unprofessional.
 */
const nodemailer = require('nodemailer');
const logger = require('../config/logger');
const { getHomeBrandingWithLogo } = require('./branding.service');
const { buildEmailHtml, buildEmailText } = require('./email_templates');
const { getIntegrationConfig } = require('../utils/integrationConfig');

const LOGO_CID = 'company-logo';

/**
 * The frontend is a Flutter web SPA with no server-side route rewriting
 * (see frontend/lib/core/router/app_router.dart — no usePathUrlStrategy()
 * call, so go_router defaults to hash-based URLs). A link straight to
 * "/approvals" hits the static file server for a path that has no
 * physical resource behind it; "/#/approvals" loads the SPA's index
 * unconditionally and lets go_router resolve the route entirely
 * client-side from the fragment, which the server never even sees.
 */
function appLink(path) {
  return `${process.env.CLIENT_URL}/#${path}`;
}

/**
 * Resolves the current SMTP config — DB-stored (set via the Integrations
 * screen) wins per-field, falling back to .env for any field left unset,
 * same precedence as every other integration in this app
 * (storage.service.js#activeProvider(), the FTP/email intake passwords).
 * No caching: built fresh on every call so an admin's config change takes
 * effect on the very next send, matching this app's existing "re-read
 * config every time" style for automated intake (no invalidation logic to
 * get wrong).
 */
async function resolveSmtpConfig() {
  const config = await getIntegrationConfig('smtp');
  const host = config.host || process.env.SMTP_HOST;
  const port = config.port ?? (Number(process.env.SMTP_PORT) || 587);
  const secure = config.secure ?? (process.env.SMTP_SECURE === 'true');
  const user = config.user || process.env.SMTP_USER;
  const password = config.password || process.env.SMTP_PASSWORD;
  const from = config.from || process.env.SMTP_FROM || 'PSPF EDMS <no-reply@pspf.co.sz>';
  return { host, port, secure, user, password, from };
}

/** Builds a transport from an already-resolved config — see resolveSmtpConfig(). */
function buildTransporter({ host, port, secure, user, password }) {
  return nodemailer.createTransport({
    host,
    port,
    secure,
    auth: user ? { user, pass: password } : undefined,
  });
}

async function sendEmail({ to, subject, text, html, attachments }) {
  try {
    const config = await resolveSmtpConfig();
    const info = await buildTransporter(config).sendMail({ from: config.from, to, subject, text, html, attachments });
    logger.info('Email sent', { to, subject, messageId: info.messageId });
    return info;
  } catch (err) {
    logger.error('Email send failed', { to, subject, error: err.message });
    throw err;
  }
}

/** Renders one branded message (both html and text parts) and sends it, with the company logo (if configured) inlined as a cid: attachment — see LOGO_CID's doc comment above. */
async function sendTemplated({ to, subject, ...templateOpts }) {
  const { branding, logo } = await getHomeBrandingWithLogo();
  const logoCid = logo ? LOGO_CID : null;
  const html = buildEmailHtml({ branding, logoCid, ...templateOpts });
  const text = buildEmailText(templateOpts);
  const attachments = logo
    ? [{ filename: 'logo', content: logo.buffer, contentType: logo.contentType, cid: LOGO_CID, contentDisposition: 'inline' }]
    : undefined;
  return sendEmail({ to, subject, text, html, attachments });
}

const sendMfaOtpEmail = (to, code) => sendTemplated({
  to,
  subject: 'Your verification code',
  preheader: `Your verification code is ${code}`,
  heading: 'Verify it\'s you',
  paragraphs: ['Use the code below to finish signing in. This code expires in 5 minutes.'],
  codeBox: { label: 'Verification code', code },
  footerNote: 'If you did not request this code, contact your ICT administrator immediately.',
});

const sendApprovalAlertEmail = (to, recordNo, title) => sendTemplated({
  to,
  subject: `Approval required: ${recordNo}`,
  preheader: `"${title}" is awaiting your review`,
  heading: 'A document needs your approval',
  paragraphs: [`"${title}" (${recordNo}) is awaiting your review and approval.`],
  cta: { text: 'Review now', url: appLink('/approvals') },
});

const sendApprovalRejectedEmail = (to, recordNo, title, comment, documentId) => sendTemplated({
  to,
  subject: `Returned: ${recordNo}`,
  preheader: `"${title}" was returned`,
  heading: 'Your document was returned',
  paragraphs: [
    `"${title}" (${recordNo}) was not approved and has been returned to you.`,
    ...(comment ? [`Reviewer's note: ${comment}`] : []),
  ],
  cta: { text: 'View document', url: appLink(documentId ? `/viewer/${documentId}` : '/repository') },
});

const sendApprovalCompletedEmail = (to, recordNo, title, documentId) => sendTemplated({
  to,
  subject: `Approved: ${recordNo}`,
  preheader: `"${title}" completed its approval workflow`,
  heading: 'Your document was approved',
  paragraphs: [`"${title}" (${recordNo}) has completed its approval workflow.`],
  cta: { text: 'View document', url: appLink(documentId ? `/viewer/${documentId}` : '/repository') },
});

const sendEscalationAlertEmail = (to, recordNo, title, stepName) => sendTemplated({
  to,
  subject: `Escalated: ${recordNo}`,
  preheader: `"${title}" is overdue and needs attention`,
  heading: 'An overdue approval needs attention',
  paragraphs: [`"${title}" (${recordNo}) has been pending at step "${stepName}" past its service-level deadline and has been escalated to you.`],
  cta: { text: 'Review now', url: appLink('/approvals') },
});

const sendOverdueApprovalEmail = (to, recordNo, title, stepName, escalationRole) => sendTemplated({
  to,
  subject: `Overdue: ${recordNo}`,
  preheader: `"${title}" is overdue`,
  heading: 'Your pending approval is overdue',
  paragraphs: [`"${title}" (${recordNo}), step "${stepName}", is overdue and has been escalated to ${escalationRole}. Please action it as soon as possible.`],
  cta: { text: 'Review now', url: appLink('/approvals') },
});

const sendPasswordResetEmail = (to, resetLink) => sendTemplated({
  to,
  subject: 'Reset your password',
  preheader: 'Use this link to reset your password',
  heading: 'Reset your password',
  paragraphs: ['We received a request to reset your password. This link is valid for 30 minutes.'],
  cta: { text: 'Reset password', url: resetLink },
  footerNote: 'If you did not request this, you can safely ignore this email.',
});

/** Real SMTP reachability check, used by the Integrations screen's Test connection. */
async function verifyTransport() {
  const config = await resolveSmtpConfig();
  try {
    await buildTransporter(config).verify();
    return { ok: true, message: `Connected to ${config.host}:${config.port}` };
  } catch (err) {
    return { ok: false, message: err.message };
  }
}

module.exports = {
  sendEmail,
  sendMfaOtpEmail,
  sendApprovalAlertEmail,
  sendApprovalRejectedEmail,
  sendApprovalCompletedEmail,
  sendEscalationAlertEmail,
  sendOverdueApprovalEmail,
  sendPasswordResetEmail,
  verifyTransport,
};
