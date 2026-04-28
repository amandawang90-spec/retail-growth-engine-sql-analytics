-- PHASE 8: SEGMENT MIGRATION (2010 vs 2011)

DROP TABLE IF EXISTS new_segment_migration;

CREATE TABLE new_segment_migration AS
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
        NTILE(5) OVER (ORDER BY DATE_PART('day', '2011-01-01'::DATE - last_purchase_date) DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC)                                                   AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC)                                                    AS m_score
    FROM year1_data
),
year2_scores AS (
    SELECT
        customer_id,
        NTILE(5) OVER (ORDER BY DATE_PART('day', '2012-01-01'::DATE - last_purchase_date) DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC)                                                   AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC)                                                    AS m_score
    FROM year2_data
),
year1_combined AS (
    SELECT
        customer_id,
        (r_score::TEXT || f_score::TEXT || m_score::TEXT) AS rfm_combined
    FROM year1_scores
),
year2_combined AS (
    SELECT
        customer_id,
        (r_score::TEXT || f_score::TEXT || m_score::TEXT) AS rfm_combined
    FROM year2_scores
),
year1_segments AS (
    SELECT
        customer_id,
        rfm_combined,
        CASE
            WHEN rfm_combined IN ('555','554','544','545','454','455','445') THEN 'Champions'
            WHEN rfm_combined IN ('543','444','435','355','354','345','344','335') THEN 'Loyal'
            WHEN rfm_combined IN ('553','551','552','541','542','533','532','531','452','451','442','441','431','453','433','432','423','353','352','351','342','341','333','323') THEN 'Potential Loyalists'
            WHEN rfm_combined IN ('512','511','422','421','412','411','311') THEN 'Recent Customers'
            WHEN rfm_combined IN ('525','524','523','522','521','515','514','513','425','424','413','414','415','315','314','313') THEN 'Promising'
            WHEN rfm_combined IN ('535','534','443','434','343','334','325','324') THEN 'Need Attention'
            WHEN rfm_combined IN ('331','321','312','221','213') THEN 'About to Sleep'
            WHEN rfm_combined IN ('255','254','245','244','253','252','243','242','235','234','225','224','153','152','145','143','142','135','134','133','125','124') THEN 'At-Risk'
            WHEN rfm_combined IN ('155','154','144','214','215','115','114','113') THEN 'Cannot Lose'
            WHEN rfm_combined IN ('332','322','231','241','251','233','232','223','222','132','123','122','212','211') THEN 'Hibernating'
            WHEN rfm_combined IN ('111','112','121','131','141','151') THEN 'Lost'
            ELSE 'General/Other'
        END AS segment_year1
    FROM year1_combined
),
year2_segments AS (
    SELECT
        customer_id,
        rfm_combined,
        CASE
            WHEN rfm_combined IN ('555','554','544','545','454','455','445') THEN 'Champions'
            WHEN rfm_combined IN ('543','444','435','355','354','345','344','335') THEN 'Loyal'
            WHEN rfm_combined IN ('553','551','552','541','542','533','532','531','452','451','442','441','431','453','433','432','423','353','352','351','342','341','333','323') THEN 'Potential Loyalists'
            WHEN rfm_combined IN ('512','511','422','421','412','411','311') THEN 'Recent Customers'
            WHEN rfm_combined IN ('525','524','523','522','521','515','514','513','425','424','413','414','415','315','314','313') THEN 'Promising'
            WHEN rfm_combined IN ('535','534','443','434','343','334','325','324') THEN 'Need Attention'
            WHEN rfm_combined IN ('331','321','312','221','213') THEN 'About to Sleep'
            WHEN rfm_combined IN ('255','254','245','244','253','252','243','242','235','234','225','224','153','152','145','143','142','135','134','133','125','124') THEN 'At-Risk'
            WHEN rfm_combined IN ('155','154','144','214','215','115','114','113') THEN 'Cannot Lose'
            WHEN rfm_combined IN ('332','322','231','241','251','233','232','223','222','132','123','122','212','211') THEN 'Hibernating'
            WHEN rfm_combined IN ('111','112','121','131','141','151') THEN 'Lost'
            ELSE 'General/Other'
        END AS segment_year2
    FROM year2_combined
)
SELECT
    y1.segment_year1,
    y2.segment_year2,
    COUNT(*)                                                   AS customer_count,
    CASE
        WHEN y1.segment_year1 = y2.segment_year2              THEN 'Stable'
        WHEN y2.segment_year2 IN ('Champions', 'Loyal', 'Potential Loyalists')
        AND y1.segment_year1 NOT IN ('Champions', 'Loyal', 'Potential Loyalists') THEN 'Upgraded'
        WHEN y2.segment_year2 IN ('Lost', 'Hibernating', 'At-Risk', 'Cannot Lose')
        AND y1.segment_year1 NOT IN ('Lost', 'Hibernating', 'At-Risk', 'Cannot Lose') THEN 'Downgraded'
        ELSE 'Shifted'
    END                                                        AS migration_type
FROM year1_segments y1
JOIN year2_segments y2 ON y1.customer_id = y2.customer_id
GROUP BY y1.segment_year1, y2.segment_year2
ORDER BY y1.segment_year1, customer_count DESC;


DROP TABLE IF EXISTS new_segment_migration_summary;
CREATE TABLE new_segment_migration_summary AS
SELECT
    migration_type,
    COUNT(*)                                                   AS customer_count,
    ROUND(COUNT(*)::NUMERIC * 100
        / SUM(COUNT(*)) OVER (), 2)                           AS pct_of_migrated_customers
FROM segment_migration
GROUP BY migration_type
ORDER BY customer_count DESC;
