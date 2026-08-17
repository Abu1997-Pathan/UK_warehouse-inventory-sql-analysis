const fs = require('fs');
const {
  Document, Packer, Paragraph, TextRun, HeadingLevel, Table, TableRow, TableCell,
  WidthType, ShadingType, AlignmentType, BorderStyle, PageBreak, Header, Footer,
  PageNumber, NumberFormat, TableOfContents, VerticalAlign
} = require('docx');

const NAVY = "1F3864";
const TEAL = "2E9E96";
const LIGHTGREY = "F2F2F2";
const DARKTEXT = "222222";

const tasks = JSON.parse(fs.readFileSync('./outputs/parsed_tasks.json', 'utf8'));

// ---------- helpers ----------
function h1(text) {
  return new Paragraph({
    text, heading: HeadingLevel.HEADING_1,
    spacing: { before: 400, after: 200 },
    border: { bottom: { color: NAVY, space: 4, style: BorderStyle.SINGLE, size: 6 } }
  });
}
function h2(text) {
  return new Paragraph({ text, heading: HeadingLevel.HEADING_2, spacing: { before: 300, after: 150 } });
}
function h3(text) {
  return new Paragraph({ text, heading: HeadingLevel.HEADING_3, spacing: { before: 200, after: 100 } });
}
function p(text, opts = {}) {
  return new Paragraph({
    children: [new TextRun({ text, italics: opts.italics, bold: opts.bold, size: opts.size || 22 })],
    spacing: { after: 160 },
    alignment: opts.align || AlignmentType.LEFT
  });
}
function bullet(text) {
  return new Paragraph({ text, bullet: { level: 0 }, spacing: { after: 80 } });
}
function labelValue(label, value) {
  return new Paragraph({
    spacing: { after: 100 },
    children: [
      new TextRun({ text: label + ": ", bold: true }),
      new TextRun({ text: value })
    ]
  });
}

function cell(text, opts = {}) {
  return new TableCell({
    width: { size: opts.width || 2000, type: WidthType.DXA },
    shading: opts.header ? { fill: NAVY, type: ShadingType.CLEAR } : (opts.alt ? { fill: LIGHTGREY, type: ShadingType.CLEAR } : undefined),
    verticalAlign: VerticalAlign.CENTER,
    margins: { top: 60, bottom: 60, left: 100, right: 100 },
    children: [new Paragraph({
      children: [new TextRun({ text: String(text), bold: !!opts.header, color: opts.header ? "FFFFFF" : DARKTEXT, size: opts.size || 18 })]
    })]
  });
}

function makeTable(headers, rows, widths) {
  const headerRow = new TableRow({
    children: headers.map((hd, i) => cell(hd, { header: true, width: widths[i] })),
    tableHeader: true
  });
  const dataRows = rows.map((r, ri) => new TableRow({
    children: r.map((val, i) => cell(val, { width: widths[i], alt: ri % 2 === 1 }))
  }));
  return new Table({
    width: { size: widths.reduce((a, b) => a + b, 0), type: WidthType.DXA },
    columnWidths: widths,
    rows: [headerRow, ...dataRows]
  });
}

function calloutBox(title, text) {
  return new Table({
    width: { size: 9350, type: WidthType.DXA },
    columnWidths: [9350],
    rows: [new TableRow({
      children: [new TableCell({
        width: { size: 9350, type: WidthType.DXA },
        shading: { fill: "EAF1FB", type: ShadingType.CLEAR },
        margins: { top: 150, bottom: 150, left: 200, right: 200 },
        children: [
          new Paragraph({ children: [new TextRun({ text: title, bold: true, size: 20, color: NAVY })], spacing: { after: 80 } }),
          new Paragraph({ children: [new TextRun({ text, size: 20 })] })
        ]
      })]
    })]
  });
}

