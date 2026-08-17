-- ============================================================================
-- WAREHOUSE INVENTORY SQL ANALYSIS
-- Complete Analytical Script
-- Platform: MySQL 8.0
-- Database: any name (create and select it before running this script)
-- ============================================================================
-- This script follows the Recommended Query File Structure (Handbook Section 4.3):
--   0. Database setup and data import (prerequisite, not a handbook task)
--   1. Database and table inspection
--   2. Date conversion and validation
--   3. Data-quality checks
--   4. Overall KPI analysis
--   5. Warehouse analysis
--   6. Product and category analysis
--   7. Supplier analysis
--   8. Dispatch and delivery analysis
--   9. Employee and storage-section analysis
--  10. Audit, temperature-control and returns analysis
--  11. Financial analysis
--  12. Time-series analysis
--  13. Advanced SQL analysis
--  14. Final reporting views or summary queries
--
-- Each analytical query is labelled with its handbook task number (e.g. -- 1.1)
-- and preceded by a short comment explaining the business question. Setup
-- steps in Section 0 are deliberately NOT given handbook task numbers, since
-- they are a technical prerequisite rather than an analytical task.
-- ============================================================================

-- IMPORTANT: Create and select your target database before running this
-- script, e.g.:
--   CREATE DATABASE warehouse_inventory CHARACTER SET utf8mb4;
--   USE warehouse_inventory;
-- No hardcoded USE statement is included here, so this script can be run
-- against a database of any name without silently switching context.

-- ============================================================================
-- SECTION 0: DATABASE SETUP AND DATA IMPORT
-- ============================================================================
-- This section makes the script fully self-contained and reproducible from
-- an empty database. It creates the raw staging table exactly as the source
-- CSV is structured (22 columns, Transaction_Date held as text pending
-- conversion in Section 2) and loads data/UK_Warehouse_Inventory_Dataset.csv
-- from the repository. It is safe to re-run: the raw table is dropped and
-- rebuilt from scratch each time, so column counts and row counts are always
-- consistent with a fresh import.

-- Setup Step 1: create the raw staging table (22 columns, matching the
-- source CSV structure before any date conversion or cleaning).
DROP TABLE IF EXISTS warehouse_transactions_raw;

