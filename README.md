🚀 Retail Growth Engine: From Transactional Data to Predictive Lifetime Value

🎯 Project Purpose

This project transforms over 1 million rows of raw transactional data into a strategic growth roadmap. By architecting an end-to-end SQL pipeline, I moved beyond descriptive reporting to identify high-value behavioral segments, quantify massive financial churn risks, and model Predictive Customer Lifetime Value (CLV) to drive data-driven marketing.

📁 Data Source & Context

Source: UCI Machine Learning Repository - Online Retail II

Context: Real-world transactional data (2009–2011) for a UK-based, non-store online giftware retailer.

Nature of Business: The company primarily sells unique all-occasion giftware; a significant portion of the customer base consists of wholesalers.

⚠️ The Business Problem

The company operated with a "Revenue Black Box": they lacked visibility into customer decay, retention stabilization, and segment profitability. Marketing spend was being distributed evenly across the database, resulting in wasted resources on low-value customers while the top 1% of the base (driving ~32% of sales) remained unidentified and underserved.

🛠️ Technical Stack & Skills

Database: PostgreSQL

Advanced SQL: Common Table Expressions (CTEs), Window Functions (NTILE, SUM OVER, ROW_NUMBER), Date/Time Arithmetic, and Data Truncation.

Analytical Frameworks: RFM Analysis, Cohort Retention Matrices, Pareto Analysis, Predictive CLV Modeling.

📝 Executive Summary

By implementing a 9-tier RFM framework and 12-month survival analysis, I identified that 22% of the customer base (Champions) drives 68.4% of total revenue, while £1.94M in revenue is currently "at-risk" within the declining Loyalist and "About to Sleep" segments.

🛠️ The Data Pipeline

1. Data Setup & Cleaning

Goal: Establish a "Single Source of Truth."

Action: Created the cleaned_retail_main view by enforcing strict data integrity rules. This involved filtering non-product transactions (fees, postage), handling NULL identifiers, and excluding negative values for Price and Quantity to remove noise. Additionally, all "C" prefix invoices were excluded to separate returns from pure sales performance, ensuring the behavioral integrity of the downstream model.

2. Multi-Dimensional RFM Segmentation

Goal: Categorize the customer base by Recency, Frequency, and Monetary value.

Action: Leveraged NTILE(5) window functions to rank 5,800+ customers across three dimensions. By scoring customers from 1–5 across Recency, Frequency, and Monetary values, I mapped the entire database into 9 actionable personas:

Segment	            RFM Logic (Scores)	Characterization
Champions	        R≥4, F≥4, M≥4	    Most valuable assets. High-frequency, high-spend, and recent.
Loyal 	            R≥3, F≥4, M≥3	    Reliable repeat customers who respond well to loyalty programs.
Big Spenders	    F≤3, M≥4	        High-margin "Whales." They buy infrequently but in massive volumes.
Potential Loyalists	R≥4, F=2-3, M≥3	    Recent spenders with growing frequency. Primary upsell targets.
Promising	        R≥4, F=1-2	        Newest customers. High potential, but haven't formed a habit yet.
About to Sleep	    R=2-3, F≥3	        Previously active customers showing early signs of disengagement.
At-Risk	            R≤2, F≥3, M≥3	    High-value customers who haven't shopped in 400+ days. Critical recovery zone.
Hibernating	        R=1, F=1-2, M=1-2	Low-value, infrequent customers who have largely moved on.
Lost	            R=1, F=1, M=1	    One-time shoppers from years ago. Candidate for database purging.

3. Longitudinal Survival (12-Month Cohort Analysis)

Goal: Track the "Longitudinal Decay" of customer cohorts.

Action: Developed a 12 month survival matrix to identify the "Retention Floor"—the month where churn stabilizes and long-term habits are formed.

Finding: Champions have a 45% retention floor at Month 12, whereas "Promising" customers see a 71% drop-off by Month 6.

4. Revenue-at-Risk & Pareto Concentration

Pareto Principle: Validated that the top 1.01% of customers drive 32% of revenue. Identified that Champions (22.1% of population) generate 68.4% of total revenue.