// ---------- Cover Page ----------
const coverPage = [
  new Paragraph({ text: "", spacing: { before: 1800 } }),
  new Paragraph({
    alignment: AlignmentType.CENTER,
    children: [new TextRun({ text: "WAREHOUSE INVENTORY", bold: true, size: 56, color: NAVY })]
  }),
  new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { after: 400 },
    children: [new TextRun({ text: "SQL ANALYSIS REPORT", bold: true, size: 40, color: TEAL })]
  }),
  new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { after: 1200 },
    children: [new TextRun({ text: "From database preparation to decision-ready reporting", italics: true, size: 24 })]
  }),
  new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 80 }, children: [new TextRun({ text: "Project Title: Warehouse Inventory SQL Analysis", size: 22 })] }),
  new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 80 }, children: [new TextRun({ text: "Database / Table: warehouse_inventory.warehouse_transactions", size: 22 })] }),
  new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 80 }, children: [new TextRun({ text: "SQL Platform Used: MySQL 8.0", size: 22 })] }),
  new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 80 }, children: [new TextRun({ text: "Prepared By: [Your Full Name]", size: 22 })] }),
  new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 80 }, children: [new TextRun({ text: "Submission Date: 17 August 2026", size: 22 })] }),
  new Paragraph({ children: [new PageBreak()] })
];

// ---------- Section 2: Executive Summary ----------
const execSummary = [
  h1("2. Executive Summary"),
  calloutBox("Executive Summary",
    "This report analyses 5,000 warehouse inventory transactions covering 1 January 2025 to 16 May 2026. " +
    "Overall, the operation received 2,614,361 units, dispatched 1,353,875 units and recorded an inventory loss rate of 5.73%. " +
    "The strongest overall performer was Leeds Fulfillment, based on the highest estimated gross profit (\u00a349.83M) combined with the lowest inventory loss percentage (5.52%) of any warehouse. " +
    "The highest operational risk was concentrated in Liverpool Logistics, which recorded the highest loss percentage (6.03%) and the highest audit failure rate (18.11%) of any location, alongside above-average delivery times. " +
    "Estimated gross profit across the operation was \u00a3362.3M, while inventory losses were valued at approximately \u00a389.75M \u2014 equivalent to 24.8% of estimated gross profit. " +
    "The single largest operational risk identified was dispatch reliability: only 29.84% of transactions were dispatched on time, while 40.82% were recorded as Delayed. " +
    "Priority actions are to (1) investigate the causes of widespread dispatch delay across all locations, (2) review handling, storage and audit practices at Liverpool Logistics, Bristol Supply Hub and Newcastle Depot, the three warehouses flagged with both above-average loss and above-average delivery time, and (3) engage Prime Wholesale UK, the only supplier combining above-average supply volume with above-average loss percentage, on quality control."
  ),
  p(""),
  h2("Key Figures at a Glance"),
];

const kpiTable = makeTable(
  ["Metric", "Value"],
  [
    ["Total transactions", "5,000"],
    ["Transaction period", "1 Jan 2025 \u2013 16 May 2026 (17 months)"],
    ["Total units received", "2,614,361"],
    ["Total units dispatched", "1,353,875"],
    ["Total remaining stock (estimated)", "1,110,658 units"],
    ["Overall inventory loss percentage", "5.73%"],
    ["Overall return percentage", "4.64%"],
    ["Overall audit failure rate", "15.42%"],
    ["Overall on-time dispatch rate", "29.84%"],
    ["Average delivery days", "5.53 days"],
    ["Total estimated sales value", "\u00a31,170,728,632.87"],
    ["Total dispatched inventory cost", "\u00a3808,422,287.40"],
    ["Total estimated gross profit", "\u00a3362,306,345.47"],
    ["Total inventory loss value", "\u00a389,754,534.13"],
  ],
  [5500, 3850]
);
execSummary.push(kpiTable, new Paragraph({ children: [new PageBreak()] }));

