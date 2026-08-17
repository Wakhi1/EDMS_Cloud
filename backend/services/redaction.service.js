/**
 * services/redaction.service.js
 * Real enforcement for the `redact_bank_numbers` system setting. Masks
 * bank-account-shaped digit runs (8-16 consecutive digits, the shape used
 * by this app's seeded payout/contribution records) in text shown to
 * non-Finance-Officer, non-System-Administrator roles.
 */
const BANK_NUMBER_PATTERN = /\b\d{8,16}\b/g;

function redactBankNumbers(text, { role }) {
  if (!text) return text;
  if (role === 'Finance Officer' || role === 'System Administrator') return text;
  return text.replace(BANK_NUMBER_PATTERN, (match) => `${'*'.repeat(match.length - 4)}${match.slice(-4)}`);
}

module.exports = { redactBankNumbers };
