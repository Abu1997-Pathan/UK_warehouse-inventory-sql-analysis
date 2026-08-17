const { Paragraph, PageBreak } = require('docx');
const P1 = require('./generate_report.js');
const { h1, h2, h3, p, bullet, calloutBox, makeTable } = P1;

// ---------- Section 9: Warehouse Performance ----------
const warehousePerf = [
  h1("9. Warehouse Performance"),
  p("Warehouse comparisons include both absolute totals and percentage-based measures, since a warehouse with the highest transaction volume does not automatically make it the least efficient warehouse."),
  h2("9.1 Warehouse Scorecard"),
];
const whTable = makeTable(
  ["Warehouse", "Txns", "Received", "Dispatched", "Loss %", "Avg Days", "On-Time %", "Audit Fail %", "Gross Profit (\u00a3)"],
  [
    ["Liverpool Logistics","602","307,481","157,676","6.03","5.66","28.07","18.11","43,262,499"],
    ["Birmingham Distribution","646","338,220","172,244","5.84","5.43","32.66","16.72","45,901,505"],
    ["Bristol Supply Hub","636","327,289","167,564","5.80","5.68","27.04","17.45","44,888,022"],
    ["Newcastle Depot","632","331,258","175,908","5.79","5.60","29.43","15.66","49,507,749"],
    ["London Central Hub","614","314,845","153,148","5.65","5.47","30.46","12.21","38,451,886"],
    ["Manchester Storage","612","324,524","167,579","5.65","5.49","28.10","13.89","42,786,655"],
    ["Glasgow Warehouse","627","333,648","177,039","5.58","5.35","33.81","16.43","47,677,762"],
    ["Leeds Fulfillment","631","337,096","182,717","5.52","5.54","29.00","12.84","49,830,267"],
  ],
  [1750, 700, 1150, 1150, 750, 800, 900, 950, 1500]
);
warehousePerf.push(whTable, p(""));
warehousePerf.push(h2("9.2 Key Findings"));
warehousePerf.push(
  calloutBox("Finding: Highest-Risk Warehouse \u2014 Liverpool Logistics",
    "Evidence: Liverpool Logistics recorded the highest inventory loss percentage (6.03%) and the highest audit failure rate (18.11%) of all 8 warehouses, alongside an above-average delivery time of 5.66 days. Business implication: the combination of elevated loss, the weakest compliance record and slower delivery makes this location the clearest single-site risk concentration in the network. Recommendation: prioritise a storage, handling and audit-process review at Liverpool Logistics before the next operating cycle."),
  p(""),
  calloutBox("Finding: Strongest Overall Performer \u2014 Leeds Fulfillment",
    "Evidence: Leeds Fulfillment combines the lowest loss percentage (5.52%) with the highest estimated gross profit (\u00a349.83M) of any warehouse, while handling the second-highest dispatch volume (182,717 units). Business implication: Leeds demonstrates that high throughput and low loss are achievable together, making its storage and handling practices a reasonable benchmark for other sites. Recommendation: document Leeds Fulfillment's current handling and audit procedures as a reference model for underperforming locations."),
  p(""),
  calloutBox("Finding: Multi-Risk Warehouses (Above-Average Loss AND Above-Average Delivery Time)",
    "Evidence: three warehouses \u2014 Liverpool Logistics (6.03% loss, 5.66 days), Bristol Supply Hub (5.80% loss, 5.68 days) and Newcastle Depot (5.79% loss, 5.60 days) \u2014 exceed both the overall average loss percentage (5.73%) and the overall average delivery time (5.53 days) simultaneously. Business implication: these three sites combine inventory risk with delivery risk, which compounds the likelihood of customer-facing problems (a delayed shipment that has also sustained damage). Recommendation: treat these three warehouses as the priority group for a combined operational review, rather than addressing loss and delivery issues separately."),
  p(""),
  calloutBox("Finding: Dispatch Reliability Is Weak Across Every Warehouse",
    "Evidence: even the best-performing warehouse for on-time dispatch, Glasgow Warehouse, achieves only 33.81% on-time delivery; the weakest, Bristol Supply Hub, achieves 27.04%. The spread between the best and worst warehouse is under 7 percentage points, which is small relative to how far every warehouse sits from full on-time performance. Business implication: dispatch delay is not a location-specific problem \u2014 it is systemic across the whole network, suggesting a shared process, carrier, or scheduling constraint rather than a site-management issue. Recommendation: investigate dispatch scheduling and carrier processes at a network level rather than warehouse-by-warehouse.")
);
warehousePerf.push(new Paragraph({ children: [new PageBreak()] }));

