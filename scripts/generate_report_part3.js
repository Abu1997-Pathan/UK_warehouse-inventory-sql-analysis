const fs = require('fs');
const { Paragraph, PageBreak, TextRun } = require('docx');
const P1 = require('./generate_report.js');
const { h1, h2, h3, p, bullet, calloutBox, makeTable } = P1;

const tasks = JSON.parse(fs.readFileSync('./outputs/parsed_tasks.json', 'utf8'));

// ---------- Section 13: Financial Analysis ----------
const financial = [
  h1("13. Financial Analysis"),
  calloutBox("Financial Terminology", "All financial figures in this section are estimates derived from transaction quantities, unit cost and selling price. They represent gross operational values and are described using the terms \u201cestimated sales value\u201d, \u201cdispatched inventory cost\u201d, \u201cestimated gross profit\u201d and \u201cinventory loss value\u201d throughout \u2014 never as audited revenue, net profit or realised loss \u2014 because transport, labour, storage, tax and other operating expenses are not included in this dataset."),
  p(""),
  h2("13.1 Overall Financial Position"),
];
const finTable = makeTable(["Metric","Value (GBP)"],[
  ["Total estimated sales value","1,170,728,632.87"],
  ["Total dispatched inventory cost","808,422,287.40"],
  ["Total estimated gross profit","362,306,345.47"],
  ["Total inventory loss value","89,754,534.13"],
  ["Adjusted contribution estimate (gross profit less loss value)","272,551,811.34"],
  ["Estimated return value (units returned \u00d7 selling price)","54,904,102.21"],
],[6500,2850]);
financial.push(finTable, p(""));
financial.push(calloutBox("Finding: Inventory Loss Materially Reduces Estimated Contribution",
  "Evidence: total inventory loss value (\u00a389.75M) equals 24.8% of total estimated gross profit (\u00a3362.3M); after deducting loss value, the adjusted contribution estimate falls to \u00a3272.6M. Business implication: loss reduction is not a marginal efficiency exercise here \u2014 it represents roughly a quarter of the commercial upside currently generated. Recommendation: track the adjusted contribution estimate (gross profit less inventory loss value) as a standing KPI alongside gross profit itself, so improvement initiatives are measured against their true bottom-line effect."));
financial.push(p(""));
financial.push(h2("13.2 Revenue and Profit by Category"));
financial.push(p("Pharma generates the highest estimated gross profit of any category (\u00a377.05M), narrowly ahead of Electronics (\u00a375.83M), despite Electronics handling a higher dispatched volume. This reflects Pharma's stronger average margin per unit rather than pure volume."));
financial.push(h2("13.3 High-Revenue, Low-Margin Exposure"));
financial.push(p("Task 11.8 identifies transactions with above-average estimated sales value but a margin percentage below 20% \u2014 a volume-driven pattern that can appear commercially strong on a sales-value basis while contributing comparatively little profit per unit. The full transaction-level list is provided in the accompanying SQL output (Appendix, Query 11.8) for procurement and pricing review."));
financial.push(new Paragraph({ children: [new PageBreak()] }));

// ---------- Section 14: Time-Series Analysis ----------
const timeSeries = [
  h1("14. Time-Series Analysis"),
  p("The converted Transaction_Date field enabled monthly and yearly trend analysis across the full 17-month period (January 2025 to May 2026). Year is grouped together with month throughout, so that the same calendar month appearing in both 2025 and 2026 is never combined incorrectly."),
  h2("14.1 Overall Pattern"),
  p("Monthly transaction counts, dispatched volume, loss percentage and estimated gross profit were calculated for all 17 months in the dataset (full detail in Appendix, Queries 12.2\u201312.7). Because the underlying transaction data is close to uniformly distributed across warehouses, products and suppliers, month-to-month variation in the core rates (loss percentage, return percentage, on-time rate) is modest and does not show a strong seasonal signal within this dataset."),
  h2("14.2 Year-over-Year Comparison (January\u2013May)"),
  p("Only January to May exist in both 2025 and 2026, enabling a like-for-like year-over-year comparison for those five months (Handbook task 12.8). The full month-by-month comparison, including percentage change, is provided in the appendix SQL output."),
  h2("14.3 Month-over-Month Change"),
  p("LAG and LEAD window functions were used to calculate month-over-month percentage change in dispatch volume, inventory loss value and estimated gross profit (Handbook tasks 12.9, 13.16, 13.17), and a running (cumulative) total of dispatched quantity was calculated using SUM as a window function (task 13.14). These outputs support operational and financial planning by showing the direction and magnitude of recent change without collapsing the underlying monthly detail."),
  h2("14.4 Peak and Trough Periods"),
  p("The best- and worst-performing month for dispatch volume, loss percentage and gross profit were identified individually (Handbook task 12.10); the specific calendar months are provided in the appendix SQL output (Query 12.10) for stock, staffing and dispatch planning purposes."),
  new Paragraph({ children: [new PageBreak()] })
];

