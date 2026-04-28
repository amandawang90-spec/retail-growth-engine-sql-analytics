-- PHASE 4A: SEGMENT YIELD & PROFITABILITY

DROP TABLE IF EXISTS new_segment_yield_and_profitability;

CREATE TABLE new_segment_yield_and_profitability AS
SELECT
    customer_segment,
    COUNT(customer_id)                                                         AS customer_count,
    SUM(frequency)                                                             AS total_orders,
    ROUND(
        COUNT(customer_id)::NUMERIC * 100
        / SUM(COUNT(customer_id)) OVER (),
        2
    )                                                                          AS pct_of_customer_base,
    ROUND(SUM(monetary)::NUMERIC, 2)                                           AS segment_revenue,
    ROUND(
        SUM(monetary)::NUMERIC * 100
        / SUM(SUM(monetary)::NUMERIC) OVER (),
        2
    )                                                                          AS pct_of_total_revenue,
    ROUND(AVG(monetary)::NUMERIC, 2)                                           AS avg_revenue_per_customer,
    ROUND(AVG(frequency)::NUMERIC, 2)                                          AS avg_frequency,
    ROUND(AVG(recency_days)::NUMERIC, 1)                                       AS avg_recency_days,
    ROUND(SUM(monetary)::NUMERIC / NULLIF(SUM(frequency), 0), 2)              AS aov
FROM new_rfm_segment_analysis
GROUP BY customer_segment
ORDER BY pct_of_total_revenue DESC;

