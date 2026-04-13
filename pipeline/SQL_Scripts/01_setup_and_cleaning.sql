ALTER TABLE "online_retail_II" RENAME TO online_retail_ii;

ALTER TABLE online_retail_ii 
  RENAME COLUMN "Invoice" TO invoice;

ALTER TABLE online_retail_ii 
  RENAME COLUMN "StockCode" TO stock_code;

ALTER TABLE online_retail_ii 
  RENAME COLUMN "Description" TO description;

ALTER TABLE online_retail_ii 
  RENAME COLUMN "Quantity" TO quantity;

ALTER TABLE online_retail_ii 
  RENAME COLUMN "InvoiceDate" TO invoice_date;

ALTER TABLE online_retail_ii 
  RENAME COLUMN "Price" TO price;

ALTER TABLE online_retail_ii 
  RENAME COLUMN "Customer ID" TO customer_id;

ALTER TABLE online_retail_ii 
  RENAME COLUMN "Country" TO country;


-- Check row count (expect ~1M rows)
SELECT COUNT(*) 
FROM online_retail_ii;

-- Preview the data
SELECT * 
FROM online_retail_ii
LIMIT 10;

-- Check date range (expect 2009-2011)
SELECT 
    MIN(invoice_date), 
    MAX(invoice_date) 
FROM online_retail_ii


-- Refining the "Gold" Dataset
CREATE TABLE cleaned_retail_main AS
SELECT 
    invoice,
    stock_code,
    description,
    quantity,
    invoice_date,
    price,
    customer_id,
    country,
    (quantity * price) AS total_price
FROM 
    online_retail_ii
WHERE 
    customer_id IS NOT NULL 
    AND price > 0 
    -- We exclude returns (C invoices) for the initial RFM 
    -- to avoid negative frequency, but we'll track them later for churn.
    AND invoice NOT LIKE 'C%' 
    AND quantity > 0
    -- Removing non-product codes common in this dataset
    AND stock_code NOT IN ('POST', 'D', 'M', 'DOT', 'CRUK', 'BANK CHARGES', 'ADJUST', 'ADJUST2');
