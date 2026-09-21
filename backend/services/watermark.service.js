/**
 * services/watermark.service.js
 * Real enforcement for the `watermark_downloads` system setting. Only PDF
 * is stamped — a diagonal text overlay via pdf-lib. Other mime types are
 * returned unmodified (documented limitation: this app has no generic
 * image/office-doc watermarking pipeline; PDF covers the majority of
 * records).
 *
 * The stamped text is admin-managed (watermark_templates + the
 * system_settings 'active_watermark_template_id' pointer, set via the
 * Settings → Watermarks screen) — deliberately NOT the downloading user's
 * identity, which is what this replaced. No caching, same as every other
 * settings-driven enforcement point in this app (settings.service.js's own
 * doc comment) — a config change takes effect on the very next download.
 */
const { PDFDocument, rgb, degrees, StandardFonts } = require('pdf-lib');
const { pool } = require('../config/db');
const { getSettingInt } = require('./settings.service');

const DEFAULT_WATERMARK_TEXT = 'CONFIDENTIAL';

async function activeWatermarkText() {
  const templateId = await getSettingInt('active_watermark_template_id', 0);
  if (!templateId) return DEFAULT_WATERMARK_TEXT;
  const [[row]] = await pool.query('SELECT text FROM watermark_templates WHERE id = ?', [templateId]);
  return row ? row.text : DEFAULT_WATERMARK_TEXT; // row may have been deleted after being set active
}

async function watermarkPdf(plaintext) {
  try {
    const pdfDoc = await PDFDocument.load(plaintext);
    const font = await pdfDoc.embedFont(StandardFonts.HelveticaBold);
    const text = await activeWatermarkText();
    const stamp = `${text} — ${new Date().toISOString()}`;

    for (const page of pdfDoc.getPages()) {
      const { width, height } = page.getSize();
      page.drawText(stamp, {
        x: width / 2 - (stamp.length * 3.5),
        y: height / 2,
        size: 14,
        font,
        color: rgb(0.6, 0.6, 0.6),
        opacity: 0.35,
        rotate: degrees(45),
      });
    }
    return Buffer.from(await pdfDoc.save());
  } catch {
    // Not a parseable PDF (or already malformed) — serve the original
    // rather than failing the whole download over a cosmetic feature.
    return plaintext;
  }
}

module.exports = { watermarkPdf };