// ---------- Section 10: Product and Category Performance ----------
const productPerf = [
  h1("10. Product and Category Performance"),
  h2("10.1 Category-Level Summary"),
];
const catTable = makeTable(
  ["Category","Txns","Received","Dispatched","Loss %","Return %","Sales Value (\u00a3)","Gross Profit (\u00a3)"],
  [
    ["Pharma","1,007","527,791","274,393","5.70","4.53","244,691,702","77,050,747"],
    ["Electronics","998","540,798","279,298","5.51","4.51","243,922,283","75,832,460"],
    ["Home Appliances","1,006","522,164","269,066","5.82","4.81","226,023,146","70,334,450"],
    ["Grocery","999","513,843","267,159","5.72","4.73","226,590,593","69,545,920"],
    ["Fashion","990","509,765","263,959","5.93","4.64","229,500,909","69,542,768"],
  ],
  [1650, 700, 1100, 1100, 750, 800, 1650, 1600]
);
productPerf.push(catTable, p(""));
productPerf.push(calloutBox("Finding: Category Risk Profile",
  "Evidence: Fashion carries the highest loss percentage of any category (5.93%) despite ranking only fourth by dispatched volume, while Electronics has the lowest loss percentage (5.51%) despite the highest received volume (540,798 units). Home Appliances has the highest return percentage (4.81%). Business implication: category-level risk is not simply a function of scale \u2014 Fashion's higher loss rate and Home Appliances' higher return rate point to product-specific handling or quality issues rather than volume pressure. Recommendation: review packaging and handling standards for Fashion items, and investigate the drivers of Home Appliances returns (e.g. product fit, damage in transit, or customer expectation mismatches)."));
productPerf.push(p(""));
productPerf.push(h2("10.2 Top Products by Estimated Gross Profit"));
const topProfitTable = makeTable(
  ["Product","Category","Gross Profit (\u00a3)"],
  [
    ["Cough Syrup","Pharma","20,626,721"],
    ["Vitamin Tablets","Pharma","20,245,907"],
    ["Paracetamol","Pharma","18,781,424"],
    ["Mixer","Home Appliances","18,546,293"],
    ["Vacuum Cleaner","Home Appliances","18,169,378"],
    ["Keyboard","Electronics","17,803,697"],
    ["Bandages","Pharma","17,396,695"],
  ],
  [3200, 2800, 2900]
);
productPerf.push(topProfitTable, p(""));
productPerf.push(h2("10.3 Highest-Risk Products (Minimum Volume Applied to Avoid Unstable Percentages)"));
const topLossTable = makeTable(
  ["Product","Received Units","Loss %"],
  [
    ["Jacket","102,834","6.18"],
    ["T-Shirt","108,887","6.15"],
    ["Coffee","99,729","6.14"],
    ["Air Fryer","136,832","6.05"],
    ["Cereal","101,390","5.94"],
  ],
  [3600, 2800, 2500]
);
productPerf.push(topLossTable, p(""));
const topReturnTable = makeTable(
  ["Product","Dispatched Units","Return %"],
  [
    ["Air Fryer","66,645","5.28"],
    ["Handbag","51,020","5.19"],
    ["Rice Pack","55,754","4.94"],
    ["Smartphone","54,435","4.81"],
    ["Cereal","53,339","4.81"],
  ],
  [3600, 2800, 2500]
);
productPerf.push(p("Products with the highest return percentage (minimum 200 dispatched units applied):"), topReturnTable, p(""));
productPerf.push(calloutBox("Finding: Air Fryer Is a Repeat Risk Item",
  "Evidence: Air Fryer appears in both the top-5 highest-loss products (6.05%, well above the 5.73% overall average) and the top-5 highest-return products (5.28%, the single highest return rate of any product in the dataset). Business implication: this product combines physical handling risk with post-dispatch quality or fulfilment risk, making it a priority for root-cause investigation ahead of any category-wide policy change. Recommendation: conduct a focused review of Air Fryer packaging, handling instructions and return reason codes before extending any changes to the rest of the Home Appliances category."));
productPerf.push(new Paragraph({ children: [new PageBreak()] }));

