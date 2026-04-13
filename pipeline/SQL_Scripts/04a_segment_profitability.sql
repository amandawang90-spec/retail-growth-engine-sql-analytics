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
        MAX(invoice_date)                        AS last_purchase_date,
        COUNT(DISTINCT invoice)::NUMERIC         AS frequency,
        SUM(total_price)::NUMERIC                AS monetary
    FROM cleaned_retail_main
    GROUP BY customer_id
),
rfm_scores AS (
    SELECT
        b.customer_id,
        b.frequency,
        b.monetary,
        DATE_PART('day', r.ref_day - b.last_purchase_date)::NUMERIC                      AS recency_days,
        NTILE(5) OVER (ORDER BY DATE_PART('day', r.ref_day - b.last_purchase_date) DESC) AS r_score,
        NTILE(5) OVER (ORDER BY b.frequency ASC)                                          AS f_score,
        NTILE(5) OVER (ORDER BY b.monetary ASC)                                           AS m_score
    FROM base_rfm b
    CROSS JOIN reference_date r
),
customer_rfm_segmented AS (
    SELECT
        *,
        (r_score::TEXT || f_score::TEXT || m_score::TEXT) AS rfm_combined,
        CASE
            WHEN r_score = 1 AND f_score = 1 AND m_score = 1                                THEN 'Lost'
            WHEN r_score = 1 AND f_score BETWEEN 1 AND 2 AND m_score BETWEEN 1 AND 2       THEN 'Hibernating'
            WHEN r_score <= 2 AND f_score >= 3 AND m_score >= 3                             THEN 'At-Risk'
            WHEN r_score BETWEEN 2 AND 3 AND f_score >= 3                                   THEN 'Needs Attention'
            WHEN r_score >= 4 AND f_score BETWEEN 1 AND 2                                   THEN 'Promising'
            WHEN r_score >= 4 AND f_score BETWEEN 2 AND 3 AND m_score >= 3                  THEN 'Potential Loyalists'
            WHEN f_score <= 3 AND m_score >= 4                                               THEN 'Big Spenders'
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4                             THEN 'Champions'
            WHEN r_score >= 3 AND f_score >= 4 AND m_score >= 3                             THEN 'Loyal'
            ELSE 'General/Other'
        END AS customer_segment
    FROM rfm_scores
)
SELECT
    customer_segment,
    COUNT(customer_id)                                                        AS customer_count,
    ROUND(
        COUNT(customer_id)::NUMERIC * 100
        / SUM(COUNT(customer_id)) OVER (),
        2
    )                                                                         AS pct_of_customer_base,
    ROUND(SUM(monetary)::NUMERIC, 2)                                          AS segment_revenue,
    ROUND(
        SUM(monetary)::NUMERIC * 100
        / SUM(SUM(monetary)) OVER (),
        2
    )                                                                         AS pct_of_total_revenue,
    ROUND(AVG(frequency::NUMERIC), 2)                                         AS avg_frequency,
    ROUND(AVG(monetary::NUMERIC), 2)                                          AS avg_revenue
FROM customer_rfm_segmented
GROUP BY customer_segment
ORDER BY pct_of_total_revenue DESC;