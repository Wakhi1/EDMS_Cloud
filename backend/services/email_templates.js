/**
 * services/email_templates.js
 * One shared, table-based HTML shell for every outgoing email (OTPs,
 * password resets, workflow/approval alerts), branded with this
 * deployment's own company name/logo/colors (services/branding.service.js).
 *
 * Table layout + inline CSS only, deliberately — this is the one part of
 * the frontend that isn't rendered by a modern browser engine; Outlook's
 * Word-based renderer and a good chunk of webmail clients strip <style>
 * blocks and mis-render flexbox/grid, so anything not inlined or built on
 * <table> risks collapsing into unstyled text in exactly the clients this
 * needs to look professional in.
 */

const DEFAULT_NAME = 'PSPF EDMS';
const DEFAULT_PRIMARY = '#0088B0'; // matches frontend/lib/core/theme/pspf_tokens.dart's light-theme accent

function escapeHtml(value) {
  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

/**
 * @param {object} opts
 * @param {object|null} opts.branding - the `branding` half of branding.service.js#getHomeBrandingWithLogo()
 * @param {string|null} opts.logoCid - Content-ID of the logo inline attachment (see email.service.js#sendTemplated); null falls back to the company name as text
 * @param {string} opts.preheader - short hidden preview text shown next to the subject in inbox lists
 * @param {string} opts.heading - main heading inside the card
 * @param {string[]} opts.paragraphs - body copy, one <p> per entry (plain text, escaped)
 * @param {{label: string, code: string}} [opts.codeBox] - large letter-spaced code display, for OTP emails
 * @param {{text: string, url: string}} [opts.cta] - primary action button
 * @param {string} [opts.footerNote] - extra line under the standard footer (e.g. "If you didn't request this, contact ICT.")
 */
function buildEmailHtml({ branding, logoCid, preheader, heading, paragraphs, codeBox, cta, footerNote }) {
  const companyName = branding?.name || DEFAULT_NAME;
  const primary = branding?.theme?.primary || DEFAULT_PRIMARY;
  const year = new Date().getFullYear();

  const bodyHtml = paragraphs.map((p) => `
              <tr><td style="padding:0 0 16px;font:15px/1.6 -apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;color:#3c3c3c;">${escapeHtml(p)}</td></tr>`).join('');

  const codeBoxHtml = codeBox ? `
              <tr><td style="padding:0 0 24px;">
                ${codeBox.label ? `<div style="font:13px/1.4 -apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;color:#6b6b6b;margin:0 0 8px;">${escapeHtml(codeBox.label)}</div>` : ''}
                <div style="font:700 32px/1.2 -apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;letter-spacing:8px;color:#1f1f1f;background:#f4f5f7;border:1px solid #e4e6ea;border-radius:8px;padding:16px 20px;text-align:center;">${escapeHtml(codeBox.code)}</div>
              </td></tr>` : '';

  const ctaHtml = cta ? `
              <tr><td style="padding:8px 0 24px;">
                <table role="presentation" cellpadding="0" cellspacing="0" border="0"><tr>
                  <td style="border-radius:6px;background:${primary};">
                    <a href="${escapeHtml(cta.url)}" target="_blank" rel="noopener" style="display:inline-block;padding:12px 28px;font:600 15px/1 -apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;color:#ffffff;text-decoration:none;border-radius:6px;">${escapeHtml(cta.text)}</a>
                  </td>
                </tr></table>
              </td></tr>` : '';

  const logoOrName = logoCid
    ? `<img src="cid:${escapeHtml(logoCid)}" alt="${escapeHtml(companyName)}" height="32" style="height:32px;display:block;border:0;">`
    : `<span style="font:700 18px/1 -apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;color:#ffffff;">${escapeHtml(companyName)}</span>`;

  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="color-scheme" content="light">
<title>${escapeHtml(heading)}</title>
</head>
<body style="margin:0;padding:0;background:#f4f5f7;">
  <div style="display:none;max-height:0;overflow:hidden;opacity:0;">${escapeHtml(preheader || heading)}</div>
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background:#f4f5f7;">
    <tr><td align="center" style="padding:32px 16px;">
      <table role="presentation" width="600" cellpadding="0" cellspacing="0" border="0" style="max-width:600px;width:100%;background:#ffffff;border-radius:10px;overflow:hidden;border:1px solid #e4e6ea;">
        <tr><td style="background:${primary};padding:20px 32px;">
          ${logoOrName}
        </td></tr>
        <tr><td style="padding:32px 32px 8px;">
          <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0">
            <tr><td style="padding:0 0 16px;font:700 20px/1.3 -apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;color:#1f1f1f;">${escapeHtml(heading)}</td></tr>
            ${bodyHtml}
            ${codeBoxHtml}
            ${ctaHtml}
          </table>
        </td></tr>
        <tr><td style="padding:20px 32px 28px;border-top:1px solid #eef0f2;">
          <p style="margin:0 0 6px;font:12.5px/1.6 -apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;color:#8a8a8a;">This is an automated message from ${escapeHtml(companyName)} — please do not reply to this address.</p>
          ${footerNote ? `<p style="margin:0 0 6px;font:12.5px/1.6 -apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;color:#8a8a8a;">${escapeHtml(footerNote)}</p>` : ''}
          <p style="margin:0;font:12.5px/1.6 -apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;color:#b0b0b0;">&copy; ${year} ${escapeHtml(companyName)}</p>
        </td></tr>
      </table>
    </td></tr>
  </table>
</body>
</html>`;
}

/** Plain-text alternative part — required alongside html on every send (a multipart message with no text part scores noticeably worse with most spam filters than one with both parts). */
function buildEmailText({ heading, paragraphs, codeBox, cta, footerNote }) {
  const lines = [heading, '', ...paragraphs];
  if (codeBox) lines.push('', `${codeBox.label || 'Code'}: ${codeBox.code}`);
  if (cta) lines.push('', `${cta.text}: ${cta.url}`);
  if (footerNote) lines.push('', footerNote);
  lines.push('', 'This is an automated message — please do not reply to this address.');
  return lines.join('\n');
}

module.exports = { buildEmailHtml, buildEmailText };
