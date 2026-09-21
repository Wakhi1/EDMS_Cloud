/**
 * utils/exportTable.js
 * Shared CSV/XLSX/PDF table generation for every export button in the app
 * (Audit Trail, Reports) — one place that knows how to turn a set of
 * {title, headers, rows} sections into each of the three formats, so the
 * three buttons on a given screen always describe the same data.
 */
const XLSX = require('xlsx');
const { PDFDocument, rgb, StandardFonts } = require('pdf-lib');

function toCsv(headers, rows) {
  const esc = (v) => (v === null || v === undefined ? '' : `"${String(v).replace(/"/g, '""')}"`);
  const header = headers.map(esc).join(',');
  const body = rows.map((r) => headers.map((h) => esc(r[h])).join(',')).join('\n');
  return `${header}\n${body}`;
}

/**
 * sections: [{ name, headers, rows }] — one worksheet per section.
 * [companyName]: when given, prepends a "Cover" sheet naming the
 * deployment — the installed `xlsx` package (community SheetJS) can't
 * write cell styling/colors on the free tier, so this is XLSX's entire
 * "branding" surface; visual logo/color branding lives in the PDF export.
 */
function toXlsxBuffer(sections, { companyName } = {}) {
  const wb = XLSX.utils.book_new();
  const usedNames = new Set();
  if (companyName) {
    const coverWs = XLSX.utils.aoa_to_sheet([[companyName], ['Reports Export'], [`Generated ${new Date().toISOString()}`]]);
    XLSX.utils.book_append_sheet(wb, coverWs, 'Cover');
    usedNames.add('Cover');
  }
  for (const { name, headers, rows } of sections) {
    const data = [headers, ...rows.map((r) => headers.map((h) => r[h] ?? ''))];
    const ws = XLSX.utils.aoa_to_sheet(data);
    // Excel sheet names are capped at 31 chars and must be unique within the workbook.
    let sheetName = name.slice(0, 31);
    let n = 2;
    while (usedNames.has(sheetName)) sheetName = `${name.slice(0, 28)} ${n++}`;
    usedNames.add(sheetName);
    XLSX.utils.book_append_sheet(wb, ws, sheetName);
  }
  return XLSX.write(wb, { type: 'buffer', bookType: 'xlsx' });
}

/** '#RRGGBB' -> pdf-lib rgb() in 0-1 space, or null if absent/malformed — callers fall back to a fixed color rather than fail the export. */
function hexToRgb01(hex) {
  const m = typeof hex === 'string' ? /^#?([0-9a-f]{6})$/i.exec(hex.trim()) : null;
  if (!m) return null;
  const int = parseInt(m[1], 16);
  return rgb(((int >> 16) & 255) / 255, ((int >> 8) & 255) / 255, (int & 255) / 255);
}

/**
 * sections: [{ title, headers, rows }] — a simple, printable table per
 * section, paginated when it runs off the bottom of the page. No layout
 * library involved (pdf-lib is low-level); columns are fixed-width and
 * long values are truncated, which suits a data export, not a
 * pixel-perfect print layout.
 *
 * [branding]: { name, primaryColor } from branding.service.js — drives the
 * header's title color and (with [logo]) a logo image; both are optional
 * and any failure embedding the logo just falls back to the plain
 * unbranded header rather than failing the export.
 * [logo]: { buffer, contentType } — raw image bytes, see [branding].
 * [signature]: { buffer, contentType, signedBy } — when given, appends a
 * dedicated attestation page with the signer's name and their saved
 * signature image (Settings -> My Signature).
 */
