-- Phase 3: Churn & Retention Analysis

-- Defining the "Churn Point": No purchase in the last 90 days of the dataset.

CREATE TABLE churned_or_not AS

WITH study_end AS (
    SELECT MAX(invoice_date) + INTERVAL '1 day' AS ref_day
    FROM cleaned_retail_main
),
churn_base AS (
    SELECT
        c.customer_id,
        MAX(c.invoice_date)                                              AS last_purchase_date,
        s.ref_day                                                        AS study_end_date,
        DATE_PART('day', s.ref_day - MAX(c.invoice_date))                AS days_since_last_purchase,
        CASE
            WHEN DATE_PART('day', s.ref_day - MAX(c.invoice_date)) > 90
            THEN 1
            ELSE 0
        END AS is_churned
    FROM cleaned_retail_main c
    CROSS JOIN study_end s
    GROUP BY c.customer_id, s.ref_day
)
SELECT * FROM churn_base;


-- Monthly Retention & Churn Rate by Cohort (1-12 Months)

CREATE TABLE churn_and_retention_rate_by_cohort AS

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
        (EXTRACT(year  FROM c.invoice_date) - EXTRACT(year  FROM f.cohort_month)) * 12 +
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
    TO_CHAR(cohort_month, 'YYYY-MM')                                           AS cohort,
    month_number                                                               AS month_number,
    active_customers,
    cohort_size,
    ROUND(active_customers::NUMERIC / cohort_size * 100, 2)                  AS retention_rate_pct,
    (100 - ROUND(active_customers::NUMERIC / cohort_size * 100, 2))          AS churn_rate_pct
FROM survival_base
WHERE month_number BETWEEN 1 AND 12
ORDER BY cohort_month, month_number;


--Step 2: Monthly Churn & Retention Rate by RFM Segment (Months 1–12) 

--Define RFM Segments

CREATE TABLE retention_rates_by_rfm_segments AS

WITH reference_date AS (
    SELECT MAX(invoice_date) + INTERVAL '1 day' AS ref_day
    FROM cleaned_retail_main
),
base_rfm AS (
    SELECT
        customer_id,
        MAX(invoice_date)            AS last_purchase_date,
        COUNT(DISTINCT invoice)      AS frequency,
        SUM(total_price)             AS monetary
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
        NTILE(5) OVER (ORDER BY b.frequency ASC)                                          AS f_score,
        NTILE(5) OVER (ORDER BY b.monetary ASC)                                           AS m_score
    FROM base_rfm b
    CROSS JOIN reference_date r
),
rfm_final AS (
    SELECT
        *,
        CASE
            WHEN r_score = 1 AND f_score = 1 AND m_score = 1                                THEN 'Lost'
            WHEN r_score = 1 AND f_score BETWEEN 1 AND 2 AND m_score BETWEEN 1 AND 2        THEN 'Hibernating'
            WHEN r_score <= 2 AND f_score >= 3 AND m_score >= 3                             THEN 'At-Risk'
            WHEN r_score BETWEEN 2 AND 3 AND f_score >= 3                                   THEN 'Needs Attention'
            WHEN r_score >= 4 AND f_score BETWEEN 1 AND 2                                   THEN 'Promising'
            WHEN r_score >= 4 AND f_score BETWEEN 2 AND 3 AND m_score >= 3                  THEN 'Potential Loyalists'
            WHEN f_score <= 3 AND m_score >= 4                                              THEN 'Big Spenders'
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4                             THEN 'Champions'
            WHEN r_score >= 3 AND f_score >= 4 AND m_score >= 3                             THEN 'Loyal'
            ELSE 'General/Other'
        END AS customer_segment
    FROM rfm_scores
),
first_purchase AS (
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
    JOIN rfm_final r ON f.customer_id = r.customer_id
    GROUP BY r.customer_segment
),
cohort_activity AS (
    SELECT
        f.customer_id,
        r.customer_segment,
        (EXTRACT(year  FROM c.invoice_date) - EXTRACT(year  FROM f.cohort_month)) * 12 +
        (EXTRACT(month FROM c.invoice_date) - EXTRACT(month FROM f.cohort_month)) AS month_number
    FROM first_purchase f
    JOIN cleaned_retail_main c  ON f.customer_id = c.customer_id
    JOIN rfm_final r             ON f.customer_id = r.customer_id
    WHERE (EXTRACT(year  FROM c.invoice_date) - EXTRACT(year  FROM f.cohort_month)) * 12 +
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
    ROUND(m.active_customers::NUMERIC / NULLIF(c.total_customers, 0) * 100, 1)          AS retention_rate_pct,
    ROUND(100 - (m.active_customers::NUMERIC / NULLIF(c.total_customers, 0) * 100), 1)  AS churn_rate_pct
FROM monthly_retained m
JOIN cohort_size c USING (customer_segment)
ORDER BY
    CASE m.customer_segment
        WHEN 'Champions'            THEN 1
        WHEN 'Loyal'                THEN 2
        WHEN 'Potential Loyalists'  THEN 3
        WHEN 'Promising'            THEN 4
        WHEN 'Big Spenders'         THEN 5
        WHEN 'Needs Attention'      THEN 6
        WHEN 'At-Risk'              THEN 7
        WHEN 'Hibernating'          THEN 8
        WHEN 'Lost'                 THEN 9
        ELSE                        10
    END,
    m.month_number;