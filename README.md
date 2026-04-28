# 🛍️ Online Retail II — Customer Analytics

> A comprehensive end-to-end customer analytics project built on the UCI Online Retail II dataset, covering RFM segmentation, churn analysis, CLV prediction, cohort retention, Pareto analysis, seasonality, product analysis, segment migration, and win-back analysis.

---

## 📌 Project Purpose

This project aims to transform raw transactional retail data into actionable business intelligence. By applying a structured analytics pipeline — from data cleaning through to predictive modelling — the goal is to answer key business questions:

- Who are the most valuable customers, and how concentrated is revenue?
- Which customers are at risk of churning, and how much revenue is at stake?
- How do customer segments behave over time, and do they migrate between segments?
- What is the predicted lifetime value of each customer segment?
- When is the optimal moment to intervene with a win-back campaign?
- What seasonal and product patterns underpin the business?

---

## 📊 Dashboard

An interactive Tableau dashboard has been built to visualise the RFM segmentation findings.

| Dashboard | Link |
|-----------|------|
| **RFM Analysis — Target Marketing Strategies** | [View on Tableau Public](https://public.tableau.com/app/profile/jing.wang8227/viz/RFMAnalysisforTargetMarketingStrategies/Dashboard1) |

### Dashboard Structure & Features

The dashboard is organised into three pages with a global Customer Segment filter and navigation buttons:

**Page 1 — Customer Overview**
- **KPI strip** — Total customers, avg recency, avg frequency, avg monetary
- **Treemap** — Customer distribution across all 11 RFM segments (acts as interactive filter)
- **Scatter plot (RFM Values)** — Avg recency days vs avg monetary per segment, sized by avg frequency; with 90-day churn threshold reference line
- **Scatter plot (RFM Scores)** — Avg R score vs avg M score per segment, sized by avg F score; same concept using normalised 1–5 scores
- **Customer list table** — Individual customer view with RFM score, recency, frequency and monetary bar

**Page 2 — What Are They Worth?**
- **KPI strip** — Total revenue, total orders, avg CLV, avg AOV
- **Segment performance comparison** — Customer share %, revenue share %, order share % and AOV for the selected segment vs all others; updates dynamically via segment parameter selector
- **Summary text table** — Full segment breakdown showing total customers, customer share %, total orders, order share %, total revenue, revenue share %, avg recency, avg frequency and avg monetary; provides stakeholders with a complete at-a-glance reference

**Page 3 — Risk + Action Plan**
- **KPI strip** — Revenue at risk, churned customers, avg churn rate
- **Bubble chart** — Revenue at risk by segment; bubble size represents total revenue lost; acts as interactive filter
- **Top 10 at-risk customers bar chart** — Updates dynamically when a segment bubble is clicked; shows highest-value churned customers within the selected segment
- **Scatter plot** — Churn rate vs avg monetary per segment; reveals which segments combine high value with high churn risk
- **Urgency & win-back strategy table** — Summarises urgency level per segment and recommended win-back tactics; designed as a stakeholder-ready action reference

---

## 📂 Data Source

| Property | Details |
|----------|---------|
| **Dataset** | UCI Online Retail II |
| **Source** | [UCI Machine Learning Repository](https://archive.ics.uci.edu/ml/datasets/Online+Retail+II) |
| **Period** | December 2009 – December 2011 |
| **Records** | ~1,067,371 transactions |
| **Business** | UK-based online gift and novelty retailer |
| **Geography** | Primarily UK (83.8%), with 40 international markets |

### Raw Schema

| Column | Description |
|--------|-------------|
| `Invoice` | Invoice number (prefix `C` = cancellation/return) |
| `StockCode` | Product code |
| `Description` | Product description |
| `Quantity` | Units per transaction |
| `InvoiceDate` | Date and time of transaction |
| `Price` | Unit price in GBP |
| `Customer ID` | Unique customer identifier |
| `Country` | Customer country |

---

## 🛠️ Technical Stack

| Layer | Tool |
|-------|------|
| **Data Storage & Querying** | PostgreSQL |
| **Data Analysis & Modelling** | Python (pandas, numpy) |
| **Visualisation** | Tableau |

---

## 🏗️ Data Pipeline

```
Raw Data (online_retail_ii)
        │
        ▼
Phase 1: Data Preparation
  - Rename columns (snake_case)
  - Filter nulls, returns, invalid prices/quantities
  - Exclude non-product stock codes
  - Derive total_price column
        │
        ▼
cleaned_retail_main (Gold Dataset)
        │
        ▼
Phase 2: RFM Segmentation → rfm_segment_analysis_whole_period (Centre Table)
        │
        ├──► Phase 3: Churn & Retention Analysis
        ├──► Phase 4A: Segment Yield & Profitability
        ├──► Phase 4B: Revenue at Risk
        ├──► Phase 5A: Pareto Analysis
        ├──► Phase 5B: Predictive CLV
        ├──► Phase 6: Seasonality Analysis
        ├──► Phase 7: Product Analysis
        ├──► Phase 8: Segment Migration
        └──► Phase 9: Win-back Analysis
```

### Cleaning Rules Applied

| Rule | Reason |
|------|--------|
| `customer_id IS NOT NULL` | Removes ~25% of rows unusable for customer analysis |
| `price > 0` | Removes zero-price administrative entries |
| `quantity > 0` | Removes returns and negative adjustments |
| `invoice NOT LIKE 'C%'` | Excludes cancellation invoices |
| Stock code exclusions | Removes non-product codes: `POST`, `D`, `M`, `DOT`, `CRUK`, `BANK CHARGES`, `ADJUST`, `ADJUST2` |

---

## 🗺️ Project Roadmap

| Phase | Analysis | Output Table(s) |
|-------|----------|----------------|
| **1** | Data Preparation & Cleaning | `cleaned_retail_main` |
| **2** | RFM Segmentation | `rfm_segment_analysis_whole_period`, `rfm_segment_summary` |
| **3** | Churn & Cohort Retention | `churned_or_not`, `churn_and_retention_rate_by_cohort`, `retention_rates_by_rfm_segments` |
| **4A** | Segment Yield & Profitability | `segment_yield_and_profitability` |
| **4B** | Revenue at Risk & Attrition | `revenue_at_risk_and_segment_attrition` |
| **5A** | Pareto Analysis | `pareto_analysis` |
| **5B** | Predictive CLV | `predictive_clv_analysis` |
| **6** | Seasonality Analysis | `monthly_revenue_trends`, `monthly_new_customers`, `revenue_by_month_of_year` |
| **7** | Product Analysis | `top_products_by_revenue`, `product_return_analysis`, `revenue_by_price_band` |
| **8** | Segment Migration | `segment_migration`, `segment_migration_summary` |
| **9** | Win-back Analysis | `winback_analysis`, `winback_summary` |

---

## 📐 RFM Segmentation Standard

RFM scores are calculated using `NTILE(5)` on the whole-period dataset, with a reference date of `MAX(invoice_date) + 1 day`. Segmentation follows the **RFM.io / Putler industry standard** using exact `rfm_combined` score mappings.

| Dimension | NTILE Order | Score 5 Means |
|-----------|-------------|--------------|
| **Recency** | `ORDER BY recency_days DESC` | Purchased very recently |
| **Frequency** | `ORDER BY frequency ASC` | Purchases very often |
| **Monetary** | `ORDER BY monetary ASC` | Spends the most |

### Segment Definitions

Segments are assigned using exact `rfm_combined` score mappings (RFM.io / Putler standard):

| Segment | RFM Score Combinations |
|---------|----------------------|
| **Champions** | 555, 554, 544, 545, 454, 455, 445 |
| **Loyal** | 543, 444, 435, 355, 354, 345, 344, 335 |
| **Potential Loyalists** | 553, 551, 552, 541, 542, 533, 532, 531, 452, 451, 442, 441, 431, 453, 433, 432, 423, 353, 352, 351, 342, 341, 333, 323 |
| **Recent Customers** | 512, 511, 422, 421, 412, 411, 311 |
| **Promising** | 525, 524, 523, 522, 521, 515, 514, 513, 425, 424, 413, 414, 415, 315, 314, 313 |
| **Need Attention** | 535, 534, 443, 434, 343, 334, 325, 324 |
| **About to Sleep** | 331, 321, 312, 221, 213 |
| **At-Risk** | 255, 254, 245, 244, 253, 252, 243, 242, 235, 234, 225, 224, 153, 152, 145, 143, 142, 135, 134, 133, 125, 124 |
| **Cannot Lose** | 155, 154, 144, 214, 215, 115, 114, 113 |
| **Hibernating** | 332, 322, 231, 241, 251, 233, 232, 223, 222, 132, 123, 122, 212, 211 |
| **Lost** | 111, 112, 121, 131, 141, 151 |
| **General/Other** | All remaining combinations |

### Macro Segments

For strategic planning, segments are grouped into four macro categories:

| Macro Segment | Segments |
|---------------|---------|
| **Loyal** | Champions, Loyal, Potential Loyalists |
| **Promising** | Recent Customers, Promising, Need Attention |
| **At Risk** | About to Sleep, At-Risk, Cannot Lose |
| **Lost** | Hibernating, Lost |

### Segment Summary

| Segment | Customers | % Customers | % Revenue | Avg Monetary | Avg Recency (days) | AOV |
|---------|-----------|-------------|-----------|--------------|-------------------|-----|
| Champions | 1,139 | 19.46% | 66.70% | £10,217 | 17.4 | £554 |
| Loyal | 666 | 11.38% | 11.97% | £3,136 | 74.2 | £402 |
| At-Risk | 496 | 8.47% | 7.91% | £2,783 | 358.5 | £486 |
| Cannot Lose | 118 | 2.02% | 1.46% | £2,157 | 490.4 | £475 |
| Promising | 175 | 2.99% | 1.95% | £1,943 | 32.1 | £1,245 |
| Need Attention | 322 | 5.50% | 2.76% | £1,495 | 68.5 | £367 |
| Potential Loyalists | 591 | 10.10% | 2.52% | £743 | 54.2 | £231 |
| Hibernating | 938 | 16.03% | 2.71% | £504 | 326.3 | £244 |
| About to Sleep | 361 | 6.17% | 0.62% | £302 | 208.1 | £247 |
| Recent Customers | 318 | 5.43% | 0.46% | £251 | 46.7 | £211 |
| Lost | 729 | 12.46% | 0.95% | £227 | 564.3 | £204 |

---

## 🔑 Key Findings

### 1. Revenue Concentration is Extreme

- **Champions** (19.46% of customers) generate **66.7% of total revenue** at £10,217 average spend
- The **top 1%** (58 customers) account for **31.93%** of total revenue
- The **top 20%** of customers drive **77.17%** of revenue
- The **bottom 50%** of customers contribute just **6.47%** of revenue

### 2. The Business Faces Severe Retention Pressure

- **£3.38M** in revenue is at risk from churned customers
- At-Risk (40.81%) and Loyal (23.99%) account for **64.8% of all lost revenue**
- At-Risk and Cannot Lose segments have **100% churn rate** — all customers inactive 90+ days
- Champions show **0% churn** — the only fully active segment

### 3. Cannot Lose Segment is the Most Urgent Target

- Cannot Lose customers average **490 days** since last purchase — highest recency of any valuable segment
- Despite high average monetary (£2,157) and AOV (£475), all 118 customers have churned
- Combined At-Risk + Cannot Lose represents **£1.63M** in lost revenue from high-value disengaging customers

### 4. Promising Segment Has Surprisingly High AOV

- Despite being a low-frequency segment (avg 1.56 orders), Promising customers have the **highest AOV at £1,245**
- Predicted CLV of £14,011 (second highest) driven by high AOV and low churn rate (6.86%)
- These are high-value occasional buyers worth targeting with re-engagement campaigns

### 5. CLV Concentration Mirrors Revenue Concentration

| Segment | Predicted CLV | AOV | Churn Rate |
|---------|--------------|-----|------------|
| Champions | £106,057 | £554 | 4.76% (floored) |
| Promising | £14,011 | £1,245 | 6.86% |
| Loyal | £4,873 | £402 | 31.83% |
| Need Attention | £2,706 | £367 | 27.33% |
| Potential Loyalists | £1,939 | £231 | 18.95% |
| At-Risk | £1,390 | £486 | 99% |
| Recent Customers | £1,161 | £211 | 10.69% |
| Cannot Lose | £1,078 | £475 | 99% |
| Hibernating | £261 | £244 | 95.42% |
| About to Sleep | £198 | £247 | 75.35% |
| Lost | £113 | £204 | 99% |

### 6. Seasonality is Structural and Predictable

- Q4 (September–November) consistently generates the highest revenue, peaking in November
- The August → September jump is the sharpest of the year at **+42% month-over-month**
- January and February are consistently the weakest months, dropping **20–35% from December**
- The pattern repeats reliably across both years — driven by the gift/novelty nature of the catalog

### 7. The Business is a High-Volume, Low-Price Model

- **66.94% of revenue** comes from products priced £1–£5
- No single product exceeds **1.64% of total revenue** — healthy catalog diversification
- Premium products (£20+) represent less than **1.2% of revenue** despite 93 SKUs

### 8. International Customers Are Fewer but More Valuable

- Non-UK customers (519) have an AOV of **£36 vs £20 for UK** customers — 78% higher
- Netherlands (£110), Australia (£93), Japan (£97), and Denmark (£88) are the highest-value international markets
- Sample sizes outside the UK are too small for RFM/CLV segmentation but the AOV gap is commercially significant

### 9. Win-back is Commercially Worthwhile but Time-Sensitive

- **3,025 win-back events** generated **£7.77M** in recovered revenue
- Post-winback revenue drops sharply with gap length:

| Gap | Customers | Avg Revenue After Win-back |
|-----|-----------|--------------------------|
| 91–120 days | 1,202 | £2,143 |
| 121–180 days | 1,326 | £1,452 |
| 181–365 days | 1,437 | £1,151 |
| 365+ days | 320 | £449 |

- **Day 91** is the optimal win-back trigger — customers returning within 91–120 days generate nearly **5× more** than those returning after 365+ days

---

## 💡 Actionable Recommendations

### Marketing Budget Allocation

| Segment | Priority | Budget % | Goal |
|---------|----------|---------|------|
| Champions | Tier 1 — Protect | 30–35% | Retention & VIP programme |
| At-Risk | Tier 2 — Recover | 20–25% | Day-91 win-back campaign |
| Cannot Lose | Tier 2 — Recover | 10–15% | Urgent personal outreach |
| Loyal | Tier 3 — Nurture | 8–10% | Sustain & upsell |
| Potential Loyalists | Tier 3 — Develop | 5–8% | Drive 2nd/3rd purchase |
| Promising | Tier 3 — Develop | 5–8% | Re-engagement — high AOV |
| Need Attention | Tier 4 — Monitor | 3–5% | Re-engagement campaigns |
| Recent Customers | Tier 4 — Develop | 2–3% | Onboarding & 2nd purchase |
| About to Sleep | Tier 5 — Minimal | 1–2% | Single reactivation attempt |
| Hibernating | Tier 5 — Minimal | 1% | Annual touch only |
| Lost | Tier 5 — Minimal | 0–1% | Write-off or final attempt |

### Specific Recommendations

1. **Protect Champions at all costs** — 19.46% of customers generate 66.7% of revenue. VIP rewards, early access, and personal account management are justified.
2. **Trigger win-back campaigns at day 91** — avg £2,143 recovered vs £449 after 365+ days — a 5× difference.
3. **Act immediately on Cannot Lose** — all 118 customers have churned despite averaging £2,157 spend. Personal outreach is warranted.
4. **Re-engage Promising customers** — highest AOV at £1,245 and second-highest predicted CLV at £14,011. Only 6.86% churn rate makes these highly recoverable.
5. **Develop Potential Loyalists within 3 months** — retention drops sharply from month 3; early incentives to drive repeat purchase are critical.
6. **Deprioritise Hibernating and Lost** — 95%+ churn rate and low post-winback value makes sustained investment commercially unjustifiable.
7. **Plan campaigns around seasonality** — September is the optimal launch month for retention campaigns, capturing the natural Q4 uplift before peak.
8. **Investigate wholesale/B2B customers** — the extreme Pareto concentration (top 1% = 31.93% of revenue) suggests a B2B segment within the data that warrants separate treatment.
9. **Experimental international budget** — allocate 2–3% outside main budget to Netherlands, Australia, and Japan given their significantly higher AOV.

---

## 📁 Project Structure

```
online-retail-ii-analytics/
│
├── data/
│   └── online_retail_ii.csv                        # Raw dataset (not included, see Data Source)
│
├── sql/
│   ├── 01_setup_and_cleaning.sql                   # Phase 1: Cleaning & gold dataset
│   ├── 02_rfm_segmentation.sql                     # Phase 2: RFM scoring & segmentation
│   ├── 03_churn_retention.sql                      # Phase 3: Churn flag & cohort analysis
│   ├── 04a_segment_profitability.sql               # Phase 4A: Yield & profitability
│   ├── 04b_revenue_at_risk.sql                     # Phase 4B: Revenue at risk & attrition
│   ├── 05a_pareto_analysis.sql                     # Phase 5A: Pareto / revenue concentration
│   ├── 05b_predictive_clv.sql                      # Phase 5B: Predictive CLV
│   ├── 06_seasonality.sql                          # Phase 6: Monthly & seasonal trends
│   ├── 07_product_analysis.sql                     # Phase 7: Product revenue & returns
│   ├── 08_segment_migration.sql                    # Phase 8: Year-on-year segment migration
│   └── 09_winback_analysis.sql                     # Phase 9: Win-back events & recovery
│
├── notebooks/
│   └── Retail_Data_Ingestion_and_ETL.ipynb         # Python data ingestion & ETL pipeline
│
├── visualisations/
│   └── RFM Analysis for Target Marketing Strategies# Tableau dashboard (RFM Analysis)
│
└── README.md                                        # This file
```

---

## ⚙️ Technical Notes

### Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Reference date: `MAX(invoice_date) + 1 day` | Ensures the most recent customer gets recency > 0; consistent across all phases |
| Whole-period RFM (not yearly) | One segment per customer based on full dataset; avoids duplication and supports CLV/AOV calculations |
| `rfm_combined IN (...)` segmentation | Exact industry-standard score mappings; eliminates overlap and ambiguity from conditional CASE logic |
| Churn threshold: 90 days (Phase 3 & 4B) | Standard retail inactivity window; actionable and consistent |
| NTILE(5) for RFM scoring | Produces equal-sized quintile buckets; robust to skewed distributions |
| `NUMERIC` casting at source | Prevents PostgreSQL `ROUND(double precision, integer)` type errors throughout |
| `CROSS JOIN` for reference date | Explicit and readable alternative to correlated subqueries |
| `GREATEST(churn_rate, 0.001)` floor | Prevents division by zero in CLV formula for fully active segments |

### Known Data Quality Issues

- **Return rate anomalies**: Some products show return rates exceeding 100% due to cancellation invoices referencing sales that predate the dataset window.
- **December 2011 incomplete**: The dataset ends partway through December 2011, making that month's figures non-comparable to prior Decembers.
- **December 2009 acquisition spike**: The dataset starts in December 2009, causing all pre-existing customers to appear as new acquisitions in that month — a data artifact, not a real spike.
- **Wholesale/B2B outliers**: Extremely high single-order quantities suggest the presence of wholesale buyers within the otherwise retail dataset.
- **Champions CLV**: Champions show 0% observed churn — the 0.001 floor produces an illustrative CLV of £106,057. Historical average revenue (Phase 4A) is a more reliable value indicator for this segment.

---

## 📊 CLV Formula

```
CLV = (Average Order Value × Purchase Frequency) / Churn Rate

Where:
  Average Order Value  = Segment Total Revenue / Segment Total Orders
  Purchase Frequency   = Average annual orders per customer in segment
  Churn Rate           = % of customers with no purchase in last 90 days
  Customer Lifespan    = 1 / Churn Rate (in years)
```

> For segments with 0% churn, a floor of 0.001 (0.1%) is applied to allow the formula to compute. Results for these segments should be treated as illustrative rather than predictive.

---

## 👤 Author

Built as a personal portfolio project demonstrating end-to-end customer analytics using SQL, Python, and Tableau.

---

## 📜 License

This project is for educational and portfolio purposes. The underlying dataset is publicly available via the UCI Machine Learning Repository under their standard terms.