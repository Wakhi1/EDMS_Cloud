/**
 * services/sms.service.js
 * SMS delivery via Vonage (formerly Nexmo) SMS API, used for SMS-based MFA
 * and critical alerts. Swap the Vonage calls for another gateway by editing
 * only this file.
 */
const logger = require('../config/logger');

const SMS_ENDPOINT = 'https://rest.nexmo.com/sms/json';
const BALANCE_ENDPOINT = 'https://rest.nexmo.com/account/get-balance';

// + followed by 8-15 digits (E.164). Gates SMS MFA to users whose phone
// number is actually usable, rather than attempting delivery to garbage.
const E164_RE = /^\+[1-9]\d{7,14}$/;

function isValidE164(phone) {
  return typeof phone === 'string' && E164_RE.test(phone);
}

function isConfigured() {
  return Boolean(process.env.VONAGE_API_KEY && process.env.VONAGE_API_SECRET);
}

async function sendSms(toE164, body) {
  if (!isValidE164(toE164)) {
    logger.warn('SMS not sent — phone number is not in E.164 format', { to: toE164 });
    throw new Error('Recipient phone number is not in a valid international (E.164) format');
  }
  if (!isConfigured()) {
    logger.warn('SMS not sent — Vonage not configured', { to: toE164 });
    return { skipped: true };
  }

  const params = new URLSearchParams({
    api_key: process.env.VONAGE_API_KEY,
    api_secret: process.env.VONAGE_API_SECRET,
    to: toE164.replace('+', ''),
    from: process.env.VONAGE_FROM || 'PSPFEDMS',
    text: body,
  });

  const response = await fetch(SMS_ENDPOINT, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: params,
  });
  const data = await response.json();
  const message = data.messages && data.messages[0];
  if (!message || message.status !== '0') {
    const errorText = message ? message['error-text'] : 'Unknown Vonage error';
    logger.error('SMS send failed', { to: toE164, error: errorText });
    throw new Error(`SMS delivery failed: ${errorText}`);
  }

  logger.info('SMS sent', { to: toE164, messageId: message['message-id'] });
  return message;
}

const sendMfaOtpSms = (toE164, code) =>
  sendSms(toE164, `PSPF EDMS verification code: ${code}. Expires in 5 minutes.`);

/**
 * Integration "test" tester (see routes/integrations.routes.js testerFor) —
 * checks the configured API key/secret actually authenticate against
 * Vonage's account-balance endpoint, without sending an SMS.
 */
async function testConnection() {
  if (!isConfigured()) {
    return { ok: false, message: 'VONAGE_API_KEY / VONAGE_API_SECRET are not set in the environment' };
  }
  const params = new URLSearchParams({
    api_key: process.env.VONAGE_API_KEY,
    api_secret: process.env.VONAGE_API_SECRET,
  });
  try {
    const response = await fetch(`${BALANCE_ENDPOINT}?${params}`);
    const data = await response.json();
    if (typeof data.value === 'number') {
      return { ok: true, message: `Connected — account balance €${data.value.toFixed(2)}` };
    }
    return { ok: false, message: data['error-code-label'] || 'Vonage rejected the API key/secret' };
  } catch (err) {
    return { ok: false, message: err.message };
  }
}

module.exports = { sendSms, sendMfaOtpSms, isValidE164, isConfigured, testConnection };