// ---------- Section 11: Supplier Performance ----------
const supplierPerf = [
  h1("11. Supplier Performance"),
  p("Supplier comparisons use percentage-based measures throughout, since high-volume suppliers should not be judged on total losses alone."),
];
const supTable = makeTable(
  ["Supplier","Txns","Received","Loss %","Audit Fail %","Return %","Gross Profit (\u00a3)"],
  [
    ["ASDA Distribution","611","309,674","6.04","14.40","4.60","45,818,653"],
    ["UK Retail Goods","619","314,432","5.93","16.96","4.81","41,819,605"],
    ["Tesco Supply Ltd","610","317,507","5.78","16.07","4.48","42,612,594"],
    ["Prime Wholesale UK","658","348,061","5.74","13.37","4.71","45,460,827"],
    ["London Trade Corp","616","323,005","5.70","15.58","4.77","48,570,058"],
    ["Britannia Pharma","630","332,763","5.62","17.62","4.61","46,483,443"],
    ["Northern Supply Chain","626","333,882","5.55","15.50","4.65","47,083,102"],
    ["Sainsbury Logistics","630","335,037","5.52","13.97","4.51","44,458,064"],
  ],
  [1900, 650, 1100, 750, 1050, 800, 1600]
);
supplierPerf.push(supTable, p(""));
supplierPerf.push(calloutBox("Finding: Highest-Risk Supplier \u2014 ASDA Distribution",
  "Evidence: ASDA Distribution recorded the highest loss percentage of any supplier (6.04%, against an overall average of 5.73%). Britannia Pharma recorded the highest audit failure rate of any supplier (17.62%). Business implication: these two suppliers warrant separate conversations \u2014 ASDA Distribution on physical product quality and packaging, Britannia Pharma on compliance and documentation standards, since their risk profiles differ in nature. Recommendation: schedule a supplier quality review with ASDA Distribution and a compliance/documentation review with Britannia Pharma."));
supplierPerf.push(p(""));
supplierPerf.push(calloutBox("Finding: Priority Supplier \u2014 Above-Average Volume AND Above-Average Loss",
  "Evidence: applying the combined filter of above-average supply volume and above-average loss percentage (Handbook task 7.7) identifies exactly one supplier meeting both conditions: Prime Wholesale UK, with the highest received volume of any supplier (348,061 units) and a loss percentage (5.74%) marginally above the 5.73% overall average. Business implication: because Prime Wholesale UK supplies more volume than any other partner, even a small loss-rate premium translates into a large absolute loss exposure, making it the single supplier where a modest quality improvement would have the greatest network-wide impact. Recommendation: prioritise Prime Wholesale UK for supplier engagement, since improvement here scales further than at any other supplier."));
supplierPerf.push(new Paragraph({ children: [new PageBreak()] }));

// ---------- Section 12: Operational Performance ----------
const opPerf = [
  h1("12. Operational Performance"),
  h2("12.1 Dispatch Status and Delivery Time"),
];
const dispatchTable = makeTable(
  ["Dispatch Status","Transactions","% of Total","Avg Delivery Days"],
  [
    ["Delayed","2,041","40.82","8.49"],
    ["On Time","1,492","29.84","2.01"],
    ["Slightly Delayed","1,467","29.34","5.00"],
  ],
  [2700, 2200, 2200, 2250]
);
opPerf.push(dispatchTable, p(""));
opPerf.push(calloutBox("Finding: Dispatch Delay Is the Operation's Single Largest Risk",
  "Evidence: 40.82% of all transactions are recorded as Delayed (averaging 8.49 delivery days), while only 29.84% are On Time (averaging 2.01 days). This pattern is consistent across every warehouse (best: Glasgow Warehouse at 33.81% on-time; worst: Bristol Supply Hub at 27.04% on-time), every product category and every supplier, indicating the issue is systemic rather than isolated to any single segment. Business implication: this is the largest deviation from an operational ideal found anywhere in the dataset \u2014 far larger in scale than the roughly 0.5 percentage-point spread seen in loss rates across warehouses, products and suppliers \u2014 and is the finding most likely to affect customer satisfaction, since delayed dispatch is also associated with the highest average delivery time by a wide margin. Recommendation: this should be the number-one priority for operational investigation, ahead of the smaller, segment-specific loss and audit findings elsewhere in this report."));
opPerf.push(p(""));

opPerf.push(h2("12.2 Employee Handling Analysis"));
opPerf.push(calloutBox("Interpretation Caution",
  "The database shows association, not direct causation. Differences between employees may reflect transaction mix, warehouse conditions, supplier quality or workload rather than individual performance alone. Findings below use wording such as \u201ctransactions associated with this employee recorded a higher rate\u201d rather than attributing cause, and recommend investigation of workload, product mix and warehouse conditions rather than direct performance judgement."));
