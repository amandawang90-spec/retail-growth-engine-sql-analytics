-- PHASE 9: WIN-BACK ANALYSIS
-- Goal: Identify customers who churned (90+ days inactive) and then returned.
-- How many came back? How long did reactivation take? How much did they spend after returning?

CREATE TABLE winback_analysis AS
WITH customer_purchases AS (
    SELECT
        customer_id,
        invoice,
        invoice_date,
        total_price,
        -- Calculate days since previous purchase for each transaction
        LAG(invoice_date) OVER (
            PARTITION BY customer_id
            ORDER BY invoice_date
        )                                                      AS prev_purchase_date,
        DATE_PART('day', invoice_date - LAG(invoice_date) OVER (
            PARTITION BY customer_id
            ORDER BY invoice_date
        ))::NUMERIC                                            AS days_since_prev_purchase
    FROM cleaned_retail_main
),
churned_then_returned AS (
    -- A win-back event is when a customer returns after 90+ days of inactivity
    SELECT
        customer_id,
        invoice_date                                           AS winback_date,
        prev_purchase_date                                     AS last_purchase_before_gap,
        days_since_prev_purchase                               AS gap_days
    FROM customer_purchases
    WHERE days_since_prev_purchase > 90
),
post_winback_revenue AS (
    -- Calculate how much each customer spent AFTER their win-back date
    SELECT
        w.customer_id,
        w.winback_date,
        w.last_purchase_before_gap,
        w.gap_days,
        COUNT(DISTINCT c.invoice)                              AS orders_after_winback,
        ROUND(SUM(c.total_price)::NUMERIC, 2)                 AS revenue_after_winback
    FROM churned_then_returned w
    JOIN cleaned_retail_main c ON w.customer_id = c.customer_id
        AND c.invoice_date >= w.winback_date
    GROUP BY w.customer_id, w.winback_date, w.last_purchase_before_gap, w.gap_days
)
SELECT
    customer_id,
    last_purchase_before_gap,
    winback_date,
    ROUND(gap_days, 0)                                         AS gap_days,
    orders_after_winback,
    revenue_after_winback
FROM post_winback_revenue
ORDER BY revenue_after_winback DESC;


-- WIN-BACK GLOBAL SUMMARY
CREATE TABLE winback_analysis_summary AS
SELECT
    COUNT(DISTINCT customer_id)                            AS total_winback_customers,
    ROUND(AVG(gap_days)::NUMERIC, 1)                      AS avg_gap_days,
    ROUND(MIN(gap_days)::NUMERIC, 0)                      AS min_gap_days,
    ROUND(MAX(gap_days)::NUMERIC, 0)                      AS max_gap_days,
    ROUND(AVG(revenue_after_winback)::NUMERIC, 2)         AS avg_revenue_after_winback,
    ROUND(SUM(revenue_after_winback)::NUMERIC, 2)         AS total_revenue_after_winback,
    ROUND(AVG(orders_after_winback)::NUMERIC, 2)          AS avg_orders_after_winback
FROM winback_analysis;


-- WIN-BACK BY GAP BUCKET
CREATE TABLE winback_analysis_by_gap_bucket AS
SELECT
    CASE
        WHEN gap_days BETWEEN 91 AND 120   THEN '91-120 days'
        WHEN gap_days BETWEEN 121 AND 180  THEN '121-180 days'
        WHEN gap_days BETWEEN 181 AND 365  THEN '181-365 days'
        ELSE '365+ days'
    END                                                    AS gap_bucket,
    COUNT(DISTINCT customer_id)                            AS customer_count,
    ROUND(AVG(revenue_after_winback)::NUMERIC, 2)         AS avg_revenue_after_winback
FROM winback_analysis
GROUP BY gap_bucket
ORDER BY MIN(gap_days);