CREATE TABLE warehouse_transactions_raw (
    Transaction_ID          VARCHAR(20)     NOT NULL,
    Transaction_Date_Text   VARCHAR(20)     NOT NULL,   -- original text date, DD-MM-YYYY (maps to the CSV's "Transaction_Date" column by position)
    Warehouse_Name          VARCHAR(100)    NOT NULL,
    City                    VARCHAR(100)    NOT NULL,
    Product_Category        VARCHAR(100)    NOT NULL,
    Product_Name            VARCHAR(100)    NOT NULL,
    Supplier_Name            VARCHAR(100)    NOT NULL,
    Batch_Number              VARCHAR(50)     NOT NULL,
    Inventory_Type             VARCHAR(20)     NOT NULL,
    Quantity_Received          INT             NOT NULL,
    Quantity_Dispatched        INT             NOT NULL,
    Damaged_Units               INT             NOT NULL,
    Missing_Units                INT             NOT NULL,
    Unit_Cost_GBP                 DECIMAL(10,2)   NOT NULL,
    Selling_Price_GBP             DECIMAL(10,2)   NOT NULL,
    Storage_Section                VARCHAR(10)     NOT NULL,
    Employee_Handling               VARCHAR(100)    NOT NULL,
    Dispatch_Status                  VARCHAR(30)     NOT NULL,
    Delivery_Days                     INT             NOT NULL,
    Temperature_Controlled             VARCHAR(5)      NOT NULL,
    Stock_Audit_Status                  VARCHAR(20)     NOT NULL,
    Customer_Returns                     INT             NOT NULL,
    PRIMARY KEY (Transaction_ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Setup Step 2: enable LOCAL INFILE loading for this session (required by
-- some MySQL client/server configurations before LOAD DATA LOCAL INFILE
-- will run). If your server already permits this, the statement is harmless.
SET GLOBAL local_infile = 1;

-- Setup Step 3: load the source dataset. Path is relative to the
-- repository root — adjust it if you run this script from a different
-- working directory or client.
LOAD DATA LOCAL INFILE 'data/UK_Warehouse_Inventory_Dataset.csv'
INTO TABLE warehouse_transactions_raw
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(Transaction_ID, Transaction_Date_Text, Warehouse_Name, City, Product_Category, Product_Name,
 Supplier_Name, Batch_Number, Inventory_Type, Quantity_Received, Quantity_Dispatched,
 Damaged_Units, Missing_Units, Unit_Cost_GBP, Selling_Price_GBP, Storage_Section,
 Employee_Handling, Dispatch_Status, Delivery_Days, Temperature_Controlled,
 Stock_Audit_Status, Customer_Returns);

-- Setup Step 4: confirm the import before proceeding to Phase 1.
SELECT COUNT(*) AS Rows_Imported FROM warehouse_transactions_raw;


-- ============================================================================
-- SECTION 1: DATABASE AND TABLE INSPECTION (Handbook Phase 1, 5.1)
-- ============================================================================

-- 1.1 Display table structure and current data types.
-- Reason: confirms whether numeric, text and date fields imported correctly.
DESCRIBE warehouse_transactions_raw;

-- 1.2 Display the first 20 rows for a visual check of formats and values.
SELECT *
FROM warehouse_transactions_raw
LIMIT 20;

-- 1.3 Count all records in the table to confirm the expected 5,000 rows loaded.
SELECT COUNT(*) AS Total_Row_Count
FROM warehouse_transactions_raw;

-- 1.4 Count the number of columns to confirm all 22 expected fields are present.
SELECT COUNT(*) AS Total_Column_Count
FROM information_schema.columns
WHERE table_schema = DATABASE()
  AND table_name   = 'warehouse_transactions_raw';

-- 1.5 List distinct values for each major categorical field.
SELECT DISTINCT Warehouse_Name FROM warehouse_transactions_raw ORDER BY Warehouse_Name;
SELECT DISTINCT City FROM warehouse_transactions_raw ORDER BY City;
SELECT DISTINCT Product_Category FROM warehouse_transactions_raw ORDER BY Product_Category;
SELECT DISTINCT Product_Name FROM warehouse_transactions_raw ORDER BY Product_Name;
SELECT DISTINCT Supplier_Name FROM warehouse_transactions_raw ORDER BY Supplier_Name;
SELECT DISTINCT Inventory_Type FROM warehouse_transactions_raw ORDER BY Inventory_Type;
SELECT DISTINCT Dispatch_Status FROM warehouse_transactions_raw ORDER BY Dispatch_Status;
SELECT DISTINCT Stock_Audit_Status FROM warehouse_transactions_raw ORDER BY Stock_Audit_Status;
SELECT DISTINCT Temperature_Controlled FROM warehouse_transactions_raw ORDER BY Temperature_Controlled;

-- 1.6 Count distinct values for each major categorical field (structural profile).
SELECT
    COUNT(DISTINCT Warehouse_Name)       AS Distinct_Warehouses,
    COUNT(DISTINCT City)                 AS Distinct_Cities,
    COUNT(DISTINCT Product_Category)     AS Distinct_Categories,
    COUNT(DISTINCT Product_Name)         AS Distinct_Products,
    COUNT(DISTINCT Supplier_Name)        AS Distinct_Suppliers,
    COUNT(DISTINCT Employee_Handling)    AS Distinct_Employees,
    COUNT(DISTINCT Storage_Section)      AS Distinct_Storage_Sections,
    COUNT(DISTINCT Inventory_Type)       AS Distinct_Inventory_Types,
    COUNT(DISTINCT Dispatch_Status)      AS Distinct_Dispatch_Statuses,
    COUNT(DISTINCT Stock_Audit_Status)   AS Distinct_Audit_Statuses
FROM warehouse_transactions_raw;

-- ============================================================================
-- SECTION 2: DATE CONVERSION AND VALIDATION (Handbook 5.2)
-- ============================================================================

-- Step 1: Inspect a sample of the original date values to confirm the format
-- is consistently day-month-year (DD-MM-YYYY).
SELECT Transaction_ID, Transaction_Date_Text
FROM warehouse_transactions_raw
LIMIT 20;

-- Step 2: Create a separate DATE column rather than changing the original
-- field immediately (data-safety requirement).
ALTER TABLE warehouse_transactions_raw
    DROP COLUMN IF EXISTS Transaction_Date_Converted;

ALTER TABLE warehouse_transactions_raw
    ADD COLUMN Transaction_Date_Converted DATE NULL;

-- Step 3: Parse the text date (DD-MM-YYYY) into the new DATE column.
UPDATE warehouse_transactions_raw
SET Transaction_Date_Converted = STR_TO_DATE(Transaction_Date_Text, '%d-%m-%Y');

-- Step 4: Compare the original text date and converted date side by side
-- for a representative sample.
SELECT Transaction_ID, Transaction_Date_Text, Transaction_Date_Converted
FROM warehouse_transactions_raw
LIMIT 20;

-- Step 5: Validation query - find records where the original date is present
-- but the converted date is null (parsing failure).
SELECT COUNT(*) AS Date_Conversion_Failures
FROM warehouse_transactions_raw
WHERE Transaction_Date_Text IS NOT NULL
  AND Transaction_Date_Text <> ''
  AND Transaction_Date_Converted IS NULL;

-- Step 6: Check the minimum and maximum converted dates and confirm the
-- expected range from 1 January 2025 to 16 May 2026.
SELECT
    MIN(Transaction_Date_Converted) AS Earliest_Transaction_Date,
    MAX(Transaction_Date_Converted) AS Latest_Transaction_Date
FROM warehouse_transactions_raw;

-- Step 7: Build the final validated analytical table. The original text
-- date is archived as Transaction_Date_Text and the converted field is
-- renamed to Transaction_Date, matching the recommended DATE type.
DROP TABLE IF EXISTS warehouse_transactions;

CREATE TABLE warehouse_transactions AS
SELECT
    Transaction_ID,
    Transaction_Date_Converted AS Transaction_Date,
    Transaction_Date_Text,                         -- original text date retained (data-safety / audit trail)
    Warehouse_Name,
    City,
    Product_Category,
    Product_Name,
    Supplier_Name,
    Batch_Number,
    Inventory_Type,
    Quantity_Received,
    Quantity_Dispatched,
    Damaged_Units,
    Missing_Units,
    Unit_Cost_GBP,
    Selling_Price_GBP,
    Storage_Section,
    Employee_Handling,
    Dispatch_Status,
    Delivery_Days,
    Temperature_Controlled,
    Stock_Audit_Status,
    Customer_Returns
FROM warehouse_transactions_raw;

ALTER TABLE warehouse_transactions
    ADD PRIMARY KEY (Transaction_ID),
    MODIFY COLUMN Transaction_Date DATE NOT NULL,
    ADD INDEX idx_warehouse (Warehouse_Name),
    ADD INDEX idx_category (Product_Category),
    ADD INDEX idx_supplier (Supplier_Name),
    ADD INDEX idx_date (Transaction_Date);

-- Step 8: Recheck the table structure and confirm Transaction_Date now
-- uses the DATE data type.
DESCRIBE warehouse_transactions;

SELECT COUNT(*) AS Final_Table_Row_Count FROM warehouse_transactions;

-- ============================================================================
-- SECTION 3: DATA-QUALITY CHECKS (Handbook Phase 2, 6.1 - 6.3)
-- ============================================================================

-- 2.1 Identify duplicate Transaction_ID values.
SELECT Transaction_ID, COUNT(*) AS Occurrence_Count
FROM warehouse_transactions
GROUP BY Transaction_ID
HAVING COUNT(*) > 1;

-- 2.2 Count null values in every column (completeness summary).
SELECT
    SUM(Transaction_ID IS NULL)         AS Null_Transaction_ID,
    SUM(Transaction_Date IS NULL)       AS Null_Transaction_Date,
    SUM(Warehouse_Name IS NULL)         AS Null_Warehouse_Name,
    SUM(City IS NULL)                   AS Null_City,
    SUM(Product_Category IS NULL)       AS Null_Product_Category,
    SUM(Product_Name IS NULL)           AS Null_Product_Name,
    SUM(Supplier_Name IS NULL)          AS Null_Supplier_Name,
    SUM(Batch_Number IS NULL)           AS Null_Batch_Number,
    SUM(Inventory_Type IS NULL)         AS Null_Inventory_Type,
    SUM(Quantity_Received IS NULL)      AS Null_Quantity_Received,
    SUM(Quantity_Dispatched IS NULL)    AS Null_Quantity_Dispatched,
    SUM(Damaged_Units IS NULL)          AS Null_Damaged_Units,
    SUM(Missing_Units IS NULL)          AS Null_Missing_Units,
    SUM(Unit_Cost_GBP IS NULL)          AS Null_Unit_Cost_GBP,
    SUM(Selling_Price_GBP IS NULL)      AS Null_Selling_Price_GBP,
    SUM(Storage_Section IS NULL)        AS Null_Storage_Section,
    SUM(Employee_Handling IS NULL)      AS Null_Employee_Handling,
    SUM(Dispatch_Status IS NULL)        AS Null_Dispatch_Status,
    SUM(Delivery_Days IS NULL)          AS Null_Delivery_Days,
    SUM(Temperature_Controlled IS NULL) AS Null_Temperature_Controlled,
    SUM(Stock_Audit_Status IS NULL)     AS Null_Stock_Audit_Status,
    SUM(Customer_Returns IS NULL)       AS Null_Customer_Returns
FROM warehouse_transactions;

-- 2.3 Find blank or whitespace-only values in text columns.
SELECT
    SUM(TRIM(Warehouse_Name) = '')      AS Blank_Warehouse_Name,
    SUM(TRIM(City) = '')                AS Blank_City,
    SUM(TRIM(Product_Category) = '')    AS Blank_Product_Category,
    SUM(TRIM(Product_Name) = '')        AS Blank_Product_Name,
    SUM(TRIM(Supplier_Name) = '')       AS Blank_Supplier_Name,
    SUM(TRIM(Batch_Number) = '')        AS Blank_Batch_Number,
    SUM(TRIM(Storage_Section) = '')     AS Blank_Storage_Section,
    SUM(TRIM(Employee_Handling) = '')   AS Blank_Employee_Handling
FROM warehouse_transactions;

-- 2.4 Identify negative values in quantity, price, delivery or return fields.
SELECT COUNT(*) AS Rows_With_Negative_Values
FROM warehouse_transactions
WHERE Quantity_Received < 0 OR Quantity_Dispatched < 0
   OR Damaged_Units < 0     OR Missing_Units < 0
   OR Unit_Cost_GBP < 0     OR Selling_Price_GBP < 0
   OR Delivery_Days < 0     OR Customer_Returns < 0;

-- 2.5 Identify zero values in major quantity and price columns (business-rule review).
SELECT
    SUM(Quantity_Received = 0)   AS Zero_Quantity_Received,
    SUM(Quantity_Dispatched = 0) AS Zero_Quantity_Dispatched,
    SUM(Unit_Cost_GBP = 0)       AS Zero_Unit_Cost,
    SUM(Selling_Price_GBP = 0)   AS Zero_Selling_Price
FROM warehouse_transactions;

-- 2.6 Detect categorical values outside the known lists (unexpected categories).
SELECT DISTINCT Inventory_Type FROM warehouse_transactions
WHERE Inventory_Type NOT IN ('Inbound','Outbound');

SELECT DISTINCT Dispatch_Status FROM warehouse_transactions
WHERE Dispatch_Status NOT IN ('On Time','Slightly Delayed','Delayed');

SELECT DISTINCT Stock_Audit_Status FROM warehouse_transactions
WHERE Stock_Audit_Status NOT IN ('Passed','Failed');

SELECT DISTINCT Temperature_Controlled FROM warehouse_transactions
WHERE Temperature_Controlled NOT IN ('Yes','No');

-- 2.7 Identify records where quantity dispatched exceeds quantity received
-- (potential stock inconsistency).
SELECT Transaction_ID, Quantity_Received, Quantity_Dispatched
FROM warehouse_transactions
WHERE Quantity_Dispatched > Quantity_Received
ORDER BY (Quantity_Dispatched - Quantity_Received) DESC;

-- 2.8 Identify records where damaged plus missing units exceed quantity received.
SELECT Transaction_ID, Quantity_Received, Damaged_Units, Missing_Units,
       (Damaged_Units + Missing_Units) AS Total_Loss_Units
FROM warehouse_transactions
WHERE (Damaged_Units + Missing_Units) > Quantity_Received
ORDER BY Total_Loss_Units DESC;

-- 2.9 Identify records where customer returns exceed quantity dispatched.
SELECT Transaction_ID, Quantity_Dispatched, Customer_Returns
FROM warehouse_transactions
WHERE Customer_Returns > Quantity_Dispatched
ORDER BY (Customer_Returns - Quantity_Dispatched) DESC;

-- 2.10 Identify records where selling price is below unit cost (loss-making sales).
SELECT Transaction_ID, Unit_Cost_GBP, Selling_Price_GBP,
       (Selling_Price_GBP - Unit_Cost_GBP) AS Unit_Margin
FROM warehouse_transactions
WHERE Selling_Price_GBP < Unit_Cost_GBP
ORDER BY Unit_Margin ASC;

-- 2.11 Identify invalid delivery days (business rule: 1-10 days is the
-- expected operational range for this operation).
SELECT Transaction_ID, Delivery_Days
FROM warehouse_transactions
WHERE Delivery_Days < 1 OR Delivery_Days > 10
ORDER BY Delivery_Days DESC;

-- 2.12 Identify mismatches between Warehouse_Name and City. A fixed
-- warehouse-city mapping is NOT assumed here: this query profiles how many
-- distinct cities are associated with each warehouse so the relationship
-- can be documented rather than assumed.
SELECT
    Warehouse_Name,
    COUNT(DISTINCT City) AS Distinct_Cities_Linked,
    COUNT(*)             AS Transaction_Count
FROM warehouse_transactions
GROUP BY Warehouse_Name
ORDER BY Distinct_Cities_Linked DESC;

-- 2.13 Identify batches associated with multiple products or suppliers
-- (checks whether Batch_Number is a reliable reference).
SELECT
    Batch_Number,
    COUNT(DISTINCT Product_Name)  AS Distinct_Products,
    COUNT(DISTINCT Supplier_Name) AS Distinct_Suppliers,
    COUNT(*)                      AS Transaction_Count
FROM warehouse_transactions
GROUP BY Batch_Number
HAVING COUNT(DISTINCT Product_Name) > 1 OR COUNT(DISTINCT Supplier_Name) > 1
ORDER BY Distinct_Products DESC, Distinct_Suppliers DESC;

-- 2.14 Consolidated data-quality summary using conditional aggregation.
-- This summary should appear in the final report before any performance analysis.
SELECT
    (SELECT COUNT(*) FROM (
        SELECT Transaction_ID FROM warehouse_transactions
        GROUP BY Transaction_ID HAVING COUNT(*) > 1
     ) dup)                                                         AS Duplicate_Transaction_IDs,
    SUM(CASE WHEN Quantity_Received IS NULL OR Quantity_Dispatched IS NULL
              OR Unit_Cost_GBP IS NULL OR Selling_Price_GBP IS NULL
         THEN 1 ELSE 0 END)                                         AS Null_Value_Rows,
    SUM(CASE WHEN Quantity_Received < 0 OR Quantity_Dispatched < 0
              OR Damaged_Units < 0 OR Missing_Units < 0
              OR Delivery_Days < 0 OR Customer_Returns < 0
         THEN 1 ELSE 0 END)                                         AS Negative_Value_Rows,
    SUM(CASE WHEN Quantity_Dispatched > Quantity_Received
              OR (Damaged_Units + Missing_Units) > Quantity_Received
         THEN 1 ELSE 0 END)                                         AS Inconsistent_Quantity_Rows,
    SUM(CASE WHEN Customer_Returns > Quantity_Dispatched
         THEN 1 ELSE 0 END)                                         AS Return_Exception_Rows,
    SUM(CASE WHEN Selling_Price_GBP < Unit_Cost_GBP
         THEN 1 ELSE 0 END)                                         AS Pricing_Exception_Rows,
    (SELECT COUNT(*) FROM warehouse_transactions_raw
        WHERE Transaction_Date_Text IS NOT NULL AND Transaction_Date_Text <> ''
          AND Transaction_Date_Converted IS NULL)                   AS Date_Conversion_Failures
FROM warehouse_transactions;

-- ============================================================================
-- SECTION 4: OVERALL KPI ANALYSIS (Handbook Phase 3, 7.1)
-- ============================================================================

-- 3.1 Calculate the total number of transactions.
SELECT COUNT(*) AS Total_Transactions
FROM warehouse_transactions;

-- 3.2 Calculate total quantity received and total quantity dispatched.
SELECT
    SUM(Quantity_Received)   AS Total_Received,
    SUM(Quantity_Dispatched) AS Total_Dispatched
FROM warehouse_transactions;

-- 3.3 Calculate total damaged units, missing units and customer returns.
SELECT
    SUM(Damaged_Units)    AS Total_Damaged_Units,
    SUM(Missing_Units)    AS Total_Missing_Units,
    SUM(Customer_Returns) AS Total_Customer_Returns
FROM warehouse_transactions;

-- 3.4 Calculate average quantity received and average quantity dispatched
-- per transaction.
SELECT
    ROUND(AVG(Quantity_Received), 2)   AS Avg_Received_Per_Transaction,
    ROUND(AVG(Quantity_Dispatched), 2) AS Avg_Dispatched_Per_Transaction
FROM warehouse_transactions;

-- 3.5 Calculate minimum, maximum and average unit cost and selling price.
SELECT
    MIN(Unit_Cost_GBP)              AS Min_Unit_Cost,
    MAX(Unit_Cost_GBP)              AS Max_Unit_Cost,
    ROUND(AVG(Unit_Cost_GBP), 2)    AS Avg_Unit_Cost,
    MIN(Selling_Price_GBP)          AS Min_Selling_Price,
    MAX(Selling_Price_GBP)          AS Max_Selling_Price,
    ROUND(AVG(Selling_Price_GBP),2) AS Avg_Selling_Price
FROM warehouse_transactions;

-- 3.6 Calculate minimum, maximum and average delivery days.
SELECT
    MIN(Delivery_Days)             AS Min_Delivery_Days,
    MAX(Delivery_Days)             AS Max_Delivery_Days,
    ROUND(AVG(Delivery_Days), 2)   AS Avg_Delivery_Days
FROM warehouse_transactions;

-- 3.7 Calculate total remaining stock units.
SELECT
    SUM(Quantity_Received - Quantity_Dispatched - Damaged_Units - Missing_Units) AS Total_Remaining_Stock
FROM warehouse_transactions;

-- 3.8 Calculate total inventory loss units and overall loss percentage.
SELECT
    SUM(Damaged_Units + Missing_Units) AS Total_Inventory_Loss_Units,
    ROUND(SUM(Damaged_Units + Missing_Units) / NULLIF(SUM(Quantity_Received), 0) * 100, 2) AS Overall_Loss_Percentage
FROM warehouse_transactions;

-- 3.9 Calculate total estimated sales value, dispatched inventory cost,
-- estimated gross profit and inventory loss value.
SELECT
    ROUND(SUM(Quantity_Dispatched * Selling_Price_GBP), 2)                         AS Total_Estimated_Sales_Value_GBP,
    ROUND(SUM(Quantity_Dispatched * Unit_Cost_GBP), 2)                             AS Total_Dispatched_Inventory_Cost_GBP,
    ROUND(SUM(Quantity_Dispatched * (Selling_Price_GBP - Unit_Cost_GBP)), 2)       AS Total_Estimated_Gross_Profit_GBP,
    ROUND(SUM((Damaged_Units + Missing_Units) * Unit_Cost_GBP), 2)                 AS Total_Inventory_Loss_Value_GBP
FROM warehouse_transactions;

-- 3.10 Calculate overall return percentage, audit failure rate and
-- on-time dispatch rate.
SELECT
    ROUND(SUM(Customer_Returns) / NULLIF(SUM(Quantity_Dispatched), 0) * 100, 2) AS Overall_Return_Percentage,
    ROUND(SUM(CASE WHEN Stock_Audit_Status = 'Failed' THEN 1 ELSE 0 END)
          / NULLIF(COUNT(*), 0) * 100, 2)                                       AS Overall_Audit_Failure_Rate,
    ROUND(SUM(CASE WHEN Dispatch_Status = 'On Time' THEN 1 ELSE 0 END)
          / NULLIF(COUNT(*), 0) * 100, 2)                                       AS Overall_On_Time_Dispatch_Rate
FROM warehouse_transactions;

-- ============================================================================
-- SECTION 5: WAREHOUSE ANALYSIS
-- Includes Handbook Phase 4 (Inventory Movement and Stock Position, 8.1)
-- and Phase 5 (Warehouse Performance Analysis, 9.1 - 9.2)
-- ============================================================================

-- ---- Phase 4: Inventory Flow Queries ----

-- 4.1 Compare inbound and outbound transaction counts.
SELECT
    Inventory_Type,
    COUNT(*) AS Transaction_Count,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM warehouse_transactions) * 100, 2) AS Percentage_Of_Total
FROM warehouse_transactions
GROUP BY Inventory_Type
ORDER BY Transaction_Count DESC;

-- 4.2 Calculate quantity received and dispatched by inventory type.
SELECT
    Inventory_Type,
    SUM(Quantity_Received)   AS Total_Received,
    SUM(Quantity_Dispatched) AS Total_Dispatched
FROM warehouse_transactions
GROUP BY Inventory_Type;

-- 4.3 Calculate remaining stock for every transaction (transaction-level).
SELECT
    Transaction_ID,
    Quantity_Received,
    Quantity_Dispatched,
    Damaged_Units,
    Missing_Units,
    (Quantity_Received - Quantity_Dispatched - Damaged_Units - Missing_Units) AS Remaining_Stock_Units
FROM warehouse_transactions
ORDER BY Remaining_Stock_Units DESC
LIMIT 50;

-- 4.4 Classify each transaction as high, medium or low remaining stock.
SELECT
    Transaction_ID,
    (Quantity_Received - Quantity_Dispatched - Damaged_Units - Missing_Units) AS Remaining_Stock_Units,
    CASE
        WHEN (Quantity_Received - Quantity_Dispatched - Damaged_Units - Missing_Units) >= 400 THEN 'High'
        WHEN (Quantity_Received - Quantity_Dispatched - Damaged_Units - Missing_Units) >= 100 THEN 'Medium'
        ELSE 'Low'
    END AS Stock_Level_Classification
FROM warehouse_transactions
ORDER BY Remaining_Stock_Units DESC
LIMIT 50;

-- 4.5 Count transactions with negative, zero and positive remaining stock.
SELECT
    SUM(CASE WHEN Remaining_Stock_Units < 0 THEN 1 ELSE 0 END) AS Negative_Remaining_Stock_Count,
    SUM(CASE WHEN Remaining_Stock_Units = 0 THEN 1 ELSE 0 END) AS Zero_Remaining_Stock_Count,
    SUM(CASE WHEN Remaining_Stock_Units > 0 THEN 1 ELSE 0 END) AS Positive_Remaining_Stock_Count
FROM (
    SELECT (Quantity_Received - Quantity_Dispatched - Damaged_Units - Missing_Units) AS Remaining_Stock_Units
    FROM warehouse_transactions
) stock_calc;

-- 4.6 Identify the top 20 transactions by remaining stock (stock accumulation).
SELECT
    Transaction_ID, Warehouse_Name, Product_Name,
    (Quantity_Received - Quantity_Dispatched - Damaged_Units - Missing_Units) AS Remaining_Stock_Units
FROM warehouse_transactions
ORDER BY Remaining_Stock_Units DESC
LIMIT 20;

-- 4.7 Identify the top 20 transactions by inventory loss units (highest-loss transactions).
SELECT
    Transaction_ID, Warehouse_Name, Product_Name,
    (Damaged_Units + Missing_Units) AS Inventory_Loss_Units
FROM warehouse_transactions
ORDER BY Inventory_Loss_Units DESC
LIMIT 20;

-- 4.8 Compare damage percentage and missing percentage overall.
SELECT
    ROUND(SUM(Damaged_Units) / NULLIF(SUM(Quantity_Received), 0) * 100, 2) AS Overall_Damage_Percentage,
    ROUND(SUM(Missing_Units) / NULLIF(SUM(Quantity_Received), 0) * 100, 2) AS Overall_Missing_Percentage
FROM warehouse_transactions;

-- ---- Phase 5: Warehouse Performance Analysis ----

-- 5.1 Count transactions by warehouse (operational workload).
SELECT
    Warehouse_Name,
    COUNT(*) AS Transaction_Count
FROM warehouse_transactions
GROUP BY Warehouse_Name
ORDER BY Transaction_Count DESC;

-- 5.2 Calculate total quantity received, dispatched and remaining by warehouse.
SELECT
    Warehouse_Name,
    SUM(Quantity_Received)   AS Total_Received,
    SUM(Quantity_Dispatched) AS Total_Dispatched,
    SUM(Quantity_Received - Quantity_Dispatched - Damaged_Units - Missing_Units) AS Total_Remaining_Stock
FROM warehouse_transactions
GROUP BY Warehouse_Name
ORDER BY Total_Received DESC;

-- 5.3 Calculate average transaction size by warehouse.
SELECT
    Warehouse_Name,
    ROUND(AVG(Quantity_Received), 2)   AS Avg_Received_Per_Transaction,
    ROUND(AVG(Quantity_Dispatched), 2) AS Avg_Dispatched_Per_Transaction
FROM warehouse_transactions
GROUP BY Warehouse_Name
ORDER BY Avg_Dispatched_Per_Transaction DESC;

-- 5.4 Rank warehouses by total quantity dispatched (dispatch-volume ranking).
SELECT
    Warehouse_Name,
    SUM(Quantity_Dispatched) AS Total_Dispatched,
    RANK() OVER (ORDER BY SUM(Quantity_Dispatched) DESC) AS Dispatch_Volume_Rank
FROM warehouse_transactions
GROUP BY Warehouse_Name
ORDER BY Dispatch_Volume_Rank;

-- 5.5 Calculate the received-to-dispatched ratio by warehouse (inventory conversion).
SELECT
    Warehouse_Name,
    SUM(Quantity_Received)   AS Total_Received,
    SUM(Quantity_Dispatched) AS Total_Dispatched,
    ROUND(SUM(Quantity_Dispatched) / NULLIF(SUM(Quantity_Received), 0), 3) AS Inventory_Conversion_Ratio
FROM warehouse_transactions
GROUP BY Warehouse_Name
ORDER BY Inventory_Conversion_Ratio DESC;

-- 5.6 Calculate damaged units, missing units, total loss units and loss
-- percentage by warehouse.
SELECT
    Warehouse_Name,
    SUM(Damaged_Units)                 AS Total_Damaged_Units,
    SUM(Missing_Units)                 AS Total_Missing_Units,
    SUM(Damaged_Units + Missing_Units) AS Total_Loss_Units,
    ROUND(SUM(Damaged_Units + Missing_Units) / NULLIF(SUM(Quantity_Received), 0) * 100, 2) AS Loss_Percentage
FROM warehouse_transactions
GROUP BY Warehouse_Name
ORDER BY Loss_Percentage DESC;

-- 5.7 Calculate inventory loss value by warehouse (financial impact ranking).
SELECT
    Warehouse_Name,
    ROUND(SUM((Damaged_Units + Missing_Units) * Unit_Cost_GBP), 2) AS Inventory_Loss_Value_GBP
FROM warehouse_transactions
GROUP BY Warehouse_Name
ORDER BY Inventory_Loss_Value_GBP DESC;

-- 5.8 Calculate customer returns and return percentage by warehouse.
SELECT
    Warehouse_Name,
    SUM(Customer_Returns)   AS Total_Customer_Returns,
    ROUND(SUM(Customer_Returns) / NULLIF(SUM(Quantity_Dispatched), 0) * 100, 2) AS Return_Percentage
FROM warehouse_transactions
GROUP BY Warehouse_Name
ORDER BY Return_Percentage DESC;

-- 5.9 Calculate on-time, slightly delayed and delayed transaction counts by warehouse.
SELECT
    Warehouse_Name,
    SUM(CASE WHEN Dispatch_Status = 'On Time' THEN 1 ELSE 0 END)          AS On_Time_Count,
    SUM(CASE WHEN Dispatch_Status = 'Slightly Delayed' THEN 1 ELSE 0 END) AS Slightly_Delayed_Count,
    SUM(CASE WHEN Dispatch_Status = 'Delayed' THEN 1 ELSE 0 END)          AS Delayed_Count
FROM warehouse_transactions
GROUP BY Warehouse_Name
ORDER BY Warehouse_Name;

-- 5.10 Calculate average delivery days and on-time dispatch rate by warehouse.
SELECT
    Warehouse_Name,
    ROUND(AVG(Delivery_Days), 2) AS Avg_Delivery_Days,
    ROUND(SUM(CASE WHEN Dispatch_Status = 'On Time' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2) AS On_Time_Dispatch_Rate
FROM warehouse_transactions
GROUP BY Warehouse_Name
ORDER BY On_Time_Dispatch_Rate DESC;

-- 5.11 Calculate audit failure count and failure rate by warehouse.
SELECT
    Warehouse_Name,
    SUM(CASE WHEN Stock_Audit_Status = 'Failed' THEN 1 ELSE 0 END) AS Audit_Failure_Count,
    ROUND(SUM(CASE WHEN Stock_Audit_Status = 'Failed' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2) AS Audit_Failure_Rate
FROM warehouse_transactions
GROUP BY Warehouse_Name
ORDER BY Audit_Failure_Rate DESC;

-- 5.12 Create a warehouse performance score using selected rates and
-- CASE-based scoring rules (lower loss/failure/delay and higher on-time = better).
SELECT
    Warehouse_Name,
    Loss_Percentage,
    Audit_Failure_Rate,
    On_Time_Dispatch_Rate,
    (CASE WHEN Loss_Percentage <= 5 THEN 2 WHEN Loss_Percentage <= 8 THEN 1 ELSE 0 END
     + CASE WHEN Audit_Failure_Rate <= 25 THEN 2 WHEN Audit_Failure_Rate <= 35 THEN 1 ELSE 0 END
     + CASE WHEN On_Time_Dispatch_Rate >= 40 THEN 2 WHEN On_Time_Dispatch_Rate >= 30 THEN 1 ELSE 0 END) AS Performance_Score,
    CASE
        WHEN (CASE WHEN Loss_Percentage <= 5 THEN 2 WHEN Loss_Percentage <= 8 THEN 1 ELSE 0 END
             + CASE WHEN Audit_Failure_Rate <= 25 THEN 2 WHEN Audit_Failure_Rate <= 35 THEN 1 ELSE 0 END
             + CASE WHEN On_Time_Dispatch_Rate >= 40 THEN 2 WHEN On_Time_Dispatch_Rate >= 30 THEN 1 ELSE 0 END) >= 5 THEN 'High Performance'
        WHEN (CASE WHEN Loss_Percentage <= 5 THEN 2 WHEN Loss_Percentage <= 8 THEN 1 ELSE 0 END
             + CASE WHEN Audit_Failure_Rate <= 25 THEN 2 WHEN Audit_Failure_Rate <= 35 THEN 1 ELSE 0 END
             + CASE WHEN On_Time_Dispatch_Rate >= 40 THEN 2 WHEN On_Time_Dispatch_Rate >= 30 THEN 1 ELSE 0 END) >= 3 THEN 'Moderate Performance'
        ELSE 'Low Performance'
    END AS Performance_Category
FROM (
    SELECT
        Warehouse_Name,
        ROUND(SUM(Damaged_Units + Missing_Units) / NULLIF(SUM(Quantity_Received), 0) * 100, 2) AS Loss_Percentage,
        ROUND(SUM(CASE WHEN Stock_Audit_Status = 'Failed' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2) AS Audit_Failure_Rate,
        ROUND(SUM(CASE WHEN Dispatch_Status = 'On Time' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2) AS On_Time_Dispatch_Rate
    FROM warehouse_transactions
    GROUP BY Warehouse_Name
) wh_rates
ORDER BY Performance_Score DESC;

-- 5.13 Identify warehouses with above-average loss percentage AND
-- above-average delivery days (combined inventory and delivery risk).
SELECT
    wh.Warehouse_Name,
    wh.Loss_Percentage,
    wh.Avg_Delivery_Days
FROM (
    SELECT
        Warehouse_Name,
        ROUND(SUM(Damaged_Units + Missing_Units) / NULLIF(SUM(Quantity_Received), 0) * 100, 2) AS Loss_Percentage,
        ROUND(AVG(Delivery_Days), 2) AS Avg_Delivery_Days
    FROM warehouse_transactions
    GROUP BY Warehouse_Name
) wh
WHERE wh.Loss_Percentage > (SELECT ROUND(SUM(Damaged_Units + Missing_Units) / NULLIF(SUM(Quantity_Received), 0) * 100, 2) FROM warehouse_transactions)
  AND wh.Avg_Delivery_Days > (SELECT ROUND(AVG(Delivery_Days), 2) FROM warehouse_transactions)
ORDER BY wh.Loss_Percentage DESC;

-- ============================================================================
-- SECTION 6: PRODUCT AND CATEGORY ANALYSIS (Handbook Phase 6, 10.1 - 10.2)
-- ============================================================================

-- ---- 10.1 Product Category Analysis ----

-- 6.1 Count transactions by product category.
SELECT
    Product_Category,
    COUNT(*) AS Transaction_Count,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM warehouse_transactions) * 100, 2) AS Percentage_Of_Total
FROM warehouse_transactions
GROUP BY Product_Category
ORDER BY Transaction_Count DESC;

-- 6.2 Calculate received, dispatched and remaining stock by category.
SELECT
    Product_Category,
    SUM(Quantity_Received)   AS Total_Received,
    SUM(Quantity_Dispatched) AS Total_Dispatched,
    SUM(Quantity_Received - Quantity_Dispatched - Damaged_Units - Missing_Units) AS Total_Remaining_Stock
FROM warehouse_transactions
GROUP BY Product_Category
ORDER BY Total_Received DESC;

-- 6.3 Calculate total loss units, loss percentage and loss value by category.
SELECT
    Product_Category,
    SUM(Damaged_Units + Missing_Units) AS Total_Loss_Units,
    ROUND(SUM(Damaged_Units + Missing_Units) / NULLIF(SUM(Quantity_Received), 0) * 100, 2) AS Loss_Percentage,
    ROUND(SUM((Damaged_Units + Missing_Units) * Unit_Cost_GBP), 2) AS Loss_Value_GBP
FROM warehouse_transactions
GROUP BY Product_Category
ORDER BY Loss_Percentage DESC;

-- 6.4 Calculate customer returns and return percentage by category.
SELECT
    Product_Category,
    SUM(Customer_Returns) AS Total_Customer_Returns,
    ROUND(SUM(Customer_Returns) / NULLIF(SUM(Quantity_Dispatched), 0) * 100, 2) AS Return_Percentage
FROM warehouse_transactions
GROUP BY Product_Category
ORDER BY Return_Percentage DESC;

-- 6.5 Calculate estimated sales value and gross profit by category.
SELECT
    Product_Category,
    ROUND(SUM(Quantity_Dispatched * Selling_Price_GBP), 2)                   AS Estimated_Sales_Value_GBP,
    ROUND(SUM(Quantity_Dispatched * (Selling_Price_GBP - Unit_Cost_GBP)), 2) AS Estimated_Gross_Profit_GBP
FROM warehouse_transactions
GROUP BY Product_Category
ORDER BY Estimated_Gross_Profit_GBP DESC;

-- 6.6 Calculate average delivery days and on-time dispatch rate by category.
SELECT
    Product_Category,
    ROUND(AVG(Delivery_Days), 2) AS Avg_Delivery_Days,
    ROUND(SUM(CASE WHEN Dispatch_Status = 'On Time' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2) AS On_Time_Dispatch_Rate
FROM warehouse_transactions
GROUP BY Product_Category
ORDER BY On_Time_Dispatch_Rate DESC;

-- 6.7 Compare temperature-controlled and non-temperature-controlled
-- performance within each category.
SELECT
    Product_Category,
    Temperature_Controlled,
    COUNT(*)                                                             AS Transaction_Count,
    ROUND(SUM(Damaged_Units + Missing_Units) / NULLIF(SUM(Quantity_Received), 0) * 100, 2) AS Loss_Percentage,
    ROUND(SUM(CASE WHEN Stock_Audit_Status = 'Failed' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2) AS Audit_Failure_Rate,
    ROUND(AVG(Delivery_Days), 2)                                         AS Avg_Delivery_Days
FROM warehouse_transactions
GROUP BY Product_Category, Temperature_Controlled
ORDER BY Product_Category, Temperature_Controlled;

-- ---- 10.2 Product-Level Analysis ----

-- 6.8 Identify the top 15 products by dispatched units.
SELECT
    Product_Name,
    Product_Category,
    SUM(Quantity_Dispatched) AS Total_Dispatched
FROM warehouse_transactions
GROUP BY Product_Name, Product_Category
ORDER BY Total_Dispatched DESC
LIMIT 15;

-- 6.9 Identify the top 15 products by estimated sales value.
SELECT
    Product_Name,
    Product_Category,
    ROUND(SUM(Quantity_Dispatched * Selling_Price_GBP), 2) AS Estimated_Sales_Value_GBP
FROM warehouse_transactions
GROUP BY Product_Name, Product_Category
ORDER BY Estimated_Sales_Value_GBP DESC
LIMIT 15;

-- 6.10 Identify the top 15 products by estimated gross profit.
SELECT
    Product_Name,
    Product_Category,
    ROUND(SUM(Quantity_Dispatched * (Selling_Price_GBP - Unit_Cost_GBP)), 2) AS Estimated_Gross_Profit_GBP
FROM warehouse_transactions
GROUP BY Product_Name, Product_Category
ORDER BY Estimated_Gross_Profit_GBP DESC
LIMIT 15;

-- 6.11 Identify products with the highest loss percentage (minimum 50 units
-- received across the dataset, to avoid unstable percentages from tiny samples).
SELECT
    Product_Name,
    Product_Category,
    SUM(Quantity_Received)             AS Total_Received,
    SUM(Damaged_Units + Missing_Units) AS Total_Loss_Units,
    ROUND(SUM(Damaged_Units + Missing_Units) / NULLIF(SUM(Quantity_Received), 0) * 100, 2) AS Loss_Percentage
FROM warehouse_transactions
GROUP BY Product_Name, Product_Category
HAVING SUM(Quantity_Received) >= 500
ORDER BY Loss_Percentage DESC
LIMIT 15;

-- 6.12 Identify products with the highest return percentage
-- (minimum dispatched volume to avoid unstable percentages).
SELECT
    Product_Name,
    Product_Category,
    SUM(Quantity_Dispatched) AS Total_Dispatched,
    SUM(Customer_Returns)    AS Total_Customer_Returns,
    ROUND(SUM(Customer_Returns) / NULLIF(SUM(Quantity_Dispatched), 0) * 100, 2) AS Return_Percentage
FROM warehouse_transactions
GROUP BY Product_Name, Product_Category
HAVING SUM(Quantity_Dispatched) >= 200
ORDER BY Return_Percentage DESC
LIMIT 15;

-- 6.13 Compare product performance against the average of its own category
-- (over- or under-performance benchmark).
SELECT
    p.Product_Name,
    p.Product_Category,
    p.Product_Loss_Percentage,
    c.Category_Avg_Loss_Percentage,
    ROUND(p.Product_Loss_Percentage - c.Category_Avg_Loss_Percentage, 2) AS Variance_From_Category_Avg,
    CASE WHEN p.Product_Loss_Percentage > c.Category_Avg_Loss_Percentage THEN 'Underperforms Category'
         ELSE 'Outperforms or Matches Category' END AS Benchmark_Result
FROM (
    SELECT Product_Name, Product_Category,
           ROUND(SUM(Damaged_Units + Missing_Units) / NULLIF(SUM(Quantity_Received), 0) * 100, 2) AS Product_Loss_Percentage
    FROM warehouse_transactions
    GROUP BY Product_Name, Product_Category
) p
JOIN (
    SELECT Product_Category,
           ROUND(SUM(Damaged_Units + Missing_Units) / NULLIF(SUM(Quantity_Received), 0) * 100, 2) AS Category_Avg_Loss_Percentage
    FROM warehouse_transactions
    GROUP BY Product_Category
) c ON p.Product_Category = c.Product_Category
ORDER BY Variance_From_Category_Avg DESC;

-- 6.14 Classify products as high-value/high-risk, high-value/low-risk,
-- low-value/high-risk or low-value/low-risk (portfolio view).
SELECT
    Product_Name,
    Product_Category,
    Estimated_Gross_Profit_GBP,
    Loss_Percentage,
    CASE
        WHEN Estimated_Gross_Profit_GBP >= (SELECT AVG(gp) FROM (
                SELECT SUM(Quantity_Dispatched * (Selling_Price_GBP - Unit_Cost_GBP)) AS gp
                FROM warehouse_transactions GROUP BY Product_Name) t)
             AND Loss_Percentage >= (SELECT AVG(Damaged_Units + Missing_Units) / NULLIF(AVG(Quantity_Received),0) * 100 FROM warehouse_transactions)
        THEN 'High-Value / High-Risk'
        WHEN Estimated_Gross_Profit_GBP >= (SELECT AVG(gp) FROM (
                SELECT SUM(Quantity_Dispatched * (Selling_Price_GBP - Unit_Cost_GBP)) AS gp
                FROM warehouse_transactions GROUP BY Product_Name) t)
        THEN 'High-Value / Low-Risk'
        WHEN Loss_Percentage >= (SELECT AVG(Damaged_Units + Missing_Units) / NULLIF(AVG(Quantity_Received),0) * 100 FROM warehouse_transactions)
        THEN 'Low-Value / High-Risk'
        ELSE 'Low-Value / Low-Risk'
    END AS Risk_Value_Classification
FROM (
    SELECT
        Product_Name,
        Product_Category,
        ROUND(SUM(Quantity_Dispatched * (Selling_Price_GBP - Unit_Cost_GBP)), 2) AS Estimated_Gross_Profit_GBP,
        ROUND(SUM(Damaged_Units + Missing_Units) / NULLIF(SUM(Quantity_Received), 0) * 100, 2) AS Loss_Percentage
    FROM warehouse_transactions
    GROUP BY Product_Name, Product_Category
) prod_summary
ORDER BY Estimated_Gross_Profit_GBP DESC;

-- ============================================================================
-- SECTION 7: SUPPLIER ANALYSIS (Handbook Phase 7, 11.1)
-- ============================================================================

-- 7.1 Count transactions and calculate quantity received by supplier.
SELECT
    Supplier_Name,
    COUNT(*)                AS Transaction_Count,
    SUM(Quantity_Received)  AS Total_Quantity_Received
FROM warehouse_transactions
GROUP BY Supplier_Name
ORDER BY Total_Quantity_Received DESC;

-- 7.2 Calculate damaged units, missing units, total loss units and loss
-- percentage by supplier.
SELECT
    Supplier_Name,
    SUM(Damaged_Units)                 AS Total_Damaged_Units,
    SUM(Missing_Units)                 AS Total_Missing_Units,
    SUM(Damaged_Units + Missing_Units) AS Total_Loss_Units,
    ROUND(SUM(Damaged_Units + Missing_Units) / NULLIF(SUM(Quantity_Received), 0) * 100, 2) AS Loss_Percentage
FROM warehouse_transactions
GROUP BY Supplier_Name
ORDER BY Loss_Percentage DESC;

-- 7.3 Calculate inventory loss value by supplier.
SELECT
    Supplier_Name,
    ROUND(SUM((Damaged_Units + Missing_Units) * Unit_Cost_GBP), 2) AS Inventory_Loss_Value_GBP
FROM warehouse_transactions
GROUP BY Supplier_Name
ORDER BY Inventory_Loss_Value_GBP DESC;

-- 7.4 Calculate audit failure count and failure rate by supplier.
SELECT
    Supplier_Name,
    SUM(CASE WHEN Stock_Audit_Status = 'Failed' THEN 1 ELSE 0 END) AS Audit_Failure_Count,
    ROUND(SUM(CASE WHEN Stock_Audit_Status = 'Failed' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2) AS Audit_Failure_Rate
FROM warehouse_transactions
GROUP BY Supplier_Name
ORDER BY Audit_Failure_Rate DESC;

-- 7.5 Calculate returns and return percentage by supplier.
SELECT
    Supplier_Name,
    SUM(Customer_Returns) AS Total_Customer_Returns,
    ROUND(SUM(Customer_Returns) / NULLIF(SUM(Quantity_Dispatched), 0) * 100, 2) AS Return_Percentage
FROM warehouse_transactions
GROUP BY Supplier_Name
ORDER BY Return_Percentage DESC;

-- 7.6 Calculate estimated gross profit by supplier.
SELECT
    Supplier_Name,
    ROUND(SUM(Quantity_Dispatched * (Selling_Price_GBP - Unit_Cost_GBP)), 2) AS Estimated_Gross_Profit_GBP
FROM warehouse_transactions
GROUP BY Supplier_Name
ORDER BY Estimated_Gross_Profit_GBP DESC;

-- 7.7 Identify suppliers with above-average supply volume AND
-- above-average loss percentage (strategically important + elevated risk).
SELECT
    s.Supplier_Name,
    s.Total_Received,
    s.Loss_Percentage
FROM (
    SELECT
        Supplier_Name,
        SUM(Quantity_Received) AS Total_Received,
        ROUND(SUM(Damaged_Units + Missing_Units) / NULLIF(SUM(Quantity_Received), 0) * 100, 2) AS Loss_Percentage
    FROM warehouse_transactions
    GROUP BY Supplier_Name
) s
WHERE s.Total_Received > (SELECT AVG(Total_Received) FROM (
        SELECT SUM(Quantity_Received) AS Total_Received FROM warehouse_transactions GROUP BY Supplier_Name) t)
  AND s.Loss_Percentage > (SELECT ROUND(SUM(Damaged_Units + Missing_Units) / NULLIF(SUM(Quantity_Received), 0) * 100, 2) FROM warehouse_transactions)
ORDER BY s.Loss_Percentage DESC;

-- 7.8 Rank suppliers within each product category by loss percentage.
SELECT
    Product_Category,
    Supplier_Name,
    Loss_Percentage,
    RANK() OVER (PARTITION BY Product_Category ORDER BY Loss_Percentage DESC) AS Loss_Rank_Within_Category
FROM (
    SELECT
        Product_Category,
        Supplier_Name,
        ROUND(SUM(Damaged_Units + Missing_Units) / NULLIF(SUM(Quantity_Received), 0) * 100, 2) AS Loss_Percentage
    FROM warehouse_transactions
    GROUP BY Product_Category, Supplier_Name
) cat_supplier
ORDER BY Product_Category, Loss_Rank_Within_Category;

-- 7.9 Classify suppliers into preferred, monitor and high-risk groups
-- using CASE, based on loss percentage and audit failure rate.
SELECT
    Supplier_Name,
    Loss_Percentage,
    Audit_Failure_Rate,
    Return_Percentage,
    CASE
        WHEN Loss_Percentage <= 5 AND Audit_Failure_Rate <= 25 THEN 'Preferred'
        WHEN Loss_Percentage <= 8 AND Audit_Failure_Rate <= 35 THEN 'Monitor'
        ELSE 'High-Risk'
    END AS Supplier_Classification
FROM (
    SELECT
        Supplier_Name,
        ROUND(SUM(Damaged_Units + Missing_Units) / NULLIF(SUM(Quantity_Received), 0) * 100, 2) AS Loss_Percentage,
        ROUND(SUM(CASE WHEN Stock_Audit_Status = 'Failed' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2) AS Audit_Failure_Rate,
        ROUND(SUM(Customer_Returns) / NULLIF(SUM(Quantity_Dispatched), 0) * 100, 2) AS Return_Percentage
    FROM warehouse_transactions
    GROUP BY Supplier_Name
) supp_rates
ORDER BY Loss_Percentage DESC;

-- ============================================================================
-- SECTION 8: DISPATCH AND DELIVERY ANALYSIS (Handbook Phase 8, 12.1)
-- ============================================================================

-- 8.1 Count and calculate the percentage of transactions in each dispatch status.
SELECT
    Dispatch_Status,
    COUNT(*) AS Transaction_Count,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM warehouse_transactions) * 100, 2) AS Percentage_Of_Total
FROM warehouse_transactions
GROUP BY Dispatch_Status
ORDER BY Transaction_Count DESC;

-- 8.2 Calculate average delivery days for each dispatch status.
SELECT
    Dispatch_Status,
    ROUND(AVG(Delivery_Days), 2) AS Avg_Delivery_Days
FROM warehouse_transactions
GROUP BY Dispatch_Status
ORDER BY Avg_Delivery_Days;

-- 8.3 Find the minimum and maximum delivery days within each dispatch status.
SELECT
    Dispatch_Status,
    MIN(Delivery_Days) AS Min_Delivery_Days,
    MAX(Delivery_Days) AS Max_Delivery_Days
FROM warehouse_transactions
GROUP BY Dispatch_Status
ORDER BY Dispatch_Status;

-- 8.4 Classify delivery days into custom speed bands using CASE.
SELECT
    Transaction_ID,
    Delivery_Days,
    CASE
        WHEN Delivery_Days <= 2 THEN 'Fast'
        WHEN Delivery_Days <= 5 THEN 'Standard'
        WHEN Delivery_Days <= 8 THEN 'Slow'
        ELSE 'Critical'
    END AS Delivery_Speed_Band
FROM warehouse_transactions
ORDER BY Delivery_Days DESC
LIMIT 50;

-- 8.5 Compare dispatch status by warehouse, product category and supplier
-- (segmented dispatch-performance tables).
SELECT
    Warehouse_Name,
    SUM(CASE WHEN Dispatch_Status = 'On Time' THEN 1 ELSE 0 END)          AS On_Time,
    SUM(CASE WHEN Dispatch_Status = 'Slightly Delayed' THEN 1 ELSE 0 END) AS Slightly_Delayed,
    SUM(CASE WHEN Dispatch_Status = 'Delayed' THEN 1 ELSE 0 END)          AS Delayed_Count
FROM warehouse_transactions
GROUP BY Warehouse_Name
ORDER BY Warehouse_Name;

SELECT
    Product_Category,
    SUM(CASE WHEN Dispatch_Status = 'On Time' THEN 1 ELSE 0 END)          AS On_Time,
    SUM(CASE WHEN Dispatch_Status = 'Slightly Delayed' THEN 1 ELSE 0 END) AS Slightly_Delayed,
    SUM(CASE WHEN Dispatch_Status = 'Delayed' THEN 1 ELSE 0 END)          AS Delayed_Count
FROM warehouse_transactions
GROUP BY Product_Category
ORDER BY Product_Category;

SELECT
    Supplier_Name,
    SUM(CASE WHEN Dispatch_Status = 'On Time' THEN 1 ELSE 0 END)          AS On_Time,
    SUM(CASE WHEN Dispatch_Status = 'Slightly Delayed' THEN 1 ELSE 0 END) AS Slightly_Delayed,
    SUM(CASE WHEN Dispatch_Status = 'Delayed' THEN 1 ELSE 0 END)          AS Delayed_Count
FROM warehouse_transactions
GROUP BY Supplier_Name
ORDER BY Supplier_Name;

-- 8.6 Calculate return percentage by dispatch status.
SELECT
    Dispatch_Status,
    SUM(Customer_Returns)    AS Total_Customer_Returns,
    SUM(Quantity_Dispatched) AS Total_Dispatched,
    ROUND(SUM(Customer_Returns) / NULLIF(SUM(Quantity_Dispatched), 0) * 100, 2) AS Return_Percentage
FROM warehouse_transactions
GROUP BY Dispatch_Status
ORDER BY Return_Percentage DESC;

-- 8.7 Calculate estimated sales value and gross profit by dispatch status.
SELECT
    Dispatch_Status,
    ROUND(SUM(Quantity_Dispatched * Selling_Price_GBP), 2)                   AS Estimated_Sales_Value_GBP,
    ROUND(SUM(Quantity_Dispatched * (Selling_Price_GBP - Unit_Cost_GBP)), 2) AS Estimated_Gross_Profit_GBP
FROM warehouse_transactions
GROUP BY Dispatch_Status
ORDER BY Estimated_Sales_Value_GBP DESC;

-- 8.8 Identify the top 20 transactions with the longest delivery times.
SELECT
    Transaction_ID, Warehouse_Name, Product_Name, Dispatch_Status, Delivery_Days
FROM warehouse_transactions
ORDER BY Delivery_Days DESC
LIMIT 20;

-- 8.9 Identify warehouses or categories where delayed transactions exceed
-- the overall delayed percentage.
SELECT
    Warehouse_Name,
    ROUND(SUM(CASE WHEN Dispatch_Status = 'Delayed' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2) AS Delayed_Percentage
FROM warehouse_transactions
GROUP BY Warehouse_Name
HAVING ROUND(SUM(CASE WHEN Dispatch_Status = 'Delayed' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2)
       > (SELECT ROUND(SUM(CASE WHEN Dispatch_Status = 'Delayed' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2) FROM warehouse_transactions)
ORDER BY Delayed_Percentage DESC;

SELECT
    Product_Category,
    ROUND(SUM(CASE WHEN Dispatch_Status = 'Delayed' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2) AS Delayed_Percentage
FROM warehouse_transactions
GROUP BY Product_Category
HAVING ROUND(SUM(CASE WHEN Dispatch_Status = 'Delayed' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2)
       > (SELECT ROUND(SUM(CASE WHEN Dispatch_Status = 'Delayed' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2) FROM warehouse_transactions)
ORDER BY Delayed_Percentage DESC;

-- ============================================================================
-- SECTION 9: EMPLOYEE AND STORAGE-SECTION ANALYSIS (Handbook Phase 9, 13.1)
-- ============================================================================
-- Note (Interpretation Caution per handbook 13.1): this analysis shows
-- association, not direct causation. Differences may reflect transaction
-- mix, warehouse conditions, supplier quality or workload rather than
-- individual employee performance alone.

-- 9.1 Count transactions handled by each employee.
SELECT
    Employee_Handling,
    COUNT(*) AS Transaction_Count
FROM warehouse_transactions
GROUP BY Employee_Handling
ORDER BY Transaction_Count DESC;

-- 9.2 Calculate received and dispatched units handled by each employee.
SELECT
    Employee_Handling,
    SUM(Quantity_Received)   AS Total_Received,
    SUM(Quantity_Dispatched) AS Total_Dispatched
FROM warehouse_transactions
GROUP BY Employee_Handling
ORDER BY Total_Received DESC;

-- 9.3 Calculate loss units, loss percentage and loss value by employee.
SELECT
    Employee_Handling,
    SUM(Damaged_Units + Missing_Units) AS Total_Loss_Units,
    ROUND(SUM(Damaged_Units + Missing_Units) / NULLIF(SUM(Quantity_Received), 0) * 100, 2) AS Loss_Percentage,
    ROUND(SUM((Damaged_Units + Missing_Units) * Unit_Cost_GBP), 2)         AS Loss_Value_GBP
FROM warehouse_transactions
GROUP BY Employee_Handling
ORDER BY Loss_Percentage DESC;

-- 9.4 Calculate average delivery days and dispatch-status distribution by employee.
SELECT
    Employee_Handling,
    ROUND(AVG(Delivery_Days), 2) AS Avg_Delivery_Days,
    SUM(CASE WHEN Dispatch_Status = 'On Time' THEN 1 ELSE 0 END)          AS On_Time_Count,
    SUM(CASE WHEN Dispatch_Status = 'Slightly Delayed' THEN 1 ELSE 0 END) AS Slightly_Delayed_Count,
    SUM(CASE WHEN Dispatch_Status = 'Delayed' THEN 1 ELSE 0 END)          AS Delayed_Count
FROM warehouse_transactions
GROUP BY Employee_Handling
ORDER BY Avg_Delivery_Days;

-- 9.5 Calculate audit failure rate by employee.
SELECT
    Employee_Handling,
    SUM(CASE WHEN Stock_Audit_Status = 'Failed' THEN 1 ELSE 0 END) AS Audit_Failure_Count,
    ROUND(SUM(CASE WHEN Stock_Audit_Status = 'Failed' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2) AS Audit_Failure_Rate
FROM warehouse_transactions
GROUP BY Employee_Handling
ORDER BY Audit_Failure_Rate DESC;

-- 9.6 Calculate return percentage by employee.
SELECT
    Employee_Handling,
    SUM(Customer_Returns) AS Total_Customer_Returns,
    ROUND(SUM(Customer_Returns) / NULLIF(SUM(Quantity_Dispatched), 0) * 100, 2) AS Return_Percentage
FROM warehouse_transactions
GROUP BY Employee_Handling
ORDER BY Return_Percentage DESC;

-- 9.7 Compare each employee with the overall average loss and return rates
-- (benchmark classification, not raw totals).
SELECT
    Employee_Handling,
    Loss_Percentage,
    Return_Percentage,
    CASE WHEN Loss_Percentage > (SELECT ROUND(SUM(Damaged_Units + Missing_Units) / NULLIF(SUM(Quantity_Received), 0) * 100, 2) FROM warehouse_transactions)
         THEN 'Above-Average Loss' ELSE 'At or Below-Average Loss' END AS Loss_Benchmark,
    CASE WHEN Return_Percentage > (SELECT ROUND(SUM(Customer_Returns) / NULLIF(SUM(Quantity_Dispatched), 0) * 100, 2) FROM warehouse_transactions)
         THEN 'Above-Average Returns' ELSE 'At or Below-Average Returns' END AS Return_Benchmark
FROM (
    SELECT
        Employee_Handling,
        ROUND(SUM(Damaged_Units + Missing_Units) / NULLIF(SUM(Quantity_Received), 0) * 100, 2) AS Loss_Percentage,
        ROUND(SUM(Customer_Returns) / NULLIF(SUM(Quantity_Dispatched), 0) * 100, 2) AS Return_Percentage
    FROM warehouse_transactions
    GROUP BY Employee_Handling
) emp_rates
ORDER BY Loss_Percentage DESC;

-- 9.8 Rank employees within each warehouse by handled volume, loss rate
-- and on-time rate (controls for warehouse-environment differences).
SELECT
    Warehouse_Name,
    Employee_Handling,
    Total_Handled_Volume,
    RANK() OVER (PARTITION BY Warehouse_Name ORDER BY Total_Handled_Volume DESC) AS Volume_Rank_Within_Warehouse,
    Loss_Percentage,
    RANK() OVER (PARTITION BY Warehouse_Name ORDER BY Loss_Percentage ASC) AS Loss_Rank_Within_Warehouse,
    On_Time_Rate,
    RANK() OVER (PARTITION BY Warehouse_Name ORDER BY On_Time_Rate DESC) AS OnTime_Rank_Within_Warehouse
FROM (
    SELECT
        Warehouse_Name,
        Employee_Handling,
        SUM(Quantity_Received + Quantity_Dispatched) AS Total_Handled_Volume,
        ROUND(SUM(Damaged_Units + Missing_Units) / NULLIF(SUM(Quantity_Received), 0) * 100, 2) AS Loss_Percentage,
        ROUND(SUM(CASE WHEN Dispatch_Status = 'On Time' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2) AS On_Time_Rate
    FROM warehouse_transactions
    GROUP BY Warehouse_Name, Employee_Handling
) wh_emp
ORDER BY Warehouse_Name, Volume_Rank_Within_Warehouse;

-- ---- Storage Section Analysis (Handbook 14.1) ----

-- 10.1 Calculate transaction volume, received quantity and remaining stock
-- by storage section.
SELECT
    Storage_Section,
    COUNT(*)                AS Transaction_Count,
    SUM(Quantity_Received)  AS Total_Received,
    SUM(Quantity_Received - Quantity_Dispatched - Damaged_Units - Missing_Units) AS Total_Remaining_Stock
FROM warehouse_transactions
GROUP BY Storage_Section
ORDER BY Storage_Section;

-- 10.2 Calculate loss units, loss percentage and loss value by storage section.
SELECT
    Storage_Section,
    SUM(Damaged_Units + Missing_Units) AS Total_Loss_Units,
    ROUND(SUM(Damaged_Units + Missing_Units) / NULLIF(SUM(Quantity_Received), 0) * 100, 2) AS Loss_Percentage,
    ROUND(SUM((Damaged_Units + Missing_Units) * Unit_Cost_GBP), 2)         AS Loss_Value_GBP
FROM warehouse_transactions
GROUP BY Storage_Section
ORDER BY Loss_Percentage DESC;

-- 10.3 Calculate audit failure rate by storage section.
SELECT
    Storage_Section,
    SUM(CASE WHEN Stock_Audit_Status = 'Failed' THEN 1 ELSE 0 END) AS Audit_Failure_Count,
    ROUND(SUM(CASE WHEN Stock_Audit_Status = 'Failed' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2) AS Audit_Failure_Rate
FROM warehouse_transactions
GROUP BY Storage_Section
ORDER BY Audit_Failure_Rate DESC;

-- 10.4 Calculate return percentage by storage section.
SELECT
    Storage_Section,
    SUM(Customer_Returns) AS Total_Customer_Returns,
    ROUND(SUM(Customer_Returns) / NULLIF(SUM(Quantity_Dispatched), 0) * 100, 2) AS Return_Percentage
FROM warehouse_transactions
GROUP BY Storage_Section
ORDER BY Return_Percentage DESC;

-- ============================================================================
-- SECTION 10: AUDIT, TEMPERATURE CONTROL AND RETURNS (Handbook Phase 10)
-- ============================================================================

-- ---- 14.2 Temperature-Control Analysis ----

-- 10.5 Compare transaction volume for temperature-controlled and
-- non-controlled inventory.
SELECT
    Temperature_Controlled,
    COUNT(*)                AS Transaction_Count,
    SUM(Quantity_Received)  AS Total_Received_Units
FROM warehouse_transactions
GROUP BY Temperature_Controlled;

-- 10.6 Compare loss percentage, audit failure rate and return percentage
-- by temperature-control status.
SELECT
    Temperature_Controlled,
    ROUND(SUM(Damaged_Units + Missing_Units) / NULLIF(SUM(Quantity_Received), 0) * 100, 2) AS Loss_Percentage,
    ROUND(SUM(CASE WHEN Stock_Audit_Status = 'Failed' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2) AS Audit_Failure_Rate,
    ROUND(SUM(Customer_Returns) / NULLIF(SUM(Quantity_Dispatched), 0) * 100, 2) AS Return_Percentage
FROM warehouse_transactions
GROUP BY Temperature_Controlled;

-- 10.7 Compare average delivery days and delayed percentage by
-- temperature-control status.
SELECT
    Temperature_Controlled,
    ROUND(AVG(Delivery_Days), 2) AS Avg_Delivery_Days,
    ROUND(SUM(CASE WHEN Dispatch_Status = 'Delayed' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2) AS Delayed_Percentage
FROM warehouse_transactions
GROUP BY Temperature_Controlled;

-- 10.8 Analyse temperature-control performance separately by product
-- category (avoids mixing categories with different storage requirements).
SELECT
    Product_Category,
    Temperature_Controlled,
    COUNT(*)                                                                       AS Transaction_Count,
    ROUND(SUM(Damaged_Units + Missing_Units) / NULLIF(SUM(Quantity_Received), 0) * 100, 2) AS Loss_Percentage,
    ROUND(AVG(Delivery_Days), 2)                                                   AS Avg_Delivery_Days
FROM warehouse_transactions
GROUP BY Product_Category, Temperature_Controlled
ORDER BY Product_Category, Temperature_Controlled;

-- ---- 14.3 Stock Audit Analysis ----

-- 10.9 Count passed and failed audits and calculate the failure rate.
SELECT
    Stock_Audit_Status,
    COUNT(*) AS Transaction_Count,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM warehouse_transactions) * 100, 2) AS Percentage_Of_Total
FROM warehouse_transactions
GROUP BY Stock_Audit_Status;

-- 10.10 Compare loss percentage between passed and failed audits.
SELECT
    Stock_Audit_Status,
    ROUND(SUM(Damaged_Units + Missing_Units) / NULLIF(SUM(Quantity_Received), 0) * 100, 2) AS Loss_Percentage
FROM warehouse_transactions
GROUP BY Stock_Audit_Status;

-- 10.11 Compare missing percentage and damage percentage between audit outcomes.
SELECT
    Stock_Audit_Status,
    ROUND(SUM(Missing_Units) / NULLIF(SUM(Quantity_Received), 0) * 100, 2) AS Missing_Percentage,
    ROUND(SUM(Damaged_Units) / NULLIF(SUM(Quantity_Received), 0) * 100, 2) AS Damage_Percentage
FROM warehouse_transactions
GROUP BY Stock_Audit_Status;

-- 10.12 Compare return percentage and delivery days by audit outcome.
SELECT
    Stock_Audit_Status,
    ROUND(SUM(Customer_Returns) / NULLIF(SUM(Quantity_Dispatched), 0) * 100, 2) AS Return_Percentage,
    ROUND(AVG(Delivery_Days), 2)                                               AS Avg_Delivery_Days
FROM warehouse_transactions
GROUP BY Stock_Audit_Status;

-- 10.13 Identify high-value transactions with failed audits
-- (prioritises audit exceptions by financial exposure).
SELECT
    Transaction_ID, Warehouse_Name, Product_Name, Supplier_Name,
    ROUND(Quantity_Dispatched * Selling_Price_GBP, 2) AS Estimated_Sales_Value_GBP,
    Stock_Audit_Status
FROM warehouse_transactions
WHERE Stock_Audit_Status = 'Failed'
ORDER BY Estimated_Sales_Value_GBP DESC
LIMIT 20;

-- ---- 14.4 Customer Return Analysis ----

-- 10.14 Calculate total returns and overall return percentage.
SELECT
    SUM(Customer_Returns) AS Total_Customer_Returns,
    ROUND(SUM(Customer_Returns) / NULLIF(SUM(Quantity_Dispatched), 0) * 100, 2) AS Overall_Return_Percentage
FROM warehouse_transactions;

-- 10.15 Compare return percentage by warehouse, category, product,
-- supplier and employee (segmented return-rate rankings).
SELECT Warehouse_Name,
       ROUND(SUM(Customer_Returns) / NULLIF(SUM(Quantity_Dispatched), 0) * 100, 2) AS Return_Percentage
FROM warehouse_transactions GROUP BY Warehouse_Name ORDER BY Return_Percentage DESC;

SELECT Product_Category,
       ROUND(SUM(Customer_Returns) / NULLIF(SUM(Quantity_Dispatched), 0) * 100, 2) AS Return_Percentage
FROM warehouse_transactions GROUP BY Product_Category ORDER BY Return_Percentage DESC;

SELECT Product_Name,
       ROUND(SUM(Customer_Returns) / NULLIF(SUM(Quantity_Dispatched), 0) * 100, 2) AS Return_Percentage
FROM warehouse_transactions GROUP BY Product_Name
HAVING SUM(Quantity_Dispatched) >= 200
ORDER BY Return_Percentage DESC LIMIT 15;

SELECT Supplier_Name,
       ROUND(SUM(Customer_Returns) / NULLIF(SUM(Quantity_Dispatched), 0) * 100, 2) AS Return_Percentage
FROM warehouse_transactions GROUP BY Supplier_Name ORDER BY Return_Percentage DESC;

SELECT Employee_Handling,
       ROUND(SUM(Customer_Returns) / NULLIF(SUM(Quantity_Dispatched), 0) * 100, 2) AS Return_Percentage
FROM warehouse_transactions GROUP BY Employee_Handling ORDER BY Return_Percentage DESC;

-- 10.16 Identify the top 20 transactions with the highest return percentage.
SELECT
    Transaction_ID, Warehouse_Name, Product_Name,
    Quantity_Dispatched, Customer_Returns,
    ROUND(Customer_Returns / NULLIF(Quantity_Dispatched, 0) * 100, 2) AS Return_Percentage
FROM warehouse_transactions
WHERE Quantity_Dispatched > 0
ORDER BY Return_Percentage DESC
LIMIT 20;

-- 10.17 Classify return risk using CASE (low, moderate, high).
SELECT
    Transaction_ID,
    ROUND(Customer_Returns / NULLIF(Quantity_Dispatched, 0) * 100, 2) AS Return_Percentage,
    CASE
        WHEN Customer_Returns / NULLIF(Quantity_Dispatched, 0) * 100 >= 15 THEN 'High'
        WHEN Customer_Returns / NULLIF(Quantity_Dispatched, 0) * 100 >= 5  THEN 'Moderate'
        ELSE 'Low'
    END AS Return_Risk_Category
FROM warehouse_transactions
WHERE Quantity_Dispatched > 0
ORDER BY Return_Percentage DESC
LIMIT 50;

-- 10.18 Compare returns with dispatch status, audit status and
-- temperature-control status (tests whether returns align with delivery
-- or control issues).
SELECT
    Dispatch_Status,
    Stock_Audit_Status,
    Temperature_Controlled,
    ROUND(SUM(Customer_Returns) / NULLIF(SUM(Quantity_Dispatched), 0) * 100, 2) AS Return_Percentage
FROM warehouse_transactions
GROUP BY Dispatch_Status, Stock_Audit_Status, Temperature_Controlled
ORDER BY Return_Percentage DESC;

-- ============================================================================
-- SECTION 11: FINANCIAL ANALYSIS (Handbook Phase 11, 15.1)
-- ============================================================================
-- Financial measures are estimates derived from transaction quantities,
-- unit cost and selling price. They represent gross operational values and
-- are NOT labelled as net profit, audited revenue or realised loss, since
-- transport, labour, storage, tax and other operating expenses are not
-- included in this dataset.

-- 11.1 Calculate estimated sales value, dispatched inventory cost and
-- estimated gross profit for every transaction (transaction-level financial base).
SELECT
    Transaction_ID,
    ROUND(Quantity_Dispatched * Selling_Price_GBP, 2)                   AS Estimated_Sales_Value_GBP,
    ROUND(Quantity_Dispatched * Unit_Cost_GBP, 2)                       AS Dispatched_Inventory_Cost_GBP,
    ROUND(Quantity_Dispatched * (Selling_Price_GBP - Unit_Cost_GBP), 2) AS Estimated_Gross_Profit_GBP
FROM warehouse_transactions
ORDER BY Estimated_Gross_Profit_GBP DESC
LIMIT 50;

-- 11.2 Calculate total estimated sales value, cost and gross profit (overall financial KPIs).
SELECT
    ROUND(SUM(Quantity_Dispatched * Selling_Price_GBP), 2)                   AS Total_Estimated_Sales_Value_GBP,
    ROUND(SUM(Quantity_Dispatched * Unit_Cost_GBP), 2)                       AS Total_Dispatched_Inventory_Cost_GBP,
    ROUND(SUM(Quantity_Dispatched * (Selling_Price_GBP - Unit_Cost_GBP)), 2) AS Total_Estimated_Gross_Profit_GBP
FROM warehouse_transactions;

-- 11.3 Calculate unit margin and margin percentage for each product.
SELECT
    Product_Name,
    ROUND(AVG(Selling_Price_GBP - Unit_Cost_GBP), 2)                              AS Avg_Unit_Margin_GBP,
    ROUND(AVG((Selling_Price_GBP - Unit_Cost_GBP) / NULLIF(Selling_Price_GBP,0)) * 100, 2) AS Avg_Margin_Percentage
FROM warehouse_transactions
GROUP BY Product_Name
ORDER BY Avg_Margin_Percentage DESC;

-- 11.4 Calculate revenue and gross profit by warehouse, category, product
-- and supplier (segmented revenue and profit rankings).
SELECT Warehouse_Name,
       ROUND(SUM(Quantity_Dispatched * Selling_Price_GBP), 2) AS Estimated_Sales_Value_GBP,
       ROUND(SUM(Quantity_Dispatched * (Selling_Price_GBP - Unit_Cost_GBP)), 2) AS Estimated_Gross_Profit_GBP
FROM warehouse_transactions GROUP BY Warehouse_Name ORDER BY Estimated_Gross_Profit_GBP DESC;

SELECT Product_Category,
       ROUND(SUM(Quantity_Dispatched * Selling_Price_GBP), 2) AS Estimated_Sales_Value_GBP,
       ROUND(SUM(Quantity_Dispatched * (Selling_Price_GBP - Unit_Cost_GBP)), 2) AS Estimated_Gross_Profit_GBP
FROM warehouse_transactions GROUP BY Product_Category ORDER BY Estimated_Gross_Profit_GBP DESC;

SELECT Product_Name,
       ROUND(SUM(Quantity_Dispatched * Selling_Price_GBP), 2) AS Estimated_Sales_Value_GBP,
       ROUND(SUM(Quantity_Dispatched * (Selling_Price_GBP - Unit_Cost_GBP)), 2) AS Estimated_Gross_Profit_GBP
FROM warehouse_transactions GROUP BY Product_Name ORDER BY Estimated_Gross_Profit_GBP DESC LIMIT 15;

SELECT Supplier_Name,
       ROUND(SUM(Quantity_Dispatched * Selling_Price_GBP), 2) AS Estimated_Sales_Value_GBP,
       ROUND(SUM(Quantity_Dispatched * (Selling_Price_GBP - Unit_Cost_GBP)), 2) AS Estimated_Gross_Profit_GBP
FROM warehouse_transactions GROUP BY Supplier_Name ORDER BY Estimated_Gross_Profit_GBP DESC;

-- 11.5 Calculate inventory loss value by warehouse, category, product,
-- supplier and storage section (segmented loss-value rankings).
SELECT Warehouse_Name,
       ROUND(SUM((Damaged_Units + Missing_Units) * Unit_Cost_GBP), 2) AS Inventory_Loss_Value_GBP
FROM warehouse_transactions GROUP BY Warehouse_Name ORDER BY Inventory_Loss_Value_GBP DESC;

SELECT Product_Category,
       ROUND(SUM((Damaged_Units + Missing_Units) * Unit_Cost_GBP), 2) AS Inventory_Loss_Value_GBP
FROM warehouse_transactions GROUP BY Product_Category ORDER BY Inventory_Loss_Value_GBP DESC;

SELECT Product_Name,
       ROUND(SUM((Damaged_Units + Missing_Units) * Unit_Cost_GBP), 2) AS Inventory_Loss_Value_GBP
FROM warehouse_transactions GROUP BY Product_Name ORDER BY Inventory_Loss_Value_GBP DESC LIMIT 15;

SELECT Supplier_Name,
       ROUND(SUM((Damaged_Units + Missing_Units) * Unit_Cost_GBP), 2) AS Inventory_Loss_Value_GBP
FROM warehouse_transactions GROUP BY Supplier_Name ORDER BY Inventory_Loss_Value_GBP DESC;

SELECT Storage_Section,
       ROUND(SUM((Damaged_Units + Missing_Units) * Unit_Cost_GBP), 2) AS Inventory_Loss_Value_GBP
FROM warehouse_transactions GROUP BY Storage_Section ORDER BY Inventory_Loss_Value_GBP DESC;

-- 11.6 Estimate the selling value associated with customer returns
-- (gross value exposed to returned units).
SELECT
    ROUND(SUM(Customer_Returns * Selling_Price_GBP), 2) AS Estimated_Return_Value_GBP
FROM warehouse_transactions;

SELECT
    Product_Category,
    ROUND(SUM(Customer_Returns * Selling_Price_GBP), 2) AS Estimated_Return_Value_GBP
FROM warehouse_transactions
GROUP BY Product_Category
ORDER BY Estimated_Return_Value_GBP DESC;

-- 11.7 Calculate profit after deducting inventory loss value as an
-- adjusted analytical measure (shows how stock loss reduces gross
-- operational contribution).
SELECT
    ROUND(SUM(Quantity_Dispatched * (Selling_Price_GBP - Unit_Cost_GBP)), 2)  AS Estimated_Gross_Profit_GBP,
    ROUND(SUM((Damaged_Units + Missing_Units) * Unit_Cost_GBP), 2)            AS Inventory_Loss_Value_GBP,
    ROUND(SUM(Quantity_Dispatched * (Selling_Price_GBP - Unit_Cost_GBP))
          - SUM((Damaged_Units + Missing_Units) * Unit_Cost_GBP), 2)          AS Adjusted_Contribution_Estimate_GBP
FROM warehouse_transactions;

SELECT
    Warehouse_Name,
    ROUND(SUM(Quantity_Dispatched * (Selling_Price_GBP - Unit_Cost_GBP)), 2)  AS Estimated_Gross_Profit_GBP,
    ROUND(SUM((Damaged_Units + Missing_Units) * Unit_Cost_GBP), 2)            AS Inventory_Loss_Value_GBP,
    ROUND(SUM(Quantity_Dispatched * (Selling_Price_GBP - Unit_Cost_GBP))
          - SUM((Damaged_Units + Missing_Units) * Unit_Cost_GBP), 2)          AS Adjusted_Contribution_Estimate_GBP
FROM warehouse_transactions
GROUP BY Warehouse_Name
ORDER BY Adjusted_Contribution_Estimate_GBP DESC;

-- 11.8 Identify high-revenue transactions with low margin percentage
-- (volume-driven transactions that may appear strong but produce weak margins).
SELECT
    Transaction_ID, Warehouse_Name, Product_Name,
    ROUND(Quantity_Dispatched * Selling_Price_GBP, 2) AS Estimated_Sales_Value_GBP,
    ROUND((Selling_Price_GBP - Unit_Cost_GBP) / NULLIF(Selling_Price_GBP,0) * 100, 2) AS Margin_Percentage
FROM warehouse_transactions
WHERE Quantity_Dispatched * Selling_Price_GBP >= (
        SELECT AVG(Quantity_Dispatched * Selling_Price_GBP) FROM warehouse_transactions)
  AND (Selling_Price_GBP - Unit_Cost_GBP) / NULLIF(Selling_Price_GBP,0) * 100 < 20
ORDER BY Estimated_Sales_Value_GBP DESC
LIMIT 20;

-- 11.9 Identify segments (categories) with high profit contribution
-- AND high loss value (commercially important areas needing risk reduction).
SELECT
    Product_Category,
    Estimated_Gross_Profit_GBP,
    Inventory_Loss_Value_GBP
FROM (
    SELECT
        Product_Category,
        ROUND(SUM(Quantity_Dispatched * (Selling_Price_GBP - Unit_Cost_GBP)), 2) AS Estimated_Gross_Profit_GBP,
        ROUND(SUM((Damaged_Units + Missing_Units) * Unit_Cost_GBP), 2)           AS Inventory_Loss_Value_GBP
    FROM warehouse_transactions
    GROUP BY Product_Category
) cat_fin
WHERE Estimated_Gross_Profit_GBP > (SELECT AVG(gp) FROM (
        SELECT SUM(Quantity_Dispatched * (Selling_Price_GBP - Unit_Cost_GBP)) AS gp
        FROM warehouse_transactions GROUP BY Product_Category) t)
  AND Inventory_Loss_Value_GBP > (SELECT AVG(lv) FROM (
        SELECT SUM((Damaged_Units + Missing_Units) * Unit_Cost_GBP) AS lv
        FROM warehouse_transactions GROUP BY Product_Category) t2)
ORDER BY Inventory_Loss_Value_GBP DESC;

-- ============================================================================
-- SECTION 12: TIME-SERIES ANALYSIS (Handbook Phase 12, 16.1)
-- ============================================================================
-- Year is always included with month so the same calendar month from
-- different years is never combined incorrectly.

-- 12.1 Extract year, quarter, month number, month name and day from
-- Transaction_Date (reusable date dimensions).
SELECT
    Transaction_ID,
    Transaction_Date,
    YEAR(Transaction_Date)        AS Txn_Year,
    QUARTER(Transaction_Date)     AS Txn_Quarter,
    MONTH(Transaction_Date)       AS Txn_Month_Number,
    MONTHNAME(Transaction_Date)   AS Txn_Month_Name,
    DAYNAME(Transaction_Date)     AS Txn_Day_Name
FROM warehouse_transactions
ORDER BY Transaction_Date
LIMIT 50;

-- 12.2 Count transactions by year and month (chronological monthly trend).
SELECT
    YEAR(Transaction_Date)  AS Txn_Year,
    MONTH(Transaction_Date) AS Txn_Month,
    COUNT(*) AS Transaction_Count
FROM warehouse_transactions
GROUP BY YEAR(Transaction_Date), MONTH(Transaction_Date)
ORDER BY Txn_Year, Txn_Month;

-- 12.3 Calculate received, dispatched and remaining stock by year and month.
SELECT
    YEAR(Transaction_Date)  AS Txn_Year,
    MONTH(Transaction_Date) AS Txn_Month,
    SUM(Quantity_Received)   AS Total_Received,
    SUM(Quantity_Dispatched) AS Total_Dispatched,
    SUM(Quantity_Received - Quantity_Dispatched - Damaged_Units - Missing_Units) AS Total_Remaining_Stock
FROM warehouse_transactions
GROUP BY YEAR(Transaction_Date), MONTH(Transaction_Date)
ORDER BY Txn_Year, Txn_Month;

-- 12.4 Calculate loss units, loss percentage and loss value by year and month.
SELECT
    YEAR(Transaction_Date)  AS Txn_Year,
    MONTH(Transaction_Date) AS Txn_Month,
    SUM(Damaged_Units + Missing_Units) AS Total_Loss_Units,
    ROUND(SUM(Damaged_Units + Missing_Units) / NULLIF(SUM(Quantity_Received), 0) * 100, 2) AS Loss_Percentage,
    ROUND(SUM((Damaged_Units + Missing_Units) * Unit_Cost_GBP), 2)         AS Loss_Value_GBP
FROM warehouse_transactions
GROUP BY YEAR(Transaction_Date), MONTH(Transaction_Date)
ORDER BY Txn_Year, Txn_Month;

-- 12.5 Calculate return percentage by year and month.
SELECT
    YEAR(Transaction_Date)  AS Txn_Year,
    MONTH(Transaction_Date) AS Txn_Month,
    ROUND(SUM(Customer_Returns) / NULLIF(SUM(Quantity_Dispatched), 0) * 100, 2) AS Return_Percentage
FROM warehouse_transactions
GROUP BY YEAR(Transaction_Date), MONTH(Transaction_Date)
ORDER BY Txn_Year, Txn_Month;

-- 12.6 Calculate on-time rate and average delivery days by year and month.
SELECT
    YEAR(Transaction_Date)  AS Txn_Year,
    MONTH(Transaction_Date) AS Txn_Month,
    ROUND(SUM(CASE WHEN Dispatch_Status = 'On Time' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2) AS On_Time_Rate,
    ROUND(AVG(Delivery_Days), 2) AS Avg_Delivery_Days
FROM warehouse_transactions
GROUP BY YEAR(Transaction_Date), MONTH(Transaction_Date)
ORDER BY Txn_Year, Txn_Month;

-- 12.7 Calculate estimated sales value and gross profit by year and month.
SELECT
    YEAR(Transaction_Date)  AS Txn_Year,
    MONTH(Transaction_Date) AS Txn_Month,
    ROUND(SUM(Quantity_Dispatched * Selling_Price_GBP), 2)                   AS Estimated_Sales_Value_GBP,
    ROUND(SUM(Quantity_Dispatched * (Selling_Price_GBP - Unit_Cost_GBP)), 2) AS Estimated_Gross_Profit_GBP
FROM warehouse_transactions
GROUP BY YEAR(Transaction_Date), MONTH(Transaction_Date)
ORDER BY Txn_Year, Txn_Month;

-- 12.8 Compare the same month across different years (year-over-year
-- monthly change) - only January to May exist in both 2025 and 2026.
SELECT
    MONTH(Transaction_Date)     AS Txn_Month,
    MONTHNAME(Transaction_Date) AS Txn_Month_Name,
    SUM(CASE WHEN YEAR(Transaction_Date) = 2025 THEN Quantity_Dispatched ELSE 0 END) AS Dispatched_2025,
    SUM(CASE WHEN YEAR(Transaction_Date) = 2026 THEN Quantity_Dispatched ELSE 0 END) AS Dispatched_2026,
    ROUND(
        (SUM(CASE WHEN YEAR(Transaction_Date) = 2026 THEN Quantity_Dispatched ELSE 0 END)
       - SUM(CASE WHEN YEAR(Transaction_Date) = 2025 THEN Quantity_Dispatched ELSE 0 END))
       / NULLIF(SUM(CASE WHEN YEAR(Transaction_Date) = 2025 THEN Quantity_Dispatched ELSE 0 END), 0) * 100, 2
    ) AS YoY_Percentage_Change
FROM warehouse_transactions
WHERE MONTH(Transaction_Date) BETWEEN 1 AND 5
GROUP BY MONTH(Transaction_Date), MONTHNAME(Transaction_Date)
ORDER BY Txn_Month;

-- 12.9 Calculate month-over-month percentage change for dispatch volume,
-- loss value and gross profit (direction and magnitude of recent change).
SELECT
    Txn_Year, Txn_Month,
    Total_Dispatched,
    LAG(Total_Dispatched) OVER (ORDER BY Txn_Year, Txn_Month) AS Prev_Month_Dispatched,
    ROUND((Total_Dispatched - LAG(Total_Dispatched) OVER (ORDER BY Txn_Year, Txn_Month))
          / NULLIF(LAG(Total_Dispatched) OVER (ORDER BY Txn_Year, Txn_Month), 0) * 100, 2) AS Dispatch_MoM_Pct_Change,
    Loss_Value_GBP,
    ROUND((Loss_Value_GBP - LAG(Loss_Value_GBP) OVER (ORDER BY Txn_Year, Txn_Month))
          / NULLIF(LAG(Loss_Value_GBP) OVER (ORDER BY Txn_Year, Txn_Month), 0) * 100, 2) AS Loss_Value_MoM_Pct_Change,
    Gross_Profit_GBP,
    ROUND((Gross_Profit_GBP - LAG(Gross_Profit_GBP) OVER (ORDER BY Txn_Year, Txn_Month))
          / NULLIF(LAG(Gross_Profit_GBP) OVER (ORDER BY Txn_Year, Txn_Month), 0) * 100, 2) AS Gross_Profit_MoM_Pct_Change
FROM (
    SELECT
        YEAR(Transaction_Date)  AS Txn_Year,
        MONTH(Transaction_Date) AS Txn_Month,
        SUM(Quantity_Dispatched)                                              AS Total_Dispatched,
        ROUND(SUM((Damaged_Units + Missing_Units) * Unit_Cost_GBP), 2)        AS Loss_Value_GBP,
        ROUND(SUM(Quantity_Dispatched * (Selling_Price_GBP - Unit_Cost_GBP)), 2) AS Gross_Profit_GBP
    FROM warehouse_transactions
    GROUP BY YEAR(Transaction_Date), MONTH(Transaction_Date)
) monthly
ORDER BY Txn_Year, Txn_Month;

-- 12.10 Identify the best and worst month for each major KPI
-- (peak and lowest-performing periods).
SELECT 'Highest Dispatch Volume' AS Metric, Txn_Year, Txn_Month, Total_Dispatched AS Value
FROM (SELECT YEAR(Transaction_Date) Txn_Year, MONTH(Transaction_Date) Txn_Month,
             SUM(Quantity_Dispatched) Total_Dispatched
      FROM warehouse_transactions GROUP BY 1,2) m
ORDER BY Value DESC LIMIT 1;

SELECT 'Lowest Dispatch Volume' AS Metric, Txn_Year, Txn_Month, Total_Dispatched AS Value
FROM (SELECT YEAR(Transaction_Date) Txn_Year, MONTH(Transaction_Date) Txn_Month,
             SUM(Quantity_Dispatched) Total_Dispatched
      FROM warehouse_transactions GROUP BY 1,2) m
ORDER BY Value ASC LIMIT 1;

SELECT 'Highest Loss Percentage' AS Metric, Txn_Year, Txn_Month, Loss_Pct AS Value
FROM (SELECT YEAR(Transaction_Date) Txn_Year, MONTH(Transaction_Date) Txn_Month,
             ROUND(SUM(Damaged_Units + Missing_Units) / NULLIF(SUM(Quantity_Received),0) * 100, 2) Loss_Pct
      FROM warehouse_transactions GROUP BY 1,2) m
ORDER BY Value DESC LIMIT 1;

SELECT 'Lowest Loss Percentage' AS Metric, Txn_Year, Txn_Month, Loss_Pct AS Value
FROM (SELECT YEAR(Transaction_Date) Txn_Year, MONTH(Transaction_Date) Txn_Month,
             ROUND(SUM(Damaged_Units + Missing_Units) / NULLIF(SUM(Quantity_Received),0) * 100, 2) Loss_Pct
      FROM warehouse_transactions GROUP BY 1,2) m
ORDER BY Value ASC LIMIT 1;

SELECT 'Highest Gross Profit' AS Metric, Txn_Year, Txn_Month, Gross_Profit AS Value
FROM (SELECT YEAR(Transaction_Date) Txn_Year, MONTH(Transaction_Date) Txn_Month,
             ROUND(SUM(Quantity_Dispatched * (Selling_Price_GBP - Unit_Cost_GBP)), 2) Gross_Profit
      FROM warehouse_transactions GROUP BY 1,2) m
ORDER BY Value DESC LIMIT 1;

SELECT 'Lowest Gross Profit' AS Metric, Txn_Year, Txn_Month, Gross_Profit AS Value
FROM (SELECT YEAR(Transaction_Date) Txn_Year, MONTH(Transaction_Date) Txn_Month,
             ROUND(SUM(Quantity_Dispatched * (Selling_Price_GBP - Unit_Cost_GBP)), 2) Gross_Profit
      FROM warehouse_transactions GROUP BY 1,2) m
ORDER BY Value ASC LIMIT 1;

-- ============================================================================
-- SECTION 13: ADVANCED SQL ANALYSIS (Handbook Phase 13, 17.1 - 17.4)
-- ============================================================================

-- ---- 17.1 HAVING and Conditional Aggregation ----

-- 13.1 Return warehouses with loss percentage above a selected threshold (7%).
SELECT
    Warehouse_Name,
    ROUND(SUM(Damaged_Units + Missing_Units) / NULLIF(SUM(Quantity_Received), 0) * 100, 2) AS Loss_Percentage
FROM warehouse_transactions
GROUP BY Warehouse_Name
HAVING ROUND(SUM(Damaged_Units + Missing_Units) / NULLIF(SUM(Quantity_Received), 0) * 100, 2) > 7
ORDER BY Loss_Percentage DESC;

-- 13.2 Identify products with both sufficient volume (>=500 units received)
-- AND high return or loss rates (material high-risk groups, avoiding
-- unstable percentages from very small samples).
SELECT
    Product_Name,
    SUM(Quantity_Received) AS Total_Received,
    ROUND(SUM(Damaged_Units + Missing_Units) / NULLIF(SUM(Quantity_Received), 0) * 100, 2) AS Loss_Percentage,
    ROUND(SUM(Customer_Returns) / NULLIF(SUM(Quantity_Dispatched), 0) * 100, 2) AS Return_Percentage
FROM warehouse_transactions
GROUP BY Product_Name
HAVING SUM(Quantity_Received) >= 500
   AND (ROUND(SUM(Damaged_Units + Missing_Units) / NULLIF(SUM(Quantity_Received), 0) * 100, 2) > 6.5
        OR ROUND(SUM(Customer_Returns) / NULLIF(SUM(Quantity_Dispatched), 0) * 100, 2) > 8)
ORDER BY Loss_Percentage DESC;

SELECT
    Supplier_Name,
    SUM(Quantity_Received) AS Total_Received,
    ROUND(SUM(Damaged_Units + Missing_Units) / NULLIF(SUM(Quantity_Received), 0) * 100, 2) AS Loss_Percentage,
    ROUND(SUM(Customer_Returns) / NULLIF(SUM(Quantity_Dispatched), 0) * 100, 2) AS Return_Percentage
FROM warehouse_transactions
GROUP BY Supplier_Name
HAVING SUM(Quantity_Received) >= 500
   AND (ROUND(SUM(Damaged_Units + Missing_Units) / NULLIF(SUM(Quantity_Received), 0) * 100, 2) > 6.5
        OR ROUND(SUM(Customer_Returns) / NULLIF(SUM(Quantity_Dispatched), 0) * 100, 2) > 8)
ORDER BY Loss_Percentage DESC;

-- 13.3 Conditional-aggregation query displaying dispatch statuses as
-- separate columns for each warehouse (compact matrix for reporting).
SELECT
    Warehouse_Name,
    SUM(CASE WHEN Dispatch_Status = 'On Time' THEN 1 ELSE 0 END)          AS On_Time,
    SUM(CASE WHEN Dispatch_Status = 'Slightly Delayed' THEN 1 ELSE 0 END) AS Slightly_Delayed,
    SUM(CASE WHEN Dispatch_Status = 'Delayed' THEN 1 ELSE 0 END)          AS Delayed_Count,
    COUNT(*) AS Total_Transactions
FROM warehouse_transactions
GROUP BY Warehouse_Name
ORDER BY Warehouse_Name;

-- 13.4 Conditional-aggregation query summarising passed/failed audits by
-- category and by warehouse (audit-status matrix).
SELECT
    Product_Category,
    SUM(CASE WHEN Stock_Audit_Status = 'Passed' THEN 1 ELSE 0 END) AS Passed,
    SUM(CASE WHEN Stock_Audit_Status = 'Failed' THEN 1 ELSE 0 END) AS Failed
FROM warehouse_transactions
GROUP BY Product_Category
ORDER BY Product_Category;

SELECT
    Warehouse_Name,
    SUM(CASE WHEN Stock_Audit_Status = 'Passed' THEN 1 ELSE 0 END) AS Passed,
    SUM(CASE WHEN Stock_Audit_Status = 'Failed' THEN 1 ELSE 0 END) AS Failed
FROM warehouse_transactions
GROUP BY Warehouse_Name
ORDER BY Warehouse_Name;

-- ---- 17.2 Subqueries and CTEs ----

-- 13.5 Subquery to identify transactions with loss percentage above the
-- overall average (above-average loss transactions).
SELECT
    Transaction_ID, Warehouse_Name, Product_Name,
    ROUND((Damaged_Units + Missing_Units) / NULLIF(Quantity_Received, 0) * 100, 2) AS Transaction_Loss_Percentage
FROM warehouse_transactions
WHERE (Damaged_Units + Missing_Units) / NULLIF(Quantity_Received, 0) * 100 >
      (SELECT SUM(Damaged_Units + Missing_Units) / NULLIF(SUM(Quantity_Received), 0) * 100 FROM warehouse_transactions)
ORDER BY Transaction_Loss_Percentage DESC
LIMIT 30;

-- 13.6 Subquery to identify warehouses with average delivery days above
-- the overall warehouse average (below-standard delivery locations).
SELECT
    Warehouse_Name,
    ROUND(AVG(Delivery_Days), 2) AS Avg_Delivery_Days
FROM warehouse_transactions
GROUP BY Warehouse_Name
HAVING AVG(Delivery_Days) > (SELECT AVG(Delivery_Days) FROM warehouse_transactions)
ORDER BY Avg_Delivery_Days DESC;

-- 13.7 CTE that calculates transaction-level inventory and financial
-- metrics, followed by a grouped analysis (separates calculation logic
-- from final aggregation).
WITH Transaction_Metrics AS (
    SELECT
        Transaction_ID,
        Warehouse_Name,
        Product_Category,
        (Quantity_Received - Quantity_Dispatched - Damaged_Units - Missing_Units) AS Remaining_Stock_Units,
        (Damaged_Units + Missing_Units)                                          AS Inventory_Loss_Units,
        ROUND((Damaged_Units + Missing_Units) * Unit_Cost_GBP, 2)                AS Inventory_Loss_Value_GBP,
        ROUND(Quantity_Dispatched * Selling_Price_GBP, 2)                        AS Estimated_Sales_Value_GBP,
        ROUND(Quantity_Dispatched * (Selling_Price_GBP - Unit_Cost_GBP), 2)      AS Estimated_Gross_Profit_GBP
    FROM warehouse_transactions
)
SELECT
    Warehouse_Name,
    SUM(Remaining_Stock_Units)       AS Total_Remaining_Stock,
    SUM(Inventory_Loss_Units)        AS Total_Inventory_Loss_Units,
    ROUND(SUM(Inventory_Loss_Value_GBP), 2)  AS Total_Inventory_Loss_Value_GBP,
    ROUND(SUM(Estimated_Sales_Value_GBP), 2) AS Total_Estimated_Sales_Value_GBP,
    ROUND(SUM(Estimated_Gross_Profit_GBP), 2) AS Total_Estimated_Gross_Profit_GBP
FROM Transaction_Metrics
GROUP BY Warehouse_Name
ORDER BY Total_Estimated_Gross_Profit_GBP DESC;

-- 13.8 Multiple CTEs to calculate warehouse volume, loss, delivery and
-- financial measures before joining them into one complete scorecard.
WITH Volume AS (
    SELECT Warehouse_Name,
           COUNT(*) AS Transaction_Count,
           SUM(Quantity_Received) AS Total_Received,
           SUM(Quantity_Dispatched) AS Total_Dispatched
    FROM warehouse_transactions GROUP BY Warehouse_Name
),
Loss AS (
    SELECT Warehouse_Name,
           SUM(Damaged_Units + Missing_Units) AS Total_Loss_Units,
           ROUND(SUM(Damaged_Units + Missing_Units) / NULLIF(SUM(Quantity_Received),0) * 100, 2) AS Loss_Percentage
    FROM warehouse_transactions GROUP BY Warehouse_Name
),
Delivery AS (
    SELECT Warehouse_Name,
           ROUND(AVG(Delivery_Days), 2) AS Avg_Delivery_Days,
           ROUND(SUM(CASE WHEN Dispatch_Status = 'On Time' THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0) * 100, 2) AS On_Time_Rate
    FROM warehouse_transactions GROUP BY Warehouse_Name
),
Financials AS (
    SELECT Warehouse_Name,
           ROUND(SUM(Quantity_Dispatched * (Selling_Price_GBP - Unit_Cost_GBP)), 2) AS Estimated_Gross_Profit_GBP
    FROM warehouse_transactions GROUP BY Warehouse_Name
)
SELECT
    v.Warehouse_Name,
    v.Transaction_Count, v.Total_Received, v.Total_Dispatched,
    l.Total_Loss_Units, l.Loss_Percentage,
    d.Avg_Delivery_Days, d.On_Time_Rate,
    f.Estimated_Gross_Profit_GBP
FROM Volume v
JOIN Loss l        ON v.Warehouse_Name = l.Warehouse_Name
JOIN Delivery d     ON v.Warehouse_Name = d.Warehouse_Name
JOIN Financials f   ON v.Warehouse_Name = f.Warehouse_Name
ORDER BY f.Estimated_Gross_Profit_GBP DESC;

-- 13.9 CTE to identify high-risk products based on loss, returns, audit
-- failure and delay measures (multi-factor product-risk table).
WITH Product_Risk_Factors AS (
    SELECT
        Product_Name,
        Product_Category,
        ROUND(SUM(Damaged_Units + Missing_Units) / NULLIF(SUM(Quantity_Received),0) * 100, 2) AS Loss_Percentage,
        ROUND(SUM(Customer_Returns) / NULLIF(SUM(Quantity_Dispatched),0) * 100, 2)             AS Return_Percentage,
        ROUND(SUM(CASE WHEN Stock_Audit_Status='Failed' THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0) * 100, 2) AS Audit_Failure_Rate,
        ROUND(SUM(CASE WHEN Dispatch_Status='Delayed' THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0) * 100, 2)   AS Delayed_Percentage
    FROM warehouse_transactions
    GROUP BY Product_Name, Product_Category
)
SELECT
    Product_Name, Product_Category,
    Loss_Percentage, Return_Percentage, Audit_Failure_Rate, Delayed_Percentage,
    (CASE WHEN Loss_Percentage > 7 THEN 1 ELSE 0 END
   + CASE WHEN Return_Percentage > 8 THEN 1 ELSE 0 END
   + CASE WHEN Audit_Failure_Rate > 32 THEN 1 ELSE 0 END
   + CASE WHEN Delayed_Percentage > 33 THEN 1 ELSE 0 END) AS Risk_Factor_Count
FROM Product_Risk_Factors
ORDER BY Risk_Factor_Count DESC, Loss_Percentage DESC
LIMIT 20;

-- ---- 17.3 Window Functions ----

-- 13.10 ROW_NUMBER to assign a unique position to products ordered by
-- gross profit (unique product sequence, even when values are tied).
SELECT
    Product_Name,
    Estimated_Gross_Profit_GBP,
    ROW_NUMBER() OVER (ORDER BY Estimated_Gross_Profit_GBP DESC) AS Product_Sequence
FROM (
    SELECT Product_Name,
           ROUND(SUM(Quantity_Dispatched * (Selling_Price_GBP - Unit_Cost_GBP)), 2) AS Estimated_Gross_Profit_GBP
    FROM warehouse_transactions
    GROUP BY Product_Name
) p;

-- 13.11 RANK and DENSE_RANK to rank warehouses by loss percentage
-- (alternative ranking treatment for ties).
SELECT
    Warehouse_Name,
    Loss_Percentage,
    RANK()       OVER (ORDER BY Loss_Percentage DESC) AS Loss_Rank,
    DENSE_RANK() OVER (ORDER BY Loss_Percentage DESC) AS Loss_Dense_Rank
FROM (
    SELECT Warehouse_Name,
           ROUND(SUM(Damaged_Units + Missing_Units) / NULLIF(SUM(Quantity_Received),0) * 100, 2) AS Loss_Percentage
    FROM warehouse_transactions
    GROUP BY Warehouse_Name
) w
ORDER BY Loss_Rank;

-- 13.12 PARTITION BY to rank products within each category by dispatched
-- quantity (top products inside each category).
SELECT *
FROM (
    SELECT
        Product_Category,
        Product_Name,
        Total_Dispatched,
        RANK() OVER (PARTITION BY Product_Category ORDER BY Total_Dispatched DESC) AS Rank_Within_Category
    FROM (
        SELECT Product_Category, Product_Name,
               SUM(Quantity_Dispatched) AS Total_Dispatched
        FROM warehouse_transactions
        GROUP BY Product_Category, Product_Name
    ) pc
) ranked
WHERE Rank_Within_Category <= 3
ORDER BY Product_Category, Rank_Within_Category;

-- 13.13 NTILE to divide products into performance quartiles
-- (balanced performance bands based on gross profit).
SELECT
    Product_Name,
    Estimated_Gross_Profit_GBP,
    NTILE(4) OVER (ORDER BY Estimated_Gross_Profit_GBP DESC) AS Profit_Quartile
FROM (
    SELECT Product_Name,
           ROUND(SUM(Quantity_Dispatched * (Selling_Price_GBP - Unit_Cost_GBP)), 2) AS Estimated_Gross_Profit_GBP
    FROM warehouse_transactions
    GROUP BY Product_Name
) p
ORDER BY Profit_Quartile, Estimated_Gross_Profit_GBP DESC;

-- 13.14 SUM as a window function to calculate cumulative monthly
-- dispatched quantity (running total without collapsing monthly rows).
SELECT
    Txn_Year, Txn_Month, Monthly_Dispatched,
    SUM(Monthly_Dispatched) OVER (ORDER BY Txn_Year, Txn_Month) AS Running_Total_Dispatched
FROM (
    SELECT YEAR(Transaction_Date) Txn_Year, MONTH(Transaction_Date) Txn_Month,
           SUM(Quantity_Dispatched) AS Monthly_Dispatched
    FROM warehouse_transactions
    GROUP BY YEAR(Transaction_Date), MONTH(Transaction_Date)
) m
ORDER BY Txn_Year, Txn_Month;

-- 13.15 AVG as a window function to compare each warehouse with the
-- average across all warehouses (adds a benchmark beside each result).
SELECT
    Warehouse_Name,
    Total_Dispatched,
    ROUND(AVG(Total_Dispatched) OVER (), 2) AS Overall_Warehouse_Avg_Dispatched,
    ROUND(Total_Dispatched - AVG(Total_Dispatched) OVER (), 2) AS Variance_From_Avg
FROM (
    SELECT Warehouse_Name, SUM(Quantity_Dispatched) AS Total_Dispatched
    FROM warehouse_transactions
    GROUP BY Warehouse_Name
) w
ORDER BY Variance_From_Avg DESC;

-- 13.16 LAG to compare each month with the previous month
-- (previous-month value and difference).
SELECT
    Txn_Year, Txn_Month, Monthly_Gross_Profit_GBP,
    LAG(Monthly_Gross_Profit_GBP) OVER (ORDER BY Txn_Year, Txn_Month) AS Prev_Month_Gross_Profit_GBP,
    ROUND(Monthly_Gross_Profit_GBP - LAG(Monthly_Gross_Profit_GBP) OVER (ORDER BY Txn_Year, Txn_Month), 2) AS Difference_From_Prev_Month
FROM (
    SELECT YEAR(Transaction_Date) Txn_Year, MONTH(Transaction_Date) Txn_Month,
           ROUND(SUM(Quantity_Dispatched * (Selling_Price_GBP - Unit_Cost_GBP)), 2) AS Monthly_Gross_Profit_GBP
    FROM warehouse_transactions
    GROUP BY YEAR(Transaction_Date), MONTH(Transaction_Date)
) m
ORDER BY Txn_Year, Txn_Month;

-- 13.17 LEAD to compare the current month with the following month
-- (next-month value and difference).
SELECT
    Txn_Year, Txn_Month, Monthly_Gross_Profit_GBP,
    LEAD(Monthly_Gross_Profit_GBP) OVER (ORDER BY Txn_Year, Txn_Month) AS Next_Month_Gross_Profit_GBP,
    ROUND(LEAD(Monthly_Gross_Profit_GBP) OVER (ORDER BY Txn_Year, Txn_Month) - Monthly_Gross_Profit_GBP, 2) AS Difference_To_Next_Month
FROM (
    SELECT YEAR(Transaction_Date) Txn_Year, MONTH(Transaction_Date) Txn_Month,
           ROUND(SUM(Quantity_Dispatched * (Selling_Price_GBP - Unit_Cost_GBP)), 2) AS Monthly_Gross_Profit_GBP
    FROM warehouse_transactions
    GROUP BY YEAR(Transaction_Date), MONTH(Transaction_Date)
) m
ORDER BY Txn_Year, Txn_Month;

-- ---- 17.4 Views and Reusable Reporting Layers ----

-- 13.18 View containing transaction-level calculated metrics such as
-- remaining stock, loss units, loss value, sales value and gross profit
-- (reusable transaction analytics view, avoids repeating calculations).
CREATE OR REPLACE VIEW vw_transaction_analytics AS
SELECT
    Transaction_ID,
    Transaction_Date,
    Warehouse_Name,
    City,
    Product_Category,
    Product_Name,
    Supplier_Name,
    Inventory_Type,
    Dispatch_Status,
    Stock_Audit_Status,
    Temperature_Controlled,
    Quantity_Received,
    Quantity_Dispatched,
    Damaged_Units,
    Missing_Units,
    Customer_Returns,
    Delivery_Days,
    (Quantity_Received - Quantity_Dispatched - Damaged_Units - Missing_Units) AS Remaining_Stock_Units,
    (Damaged_Units + Missing_Units)                                          AS Inventory_Loss_Units,
    ROUND((Damaged_Units + Missing_Units) / NULLIF(Quantity_Received,0) * 100, 2) AS Inventory_Loss_Percentage,
    ROUND(Customer_Returns / NULLIF(Quantity_Dispatched,0) * 100, 2)          AS Return_Percentage,
    ROUND(Quantity_Dispatched * Selling_Price_GBP, 2)                        AS Estimated_Sales_Value_GBP,
    ROUND(Quantity_Dispatched * Unit_Cost_GBP, 2)                            AS Dispatched_Inventory_Cost_GBP,
    ROUND(Quantity_Dispatched * (Selling_Price_GBP - Unit_Cost_GBP), 2)      AS Estimated_Gross_Profit_GBP,
    ROUND((Damaged_Units + Missing_Units) * Unit_Cost_GBP, 2)                AS Inventory_Loss_Value_GBP
FROM warehouse_transactions;

SELECT * FROM vw_transaction_analytics LIMIT 10;

-- 13.19 Warehouse summary view containing volume, loss, delivery, audit,
-- returns and financial KPIs (stable reporting layer for final analysis).
CREATE OR REPLACE VIEW vw_warehouse_scorecard AS
SELECT
    Warehouse_Name,
    COUNT(*)                                                                      AS Transaction_Count,
    SUM(Quantity_Received)                                                        AS Total_Received,
    SUM(Quantity_Dispatched)                                                      AS Total_Dispatched,
    SUM(Damaged_Units + Missing_Units)                                            AS Total_Loss_Units,
    ROUND(SUM(Damaged_Units + Missing_Units) / NULLIF(SUM(Quantity_Received),0) * 100, 2) AS Loss_Percentage,
    ROUND(AVG(Delivery_Days), 2)                                                  AS Avg_Delivery_Days,
    ROUND(SUM(CASE WHEN Dispatch_Status = 'On Time' THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0) * 100, 2) AS On_Time_Dispatch_Rate,
    ROUND(SUM(CASE WHEN Stock_Audit_Status = 'Failed' THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0) * 100, 2) AS Audit_Failure_Rate,
    SUM(Customer_Returns)                                                         AS Total_Customer_Returns,
    ROUND(SUM(Customer_Returns) / NULLIF(SUM(Quantity_Dispatched),0) * 100, 2)    AS Return_Percentage,
    ROUND(SUM(Quantity_Dispatched * Selling_Price_GBP), 2)                       AS Estimated_Sales_Value_GBP,
    ROUND(SUM(Quantity_Dispatched * (Selling_Price_GBP - Unit_Cost_GBP)), 2)     AS Estimated_Gross_Profit_GBP,
    ROUND(SUM((Damaged_Units + Missing_Units) * Unit_Cost_GBP), 2)               AS Inventory_Loss_Value_GBP
FROM warehouse_transactions
GROUP BY Warehouse_Name;

SELECT * FROM vw_warehouse_scorecard ORDER BY Estimated_Gross_Profit_GBP DESC;

-- 13.20 Product performance view with category, volume, loss, returns,
-- revenue and profit measures (reusable product ranking / portfolio view).
CREATE OR REPLACE VIEW vw_product_performance AS
SELECT
    Product_Name,
    Product_Category,
    COUNT(*)                                                                      AS Transaction_Count,
    SUM(Quantity_Received)                                                        AS Total_Received,
    SUM(Quantity_Dispatched)                                                      AS Total_Dispatched,
    SUM(Damaged_Units + Missing_Units)                                            AS Total_Loss_Units,
    ROUND(SUM(Damaged_Units + Missing_Units) / NULLIF(SUM(Quantity_Received),0) * 100, 2) AS Loss_Percentage,
    SUM(Customer_Returns)                                                         AS Total_Customer_Returns,
    ROUND(SUM(Customer_Returns) / NULLIF(SUM(Quantity_Dispatched),0) * 100, 2)    AS Return_Percentage,
    ROUND(SUM(Quantity_Dispatched * Selling_Price_GBP), 2)                       AS Estimated_Sales_Value_GBP,
    ROUND(SUM(Quantity_Dispatched * (Selling_Price_GBP - Unit_Cost_GBP)), 2)     AS Estimated_Gross_Profit_GBP
FROM warehouse_transactions
GROUP BY Product_Name, Product_Category;

SELECT * FROM vw_product_performance ORDER BY Estimated_Gross_Profit_GBP DESC LIMIT 15;

-- ============================================================================
-- SECTION 14: FINAL REPORTING VIEWS / SUMMARY QUERIES
-- ============================================================================
-- The three views above (vw_transaction_analytics, vw_warehouse_scorecard,
-- vw_product_performance) serve as the final reusable reporting layer.
-- The summary query below draws them together into one master KPI table
-- used directly in the Executive Summary of the analysis report.

SELECT
    (SELECT COUNT(*) FROM warehouse_transactions)                                            AS Total_Transactions,
    (SELECT SUM(Quantity_Received) FROM warehouse_transactions)                               AS Total_Received,
    (SELECT SUM(Quantity_Dispatched) FROM warehouse_transactions)                             AS Total_Dispatched,
    (SELECT ROUND(SUM(Damaged_Units+Missing_Units)/NULLIF(SUM(Quantity_Received),0)*100,2)
        FROM warehouse_transactions)                                                          AS Overall_Loss_Percentage,
    (SELECT ROUND(SUM(Customer_Returns)/NULLIF(SUM(Quantity_Dispatched),0)*100,2)
        FROM warehouse_transactions)                                                          AS Overall_Return_Percentage,
    (SELECT ROUND(SUM(CASE WHEN Stock_Audit_Status='Failed' THEN 1 ELSE 0 END)/NULLIF(COUNT(*),0)*100,2)
        FROM warehouse_transactions)                                                          AS Overall_Audit_Failure_Rate,
    (SELECT ROUND(SUM(CASE WHEN Dispatch_Status='On Time' THEN 1 ELSE 0 END)/NULLIF(COUNT(*),0)*100,2)
        FROM warehouse_transactions)                                                          AS Overall_On_Time_Rate,
    (SELECT ROUND(SUM(Quantity_Dispatched*Selling_Price_GBP),2) FROM warehouse_transactions)  AS Total_Estimated_Sales_Value_GBP,
    (SELECT ROUND(SUM(Quantity_Dispatched*(Selling_Price_GBP-Unit_Cost_GBP)),2)
        FROM warehouse_transactions)                                                          AS Total_Estimated_Gross_Profit_GBP,
    (SELECT ROUND(SUM((Damaged_Units+Missing_Units)*Unit_Cost_GBP),2) FROM warehouse_transactions) AS Total_Inventory_Loss_Value_GBP;

-- ============================================================================
-- END OF SCRIPT
-- ============================================================================