// ---------- Section 15: Advanced SQL Findings ----------
const advanced = [
  h1("15. Advanced SQL Findings"),
  p("Advanced SQL techniques \u2014 HAVING with conditional aggregation, subqueries, CTEs, window functions and reusable views \u2014 were applied only after the descriptive analysis had been validated, to answer questions that a single basic aggregation could not resolve."),
  h2("15.1 HAVING and Conditional Aggregation"),
  bullet("Warehouses with loss percentage above a 7% threshold: none of the 8 warehouses exceeded this threshold (highest was Liverpool Logistics at 6.03%), indicating no single site represents an extreme outlier."),
  bullet("Material high-risk products/suppliers (minimum volume applied to avoid unstable percentages from small samples): the filtered list is provided in Appendix Query 13.2, ensuring any product or supplier flagged as high-risk is backed by sufficient transaction volume to be actionable rather than statistical noise."),
  h2("15.2 Subqueries and CTEs"),
  bullet("A correlated subquery (task 13.5) identified individual transactions with a loss percentage above the overall database average \u2014 used as a targeted exception list rather than relying on aggregate rates alone."),
  bullet("A CTE-based warehouse scorecard (task 13.8) combined volume, loss, delivery and financial measures from four separate CTEs into a single joined result, replicated in the vw_warehouse_scorecard view for reuse."),
  bullet("A multi-factor product-risk CTE (task 13.9) combined loss percentage, return percentage, audit failure rate and delayed percentage into a single Risk_Factor_Count per product, giving a combined view of risk that no single metric could show alone."),
  h2("15.3 Window Functions"),
  bullet("RANK() and DENSE_RANK() were applied to warehouse loss percentage to demonstrate the two standard tie-handling conventions (task 13.11)."),
  bullet("PARTITION BY was used to rank products within each category by dispatched volume, surfacing the top 3 products per category rather than a single dataset-wide ranking that would be dominated by high-volume categories (task 13.12)."),
  bullet("NTILE(4) divided all 23 products into profit quartiles, giving a balanced way to discuss \u201ctop-quartile\u201d and \u201cbottom-quartile\u201d products regardless of the underlying value distribution (task 13.13)."),
  h2("15.4 Views and Reusable Reporting Layers"),
  p("Three views were created to support ongoing reporting without repeating calculation logic: vw_transaction_analytics (transaction-level metrics), vw_warehouse_scorecard (warehouse-level KPIs) and vw_product_performance (product-level KPIs). These views underpin the summary tables presented throughout Sections 9\u201313 of this report and are available for direct reuse in future analysis."),
  new Paragraph({ children: [new PageBreak()] })
];

