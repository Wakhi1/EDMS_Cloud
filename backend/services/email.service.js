/**
 * services/email.service.js
 * SMTP mailer (nodemailer) used for approval alerts, OTPs, statement
 * delivery, and password reset links. All sends are logged.
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
  try {
    const info = await getTransporter().sendMail({
      from: process.env.SMTP_FROM || 'PSPF EDMS <no-reply@pspf.co.sz>',
      to, subject, text, html,
    });
    logger.info('Email sent', { to, subject, messageId: info.messageId });
    return info;
  } catch (err) {
    logger.error('Email send failed', { to, subject, error: err.message });
    throw err;
  }
}

const sendMfaOtpEmail = (to, code) => sendEmail({
  to,
  subject: 'Your PSPF EDMS verification code',
  text: `Your verification code is ${code}. It expires in 5 minutes. If you did not request this, contact ICT immediately.`,
});

const sendApprovalAlertEmail = (to, recordNo, title) => sendEmail({
  to,
  subject: `Approval required: ${recordNo}`,
  text: `"${title}" (${recordNo}) is awaiting your approval in the PSPF EDMS.`,
});

const sendPasswordResetEmail = (to, resetLink) => sendEmail({
  to,
  subject: 'PSPF EDMS password reset',
  text: `Reset your password using this link (valid 30 minutes): ${resetLink}`,
});

/** Real SMTP reachability check, used by the Integrations screen's Test connection. */
async function verifyTransport() {
  try {
    await getTransporter().verify();
    return { ok: true, message: `Connected to ${process.env.SMTP_HOST}:${process.env.SMTP_PORT}` };
  } catch (err) {
    return { ok: false, message: err.message };
  }
}

module.exports = { sendEmail, sendMfaOtpEmail, sendApprovalAlertEmail, sendPasswordResetEmail, verifyTransport };
