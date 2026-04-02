--Phase 3: Churn & Retention Analysis

--Defining the "Churn Point": No purchase in the last 90 days of the dataset.


CREATE TABLE churned_or_not AS 
WITH churn_base AS (
    SELECT 
        customer_id,
        MAX(invoice_date) AS last_purchase_date,
        -- We use a subquery to find the 'Today' of the dataset
        (SELECT MAX(invoice_date) FROM cleaned_retail_main) AS study_end_date,
        -- Calculate the gap in days
        DATE_PART('day', (SELECT MAX(invoice_date) FROM cleaned_retail_main) - MAX(invoice_date)) AS days_since_last_purchase,
        -- Label them: 1 for Churned, 0 for Active
        CASE 
            WHEN DATE_PART('day', (SELECT MAX(invoice_date) FROM cleaned_retail_main) - MAX(invoice_date)) > 90 
            THEN 1 
            ELSE 0 
        END AS is_churned
    FROM 
        cleaned_retail_main
    GROUP BY 
        customer_id
)
SELECT * FROM churn_base;

-- Monthly Retention & Churn Rate by Cohort (1-6 Months)

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
        (EXTRACT(year from c.invoice_date) - EXTRACT(year from f.cohort_month)) * 12 +
        (EXTRACT(month from c.invoice_date) - EXTRACT(month from f.cohort_month)) AS month_number
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
    TO_CHAR(cohort_month, 'YYYY-MM') AS cohort,
    month_number AS month_age,
    active_customers,
    cohort_size,
    -- Retention: The % of the cohort still purchasing
    ROUND(active_customers::NUMERIC / cohort_size * 100, 2) AS retention_rate_pct,
    -- Churn: The % of the cohort that has dropped off
    (100 - ROUND(active_customers::NUMERIC / cohort_size * 100, 2)) AS churn_rate_pct
FROM survival_base
WHERE month_number <= 6
ORDER BY cohort_month, month_age;

--Step 2: Monthly Churn & Retention Rate by RFM Segment (Months 1–12) 

--Define RFM Segments

