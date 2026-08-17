/**
 * services/watermark.service.js
 * Real enforcement for the `watermark_downloads` system setting. Only PDF
 * is stamped — a diagonal "user + timestamp" overlay via pdf-lib. Other
 * mime types are returned unmodified (documented limitation: this app has
 * no generic image/office-doc watermarking pipeline; PDF covers the
 * majority of records).
 */
const { PDFDocument, rgb, degrees, StandardFonts } = require('pdf-lib');

async function watermarkPdf(plaintext, { userLabel }) {
  try {
    const pdfDoc = await PDFDocument.load(plaintext);
    const font = await pdfDoc.embedFont(StandardFonts.HelveticaBold);
    const stamp = `${userLabel} — ${new Date().toISOString()}`;

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
