-- PHASE 8: SEGMENT MIGRATION ANALYSIS
-- Goal: Did customers move between RFM segments between Year 1 (2010) and Year 2 (2011)?

CREATE TABLE segment_migration AS
WITH year1_data AS (
    SELECT
        customer_id,
        MAX(invoice_date)                AS last_purchase_date,
        COUNT(DISTINCT invoice)::NUMERIC AS frequency,
        SUM(total_price)::NUMERIC        AS monetary
    FROM cleaned_retail_main
    WHERE invoice_date BETWEEN '2010-01-01' AND '2010-12-31'
    GROUP BY customer_id
),
year2_data AS (
    SELECT
        customer_id,
        MAX(invoice_date)                AS last_purchase_date,
        COUNT(DISTINCT invoice)::NUMERIC AS frequency,
        SUM(total_price)::NUMERIC        AS monetary
    FROM cleaned_retail_main
    WHERE invoice_date BETWEEN '2011-01-01' AND '2011-12-31'
    GROUP BY customer_id
),
year1_scores AS (
    SELECT
        customer_id,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY DATE_PART('day', '2011-01-01'::DATE - last_purchase_date) DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC)                                                   AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC)                                                    AS m_score
    FROM year1_data
),
year2_scores AS (
    SELECT
        customer_id,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY DATE_PART('day', '2012-01-01'::DATE - last_purchase_date) DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC)                                                   AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC)                                                    AS m_score
    FROM year2_data
),
year1_segments AS (
    SELECT
        customer_id,
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
        END AS segment_year1
    FROM year1_scores
),
year2_segments AS (
    SELECT
        customer_id,
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
        END AS segment_year2
    FROM year2_scores
)
SELECT
    y1.segment_year1,
    y2.segment_year2,
    COUNT(*)                                                   AS customer_count,
    CASE
        WHEN y1.segment_year1 = y2.segment_year2              THEN 'Stable'
        WHEN y2.segment_year2 IN ('Champions', 'Loyal',
            'Potential Loyalists')
        AND y1.segment_year1 NOT IN ('Champions', 'Loyal',
            'Potential Loyalists')                             THEN 'Upgraded'
        WHEN y2.segment_year2 IN ('Lost', 'Hibernating',
            'At-Risk')
        AND y1.segment_year1 NOT IN ('Lost', 'Hibernating',
            'At-Risk')                                         THEN 'Downgraded'
        ELSE 'Shifted'
    END                                                        AS migration_type
FROM year1_segments y1
JOIN year2_segments y2 ON y1.customer_id = y2.customer_id
GROUP BY y1.segment_year1, y2.segment_year2
ORDER BY y1.segment_year1, customer_count DESC;


-- MIGRATION SUMMARY
CREATE TABLE segment_migration_summary AS
SELECT
    migration_type,
    COUNT(*)                                                   AS customer_count,
    ROUND(COUNT(*)::NUMERIC * 100
        / SUM(COUNT(*)) OVER (), 2)                           AS pct_of_migrated_customers
FROM segment_migration
GROUP BY migration_type
ORDER BY customer_count DESC;