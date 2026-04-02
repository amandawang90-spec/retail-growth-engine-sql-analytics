
-- PHASE 5A: PARETO PRINCIPLE (REVENUE CONCENTRATION)
-- Goal: Identify if 20% of customers drive 80% of revenue.

CREATE TABLE pareto_analysis AS 
WITH customer_spending AS (
    -- Step 1: Total spend per customer
    SELECT 
        customer_id,
        SUM(total_price) AS total_revenue
    FROM cleaned_retail_main
    GROUP BY customer_id
), 
running_total_calc AS ( 
    -- Step 2: Calculate running totals and ranks
    SELECT 
        customer_id,
        total_revenue,
        SUM(total_revenue) OVER (ORDER BY total_revenue DESC) AS running_total,
        (SELECT SUM(total_price) FROM cleaned_retail_main) AS grand_total,
        ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS customer_rank,
        (SELECT COUNT(DISTINCT customer_id) FROM cleaned_retail_main) AS total_customer_count
    FROM customer_spending
) 
-- Step 3: Final Percentages with explicit casting for ROUND()
SELECT 
    customer_id,
    ROUND(total_revenue::NUMERIC, 2) AS total_revenue,
    ROUND((customer_rank::NUMERIC / total_customer_count * 100)::NUMERIC, 2) AS pct_of_customer_base,
    ROUND((running_total::NUMERIC / grand_total * 100)::NUMERIC, 2) AS pct_of_total_revenue
FROM running_total_calc
WHERE 
    -- We cast to numeric here to match the ROUND signature
    ROUND((customer_rank::NUMERIC / total_customer_count * 100)::NUMERIC, 0) IN (1, 5, 10, 20, 50, 80)
    OR customer_rank = 1
ORDER BY customer_rank ASC;

--Full List
WITH customer_spending AS (
    SELECT 
        customer_id,
        SUM(total_price) AS total_revenue
    FROM cleaned_retail_main
    GROUP BY customer_id
), 
running_total_calc AS ( 
    SELECT 
        customer_id,
        total_revenue,
        SUM(total_revenue) OVER (ORDER BY total_revenue DESC) AS running_total,
        (SELECT SUM(total_price) FROM cleaned_retail_main) AS grand_total,
        ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS customer_rank,
        (SELECT COUNT(DISTINCT customer_id) FROM cleaned_retail_main) AS total_customer_count
    FROM customer_spending
) 
SELECT 
    customer_id,
    ROUND(total_revenue::NUMERIC, 2) AS total_revenue,
    ROUND((customer_rank::NUMERIC / total_customer_count * 100)::NUMERIC, 2) AS pct_of_customer_base,
    ROUND((running_total::NUMERIC / grand_total * 100)::NUMERIC, 2) AS pct_of_total_revenue
FROM running_total_calc
-- WHERE REMOVED TO SHOW ALL CUSTOMERS
ORDER BY customer_rank ASC;


-- PHASE 5B:Predictive Customer Lifetime Value Analysis

-- CLV=(Average Order Value×Purchase Frequency)×Customer Lifespan

--Average Order Value (AOV): Total Revenue / Total Number of Orders.

--Purchase Frequency: Total Number of Orders / Total Number of Customers.

--Churn Rate: (seemy churn analysis).

--Customer Lifespan: 1/Churn Rate.


CREATE TABLE predictive_clv_analysis AS 
WITH customer_stats AS (
    SELECT 
        customer_id,
        COUNT(DISTINCT invoice) AS total_orders,
        SUM(total_price) AS total_revenue,
        MAX(invoice_date) AS last_purchase_date
    FROM cleaned_retail_main
    GROUP BY customer_id
),
rfm_logic AS (
    SELECT 
        customer_id,
        total_revenue,
        total_orders,
        last_purchase_date,
        NTILE(5) OVER (ORDER BY DATE_PART('day', (SELECT MAX(invoice_date) + INTERVAL '1 day' FROM cleaned_retail_main) - last_purchase_date) DESC) AS r_score, 
        NTILE(5) OVER (ORDER BY total_revenue ASC) AS m_score,
        NTILE(5) OVER (ORDER BY total_orders ASC) AS f_score
    FROM customer_stats
),
segmented_data AS (
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
    FROM rfm_logic
),
segment_aggregates AS (
    SELECT 
        customer_segment,
        COUNT(DISTINCT customer_id) AS total_customers,
        AVG(total_revenue / NULLIF(total_orders, 0)) AS avg_order_value,
        AVG(total_orders) AS avg_frequency,
        -- Calculate the churn rate (ratio of people who haven't bought in 90 days)
        COUNT(CASE WHEN DATE_PART('day', (SELECT MAX(invoice_date) FROM cleaned_retail_main) - last_purchase_date) > 90 THEN 1 END)::NUMERIC / COUNT(*) AS churn_rate
    FROM segmented_data
    GROUP BY 1
)
-- FINAL SELECT WITH DIVISION BY ZERO PROTECTION
SELECT 
    customer_segment,
    total_customers,
    ROUND(avg_order_value::NUMERIC, 2) AS aov,
    ROUND(avg_frequency::NUMERIC, 2) AS frequency,
    ROUND(churn_rate::NUMERIC, 4) AS segment_churn_rate,
    -- If churn_rate is 0, we treat it as 0.001 (0.1%) to allow the math to work
    ROUND((avg_order_value * avg_frequency / CASE WHEN churn_rate = 0 THEN 0.001 ELSE churn_rate END)::NUMERIC, 2) AS predicted_clv
FROM segment_aggregates
ORDER BY predicted_clv DESC;