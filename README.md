# Warehouse Inventory SQL Analysis

A complete SQL-based analytical project examining 5,000 UK warehouse inventory transactions (1 January 2025 – 16 May 2026) to evaluate stock movement, inventory loss, supplier quality, warehouse efficiency, dispatch reliability, employee handling, audit outcomes, customer returns and financial performance.

**Platform:** MySQL 8.0 (developed and tested using MariaDB 10.11, which is wire-compatible with the MySQL syntax used throughout)
**Records analysed:** 5,000 transactions × 22 fields
**Analytical tasks completed:** 148 individually numbered SQL queries across 13 project phases, plus a self-contained database setup step

## Central Analytical Question

> How effectively is inventory being received, stored, handled, dispatched and converted into revenue, and where are losses, delays, audit failures and returns creating operational or financial risk?

## Key Findings (see full report for evidence and detail)

1. **Dispatch reliability is the operation's weakest area** — only 29.84% of transactions were dispatched on time, against 40.82% recorded as Delayed, consistently across every warehouse.
2. **Liverpool Logistics is the highest combined-risk warehouse** — highest inventory loss (6.03%), highest audit failure rate (18.11%), and above-average delivery time.
3. **Inventory loss represents 24.8% of estimated gross profit** — £89.75M in loss value against £362.3M in estimated gross profit.
4. **Audit failure is not associated with higher physical inventory loss** — Failed-audit and Passed-audit transactions show almost identical loss rates (5.71% vs 5.74%), suggesting audit failures relate to compliance/documentation rather than physical stock condition.
5. **Prime Wholesale UK is the priority supplier for engagement** — the only supplier combining above-average supply volume with above-average loss percentage.

## Repository Structure

```
├── README.md                                          This file
├── EXECUTIVE_SUMMARY.md                                Standalone one-page executive summary
├── sql/
│   └── warehouse_inventory_analysis.sql                Complete, self-contained SQL script (148 tasks, 14 phases,
                                                          plus a Section 0 that creates and loads the database from
                                                          scratch — no external setup required)
├── report/
│   ├── Warehouse_Inventory_SQL_Analysis_Report.docx     Full 58-page analysis report (Word), including the
                                                          complete SQL script reproduced in the appendix (20.2)
│   └── Warehouse_Inventory_SQL_Analysis_Report.pdf      Same report, PDF version
├── data/
│   ├── UK_Warehouse_Inventory_Dataset.csv               Original source dataset, as provided
│   └── warehouse_transactions_cleaned.csv               Validated analytical table (Transaction_Date converted to DATE)
└── outputs/
    ├── FULL_OUTPUT.txt                                  Complete captured output of every query, from a fresh
                                                          clean-room run against an empty database
    └── summary_tables/                                  Key result tables exported as CSV (warehouse, category,
                                                           supplier, product, dispatch, employee, storage-section,
                                                           temperature-control, audit, time-series, risk-flag tables)
```

## How to Reproduce

1. Create a MySQL/MariaDB database (any name) and select it, e.g.:
   ```sql
   CREATE DATABASE warehouse_inventory CHARACTER SET utf8mb4;
   USE warehouse_inventory;
   ```
2. Run `sql/warehouse_inventory_analysis.sql` from the repository root, e.g.:
   ```bash
   mysql -u <user> -p --local-infile=1 warehouse_inventory < sql/warehouse_inventory_analysis.sql
   ```
   The script is fully self-contained: **Section 0** creates the raw staging table and loads
   `data/UK_Warehouse_Inventory_Dataset.csv` directly (relative path, assumes you run the command
   from the repository root — adjust the path in Section 0 if running from elsewhere). No manual
   table setup or separate import step is required. The script does not hardcode a database name —
   it runs against whichever database you've selected — and is idempotent (safe to re-run in full
   from an empty database; each run rebuilds the raw table from scratch so column and row counts
   stay consistent). It will then:
   - Convert `Transaction_Date` from text (DD-MM-YYYY) to a proper `DATE` field
   - Build the validated analytical table `warehouse_transactions`
   - Run all 148 analytical queries organised into 14 phases (inspection → date conversion → data quality → KPIs → warehouse/product/supplier/dispatch/employee/audit/financial/time-series/advanced SQL → reusable views)
3. Full narrative interpretation of the results is in `report/Warehouse_Inventory_SQL_Analysis_Report.docx`, which also reproduces the complete SQL script in Appendix 20.2.

This exact process was independently re-verified against a completely empty, freshly created database, importing only from the packaged `data/UK_Warehouse_Inventory_Dataset.csv` — confirming the package is fully self-contained and reproducible end to end (5,000 rows loaded, 22 columns confirmed at initial inspection, 0 errors, identical KPIs to those reported).

## Methodology Notes

- All financial figures (estimated sales value, estimated gross profit, inventory loss value) are **estimates** derived from `Quantity_Dispatched × Selling_Price_GBP` / `Unit_Cost_GBP`. They exclude transport, labour, storage, tax and other operating expenses and should not be read as audited revenue or net profit.
- All rate-based comparisons (loss %, return %, audit failure %, on-time %) use `NULLIF`-protected safe division to avoid divide-by-zero errors.
- Employee-level findings are presented as *association*, not causation, per the report's interpretation caution in Section 12.2.
- The dataset passed all data-quality checks with zero duplicates, zero nulls, zero invalid categories, and only 12 minor cross-field exceptions (0.24% of records), which were retained and flagged rather than deleted.

## License

This project (SQL script, report and documentation) is provided under the MIT License — see [LICENSE](LICENSE). The underlying dataset's usage terms are the responsibility of the data owner.
