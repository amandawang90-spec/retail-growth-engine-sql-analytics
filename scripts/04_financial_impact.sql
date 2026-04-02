-- PART 4A: SEGMENT YIELD & PROFITABILITY
-- Goal: Identify revenue concentration and high-value segments.

CREATE TABLE segment_yield_and_profitability AS 
WITH reference_date AS (
    SELECT MAX(invoice_date) + INTERVAL '1 day' AS ref_day 
    FROM cleaned_retail_main
),
base_rfm AS (
    SELECT
        customer_id,
        MAX(invoice_date)       AS last_purchase_date,
        COUNT(DISTINCT invoice) AS frequency,
        SUM(total_price)        AS monetary
    FROM cleaned_retail_main
    GROUP BY customer_id
),
rfm_scores AS (
    SELECT
        b.customer_id,
        b.frequency,
        b.monetary,
        DATE_PART('day', r.ref_day - b.last_purchase_date) AS recency_days,
        NTILE(5) OVER (ORDER BY DATE_PART('day', r.ref_day - b.last_purchase_date) DESC) AS r_score,
        NTILE(5) OVER (ORDER BY b.frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY b.monetary ASC) AS m_score
    FROM base_rfm b
    CROSS JOIN reference_date r
),
customer_rfm_segmented AS (
    SELECT
        *,
        (r_score::TEXT || f_score::TEXT || m_score::TEXT) AS rfm_combined,
        CASE
           WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
           WHEN r_score >= 3 AND f_score >= 4 AND m_score >= 3 THEN 'Loyal'
           WHEN f_score <= 3 AND m_score >= 4 THEN 'Big spenders'
           WHEN r_score >= 4 AND f_score BETWEEN 2 AND 3 AND m_score >= 3 THEN 'Potential Loyalists'
           WHEN r_score >= 4 AND f_score BETWEEN 1 AND 2 THEN 'Promising'
           WHEN r_score BETWEEN 2 AND 3 AND f_score >= 3 THEN 'About to Sleep'
           WHEN r_score <= 2 AND f_score >= 3 AND m_score >= 3 THEN 'At-risk'
           WHEN r_score = 1 AND f_score BETWEEN 1 AND 2 AND m_score BETWEEN 1 AND 2 THEN 'Hibernating'
           WHEN r_score = 1 AND f_score = 1 AND m_score = 1 THEN 'Lost'
           ELSE 'General/Other'
         END AS customer_segment
    FROM rfm_scores
)
SELECT 
    customer_segment,
    COUNT(customer_id) AS customer_count,
    ROUND(
        (COUNT(customer_id)::NUMERIC * 100 
        / (SELECT COUNT(*) FROM customer_rfm_segmented)),
        2
    ) AS pct_of_customer_base,
    ROUND(
        SUM(monetary)::NUMERIC,
        2
    ) AS segment_revenue,
    ROUND(
        (SUM(monetary)::NUMERIC * 100 
        / (SELECT SUM(monetary)::NUMERIC FROM customer_rfm_segmented)),
        2
    ) AS pct_of_total_revenue
FROM customer_rfm_segmented
GROUP BY customer_segment
ORDER BY pct_of_total_revenue DESC;


-- PART 4B: REVENUE-AT-RISK & SEGMENT ATTRITION
-- Goal: Quantify the financial impact of customer churn.

CREATE TABLE revenue_at_risk_and_segment_attrition AS 
WITH reference_date AS (
    SELECT MAX(invoice_date) + INTERVAL '1 day' AS ref_day 
    FROM cleaned_retail_main
),
base_rfm AS (
    SELECT
        customer_id,
        MAX(invoice_date)       AS last_purchase_date,
        COUNT(DISTINCT invoice) AS frequency,
        SUM(total_price)        AS monetary
    FROM cleaned_retail_main
    GROUP BY customer_id
),
rfm_scores AS (
    SELECT
        b.customer_id,
        b.frequency,
        b.monetary,
        DATE_PART('day', r.ref_day - b.last_purchase_date) AS recency_days,
        NTILE(5) OVER (ORDER BY DATE_PART('day', r.ref_day - b.last_purchase_date) DESC) AS r_score,
        NTILE(5) OVER (ORDER BY b.frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY b.monetary ASC) AS m_score
    FROM base_rfm b
    CROSS JOIN reference_date r
),
customer_rfm_segmented AS (
    SELECT
        *,
        (r_score::TEXT || f_score::TEXT || m_score::TEXT) AS rfm_combined,
        CASE
           WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
           WHEN r_score >= 3 AND f_score >= 4 AND m_score >= 3 THEN 'Loyal'
           WHEN f_score <= 3 AND m_score >= 4 THEN 'Big spenders'
           WHEN r_score >= 4 AND f_score BETWEEN 2 AND 3 AND m_score >= 3 THEN 'Potential Loyalists'
           WHEN r_score >= 4 AND f_score BETWEEN 1 AND 2 THEN 'Promising'
           WHEN r_score BETWEEN 2 AND 3 AND f_score >= 3 THEN 'About to Sleep'
           WHEN r_score <= 2 AND f_score >= 3 AND m_score >= 3 THEN 'At-risk'
           WHEN r_score = 1 AND f_score BETWEEN 1 AND 2 AND m_score BETWEEN 1 AND 2 THEN 'Hibernating'
           WHEN r_score = 1 AND f_score = 1 AND m_score = 1 THEN 'Lost'
           ELSE 'General/Other'
         END AS customer_segment
    FROM rfm_scores
),
churn_base AS (
    -- This is Phase 3 Logic
    SELECT 
        customer_id,
        CASE 
            WHEN DATE_PART('day', (SELECT MAX(invoice_date) FROM cleaned_retail_main) - MAX(invoice_date)) > 90 
            THEN 1 
            ELSE 0 
        END AS is_churned
    FROM cleaned_retail_main
    GROUP BY customer_id
)
-- Final Phase 5 Join: Connecting Segment to Churn and Revenue
SELECT 
    crs.customer_segment,
    COUNT(crs.customer_id) AS total_customers,
    SUM(c.is_churned) AS churned_count,
    ROUND(CAST(SUM(c.is_churned) AS NUMERIC) / COUNT(*) * 100, 2) AS churn_rate_pct,
    -- This tells us exactly how much money left the building
    ROUND(SUM(CASE WHEN c.is_churned = 1 THEN crs.monetary ELSE 0 END)::NUMERIC, 2) AS total_revenue_lost
FROM customer_rfm_segmented crs
JOIN churn_base c ON crs.customer_id = c.customer_id
GROUP BY 1
ORDER BY total_revenue_lost DESC;

