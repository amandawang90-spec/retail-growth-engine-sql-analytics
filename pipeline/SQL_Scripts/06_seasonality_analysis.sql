
-- PHASE 6: SEASONALITY ANALYSIS

DROP TABLE IF EXISTS new_monthly_revenue_trends;

CREATE TABLE new_monthly_revenue_trends AS
SELECT
    DATE_TRUNC('month', invoice_date)                         AS month,
    TO_CHAR(invoice_date, 'YYYY-MM')                          AS month_label,
    COUNT(DISTINCT invoice)                                   AS total_orders,
    COUNT(DISTINCT customer_id)                               AS active_customers,
    ROUND(SUM(total_price)::NUMERIC, 2)                       AS total_revenue,
    ROUND(AVG(total_price::NUMERIC), 2)                       AS avg_order_value,
    ROUND(
        (SUM(total_price)::NUMERIC
         - LAG(SUM(total_price)::NUMERIC) OVER (ORDER BY DATE_TRUNC('month', invoice_date)))
        / NULLIF(LAG(SUM(total_price)::NUMERIC) OVER (ORDER BY DATE_TRUNC('month', invoice_date)), 0) * 100
    , 2)                                                      AS mom_revenue_growth_pct
FROM cleaned_retail_main
GROUP BY DATE_TRUNC('month', invoice_date), TO_CHAR(invoice_date, 'YYYY-MM')
ORDER BY month ASC;


DROP TABLE IF EXISTS new_monthly_new_customers;

CREATE TABLE new_monthly_new_customers AS
WITH first_purchase AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', MIN(invoice_date)) AS acquisition_month
    FROM cleaned_retail_main
    GROUP BY customer_id
)
SELECT
    TO_CHAR(acquisition_month, 'YYYY-MM')                     AS month_label,
    acquisition_month,
    COUNT(DISTINCT customer_id)                               AS new_customers
FROM first_purchase
GROUP BY acquisition_month
ORDER BY acquisition_month ASC;


DROP TABLE IF EXISTS new_revenue_by_month_of_year;

CREATE TABLE new_revenue_by_month_of_year AS
WITH monthly AS (
    SELECT
        DATE_TRUNC('month', invoice_date)     AS month,
        TO_CHAR(invoice_date, 'MM')           AS month_number,
        TO_CHAR(invoice_date, 'Month')        AS month_name,
        SUM(total_price)                      AS monthly_revenue
    FROM cleaned_retail_main
    GROUP BY 
        DATE_TRUNC('month', invoice_date),
        TO_CHAR(invoice_date, 'MM'),
        TO_CHAR(invoice_date, 'Month')
)
SELECT
    month_number,
    month_name,
    ROUND(AVG(monthly_revenue)::NUMERIC, 2)   AS avg_monthly_revenue,
    ROUND(SUM(monthly_revenue)::NUMERIC, 2)   AS total_revenue
FROM monthly
GROUP BY month_number, month_name
ORDER BY month_number ASC;

