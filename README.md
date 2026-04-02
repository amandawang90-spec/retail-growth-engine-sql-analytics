# 🚀 Retail Growth Engine: From Transactional Data to Predictive Lifetime Value

## 🎯 Project Overview

This project transforms **1M+ rows of raw transactional data** into a strategic growth roadmap. By architecting an end-to-end SQL pipeline, I moved beyond descriptive reporting to identify high-value behavioral segments, quantify financial churn risk, and model **Predictive Customer Lifetime Value (CLV)** to enable data-driven marketing decisions.

---

## 📁 Data Source

| Detail | Info |
|---|---|
| **Source** | [UCI Machine Learning Repository – Online Retail II](https://archive.ics.uci.edu/dataset/502/online+retail+ii) |
| **Period** | 2009–2011 |
| **Business** | UK-based non-store online giftware retailer |
| **Customer Mix** | Mix of individual consumers and wholesalers |

---

## ⚠️ The Business Problem

The company operated with a **"Revenue Black Box"** — no visibility into customer decay, retention stabilization, or segment profitability. Marketing spend was distributed evenly across the entire database, resulting in:

- Wasted resources on low-value customers
- The top 1% of customers (driving ~32% of revenue) remaining **unidentified and underserved**

---

## 🛠️ Technical Stack

| Layer | Tools / Methods |
|---|---|
| **Database** | PostgreSQL |
| **Advanced SQL** | CTEs, Window Functions (`NTILE`, `SUM OVER`, `ROW_NUMBER`), Date/Time Arithmetic, Data Truncation |
| **Analytical Frameworks** | RFM Analysis, Cohort Retention Matrices, Pareto Analysis, Predictive CLV Modeling |
| **Visualization** | Tableau, DBeaver |

---

## 📝 Executive Summary

By implementing a **9-tier RFM framework** and a **12-month survival analysis**, this project uncovered:

- **Champions** (22% of customers) generate **68.4% of total revenue**
- **£1.94M in revenue is at risk** within declining Loyal and "About to Sleep" segments
- The top **1.01% of customers** drive **32% of all revenue** (Pareto confirmed)

---

## 🔧 The Data Pipeline

### Step 1 — Data Setup & Cleaning
**Goal:** Establish a single source of truth.

Created the `cleaned_retail_main` view by enforcing strict data integrity rules:
- Filtered non-product transactions (fees, postage)
- Handled `NULL` customer identifiers
- Excluded negative `Price` and `Quantity` values
- Removed `"C"` prefix invoices (returns) to preserve behavioral integrity

---

### Step 2 — Multi-Dimensional RFM Segmentation
**Goal:** Categorize 5,800+ customers by Recency, Frequency, and Monetary value.

Used `NTILE(5)` window functions to score each customer 1–5 across all three dimensions, then mapped the full database into **9 actionable personas**:

| Segment | RFM Logic | Characterization |
|---|---|---|
| **Champions** | R≥4, F≥4, M≥4 | Most valuable assets — high-frequency, high-spend, and recent |
| **Loyal** | R≥3, F≥4, M≥3 | Reliable repeat customers; respond well to loyalty programs |
| **Big Spenders** | F≤3, M≥4 | High-margin "whales" — infrequent but large-volume buyers |
| **Potential Loyalists** | R≥4, F=2–3, M≥3 | Recent spenders with growing frequency; primary upsell targets |
| **Promising** | R≥4, F=1–2 | Newest customers — high potential, haven't yet formed a habit |
| **About to Sleep** | R=2–3, F≥3 | Previously active; showing early signs of disengagement |
| **At-Risk** | R≤2, F≥3, M≥3 | High-value customers who haven't purchased in 400+ days |
| **Hibernating** | R=1, F=1–2, M=1–2 | Low-value, infrequent; have largely moved on |
| **Lost** | R=1, F=1, M=1 | One-time buyers from years ago; candidates for database purge |

---

### Step 3 — 12-Month Cohort Survival Analysis
**Goal:** Track longitudinal decay across customer cohorts.

Built a 12-month survival matrix to identify the **Retention Floor** — the point where churn stabilizes and long-term habits form.

> **Key Finding:** Champions hold a **45% retention floor at Month 12**, while "Promising" customers see a **71% drop-off by Month 6**.

---

### Step 4 — Revenue-at-Risk & Pareto Concentration
- **Pareto validated:** Top 1.01% of customers → 32% of revenue
- **Champions** (22.1% of base) → 68.4% of total revenue
- **Critical £1.94M revenue leak** identified via 90-day inactivity threshold:
  - *About to Sleep*: 88% churn rate → **£1.12M loss**
  - *Loyal*: 38.7% churn rate → **£786K loss** — the mid-tier engine is rapidly decaying

---

### Step 5 — Predictive Customer Lifetime Value (CLV)

**Formula:**

$$CLV = \frac{\text{Average Order Value} \times \text{Purchase Frequency}}{\text{Churn Rate}}$$

> **Key Discovery:** A Champion is mathematically **1,100× more valuable** than a Loyal customer, due to the compounding effect of near-zero churn and high frequency.

---

## 📊 Segment Performance Summary

| Segment | % of Base | Revenue Share | Avg. Spend | 90d Churn | Predicted CLV |
|---|---|---|---|---|---|
| Champions | 22.1% | 68.4% | £9,208 | 0.0% | £7,723,318 |
| Loyal | 10.9% | 10.4% | £2,842 | 38.7% | £6,984 |
| About to Sleep | 12.1% | 6.8% | £1,671 | 88.0% | £1,530 |
| Big Spenders | 6.8% | 6.5% | £2,818 | 54.0% | £6,437 |
| General / Other | 21.9% | 3.1% | £418 | 74.3% | £630 |
| At-Risk | 2.5% | 1.7% | £2,079 | 100.0% | £2,049 |
| Potential Loyalists | 4.6% | 1.4% | £879 | 0.0% | £943,894 |
| Hibernating | 13.1% | 1.1% | £246 | 100.0% | £254 |
| Promising | 5.8% | 0.6% | £321 | 0.0% | £336,630 |

---

## 💡 Strategic Recommendations

### 1. Protect the Core Revenue Base — Champions
Champions generate the overwhelming majority of revenue with zero churn, but this also creates a **concentration risk**.

**Action:** Launch a premium loyalty program with exclusive benefits, early product access, and personalized experiences. Introduce churn prediction triggers to catch early signs of disengagement before they escalate.

---

### 2. Accelerate High-Potential Segments — Potential Loyalists & Promising
Zero churn and healthy engagement make these the **pipeline for future Champions**.

**Action:** Deploy onboarding journeys, personalized recommendations, and incentive-based tier progression to accelerate their path to Loyal and Champion status.

---

### 3. Address Early Disengagement — Loyal Customers
A ~39% churn rate signals mid-tier erosion that, if unchecked, will compound over time.

**Action:** Implement a structured retention lifecycle with timed touchpoints — reminders, personalized offers, and content — before inactivity sets in.

---

### 4. Stabilize Volatile Revenue — Big Spenders
High average spend but ~54% churn makes this segment financially unpredictable.

**Action:** Drive repeat behavior through bundle offers, subscriptions, or replenishment reminders to convert episodic purchases into regular revenue.

---

### 5. Recover or Exit High-Churn Segments — At-Risk & About to Sleep
With churn rates between 87–100%, these segments require triage.

**Action:** Run targeted win-back campaigns with strong incentives and urgency messaging. Limit high-cost marketing where recovery probability is low and evaluate ROI per reactivation attempt.

---

### 6. Optimize Marketing Efficiency — General/Other & Hibernating
Large share of the database, minimal revenue contribution, high churn.

**Action:** Shift to low-cost channels (email only). Refine segmentation within General/Other to surface any overlooked sub-segments with latent growth potential.

---

## 📂 Project Structure
```
├── .env
├── .gitignore
├── Retail_Data_Ingestion_and_ETL.ipynb
├── data/
│   ├── online_retail_II.xlsx
├── scripts/
│   ├── 01_setup_and_cleaning.sql       # Data sanitization & ledger alignment
│   ├── 02_rfm_segmentation.sql         # Scoring & 9-tier segment assignment
│   ├── 03_cohort_analysis.sql          # 12-month retention & decay matrices
│   ├── 04_financial_impact.sql         # Pareto & Revenue-at-Risk modeling
│   └── 05_pareto_and_predictive_clv.sql # Forward-looking lifetime value forecasts
```

---

**Author:** Jing Wang  

**Tools:** PostgreSQL · DBeaver · Tableau