// ---------- Section 3: Business Problem ----------
const businessProblem = [
  h1("3. Business Problem"),
  p("Warehouse transaction data records what happened at each stage of the inventory lifecycle \u2014 receipt, storage, handling, dispatch and return \u2014 but does not by itself explain why performance differs across locations, products, suppliers or operational teams. A warehouse with a high received quantity may still carry hidden damage, missing units, delayed dispatches, audit failures or customer returns; equally, a high sales value does not guarantee strong profitability if inventory loss is significant."),
  p("This report addresses that gap by connecting inventory volume, stock movement, quality, delivery, audit, returns and financial measures into a single operational view. Throughout the analysis, a clear distinction is maintained between large absolute values (which reflect scale) and poor rates (which reflect efficiency or risk) \u2014 a large warehouse can record the highest number of damaged units while still maintaining a lower damage percentage than a smaller warehouse."),
  h2("Central Analytical Question"),
  calloutBox("Central Question", "How effectively is inventory being received, stored, handled, dispatched and converted into revenue, and where are losses, delays, audit failures and returns creating operational or financial risk?"),
  p(""),
  h2("Decisions This Report Supports"),
];
const bizValueTable = makeTable(
  ["Business Area", "How the Analysis Supports Decisions"],
  [
    ["Inventory control", "Identifies excess stock, low stock movement, damage, missing units and possible stock inconsistencies."],
    ["Warehouse operations", "Compares throughput, loss rates, delivery performance, audit results and return levels by warehouse."],
    ["Supplier management", "Measures supply volume, loss rates, audit outcomes and product quality associated with each supplier."],
    ["Product management", "Determines which products and categories generate volume, revenue, profit, returns and inventory risk."],
    ["Workforce management", "Evaluates handling volume, loss exposure, delivery outcomes and audit performance associated with each employee."],
    ["Financial control", "Estimates sales value, inventory cost, gross profit, loss value and return-related value."],
    ["Planning", "Reveals monthly and yearly patterns that can support stock, staffing and dispatch planning."],
  ],
  [2600, 6750]
);
businessProblem.push(bizValueTable, new Paragraph({ children: [new PageBreak()] }));

// ---------- Section 4: Project Objectives ----------
const objectives = [
  h1("4. Project Objectives"),
  p("The following analytical objectives were completed in sequence, so that data reliability was established before business conclusions were produced:"),
];
[
  "Confirm that the database structure and data types support accurate SQL analysis.",
  "Convert the transaction date from text in DD-MM-YYYY format into a valid DATE field.",
  "Detect duplicates, missing values, invalid categories and inconsistent quantity relationships.",
  "Establish overall KPIs before comparing individual business segments.",
  "Measure inventory inflow, outflow, remaining stock and loss units.",
  "Calculate loss, return, dispatch and audit rates using appropriate denominators.",
  "Estimate revenue, cost, gross profit and inventory loss value.",
  "Compare warehouse, product, supplier, employee and storage-section performance.",
  "Analyse monthly and yearly trends across the complete transaction period.",
  "Use advanced SQL to rank entities, compare records with averages and identify unusual behaviour.",
  "Convert query outputs into concise findings, implications and recommendations.",
].forEach(t => objectives.push(bullet(t)));
objectives.push(new Paragraph({ children: [new PageBreak()] }));

// ---------- Section 5: Dataset Overview ----------
const datasetOverview = [
  h1("5. Dataset Overview"),
  p("The dataset comprises 5,000 warehouse inventory transaction records across 22 fields, covering the period from 1 January 2025 to 16 May 2026 (confirmed by the converted Transaction_Date field, with zero conversion failures). It spans 8 warehouses, 8 UK cities, 5 product categories, 23 individual products, 8 suppliers, 8 storage sections and 8 employees handling inventory."),
];
const datasetTable = makeTable(
  ["Attribute", "Project Value"],
  [
    ["Number of records", "5,000 transaction rows"],
    ["Number of fields", "22 columns"],
    ["Transaction period", "1 January 2025 to 16 May 2026"],
    ["Warehouse coverage", "8 warehouse names"],
    ["Product coverage", "5 categories and 23 products"],
    ["Supplier coverage", "8 suppliers"],
    ["Inventory directions", "Inbound and Outbound"],
    ["Dispatch categories", "On Time, Slightly Delayed, Delayed"],
    ["Audit categories", "Passed and Failed"],
    ["Temperature-control flag", "Yes and No"],
  ],
  [4200, 5150]
);
datasetOverview.push(datasetTable, p(""), h2("Role of Each Data Group"),
  bullet("Dimensions (Warehouse_Name, City, Product_Category, Product_Name, Supplier_Name, Storage_Section, Employee_Handling, Batch_Number) provide the segments used throughout the comparative analysis."),
  bullet("Volume measures (Quantity_Received, Quantity_Dispatched, Damaged_Units, Missing_Units, Customer_Returns) drive the operational KPIs and loss calculations."),
  bullet("Financial measures (Unit_Cost_GBP, Selling_Price_GBP) combine with volume measures to produce all estimated financial figures."),
  bullet("Operational status fields (Dispatch_Status, Delivery_Days, Stock_Audit_Status, Temperature_Controlled) support delivery, compliance and storage-condition analysis."),
  bullet("Transaction_Date (after conversion from text) underpins all time-series and trend analysis."),
  new Paragraph({ children: [new PageBreak()] })
);

