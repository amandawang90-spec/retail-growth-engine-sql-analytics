-- PHASE 6: SEASONALITY ANALYSIS
-- Goal: Understand revenue and customer acquisition trends over time.

-- 6A: Monthly Revenue & Order Trends
CREATE TABLE monthly_revenue_trends AS
SELECT
    DATE_TRUNC('month', invoice_date)                        AS month,
    TO_CHAR(invoice_date, 'YYYY-MM')                         AS month_label,
    COUNT(DISTINCT invoice)                                  AS total_orders,
    COUNT(DISTINCT customer_id)                              AS active_customers,
    ROUND(SUM(total_price)::NUMERIC, 2)                      AS total_revenue,
    ROUND(AVG(total_price::NUMERIC), 2)                      AS avg_order_value,
    -- Month over month revenue growth
    ROUND(
        (SUM(total_price)::NUMERIC - LAG(SUM(total_price)::NUMERIC) OVER (ORDER BY DATE_TRUNC('month', invoice_date)))
        / NULLIF(LAG(SUM(total_price)::NUMERIC) OVER (ORDER BY DATE_TRUNC('month', invoice_date)), 0) * 100
    , 2)                                                     AS mom_revenue_growth_pct
FROM cleaned_retail_main
GROUP BY DATE_TRUNC('month', invoice_date), TO_CHAR(invoice_date, 'YYYY-MM')
ORDER BY month ASC;


-- 6B: Monthly New Customer Acquisition
CREATE TABLE monthly_new_customers AS
WITH first_purchase AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', MIN(invoice_date)) AS acquisition_month
    FROM cleaned_retail_main
    GROUP BY customer_id
)
SELECT
    TO_CHAR(acquisition_month, 'YYYY-MM') AS month_label,
    COUNT(DISTINCT customer_id)           AS new_customers
FROM first_purchase
GROUP BY acquisition_month
ORDER BY acquisition_month ASC;


-- 6C: Revenue by Month of Year (aggregated across both years)
-- Goal: Identify which months are consistently strong or weak


CREATE TABLE revenue_by_month_of_year AS
WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', invoice_date) AS month,
        EXTRACT(MONTH FROM invoice_date)  AS month_number,
        TO_CHAR(invoice_date, 'Month')    AS month_name,
        SUM(total_price)                  AS monthly_revenue
    FROM cleaned_retail_main
    GROUP BY DATE_TRUNC('month', invoice_date),
             EXTRACT(MONTH FROM invoice_date),
             TO_CHAR(invoice_date, 'Month')
)
SELECT
    month_number,
    TRIM(month_name) AS month_name,
    ROUND(AVG(monthly_revenue)::NUMERIC, 2) AS avg_monthly_revenue,
    ROUND(SUM(monthly_revenue)::NUMERIC, 2) AS total_revenue
FROM monthly_revenue
GROUP BY month_number, month_name
ORDER BY month_number;