// ---------- Section 16: Key Findings ----------
const findingsData = [
  ["1", "Dispatch reliability is the operation's weakest area", "Only 29.84% on-time dispatch vs 40.82% Delayed, consistent across all 8 warehouses (27.04%\u201333.81% on-time range)", "Far larger deviation from an operational ideal than any loss, audit or return metric; the finding most likely to affect customer experience", "Investigate dispatch scheduling and carrier processes at network level, not warehouse-by-warehouse", "Overall on-time dispatch rate"],
  ["2", "Liverpool Logistics is the highest combined-risk warehouse", "Highest loss % (6.03%), highest audit failure rate (18.11%), above-average delivery time (5.66 days)", "Single clearest site-level risk concentration in the network", "Prioritise storage, handling and audit-process review at Liverpool Logistics", "Warehouse loss %, audit failure rate"],
  ["3", "Inventory loss represents 24.8% of estimated gross profit", "\u00a389.75M loss value vs \u00a3362.3M gross profit; adjusted contribution estimate \u00a3272.6M", "Loss reduction has material bottom-line impact, not a marginal efficiency issue", "Track adjusted contribution estimate (gross profit less loss value) as a standing KPI", "Inventory loss value, adjusted contribution"],
  ["4", "Audit failure shows no material link to higher physical inventory loss", "Failed-audit loss % (5.71%) and Passed-audit loss % (5.74%) are nearly identical, indicating no material descriptive difference in this dataset", "Audit failures may reflect documentation or process factors not captured in the dataset, rather than physical stock condition", "Review specific audit failure causes (paperwork, count discrepancies, timing) separately from loss-reduction initiatives", "Audit failure rate, loss %"],
  ["5", "Prime Wholesale UK is the priority supplier for engagement", "Highest supply volume (348,061 units) combined with above-average loss % (5.74% vs 5.73% overall)", "Because this supplier's volume is largest, even a small quality improvement scales further than at any other supplier", "Schedule supplier quality engagement with Prime Wholesale UK", "Supplier loss %, supply volume"],
];
const findings = [
  h1("16. Key Findings"),
  p("The five most important evidence-based conclusions from this analysis are presented below in priority order."),
];
const findingsTable = makeTable(
  ["Pri.","Finding","Evidence","Business Impact","Recommendation","KPI to Monitor"],
  findingsData,
  [500, 1700, 2200, 1900, 2100, 1450]
);
findings.push(findingsTable, new Paragraph({ children: [new PageBreak()] }));

// ---------- Section 17: Recommendations ----------
const recsData = [
  ["Investigate and reduce systemic dispatch delay across all warehouses", "Warehouse Operations / Dispatch", "Raise on-time dispatch rate from 29.84% toward an interim target of 45%+", "Overall on-time dispatch rate", "Next quarterly review", "Immediate"],
  ["Conduct combined storage, handling and audit-process review at Liverpool Logistics, Bristol Supply Hub and Newcastle Depot", "Warehouse Operations / Quality", "Bring loss percentage at all three sites below the 5.73% network average", "Warehouse loss percentage", "Next quarterly review", "Immediate"],
  ["Engage Prime Wholesale UK on supplier quality control given its scale", "Procurement", "Reduce Prime Wholesale UK loss percentage from 5.74% to at or below network average", "Supplier loss percentage", "Next supplier review cycle", "Short-term"],
  ["Review audit failure root causes separately from physical loss initiatives", "Quality / Compliance", "Identify whether audit failures are documentation-driven; reduce audit failure rate from 15.42%", "Audit failure rate", "Next quarterly review", "Short-term"],
  ["Investigate Air Fryer packaging, handling and return reasons as a repeat-risk product", "Product / Category Management", "Reduce Air Fryer loss % (6.05%) and return % (5.28%) toward category averages", "Product-level loss % and return %", "Next quarterly review", "Short-term"],
  ["Document Leeds Fulfillment's handling and audit procedures as an internal benchmark", "Warehouse Operations", "Establish a reusable best-practice reference for underperforming sites", "Warehouse loss %, gross profit", "Ongoing", "Ongoing"],
  ["Track Adjusted Contribution Estimate (gross profit less inventory loss value) as a standing financial KPI", "Finance", "Establish visibility of loss's true impact on commercial contribution", "Adjusted contribution estimate", "Monthly", "Ongoing"],
];
const recs = [
  h1("17. Recommendations"),
  p("Each recommendation below links directly to a finding in Section 16 and specifies an owner, a measurable target, and the KPI used to confirm whether the action worked."),
];
const recsTable = makeTable(
  ["Action","Owner","Target","KPI Measured","Review Period","Priority"],
  recsData,
  [2300, 1400, 2200, 1400, 1250, 1300]
);
recs.push(recsTable, new Paragraph({ children: [new PageBreak()] }));

