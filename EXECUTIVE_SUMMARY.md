# Executive Summary — Warehouse Inventory SQL Analysis

This report analyses 5,000 warehouse inventory transactions covering 1 January 2025 to 16 May 2026. Overall, the operation received 2,614,361 units, dispatched 1,353,875 units and recorded an inventory loss rate of 5.73%.

The strongest overall performer was **Leeds Fulfillment**, based on the highest estimated gross profit (£49.83M) combined with the lowest inventory loss percentage (5.52%) of any warehouse. The highest operational risk was concentrated in **Liverpool Logistics**, which recorded the highest loss percentage (6.03%) and the highest audit failure rate (18.11%) of any location, alongside above-average delivery times.

Estimated gross profit across the operation was £362.3M, while inventory losses were valued at approximately £89.75M — equivalent to 24.8% of estimated gross profit.

The single largest operational risk identified was **dispatch reliability**: only 29.84% of transactions were dispatched on time, while 40.82% were recorded as Delayed — a pattern consistent across every warehouse in the network.

## Priority Actions

1. **Investigate the causes of widespread dispatch delay** across all locations (network-level scheduling/carrier review).
2. **Review handling, storage and audit practices** at Liverpool Logistics, Bristol Supply Hub and Newcastle Depot — the three warehouses flagged with both above-average loss and above-average delivery time.
3. **Engage Prime Wholesale UK** — the only supplier combining above-average supply volume with above-average loss percentage — on quality control.

## Key Figures

| Metric | Value |
|---|---|
| Total transactions | 5,000 |
| Transaction period | 1 Jan 2025 – 16 May 2026 (17 months) |
| Overall inventory loss percentage | 5.73% |
| Overall return percentage | 4.64% |
| Overall audit failure rate | 15.42% |
| Overall on-time dispatch rate | 29.84% |
| Total estimated gross profit | £362,306,345.47 |
| Total inventory loss value | £89,754,534.13 |

*Full findings, evidence and recommendations are in `report/Warehouse_Inventory_SQL_Analysis_Report.docx`.*
