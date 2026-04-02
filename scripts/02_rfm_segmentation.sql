--In total, there are 5853 customers.
SELECT
    COUNT(DISTINCT customer_id)
FROM cleaned_retail_main

--RFM segmentation

--Segment	            Typical RFM Range	
--Champions	            R≥4, F≥4, M≥4	
--Loyal	                F≥4, M≥3, R≥3	
--Big Spenders	        M≥4, F≤3	
--Potential Loyalists	R≥4, F=2-3, M≥3	
--Promising	            R≥4, F=1-2	
--About to Sleep	    R=2-3, F≥3	
--At Risk	            R≤2, F≥3, M≥3	
--Hibernating	        R=1, F=1-2, M=1-2	
--Lost	                R=1, F=1, M=1	

-- Create a table to store the results permanently

CREATE TABLE customer_rfm_segmented as
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
        -- Score 5 = Recent (Smallest days). We sort DESC so 1 day is at the end (NTILE 5).
        NTILE(5) OVER (ORDER BY DATE_PART('day', r.ref_day - b.last_purchase_date) DESC) AS r_score,
        -- Score 5 = High Frequency. We sort ASC so highest count is at the end (NTILE 5).
        NTILE(5) OVER (ORDER BY b.frequency ASC) AS f_score,
        -- Score 5 = High Spend. We sort ASC so highest spend is at the end (NTILE 5).
        NTILE(5) OVER (ORDER BY b.monetary ASC) AS m_score
    FROM base_rfm b, reference_date r
)
SELECT
    *,
    (r_score::TEXT || f_score::TEXT || m_score::TEXT) AS rfm_combined,
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
FROM rfm_scores;

--Part 2: The Summary (Analyze the Segments)
CREATE TABLE customer_rfm_segmentation_summary AS
SELECT
    customer_segment,
    COUNT(*) AS customer_count,
    -- Calculate % of total customer base
    ROUND((COUNT(*) * 100.0 / SUM(COUNT(*)) OVER ()), 2) AS pct_of_total,
    -- Calculate averages to verify the segment logic
    ROUND(AVG(monetary)::numeric, 2)     AS avg_monetary,
    ROUND(AVG(frequency)::numeric, 2)    AS avg_frequency,
    ROUND(AVG(recency_days)::numeric, 1) AS avg_recency_days
FROM customer_rfm_segmented
GROUP BY customer_segment
ORDER BY avg_monetary DESC; -- Sorting by money usually highlights the VIPs at the top