// ---------- Section 18: Limitations ----------
const limitations = [
  h1("18. Limitations"),
  p("This analysis is subject to the following limitations, which should be considered alongside the findings and recommendations above:"),
  bullet("Financial figures are estimates only. Estimated sales value, dispatched inventory cost, estimated gross profit and inventory loss value are derived purely from Quantity_Dispatched, Unit_Cost_GBP and Selling_Price_GBP. They do not include transport, labour, storage, tax, marketing or other operating expenses, and should not be read as audited revenue, net profit or realised financial loss."),
  bullet("The dataset does not include the causes of returns. Customer_Returns records only the quantity returned per transaction; the underlying reason (damage, wrong item, customer preference, quality fault) is not captured, so return-driver conclusions in this report are necessarily inferential (e.g. correlating returns with dispatch or audit status) rather than direct."),
  bullet("Employee-level findings show association, not causation. As noted in Section 12.2, differences in loss, audit or return rates between employees may reflect transaction mix, warehouse conditions or supplier quality rather than individual performance, and have been presented accordingly."),
  bullet("No point-in-time stock snapshots are available. Remaining Stock Units is a derived transaction-level estimate (received less dispatched, damaged and missing units) rather than a physically verified stock count at any given date, so it should be treated as an operational indicator rather than an audited inventory balance."),
  bullet("No independent causal evidence is available for any of the associations reported (e.g. temperature control and loss, audit outcome and loss, storage section and audit failure). All such findings describe statistical patterns in the transaction data and are recommended as starting points for operational investigation, not as proven cause-and-effect relationships."),
  bullet("The dataset covers 17 months (January 2025 to May 2026) with only 5 overlapping months (January\u2013May) available for year-over-year comparison, which limits the strength of seasonal conclusions that can be drawn."),
  new Paragraph({ children: [new PageBreak()] })
];

// ---------- Section 19: Conclusion ----------
const conclusion = [
  h1("19. Conclusion"),
  p("Across 5,000 transactions and 17 months of activity, this operation shows a fundamentally sound inventory-quality profile: loss (5.73%), return (4.64%) and pricing-integrity rates are stable, tightly clustered across warehouses, products, suppliers and employees, and unaffected by any material data-quality problems in the underlying dataset. The clearest and most urgent finding, however, is operational rather than physical: dispatch reliability is weak everywhere, with fewer than 3 in 10 transactions dispatched on time and over 4 in 10 recorded as Delayed, consistently across every warehouse in the network."),
  p("Secondary priorities are concentrated rather than dataset-wide: Liverpool Logistics, Bristol Supply Hub and Newcastle Depot combine above-average loss with above-average delivery time and warrant a joint operational review; Prime Wholesale UK is the one supplier where its scale means a quality improvement would have outsized network impact; and the disconnect between audit outcome and physical loss suggests the audit process itself, not physical stock handling, needs review."),
  p("Immediate management priorities are: (1) a network-wide investigation into dispatch scheduling and delay causes; (2) a combined operational review at the three flagged warehouses; and (3) a supplier engagement with Prime Wholesale UK. Together, these three actions address the findings with the largest measurable gap between current performance and a reasonable operational target, and each is tied to a specific KPI (on-time dispatch rate, warehouse loss percentage, and supplier loss percentage respectively) that can confirm whether the action has worked at the next review cycle."),
  new Paragraph({ children: [new PageBreak()] })
];

// ---------- Section 20: Appendix ----------
const appendix = [
  h1("20. Appendix"),
  h2("20.1 Appendix Query Documentation"),
  p(`The table below documents all ${tasks.length} individually numbered analytical queries specified in the project handbook, in the same order as they were executed. Each entry lists the handbook task ID, the business question it answers, and the report section where its output is used. The complete, executable SQL code for every query is reproduced in full in Section 20.2 immediately below, and is also provided as a standalone file (warehouse_inventory_analysis.sql) in the accompanying GitHub repository /sql folder, organised in the same order and fully commented.`),
];

const appendixRows = tasks.map(([id, desc, section]) => [id, desc, section]);
const appendixTable = makeTable(
  ["Query ID", "Business Question / Purpose", "Report Section"],
  appendixRows,
  [900, 6300, 2150]
);
appendix.push(appendixTable, new Paragraph({ children: [new PageBreak()] }));

