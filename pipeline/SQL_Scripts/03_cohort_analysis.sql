-- PHASE 3A: CHURN FLAG (90-DAY THRESHOLD)

DROP TABLE IF EXISTS new_churned_or_not;

CREATE TABLE new_churned_or_not AS
WITH study_end AS (
    SELECT MAX(invoice_date) + INTERVAL '1 day' AS ref_day
    FROM cleaned_retail_main
)
SELECT
    r.customer_id,
    r.last_purchase_date,
    s.ref_day                                                        AS study_end_date,
    r.recency_days                                                   AS days_since_last_purchase,
    r.customer_segment,
    CASE
        WHEN r.recency_days > 90 THEN 1
        ELSE 0
    END AS is_churned
FROM new_rfm_segment_analysis r
CROSS JOIN study_end s;

-- PHASE 3B: COHORT RETENTION & CHURN (1-12 MONTHS)

DROP TABLE IF EXISTS new_churn_and_retention_rate_by_cohort;

CREATE TABLE new_churn_and_retention_rate_by_cohort AS
WITH first_purchase AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', MIN(invoice_date)) AS cohort_month
    FROM cleaned_retail_main
    GROUP BY customer_id
),
cohort_activity AS (
    SELECT
        f.customer_id,
        f.cohort_month,
        (EXTRACT(year FROM c.invoice_date) - EXTRACT(year FROM f.cohort_month)) * 12 +
        (EXTRACT(month FROM c.invoice_date) - EXTRACT(month FROM f.cohort_month)) AS month_number
    FROM first_purchase f
    JOIN cleaned_retail_main c ON f.customer_id = c.customer_id
    GROUP BY 1, 2, 3
),
retention_counts AS (
    SELECT
        cohort_month,
        month_number,
        COUNT(DISTINCT customer_id) AS active_customers
    FROM cohort_activity
    GROUP BY 1, 2
),
survival_base AS (
    SELECT
        *,
        FIRST_VALUE(active_customers) OVER (PARTITION BY cohort_month ORDER BY month_number) AS cohort_size
    FROM retention_counts
)
SELECT
    TO_CHAR(cohort_month, 'YYYY-MM')                                          AS cohort,
    month_number                                                                AS month_age,
    active_customers,
    cohort_size,
    ROUND(active_customers::NUMERIC / cohort_size * 100, 2)                   AS retention_rate_pct,
    (100 - ROUND(active_customers::NUMERIC / cohort_size * 100, 2))           AS churn_rate_pct
FROM survival_base
WHERE month_number BETWEEN 1 AND 12
ORDER BY cohort_month, month_age;

-- PHASE 3C: RETENTION RATES BY RFM SEGMENTS (1-12 MONTHS)

DROP TABLE IF EXISTS new_retention_rates_by_rfm_segments;

CREATE TABLE new_retention_rates_by_rfm_segments AS
WITH first_purchase AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', MIN(invoice_date)) AS cohort_month
    FROM cleaned_retail_main
    GROUP BY customer_id
),
cohort_size AS (
    SELECT
        r.customer_segment,
        COUNT(DISTINCT f.customer_id) AS total_customers
    FROM first_purchase f
    JOIN new_rfm_segment_analysis r ON f.customer_id = r.customer_id
    GROUP BY r.customer_segment
),
cohort_activity AS (
    SELECT
        f.customer_id,
        r.customer_segment,
        (EXTRACT(year FROM c.invoice_date) - EXTRACT(year FROM f.cohort_month)) * 12 +
        (EXTRACT(month FROM c.invoice_date) - EXTRACT(month FROM f.cohort_month)) AS month_number
    FROM first_purchase f
    JOIN cleaned_retail_main c ON f.customer_id = c.customer_id
    JOIN new_rfm_segment_analysis r ON f.customer_id = r.customer_id
    WHERE (EXTRACT(year FROM c.invoice_date) - EXTRACT(year FROM f.cohort_month)) * 12 +
          (EXTRACT(month FROM c.invoice_date) - EXTRACT(month FROM f.cohort_month)) BETWEEN 1 AND 12
    GROUP BY 1, 2, 3
),
monthly_retained AS (
    SELECT
        customer_segment,
        month_number,
        COUNT(DISTINCT customer_id) AS active_customers
    FROM cohort_activity
    GROUP BY customer_segment, month_number
)
SELECT
    m.customer_segment,
    m.month_number,
    m.active_customers,
    c.total_customers,
    ROUND(m.active_customers::NUMERIC / NULLIF(c.total_customers, 0) * 100, 1) AS retention_rate_pct,
    ROUND(100 - (m.active_customers::NUMERIC / NULLIF(c.total_customers, 0) * 100), 1) AS churn_rate_pct
FROM monthly_retained m
JOIN cohort_size c USING (customer_segment)
ORDER BY
    CASE m.customer_segment
        WHEN 'Champions'            THEN 1
        WHEN 'Loyal'                THEN 2
        WHEN 'Potential Loyalists'  THEN 3
        WHEN 'Recent Customers'     THEN 4
        WHEN 'Promising'            THEN 5
        WHEN 'Need Attention'       THEN 6
        WHEN 'About to Sleep'       THEN 7
        WHEN 'At-Risk'              THEN 8
        WHEN 'Cannot Lose'          THEN 9
        WHEN 'Hibernating'          THEN 10
        WHEN 'Lost'                 THEN 11
        ELSE                        12
    END,
    m.month_number;