// ---------- Section 6: Database Preparation ----------
const dbPrep = [
  h1("6. Database Preparation"),
  h2("6.1 Import Check"),
  p("The raw dataset was loaded into a staging table (warehouse_transactions_raw) with 22 columns matching the data dictionary. A row count check confirmed all 5,000 records imported successfully, and a column count check against information_schema confirmed all fields were present. DESCRIBE output confirmed each numeric column (Quantity_Received, Quantity_Dispatched, Damaged_Units, Missing_Units, Delivery_Days, Customer_Returns) imported as INT and each price field (Unit_Cost_GBP, Selling_Price_GBP) imported as DECIMAL(10,2), consistent with the handbook's recommended data types."),
  h2("6.2 Text-Date Issue and Conversion Process"),
  p("Transaction_Date was imported as text in DD-MM-YYYY format (e.g. \u201814-02-2025\u2019). Text dates of this kind sort alphabetically rather than chronologically and cannot be reliably analysed with YEAR, MONTH, QUARTER or date-difference functions, so a valid DATE field was a prerequisite for all time-series analysis."),
  p("Following the handbook's data-safety requirement, the original text field was preserved throughout the conversion process rather than being modified in place:"),
  bullet("A new column, Transaction_Date_Converted, was added to the staging table using STR_TO_DATE(Transaction_Date_Text, '%d-%m-%Y')."),
  bullet("A side-by-side comparison of the original text and converted date was reviewed on a 20-row sample."),
  bullet("A validation query checked for rows where the text date was present but the converted date was null: zero such rows were found."),
  bullet("MIN() and MAX() on the converted field confirmed the expected range of 1 January 2025 to 16 May 2026 exactly."),
  bullet("The final analytical table (warehouse_transactions) was built from the validated data, with the converted field renamed Transaction_Date (DATE, NOT NULL) and the original text retained as Transaction_Date_Text for audit purposes."),
  h2("6.3 Recommended Data Types Applied"),
  p("The final table structure matches the handbook's data dictionary: VARCHAR for identifiers and categorical text, INTEGER for whole-unit counts, DECIMAL(10,2) for currency fields, and DATE for the converted transaction date. A primary key was applied to Transaction_ID (confirmed unique, zero duplicates) and indexes were added on Warehouse_Name, Product_Category, Supplier_Name and Transaction_Date to support the grouped and time-based queries used throughout this analysis."),
  new Paragraph({ children: [new PageBreak()] })
];

// ---------- Section 7: Data Quality Assessment ----------
const dq = [
  h1("7. Data Quality Assessment"),
  p("Before any performance analysis was produced, the dataset was screened for completeness, uniqueness, validity and cross-field consistency. The consolidated results are summarised below."),
];
const dqTable = makeTable(
  ["Check", "Result", "Decision"],
  [
    ["Duplicate Transaction_ID values", "0", "No action required \u2014 Transaction_ID is a reliable unique key."],
    ["Null values (all columns)", "0", "No action required \u2014 dataset is fully populated."],
    ["Blank / whitespace-only text values", "0", "No action required."],
    ["Negative values (quantities, prices, delivery days, returns)", "0", "No action required."],
    ["Zero values in quantity/price fields", "0", "No action required."],
    ["Categorical values outside known lists", "0", "All categories match expected lists exactly."],
    ["Quantity_Dispatched > Quantity_Received", "0", "No stock-control inconsistency of this type present."],
    ["Damaged + Missing > Quantity_Received", "3 rows", "Retained and flagged for operational review; not deleted, as the volume is immaterial (0.06% of records) and does not distort aggregate KPIs."],
    ["Customer_Returns > Quantity_Dispatched", "9 rows", "Retained and flagged; represents 0.18% of records and is treated as a genuine exception list for operational follow-up rather than a data error."],
    ["Selling_Price_GBP < Unit_Cost_GBP", "0", "No loss-making list price rows present."],
    ["Delivery_Days outside 1\u201310 day range", "0", "All delivery times fall within the expected operational range."],
    ["Date conversion failures", "0", "All 5,000 text dates parsed successfully to DATE."],
    ["Batches linked to multiple products/suppliers", "See appendix output", "A small number of batch numbers are associated with more than one product or supplier; documented for traceability, not treated as an error."],
  ],
  [3600, 1800, 3950]
);
dq.push(dqTable, p(""),
  h2("Warehouse-City Relationship"),
  p("A cross-field consistency check (task 2.12) tested whether each warehouse is associated with a single, fixed city. The result shows every one of the 8 warehouses is linked to all 8 cities in the dataset. This is not treated as a data-quality defect: it indicates that City records the transaction's destination or service area rather than the warehouse's own physical location, and this distinction is carried through to all geography-related interpretation in this report."),
  h2("Overall Assessment"),
  p("The dataset is of high quality. With zero duplicates, zero missing values and zero invalid categories, and only a small, clearly bounded set of cross-field exceptions (12 rows total, 0.24% of the dataset), no records were removed from the analytical table. All 5,000 transactions were retained for the performance analysis that follows."),
  new Paragraph({ children: [new PageBreak()] })
);