// ---------- 20.2 Final SQL Query Script (full reproduced code) ----------
appendix.push(h2("20.2 Final SQL Query Script"));
appendix.push(p("The complete, executable SQL script is reproduced below in full, in the exact order it was run, with all comments and query numbering intact. This is the same script provided as sql/warehouse_inventory_analysis.sql in the accompanying repository."));

const sqlLines = fs.readFileSync('./sql/warehouse_inventory_analysis.sql', 'utf8').split('\n');
const sqlParagraphs = sqlLines.map(line => new Paragraph({
  children: [new TextRun({ text: line.length ? line : " ", font: "Courier New", size: 15, color: "222222" })],
  spacing: { after: 0 },
}));
appendix.push(...sqlParagraphs);
appendix.push(new Paragraph({ children: [new PageBreak()] }));

appendix.push(h2("20.3 Data Dictionary"));
const dictTable = makeTable(
  ["Column","Type","Purpose"],
  [
    ["Transaction_ID","VARCHAR (Primary Key)","Unique transaction reference"],
    ["Transaction_Date","DATE (converted)","Transaction timing; used for all time-series analysis"],
    ["Warehouse_Name","VARCHAR","Warehouse comparison"],
    ["City","VARCHAR","Geographic / destination field"],
    ["Product_Category","VARCHAR","High-level product grouping"],
    ["Product_Name","VARCHAR","Product-level analysis"],
    ["Supplier_Name","VARCHAR","Supplier quality and volume analysis"],
    ["Batch_Number","VARCHAR","Batch traceability"],
    ["Inventory_Type","VARCHAR","Inbound / Outbound classification"],
    ["Quantity_Received","INT","Inflow base measure"],
    ["Quantity_Dispatched","INT","Outflow base measure"],
    ["Damaged_Units","INT","Quality / financial-loss analysis"],
    ["Missing_Units","INT","Shrinkage / operational-control analysis"],
    ["Unit_Cost_GBP","DECIMAL(10,2)","Cost and margin calculations"],
    ["Selling_Price_GBP","DECIMAL(10,2)","Revenue and profit calculations"],
    ["Storage_Section","VARCHAR","Storage-location risk analysis"],
    ["Employee_Handling","VARCHAR","Workload and exception analysis"],
    ["Dispatch_Status","VARCHAR","Delivery-performance category"],
    ["Delivery_Days","INT","Delivery-time analysis"],
    ["Temperature_Controlled","VARCHAR","Storage-requirement analysis"],
    ["Stock_Audit_Status","VARCHAR","Compliance / audit-risk analysis"],
    ["Customer_Returns","INT","Post-dispatch quality analysis"],
  ],
  [2400, 2100, 4850]
);
appendix.push(dictTable, p(""));

appendix.push(h2("20.4 Core Metric Definitions"));
const metricTable = makeTable(
  ["Metric","Definition"],
  [
    ["Remaining Stock Units","Quantity Received \u2212 Quantity Dispatched \u2212 Damaged Units \u2212 Missing Units"],
    ["Inventory Loss Units","Damaged Units + Missing Units"],
    ["Inventory Loss Percentage","Inventory Loss Units \u00f7 Quantity Received \u00d7 100"],
    ["Damage Percentage","Damaged Units \u00f7 Quantity Received \u00d7 100"],
    ["Missing Percentage","Missing Units \u00f7 Quantity Received \u00d7 100"],
    ["Return Percentage","Customer Returns \u00f7 Quantity Dispatched \u00d7 100"],
    ["Estimated Sales Value","Quantity Dispatched \u00d7 Selling Price"],
    ["Dispatched Inventory Cost","Quantity Dispatched \u00d7 Unit Cost"],
    ["Estimated Gross Profit","Quantity Dispatched \u00d7 (Selling Price \u2212 Unit Cost)"],
    ["Inventory Loss Value","Inventory Loss Units \u00d7 Unit Cost"],
    ["Audit Failure Rate","Failed Audits \u00f7 Total Audits \u00d7 100"],
    ["On-Time Dispatch Rate","On-Time Transactions \u00f7 All Dispatch-Status Records \u00d7 100"],
  ],
  [2800, 6550]
);
appendix.push(metricTable);

module.exports = { financial, timeSeries, advanced, findings, recs, limitations, conclusion, appendix };