const empTable = makeTable(
  ["Employee","Txns","Loss %","Audit Fail %","Return %"],
  [
    ["Oliver Smith","644","5.96","15.06","4.59"],
    ["Charlie Davies","625","5.92","16.16","4.78"],
    ["Emily Harris","639","5.74","15.81","4.75"],
    ["George Brown","626","5.74","14.86","4.57"],
    ["Jack Taylor","580","5.74","16.03","4.76"],
    ["Amelia Clark","620","5.69","16.13","4.58"],
    ["Noah Wilson","615","5.56","13.33","4.49"],
    ["Harry Johnson","651","5.50","15.98","4.61"],
  ],
  [2600, 1400, 1600, 1900, 1500]
);
opPerf.push(empTable, p(""));
opPerf.push(p("Workload is evenly distributed across the 8 employees (580\u2013651 transactions each), and loss percentages associated with each employee fall within a narrow 0.46-percentage-point band (5.50%\u20135.96%). This narrow spread, combined with even workload distribution, does not point to an individual-performance issue; it is more consistent with loss being driven by product, supplier and warehouse conditions shared across the team."));
opPerf.push(new Paragraph({ children: [new PageBreak()] }));

opPerf.push(h2("12.3 Storage Section Analysis"));
const storageTable = makeTable(
  ["Storage Section","Txns","Loss Units","Loss %","Audit Fail %"],
  [
    ["A1","619","18,574","5.90","15.02"],
    ["B2","611","18,622","5.87","15.88"],
    ["D1","668","20,002","5.83","16.77"],
    ["D2","629","18,964","5.81","15.74"],
    ["B1","605","18,098","5.73","15.37"],
    ["C2","625","18,802","5.62","14.24"],
    ["A2","630","18,500","5.56","13.02"],
    ["C1","613","18,266","5.54","17.29"],
  ],
  [2600, 1400, 1700, 1500, 1800]
);
opPerf.push(storageTable, p(""));
opPerf.push(calloutBox("Finding: Storage Section C1 Decouples Loss and Audit Risk",
  "Evidence: Storage Section C1 has the lowest loss percentage of any section (5.54%) but the highest audit failure rate (17.29%) \u2014 the opposite pattern from Section A1, which has the highest loss percentage (5.90%) but a mid-range audit failure rate (15.02%). Business implication: this indicates that physical inventory loss and audit compliance are driven by different underlying causes in this operation \u2014 loss appears more closely tied to product handling, while audit failure may reflect documentation or process-compliance gaps unrelated to physical stock condition. Recommendation: investigate audit procedures specifically at Section C1 (e.g. paperwork completion, scan compliance) separately from the physical handling review recommended for Section A1."));
opPerf.push(p(""));

opPerf.push(h2("12.4 Temperature-Control Analysis"));
const tempTable = makeTable(
  ["Temperature Controlled","Txns","Loss %","Audit Fail %","Avg Delivery Days"],
  [
    ["No","2,469","5.77","15.23","5.56"],
    ["Yes","2,531","5.69","15.61","5.50"],
  ],
  [3200, 1600, 1600, 1900, 1900]
);
opPerf.push(tempTable, p(""));
opPerf.push(calloutBox("Finding: Temperature Control Shows Minimal Measurable Benefit in This Dataset",
  "Evidence: loss percentage for temperature-controlled inventory (5.69%) is only marginally lower than non-controlled inventory (5.77%), a difference of 0.08 percentage points, and audit failure rate is in fact slightly higher for temperature-controlled inventory (15.61% vs 15.23%). Business implication: on the evidence available, temperature control is not associated with a materially lower loss or higher compliance outcome in this dataset, which may reflect that damage and missing-unit causes in this operation are largely unrelated to temperature sensitivity, or that temperature-control procedures are not being differentiated operationally from standard handling. Recommendation: before further investment in temperature-control infrastructure, verify whether temperature-controlled transactions are being handled under genuinely different procedures, since the data does not currently show a clear performance benefit."));
opPerf.push(p(""));

opPerf.push(h2("12.5 Stock Audit Analysis"));
const auditTable = makeTable(
  ["Audit Outcome","Loss %","Return %","Avg Delivery Days"],
  [
    ["Failed","5.71","4.71","5.53"],
    ["Passed","5.74","4.63","5.53"],
  ],
  [3200, 2000, 2000, 2000]
);
opPerf.push(auditTable, p(""));
opPerf.push(calloutBox("Finding: Audit Outcome Shows No Material Link to Inventory Loss in This Dataset",
  "Evidence: transactions with a Failed audit outcome show a loss percentage of 5.71%, nearly identical to Passed transactions at 5.74%, indicating no material descriptive difference between the two groups; average delivery days are also identical (5.53) for both. Business implication: audit failure does not track with higher physical inventory loss in this dataset, which suggests that audit failures may reflect documentation, process or compliance factors not captured in the dataset, rather than the physical condition of stock \u2014 though this dataset cannot establish the actual cause. Recommendation: review what specifically causes audits to fail at this business (paperwork, count discrepancies, timing) since the current evidence suggests it is not simply a proxy for damaged or missing stock."));
opPerf.push(new Paragraph({ children: [new PageBreak()] }));

module.exports = { warehousePerf, productPerf, supplierPerf, opPerf };