// ---------- Section 8: Overall KPI Summary ----------
const kpiSummary = [
  h1("8. Overall KPI Summary"),
  p("These headline figures establish the scale and general condition of the operation before performance is segmented by warehouse, product, supplier or time period."),
  h2("8.1 Volume KPIs"),
];
const volKpi = makeTable(["Metric","Value"],[
  ["Total transactions","5,000"],
  ["Total units received","2,614,361"],
  ["Total units dispatched","1,353,875"],
  ["Average received per transaction","522.87 units"],
  ["Average dispatched per transaction","270.78 units"],
  ["Total remaining stock (estimated)","1,110,658 units"],
],[5500,3850]);
kpiSummary.push(volKpi, p(""));
kpiSummary.push(h2("8.2 Quality and Risk KPIs"));
const qualKpi = makeTable(["Metric","Value"],[
  ["Total damaged units","99,324"],
  ["Total missing units","50,504"],
  ["Total inventory loss units (damaged + missing)","149,828"],
  ["Overall inventory loss percentage","5.73%"],
  ["Total customer returns","62,822"],
  ["Overall return percentage","4.64%"],
  ["Overall audit failure rate","15.42%"],
],[5500,3850]);
kpiSummary.push(qualKpi, p(""));
kpiSummary.push(h2("8.3 Delivery KPIs"));
const delKpi = makeTable(["Metric","Value"],[
  ["Average delivery days","5.53 days"],
  ["Minimum / maximum delivery days","1 day / 10 days"],
  ["Overall on-time dispatch rate","29.84%"],
  ["Delayed transaction share","40.82%"],
  ["Slightly delayed transaction share","29.34%"],
],[5500,3850]);
kpiSummary.push(delKpi, p(""));
kpiSummary.push(h2("8.4 Financial KPIs (Estimates)"));
const finKpi = makeTable(["Metric","Value (GBP)"],[
  ["Total estimated sales value","\u00a31,170,728,632.87"],
  ["Total dispatched inventory cost","\u00a3808,422,287.40"],
  ["Total estimated gross profit","\u00a3362,306,345.47"],
  ["Total inventory loss value","\u00a389,754,534.13"],
  ["Estimated return value (units returned \u00d7 selling price)","\u00a354,904,102.21"],
],[5500,3850]);
kpiSummary.push(finKpi, p(""));
kpiSummary.push(calloutBox("Interpretation",
  "Inventory loss value (\u00a389.75M) represents 24.8% of estimated gross profit \u2014 a material drag on commercial performance, driven more by the operation's scale (2.6M units received) than by an unusually high loss rate. The most significant KPI in this section, however, is dispatch reliability: with only 29.84% of transactions dispatched on time against 40.82% recorded as Delayed, delivery performance is the single weakest area of the operation and the one most likely to affect customer experience and downstream return rates."));
kpiSummary.push(new Paragraph({ children: [new PageBreak()] }));

fs.writeFileSync('./outputs/_part1.json', JSON.stringify({ok:true}));
console.log("Part 1 sections built. Continuing in generate_report_part2.js");

module.exports = { coverPage, execSummary, businessProblem, objectives, datasetOverview, dbPrep, dq, kpiSummary, h1, h2, h3, p, bullet, calloutBox, makeTable, cell, NAVY, TEAL, LIGHTGREY };
