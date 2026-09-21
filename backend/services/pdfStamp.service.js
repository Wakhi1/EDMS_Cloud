/**
 * services/pdfStamp.service.js
 * Physically stamps a signature image onto a PDF page — distinct from
 * watermark.service.js (which stamps admin-managed text at DOWNLOAD time,
 * never persisted) and from workflow_approval_signatures (an immutable
 * attestation record, not drawn into the file). This is used by
 * document.service.js's embedSignatureIntoDocument to bake an approver's
 * signature into the document's actual content as a new version, when
 * system_settings.embed_approval_signatures is enabled.
 */
const { PDFDocument } = require('pdf-lib');

const BOX_WIDTH = 130; // points
const MARGIN = 24;

/** Top-left corner for each named position, given the page size and the signature's rendered box size. */
function positionFor(name, pageWidth, pageHeight, boxWidth, boxHeight) {
  switch (name) {
    case 'bottom-left': return { x: MARGIN, y: MARGIN };
    case 'bottom-center': return { x: (pageWidth - boxWidth) / 2, y: MARGIN };
    case 'top-left': return { x: MARGIN, y: pageHeight - MARGIN - boxHeight };
    case 'top-right': return { x: pageWidth - MARGIN - boxWidth, y: pageHeight - MARGIN - boxHeight };
    case 'bottom-right':
    default:
      return { x: pageWidth - MARGIN - boxWidth, y: MARGIN };
  }
}

/**
 * @param {Buffer} pdfBytes - plaintext PDF content
 * @param {Buffer} signatureBytes - PNG signature image (signature.routes.js only ever stores PNG)
 * @param {object} [placement]
 * @param {'first'|'last'} [placement.page='last']
 * @param {'bottom-right'|'bottom-left'|'bottom-center'|'top-right'|'top-left'} [placement.position='bottom-right']
 * @returns {Promise<Buffer>} the stamped PDF
 */
async function stampSignatureOntoPdf(pdfBytes, signatureBytes, { page = 'last', position = 'bottom-right' } = {}) {
  const pdfDoc = await PDFDocument.load(pdfBytes);
  const pages = pdfDoc.getPages();
  const targetPage = page === 'first' ? pages[0] : pages[pages.length - 1];

  const sigImage = await pdfDoc.embedPng(signatureBytes);
  const boxWidth = BOX_WIDTH;
  const boxHeight = boxWidth * (sigImage.height / sigImage.width);
  const { width, height } = targetPage.getSize();
  const { x, y } = positionFor(position, width, height, boxWidth, boxHeight);

  targetPage.drawImage(sigImage, { x, y, width: boxWidth, height: boxHeight });
  return Buffer.from(await pdfDoc.save());
}

module.exports = { stampSignatureOntoPdf };