CREATE TABLE retention_rates_by_rmf_segments AS 
WITH reference_date AS (
    SELECT MAX(invoice_date) + INTERVAL '1 day' AS ref_day
    FROM cleaned_retail_main
),
base_rfm AS (
    SELECT
        customer_id,
        MAX(invoice_date) AS last_purchase_date,
        COUNT(DISTINCT invoice) AS frequency,
        SUM(total_price) AS monetary
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
    FROM base_rfm b, reference_date r
),
rfm_final AS (
    SELECT
        *,
        CASE
           WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
           WHEN r_score >= 3 AND f_score >= 4 AND m_score >= 3 THEN 'Loyal'
           WHEN f_score <= 3 AND m_score >= 4 THEN 'Big spenders'
           WHEN r_score >=4 AND f_score between 2 AND 3 and m_score >=3 THEN 'Potential Loyalists'
           WHEN r_score >=4 AND f_score between 1 AND 2 THEN 'Promising'
           WHEN r_score between 2 and 3 AND f_score >=3 THEN 'About to Sleep'
           WHEN r_score <= 2 AND f_score >= 3 AND m_score >=3 THEN 'At-risk'
           WHEN r_score = 1 AND f_score between 1 and 2 AND m_score between 1 and 2 THEN 'Hibernating'
           WHEN r_score = 1 AND f_score = 1 AND m_score = 1 THEN 'Lost'
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
cohort_activity AS (
    SELECT
        f.customer_id,
        r.customer_segment,
        (EXTRACT(year FROM c.invoice_date) - EXTRACT(year FROM f.cohort_month)) * 12 +
        (EXTRACT(month FROM c.invoice_date) - EXTRACT(month FROM f.cohort_month)) AS month_number
    FROM first_purchase f
    JOIN cleaned_retail_main c ON f.customer_id = c.customer_id
    JOIN rfm_final r ON f.customer_id = r.customer_id
    WHERE (EXTRACT(year FROM c.invoice_date) - EXTRACT(year FROM f.cohort_month)) * 12 +
          (EXTRACT(month FROM c.invoice_date) - EXTRACT(month FROM f.cohort_month)) BETWEEN 1 AND 12
    GROUP BY 1,2,3
),
retention_pivot AS (
    SELECT
        customer_segment,
        COUNT(DISTINCT customer_id) AS total_customers,
        COUNT(DISTINCT CASE WHEN month_number = 1 THEN customer_id END) AS m1_act,
        COUNT(DISTINCT CASE WHEN month_number = 2 THEN customer_id END) AS m2_act,
        COUNT(DISTINCT CASE WHEN month_number = 3 THEN customer_id END) AS m3_act,
        COUNT(DISTINCT CASE WHEN month_number = 4 THEN customer_id END) AS m4_act,
        COUNT(DISTINCT CASE WHEN month_number = 5 THEN customer_id END) AS m5_act,
        COUNT(DISTINCT CASE WHEN month_number = 6 THEN customer_id END) AS m6_act,
        COUNT(DISTINCT CASE WHEN month_number = 7 THEN customer_id END) AS m7_act,
        COUNT(DISTINCT CASE WHEN month_number = 8 THEN customer_id END) AS m8_act,
        COUNT(DISTINCT CASE WHEN month_number = 9 THEN customer_id END) AS m9_act,
        COUNT(DISTINCT CASE WHEN month_number = 10 THEN customer_id END) AS m10_act,
        COUNT(DISTINCT CASE WHEN month_number = 11 THEN customer_id END) AS m11_act,
        COUNT(DISTINCT CASE WHEN month_number = 12 THEN customer_id END) AS m12_act
    FROM cohort_activity
    GROUP BY 1
)
SELECT
    customer_segment,
    total_customers,
    ROUND(m1_act::NUMERIC / NULLIF(total_customers, 0) * 100, 1) || '%' AS m1_ret,
    ROUND(m2_act::NUMERIC / NULLIF(total_customers, 0) * 100, 1) || '%' AS m2_ret,
    ROUND(m3_act::NUMERIC / NULLIF(total_customers, 0) * 100, 1) || '%' AS m3_ret,
    ROUND(m4_act::NUMERIC / NULLIF(total_customers, 0) * 100, 1) || '%' AS m4_ret,
    ROUND(m5_act::NUMERIC / NULLIF(total_customers, 0) * 100, 1) || '%' AS m5_ret,
    ROUND(m6_act::NUMERIC / NULLIF(total_customers, 0) * 100, 1) || '%' AS m6_ret,
    ROUND(m7_act::NUMERIC / NULLIF(total_customers, 0) * 100, 1) || '%' AS m7_ret,
    ROUND(m8_act::NUMERIC / NULLIF(total_customers, 0) * 100, 1) || '%' AS m8_ret,
    ROUND(m9_act::NUMERIC / NULLIF(total_customers, 0) * 100, 1) || '%' AS m9_ret,
    ROUND(m10_act::NUMERIC / NULLIF(total_customers, 0) * 100, 1) || '%' AS m10_ret,
    ROUND(m11_act::NUMERIC / NULLIF(total_customers, 0) * 100, 1) || '%' AS m11_ret,
    ROUND(m12_act::NUMERIC / NULLIF(total_customers, 0) * 100, 1) || '%' AS m12_ret
FROM retention_pivot
ORDER BY 
    CASE customer_segment
        WHEN 'Champions' THEN 1
        WHEN 'Loyalists' THEN 2
        WHEN 'Potential Loyalists' THEN 3
        WHEN 'Promising' THEN 4
        WHEN 'Big spenders' THEN 5
        WHEN 'About to Sleep' THEN 6
        WHEN 'At-risk' THEN 7
        WHEN 'Hibernating' THEN 8
        WHEN 'Lost' THEN 9
        ELSE 10
    END;