async function toPdfBuffer(documentTitle, sections, { branding, logo, signature } = {}) {
  const pdfDoc = await PDFDocument.create();
  const font = await pdfDoc.embedFont(StandardFonts.Helvetica);
  const boldFont = await pdfDoc.embedFont(StandardFonts.HelveticaBold);
  const pageWidth = 612; // US Letter, points
  const pageHeight = 792;
  const margin = 36;
  const usableWidth = pageWidth - margin * 2;
  const rowHeight = 14;
  const titleColor = hexToRgb01(branding?.primaryColor) || rgb(0.1, 0.1, 0.1);

  let logoImage = null;
  if (logo?.buffer) {
    try {
      logoImage = logo.contentType?.includes('png') ? await pdfDoc.embedPng(logo.buffer) : await pdfDoc.embedJpg(logo.buffer);
    } catch {
      logoImage = null; // unsupported/corrupt asset — export still proceeds unbranded
    }
  }

  let page = pdfDoc.addPage([pageWidth, pageHeight]);
  let y = pageHeight - margin;

  function newPage() {
    page = pdfDoc.addPage([pageWidth, pageHeight]);
    y = pageHeight - margin;
  }

  function ensureSpace(need) {
    if (y - need < margin) newPage();
  }

  const titleText = branding?.name ? `${branding.name} — ${documentTitle}` : documentTitle;
  if (logoImage) {
    const logoHeight = 28;
    const logoWidth = logoHeight * (logoImage.width / logoImage.height);
    page.drawImage(logoImage, { x: margin, y: y - logoHeight + 6, width: logoWidth, height: logoHeight });
    page.drawText(titleText, { x: margin + logoWidth + 10, y, size: 16, font: boldFont, color: titleColor });
  } else {
    page.drawText(titleText, { x: margin, y, size: 16, font: boldFont, color: titleColor });
  }
  y -= 22;
  page.drawText(`Generated ${new Date().toISOString()}`, { x: margin, y, size: 8, font, color: rgb(0.45, 0.45, 0.45) });
  y -= 10;
  page.drawLine({ start: { x: margin, y }, end: { x: pageWidth - margin, y }, thickness: 1.5, color: titleColor });
  y -= 16;

  for (const { title, headers, rows } of sections) {
    ensureSpace(rowHeight * 3);
    page.drawText(title, { x: margin, y, size: 11, font: boldFont, color: rgb(0.1, 0.1, 0.1) });
    y -= rowHeight;

    const colWidth = usableWidth / headers.length;
    const drawRow = (values, bold) => {
      ensureSpace(rowHeight);
      values.forEach((v, i) => {
        const text = String(v ?? '—').slice(0, Math.floor(colWidth / 4.5));
        page.drawText(text, { x: margin + i * colWidth, y, size: 8, font: bold ? boldFont : font, color: rgb(0.15, 0.15, 0.15) });
      });
      y -= rowHeight;
    };

    drawRow(headers, true);
    if (!rows.length) {
      drawRow(['No data']);
    } else {
      for (const r of rows) drawRow(headers.map((h) => r[h]));
    }
    y -= 10;
  }

  if (signature) {
    newPage(); // a dedicated page keeps the attestation visually separate from the data tables above
    page.drawText('Report signed by', { x: margin, y, size: 12, font: boldFont, color: rgb(0.1, 0.1, 0.1) });
    y -= 18;
    page.drawText(signature.signedBy, { x: margin, y, size: 11, font, color: rgb(0.15, 0.15, 0.15) });
    y -= 16;
    page.drawText(new Date().toISOString(), { x: margin, y, size: 9, font, color: rgb(0.45, 0.45, 0.45) });
    y -= 24;
    try {
      const sigImage = signature.contentType?.includes('png') ? await pdfDoc.embedPng(signature.buffer) : await pdfDoc.embedJpg(signature.buffer);
      const sigHeight = 60;
      const sigWidth = sigHeight * (sigImage.width / sigImage.height);
      page.drawImage(sigImage, { x: margin, y: y - sigHeight, width: sigWidth, height: sigHeight });
    } catch {
      // corrupt/unsupported signature image — the attestation text above still stands
    }
  }

  return Buffer.from(await pdfDoc.save());
}

module.exports = { toCsv, toXlsxBuffer, toPdfBuffer };