Financial Leakage: Quantified the Monetary Magnitude of churn through a 90-day inactivity threshold. Identified a critical £1.9M revenue leak. The "About to Sleep" segment represents the largest source of erosion, with an 88% churn rate resulting in a £1.12M loss. Simultaneously, a concerning 38.7% churn rate among Loyal customers led to an additional £786k loss, signaling that the brand's mid-tier engine is rapidly decaying into higher-risk categories.


5. Predictive Customer Lifetime Value (CLV)

Formula: CLV= Average Order Value × Purchase Frequency/Churn Rate
​	
Discovery: A "Champion" is mathematically 1,100x more valuable than a "Loyal" due to the compounding effect of zero recent churn and high frequency.

📈 Key Data Insights

Segment	        % of Base	Revenue Share	Avg. Spend	Churn Rate (90d)       Predicted CLV

Champions	        22.1%	    68.4%	        £9,208	     0.0%                 £7,723,318

Loyal	            10.9%	    10.4%	        £2,842	     38.7%                £6,984

About to Sleep	    12.1%	    6.8%	        £1,671	     88.0%                £1,530

Big Spenders        6.8%        6.5%            £2,818       54.0%                £6,437

General/Other       21.9%.      3.1%            £418         74.3%                £630

At-Risk	            2.5%	    1.7%	        £2,079       100.0%               £2,049

Potential Loyalists 4.6%        1.4%            £879         0.0%                 £943,894

Hibernating         13.1%       1.1%            £246         100.0%               £254

Promising           5.8%        0.6%            £321         0.0%                 £336,630


💡 Strategic Recommendations

1.Protect the Core Revenue Base (Champions)
The Champions segment represents the most critical business asset, generating overwhelmingly high total revenue with zero churn. This indicates strong engagement but also highlights a major dependency risk.

Action: Implement a proactive retention strategy through a premium loyalty program, including exclusive benefits, early access to products, and personalized experiences. Additionally, introduce churn prediction triggers based on declining activity to ensure early intervention.

2.Accelerate High-Potential Segments (Potential Loyalists & Promising)

These segments show zero churn and healthy engagement but currently contribute a smaller share of revenue. They represent the pipeline for future high-value customers.

Action: Develop targeted nurturing strategies such as onboarding journeys, personalized recommendations, and incentive-based progression into loyalty tiers. The goal is to accelerate their transition into Loyal and Champions.

3.Address Early Signs of Churn (Loyal Customers)
Despite relatively strong engagement, the Loyal segment shows a moderate churn rate (~39%), indicating early-stage disengagement.
Action: Introduce a structured retention lifecycle with timed engagement touchpoints (e.g., reminders, offers, and personalized content). Focus on maintaining consistent interaction before customers become inactive.

4.Stabilize High-Value but Volatile Customers (Big Spenders)
Big Spenders exhibit very high average spend but also high churn (~54%), making them a volatile revenue source.

Action: Encourage repeat purchasing behavior through bundle offers, subscriptions, or replenishment reminders. Increasing purchase frequency will help stabilize revenue from this segment.

5.Recover or Exit High-Churn Segments (At-Risk & About to Sleep)
These segments show extremely high churn rates (87%–100%), indicating significant disengagement.

Action: Deploy targeted win-back campaigns with strong incentives and urgency messaging. At the same time, evaluate whether continued investment in these segments is justified, and limit high-cost marketing efforts where recovery probability is low.

6.Optimize Marketing Efficiency (General/Other & Hibernating)
These segments represent a large portion of the customer base but contribute minimal revenue and show high churn rates.

Action:Reduce paid marketing spend and focus on low-cost engagement channels such as email. Additionally, refine segmentation within the “General/Other” group to identify any overlooked sub-segments with growth potential.

📂 Project Structure

scripts/01_setup_and_cleaning.sql: Initial sanitization and ledger alignment.

scripts/02_rfm_segmentation.sql: Scoring and 9-tier segment assignment.

scripts/03_cohort_analysis.sql: 12-month retention and decay matrices.

scripts/04_financial_impact.sql: Pareto and Revenue-at-Risk modeling.

scripts/05_pareto_and_predictive_clv.sql: Forward-looking lifetime value forecasts.

Author: Jing Wang

Tools: PostgreSQL, DBeaver, Tableau (Visualization)