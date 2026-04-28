-- RFM Segmentation Analysis
DROP TABLE IF EXISTS new_rfm_segment_analysis;

CREATE TABLE new_rfm_segment_analysis AS
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
        b.last_purchase_date,
        b.frequency,
        b.monetary,
        DATE_PART('day', r.ref_day - b.last_purchase_date)::NUMERIC AS recency_days,
        -- R score: smaller recency_days = more recent = better = score 5
        NTILE(5) OVER (ORDER BY DATE_PART('day', r.ref_day - b.last_purchase_date) DESC) AS r_score,
        -- F score: higher frequency = better = score 5
        NTILE(5) OVER (ORDER BY b.frequency ASC)                                          AS f_score,
        -- M score: higher monetary = better = score 5
        NTILE(5) OVER (ORDER BY b.monetary ASC)                                           AS m_score
    FROM base_rfm b
    CROSS JOIN reference_date r
),
rfm_combined AS (
    SELECT
        *,
        (r_score::TEXT || f_score::TEXT || m_score::TEXT) AS rfm_combined
    FROM rfm_scores
)
SELECT
    *,
    CASE
        -- Champions: 555,554,544,545,454,455,445
        WHEN rfm_combined IN ('555','554','544','545','454','455','445')
            THEN 'Champions'
        -- Loyal: 543,444,435,355,354,345,344,335
        WHEN rfm_combined IN ('543','444','435','355','354','345','344','335')
            THEN 'Loyal'
        -- Potential Loyalists
        WHEN rfm_combined IN ('553','551','552','541','542','533','532','531',
                              '452','451','442','441','431','453','433','432',
                              '423','353','352','351','342','341','333','323')
            THEN 'Potential Loyalists'
        -- Recent Customers: 512,511,422,421,412,411,311
        WHEN rfm_combined IN ('512','511','422','421','412','411','311')
            THEN 'Recent Customers'
        -- Promising
        WHEN rfm_combined IN ('525','524','523','522','521','515','514','513',
                              '425','424','413','414','415','315','314','313')
            THEN 'Promising'
        -- Need Attention: 535,534,443,434,343,334,325,324
        WHEN rfm_combined IN ('535','534','443','434','343','334','325','324')
            THEN 'Need Attention'
        -- About to Sleep: 331,321,312,221,213
        WHEN rfm_combined IN ('331','321','312','221','213')
            THEN 'About to Sleep'
        -- At-Risk
        WHEN rfm_combined IN ('255','254','245','244','253','252','243','242',
                              '235','234','225','224','153','152','145','143',
                              '142','135','134','133','125','124')
            THEN 'At-Risk'
        -- Cannot Lose: 155,154,144,214,215,115,114,113
        WHEN rfm_combined IN ('155','154','144','214','215','115','114','113')
            THEN 'Cannot Lose'
        -- Hibernating: 332,322,231,241,251,233,232,223,222,132,123,122,212,211
        WHEN rfm_combined IN ('332','322','231','241','251','233','232','223','222','132',
                              '123','122','212','211')
            THEN 'Hibernating'
        -- Lost: 111,112,121,131,141,151
        WHEN rfm_combined IN ('111','112','121','131','141','151')
            THEN 'Lost'
        ELSE 'General/Other'
    END AS customer_segment
FROM rfm_combined;

-- RFM Segmentation Summary
DROP TABLE IF EXISTS new_rfm_segment_summary;

CREATE TABLE new_rfm_segment_summary AS

SELECT
    customer_segment,
    COUNT(*)                                                                   AS total_customers,
    SUM(frequency)                                                             AS total_orders,
    ROUND(SUM(monetary)::NUMERIC, 2)                                           AS total_revenue,
    ROUND((COUNT(*) * 1.0 / SUM(COUNT(*)) OVER ()), 4)                        AS customer_share_pct,
    ROUND((SUM(frequency)::NUMERIC / SUM(SUM(frequency)::NUMERIC) OVER ()), 4) AS order_share_pct,
    ROUND((SUM(monetary)::NUMERIC / SUM(SUM(monetary)::NUMERIC) OVER ()), 4)   AS revenue_share_pct,
    ROUND(AVG(monetary)::NUMERIC, 2)                                           AS avg_monetary,
    ROUND(AVG(frequency)::NUMERIC, 2)                                          AS avg_frequency,
    ROUND(AVG(recency_days)::NUMERIC, 1)                                       AS avg_recency_days,
    ROUND(AVG(r_score)::NUMERIC, 2)                                            AS avg_r_score,
    ROUND(AVG(f_score)::NUMERIC, 2)                                            AS avg_f_score,
    ROUND(AVG(m_score)::NUMERIC, 2)                                            AS avg_m_score,
    ROUND(SUM(monetary)::NUMERIC / NULLIF(SUM(frequency), 0), 2)              AS aov
FROM new_rfm_segment_analysis
GROUP BY customer_segment
ORDER BY avg_monetary DESC;

--Pivot for easier visualization
DROP TABLE IF EXISTS new_rfm_segment_pivot;

CREATE TABLE new_rfm_segment_pivot AS
SELECT
    customer_segment,
    metric_name,
    ROUND(share_pct::NUMERIC, 4)                    AS share_pct,
    ROUND((1 - share_pct)::NUMERIC, 4)              AS remaining_pct,
    absolute_value,
    remaining_absolute
FROM (
    SELECT
        customer_segment,
        'Customer Share' AS metric_name,
        COUNT(*) * 1.0 / SUM(COUNT(*)) OVER ()              AS share_pct,
        COUNT(*)::NUMERIC                                    AS absolute_value,
        SUM(COUNT(*)) OVER () - COUNT(*)                     AS remaining_absolute
    FROM new_rfm_segment_analysis
    GROUP BY customer_segment

    UNION ALL

    SELECT
        customer_segment,
        'Order Share'    AS metric_name,
        SUM(frequency)::NUMERIC / SUM(SUM(frequency)::NUMERIC) OVER ()       AS share_pct,
        SUM(frequency)::NUMERIC                              AS absolute_value,
        SUM(SUM(frequency)::NUMERIC) OVER () - SUM(frequency)::NUMERIC       AS remaining_absolute
    FROM new_rfm_segment_analysis
    GROUP BY customer_segment

    UNION ALL

    SELECT
        customer_segment,
        'Revenue Share'  AS metric_name,
        SUM(monetary)::NUMERIC / SUM(SUM(monetary)::NUMERIC) OVER ()         AS share_pct,
        ROUND(SUM(monetary)::NUMERIC, 2)                     AS absolute_value,
        ROUND(SUM(SUM(monetary)::NUMERIC) OVER () - SUM(monetary)::NUMERIC, 2) AS remaining_absolute
    FROM new_rfm_segment_analysis
    GROUP BY customer_segment
) t
ORDER BY
    CASE customer_segment
        WHEN 'Champions'           THEN 1
        WHEN 'Loyal'               THEN 2
        WHEN 'Potential Loyalists' THEN 3
        WHEN 'Recent Customers'    THEN 4
        WHEN 'Promising'           THEN 5
        WHEN 'Need Attention'      THEN 6
        WHEN 'About to Sleep'      THEN 7
        WHEN 'At-Risk'             THEN 8
        WHEN 'Cannot Lose'         THEN 9
        WHEN 'Hibernating'         THEN 10
        WHEN 'Lost'                THEN 11
        ELSE                       12
    END,
    CASE metric_name
        WHEN 'Customer Share' THEN 1
        WHEN 'Order Share'    THEN 2
        WHEN 'Revenue Share'  THEN 3
    END;