-- PHASE 7: PRODUCT ANALYSIS
-- Goal: Understand which products drive revenue, which have high return rates.

-- 7A: Top 20 Products by Revenue
CREATE TABLE top_products_by_revenue AS

SELECT
    stock_code,
    description,
    COUNT(DISTINCT invoice)                                   AS total_orders,
    SUM(quantity)                                             AS total_units_sold,
    ROUND(SUM(total_price)::NUMERIC, 2)                       AS total_revenue,
    ROUND(AVG(price::NUMERIC), 2)                             AS avg_unit_price,
    ROUND(SUM(total_price)::NUMERIC * 100
        / SUM(SUM(total_price)::NUMERIC) OVER (), 2)          AS pct_of_total_revenue
FROM cleaned_retail_main
GROUP BY stock_code, description
ORDER BY total_revenue DESC
LIMIT 20;


-- 7B : Product Return Analysis
CREATE TABLE product_return_analysis AS

WITH sales AS (
    SELECT
        stock_code,
        description,
        SUM(quantity)                                         AS total_units_sold,
        COUNT(DISTINCT invoice)                               AS total_sales_orders
    FROM online_retail_ii
    WHERE invoice NOT LIKE 'C%'
        AND quantity > 0
        AND price > 0
        AND customer_id IS NOT NULL
        AND stock_code NOT IN ('POST', 'D', 'M', 'DOT', 'CRUK', 'BANK CHARGES', 'ADJUST', 'ADJUST2')
    GROUP BY stock_code, description
),
returns AS (
    SELECT
        stock_code,
        ABS(SUM(quantity))                                    AS total_units_returned,
        COUNT(DISTINCT invoice)                               AS total_return_orders
    FROM online_retail_ii
    WHERE invoice LIKE 'C%'
        AND quantity < 0
        AND customer_id IS NOT NULL
        AND stock_code NOT IN ('POST', 'D', 'M', 'DOT', 'CRUK', 'BANK CHARGES', 'ADJUST', 'ADJUST2')
    GROUP BY stock_code
)
SELECT
    s.stock_code,
    s.description,
    s.total_units_sold,
    COALESCE(r.total_units_returned, 0)                       AS total_units_returned,
    s.total_sales_orders,
    COALESCE(r.total_return_orders, 0)                        AS total_return_orders,
    LEAST(ROUND(COALESCE(r.total_units_returned, 0)::NUMERIC
    / NULLIF(s.total_units_sold, 0) * 100, 2), 100) AS return_rate_pct
FROM sales s
LEFT JOIN returns r ON s.stock_code = r.stock_code
WHERE s.total_units_sold >= 100
ORDER BY return_rate_pct DESC
LIMIT 30;

--Return rate analysis is approximate due to known data quality issues in the dataset 
--some cancellation invoices reference sales that predate the dataset window, 
--causing return rates to exceed 100% for certain products. These are capped at 100% and should be interpreted with caution.

-- 7C: Revenue by Product Category (using price bands)
-- Goal: Understand the price distribution of the product catalog
CREATE TABLE revenue_by_price_band AS

SELECT
    CASE
        WHEN price < 1       THEN '< £1'
        WHEN price < 5       THEN '£1 - £5'
        WHEN price < 10      THEN '£5 - £10'
        WHEN price < 20      THEN '£10 - £20'
        WHEN price < 50      THEN '£20 - £50'
        ELSE                      '£50+'
    END                                                       AS price_band,
    COUNT(DISTINCT stock_code)                                AS unique_products,
    COUNT(DISTINCT invoice)                                   AS total_orders,
    SUM(quantity)                                             AS total_units_sold,
    ROUND(SUM(total_price)::NUMERIC, 2)                       AS total_revenue,
    ROUND(SUM(total_price)::NUMERIC * 100
        / SUM(SUM(total_price)::NUMERIC) OVER (), 2)          AS pct_of_total_revenue
FROM cleaned_retail_main
GROUP BY price_band
ORDER BY MIN(price) ASC;

--The business operates a high-volume, low-price model. 
--80% of revenue comes from products priced under £5, 
--with the £1-£5 band being the dominant revenue driver across 3,319 SKUs. 
--Premium products (£20+) represent less than 1.2% of revenue despite accounting for 93 SKUs, 
--suggesting limited appetite for higher-priced items in the customer base.