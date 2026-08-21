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

/** sections: [{ name, headers, rows }] — one worksheet per section. */
function toXlsxBuffer(sections) {
  const wb = XLSX.utils.book_new();
  const usedNames = new Set();
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

/**
 * sections: [{ title, headers, rows }] — a simple, printable table per
 * section, paginated when it runs off the bottom of the page. No layout
 * library involved (pdf-lib is low-level); columns are fixed-width and
 * long values are truncated, which suits a data export, not a
 * pixel-perfect print layout.
 */
async function toPdfBuffer(documentTitle, sections) {
  const pdfDoc = await PDFDocument.create();
  const font = await pdfDoc.embedFont(StandardFonts.Helvetica);
  const boldFont = await pdfDoc.embedFont(StandardFonts.HelveticaBold);
  const pageWidth = 612; // US Letter, points
  const pageHeight = 792;
  const margin = 36;
  const usableWidth = pageWidth - margin * 2;
  const rowHeight = 14;

  let page = pdfDoc.addPage([pageWidth, pageHeight]);
  let y = pageHeight - margin;

  function newPage() {
    page = pdfDoc.addPage([pageWidth, pageHeight]);
    y = pageHeight - margin;
  }

  function ensureSpace(need) {
    if (y - need < margin) newPage();
  }

  page.drawText(documentTitle, { x: margin, y, size: 16, font: boldFont, color: rgb(0.1, 0.1, 0.1) });
  y -= 22;
  page.drawText(`Generated ${new Date().toISOString()}`, { x: margin, y, size: 8, font, color: rgb(0.45, 0.45, 0.45) });
  y -= 22;

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

  return Buffer.from(await pdfDoc.save());
}

module.exports = { toCsv, toXlsxBuffer, toPdfBuffer };
