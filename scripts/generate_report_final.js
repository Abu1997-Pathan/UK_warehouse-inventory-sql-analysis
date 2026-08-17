const fs = require('fs');
const {
  Document, Packer, Paragraph, TextRun, HeaderFooterType, Header, Footer,
  PageNumber, AlignmentType, NumberFormat
} = require('docx');

const P1 = require('./generate_report.js');
const P2 = require('./generate_report_part2.js');
const P3 = require('./generate_report_part3.js');

const allSections = [
  ...P1.coverPage,
  ...P1.execSummary,
  ...P1.businessProblem,
  ...P1.objectives,
  ...P1.datasetOverview,
  ...P1.dbPrep,
  ...P1.dq,
  ...P1.kpiSummary,
  ...P2.warehousePerf,
  ...P2.productPerf,
  ...P2.supplierPerf,
  ...P2.opPerf,
  ...P3.financial,
  ...P3.timeSeries,
  ...P3.advanced,
  ...P3.findings,
  ...P3.recs,
  ...P3.limitations,
  ...P3.conclusion,
  ...P3.appendix,
];

const doc = new Document({
  styles: {
    default: {
      document: { run: { font: "Calibri", size: 22, color: "222222" } }
    },
    heading1: { run: { font: "Calibri", size: 30, bold: true, color: "1F3864" } },
    heading2: { run: { font: "Calibri", size: 25, bold: true, color: "2E9E96" } },
    heading3: { run: { font: "Calibri", size: 23, bold: true, color: "222222" } },
  },
  sections: [{
    properties: {
      page: {
        size: { width: 11906, height: 16838 }, // A4
        margin: { top: 1000, bottom: 1000, left: 1100, right: 1100 }
      }
    },
    headers: {
      default: new Header({
        children: [new Paragraph({
          alignment: AlignmentType.RIGHT,
          children: [new TextRun({ text: "Warehouse Inventory SQL Analysis", size: 16, color: "888888" })]
        })]
      })
    },
    footers: {
      default: new Footer({
        children: [new Paragraph({
          alignment: AlignmentType.CENTER,
          children: [
            new TextRun({ text: "Page ", size: 16, color: "888888" }),
            new TextRun({ children: [PageNumber.CURRENT], size: 16, color: "888888" }),
            new TextRun({ text: " of ", size: 16, color: "888888" }),
            new TextRun({ children: [PageNumber.TOTAL_PAGES], size: 16, color: "888888" }),
          ]
        })]
      })
    },
    children: allSections
  }]
});

Packer.toBuffer(doc).then(buffer => {
  fs.writeFileSync('./report/Warehouse_Inventory_SQL_Analysis_Report.docx', buffer);
  console.log("Report written successfully.");
}).catch(err => {
  console.error("ERROR building document:", err);
  process.exit(1);
});
