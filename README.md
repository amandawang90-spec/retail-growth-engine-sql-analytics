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
| **RFM Analysis — Customer Segmentation** | [View on Tableau Public](https://public.tableau.com/app/profile/jing.wang8227/viz/RMFAnalysisDashboard/RMFAnalysisDashboard) |

### Dashboard Structure & Features

The dashboard is organised into four sections with global Segment and Year filters:

**Section 1 — KPI Overview**
- Total customers, total orders, total revenue with year-over-year comparisons and sparklines
- Avg recency, avg frequency, avg monetary as summary cards

**Section 2 — Segment Overview**
- **Treemap** — Customer distribution across all 10 RFM segments with RFM standard tooltip
- **Scatter plot** — Avg R Score vs Avg M Score per segment, sized by bubble; toggle between raw RFM values and avg RFM scores

**Section 3 — Revenue & Profitability**
- **Parameterised bar chart** — Compare segments across total orders, total revenue, average revenue, average order value, and predicted CLV via a selector
- **Combo chart (bar + line)** — Segment profitability showing % of customer base as bars and cumulative % of revenue as a line; switchable with a Pareto curve via chart selector

**Section 4 — Churn & Risk**
- **Bubble chart** — Revenue at risk by segment, bubble size represents revenue lost; filtered to churned segments only
- **Churn rate heatmap** — Monthly churn rate per segment over 12 months with churn rate category filter (All / Low / Medium / High / Critical)

**Section 5 — Geography & Win-back**
- **Map** — Customer distribution by country with segment breakdown tooltip
- **Donut chart** — UK vs Non-UK split by total revenue with customer count and AOV details
- **Dot chart** — Win-back value by gap length (91–120, 121–180, 181–365, 365+ days) with insight annotation

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
        ├──► Phase 2: RFM Segmentation
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
| **2** | RFM Segmentation | `customer_rfm_segmented`, `customer_rfm_segmentation_summary` |
| **3** | Churn & Cohort Retention | `churned_or_not`, `churn_and_retention_rate_by_cohort` |
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

RFM scores are calculated using `NTILE(5)` on the cleaned dataset, with a reference date of `MAX(invoice_date) + 1 day`.

| Dimension | Score Direction | Score 5 Means |
|-----------|----------------|--------------|
| **Recency** | DESC (fewest days = highest score) | Purchased very recently |
| **Frequency** | ASC (highest count = highest score) | Purchases very often |
| **Monetary** | ASC (highest spend = highest score) | Spends the most |

### Segment Definitions

Segments are assigned using a `CASE` statement ordered from most specific to least specific to prevent overlap:

| Segment | R Score | F Score | M Score |
|---------|---------|---------|---------|
| **Lost** | = 1 | = 1 | = 1 |
| **Hibernating** | = 1 | 1–2 | 1–2 |
| **At-Risk** | ≤ 2 | ≥ 3 | ≥ 3 |
| **Needs Attention** | 2–3 | ≥ 3 | — |
| **Promising** | ≥ 4 | 1–2 | — |
| **Potential Loyalists** | ≥ 4 | 2–3 | ≥ 3 |
| **Big Spenders** | — | ≤ 3 | ≥ 4 |
| **Champions** | ≥ 4 | ≥ 4 | ≥ 4 |
| **Loyal** | ≥ 3 | ≥ 4 | ≥ 3 |
| **General/Other** | — | — | — |

> ⚠️ **CASE order matters.** Always place most specific conditions first (Lost before Hibernating, Champions before Loyal) to prevent overlapping segment assignment.

---

## 🔑 Key Findings

### 1. Revenue Concentration is Extreme
- Champions (22% of customers) generate **68.4% of total revenue** at £9,208 average spend — far exceeding the classic 80/20 Pareto rule
- The top 10% of customers drive **51.98% of revenue**; the top 1% (59 customers) alone account for **32.09%**
- A single customer spent **£608,821** — likely a wholesale/B2B buyer representing 3.49% of total revenue
- The bottom 50% of customers contribute just **6.46% of revenue**

### 2. The Business Faces Growing Retention Pressure
- **£3.38M in revenue** has already been lost to churned customers
- At-Risk (46%) and Needs Attention (31.5%) account for **77.55% of all lost revenue**
- New customer acquisition declined **~50% from 2010 to 2011** (280 → 130 new customers/month)
- Revenue remained stable, meaning **existing customers are compensating** — making retention business-critical
- Only **10.5% of customers** remained in the same RFM segment across both years; downgraded customers (21%) slightly outnumber upgraded ones (20%)

### 3. At-Risk and Big Spenders Are the Most Urgent Targets
- At-Risk customers average £2,532 spend but haven't purchased in **355 days** — 100% churn rate
- Big Spenders have the highest AOV at **£1,613 per order** but 78.57% have already churned; only 18 remain active
- Combined these two segments represent **£1.73M in revenue from actively disengaging customers**

### 4. Segment Labels Don't Always Reflect Behaviour
- **Loyal** customers show a retention decline from 27.6% → 8.6% over 12 months — weaker than Champions and At-Risk in early months
- **Potential Loyalists** fail to convert — retention drops from 25.8% → 2.4% by month 10
- **Promising** customers are largely one-time buyers — retention falls below 1% by month 10
- **Needs Attention** is the most volatile and recoverable segment with balanced upgrade/downgrade rates

### 5. Seasonality is Structural and Predictable
- Q4 (September–November) consistently generates the highest revenue, peaking in November
- The August → September jump is the sharpest of the year at **+42% month-over-month**
- January and February are consistently the weakest months, dropping **20–35% from December**
- The pattern repeats reliably across both years — driven by the gift/novelty nature of the catalog

### 6. The Business is a High-Volume, Low-Price Model
- **66.94% of revenue** comes from products priced £1–£5
- No single product exceeds **1.64% of total revenue** — healthy catalog diversification
- Premium products (£20+) represent less than **1.2% of revenue** despite 93 SKUs

### 7. International Customers Are Fewer but More Valuable
- Non-UK customers (519) have an AOV of **£36 vs £20 for UK** customers — 78% higher
- Netherlands (£110), Australia (£93), Japan (£97), and Denmark (£88) are the highest-value international markets
- Sample sizes outside the UK are too small for RFM/CLV segmentation but the AOV gap is commercially significant

### 8. Win-back is Commercially Worthwhile but Time-Sensitive
- **3,025 win-back events** generated **£7.77M** in recovered revenue
- Post-winback revenue drops sharply with gap length:

| Gap | Customers | Avg Revenue After Winback |
|-----|-----------|--------------------------|
| 91–120 days | 1,202 | £2,143 |
| 121–180 days | 1,326 | £1,452 |
| 181–365 days | 1,437 | £1,151 |
| 365+ days | 320 | £449 |

- **Day 91** is the optimal win-back trigger — customers returning within 91–120 days generate nearly **5x more** than those returning after 365+ days

---

## 💡 Actionable Recommendations

### Marketing Budget Allocation

| Segment | Priority | Budget % | Goal |
|---------|----------|---------|------|
| Champions | Tier 1 — Protect | 30–35% | Retention |
| Needs Attention | Tier 2 — Recover | 25–30% | Re-engagement |
| At-Risk | Tier 2 — Recover | 15–20% | Win-back |
| Potential Loyalists | Tier 3 — Develop | 8–10% | Upgrade |
| Promising | Tier 3 — Develop | 5–8% | 2nd purchase |
| Big Spenders | Tier 4 — Selective | 3–5% | Personal outreach |
| General/Other | Tier 4 — Monitor | 2–3% | Low-cost campaigns |
| Loyal | Tier 5 — Passive | 1–2% | Standard comms |
| Hibernating | Tier 5 — Minimal | 1% | Single reactivation |
| Lost | Tier 5 — Minimal | 0–1% | Annual touch only |

### Specific Recommendations

1. **Protect Champions at all costs** — 68.4% of revenue depends on 22% of customers. Any Champions retention programme has outsized ROI.
2. **Trigger win-back campaigns at day 91** — the optimal intervention point before post-winback value deteriorates significantly.
3. **Prioritise Needs Attention for re-engagement** — highest recoverable revenue pool with the most balanced upgrade/downgrade split.
4. **Act immediately on Big Spenders** — only 18 remain active. Each lost Big Spender represents ~£2,579 in revenue.
5. **Deprioritise Hibernating and Lost** — retention below 4% and diminishing post-winback value makes investment commercially unjustifiable.
6. **Plan campaigns around seasonality** — September is the optimal launch month for retention campaigns, capturing the natural Q4 uplift before peak.
7. **Investigate wholesale/B2B customers** — the extreme Pareto concentration and single-customer outlier (£608,821) suggests a B2B segment exists within the data that warrants separate treatment.
8. **Intervene with Potential Loyalists within 3 months** — retention drops sharply from month 3 onward; early engagement is critical.
9. **Experimental international budget** — allocate 2–3% outside main budget to Netherlands, Australia, and Japan given their significantly higher AOV.

---

## 📁 Project Structure

```
online-retail-ii-analytics/
│
├── data/
│   └── online_retail_ii.csv                        # Raw dataset (not included, see Data Source)
│
├── pipeline/
│   ├── Retail_Data_Ingestion_and_ETL.ipynb         # Python data ingestion & ETL pipeline
│   └── sql_scripts/
│       ├── 01_setup_and_cleaning.sql               # Phase 1: Cleaning & gold dataset
│       ├── 02_rfm_segmentation.sql                 # Phase 2: RFM scoring & segmentation
│       ├── 03_churn_retention.sql                  # Phase 3: Churn flag & cohort analysis
│       ├── 04a_segment_profitability.sql           # Phase 4A: Yield & profitability
│       ├── 04b_revenue_at_risk.sql                 # Phase 4B: Revenue at risk & attrition
│       ├── 05a_pareto_analysis.sql                 # Phase 5A: Pareto / revenue concentration
│       ├── 05b_predictive_clv.sql                  # Phase 5B: Predictive CLV
│       ├── 06_seasonality.sql                      # Phase 6: Monthly & seasonal trends
│       ├── 07_product_analysis.sql                 # Phase 7: Product revenue & returns
│       ├── 08_segment_migration.sql                # Phase 8: Year-on-year segment migration
│       └── 09_winback_analysis.sql                 # Phase 9: Win-back events & recovery
│
├── visualisations/
│   └── RMFAnalysisDashboard.twb                   # Tableau dashboard (RFM Analysis)
│
└── README.md                                        # This file
```

---

## ⚙️ Technical Notes

### Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Reference date: `MAX(invoice_date) + 1 day` | Ensures the most recent customer gets recency > 0; consistent across all phases |
| Churn threshold: 90 days (Phase 3 & 4B) | Standard retail inactivity window; actionable and consistent |
| Churn threshold: 180 days (Phase 5B CLV) | Smooths Christmas seasonality noise for stable CLV formula inputs |
| NTILE(5) for RFM scoring | Produces equal-sized quintile buckets; robust to skewed distributions |
| `NUMERIC` casting at source | Prevents PostgreSQL `ROUND(double precision, integer)` type errors throughout |
| `CROSS JOIN` for reference date | Explicit and readable alternative to correlated subqueries |
| `GREATEST(churn_rate, 0.001)` floor | Prevents division by zero in CLV formula for fully active segments |

### Known Data Quality Issues

- **Return rate anomalies**: Some products show return rates exceeding 100% due to cancellation invoices referencing sales that predate the dataset window. Return rates are capped at 100% and should be interpreted with caution.
- **December 2011 incomplete**: The dataset ends partway through December 2011, making that month's figures non-comparable to prior Decembers.
- **December 2009 acquisition spike**: The dataset starts in December 2009, causing all pre-existing customers to appear as new acquisitions in that month — a data artifact, not a real spike.
- **Wholesale/B2B outliers**: Extremely high single-order quantities (e.g. 80,995 units of a single product in one invoice) suggest the presence of wholesale buyers within the otherwise retail dataset.
- **CLV formula limitation**: Segments with 0% observed churn within the 180-day window hit the 0.001 floor, producing a capped CLV of £3,000. For these segments, historical average revenue (Phase 4A) is a more reliable value indicator.

---

## 📊 CLV Formula

```
CLV = (Average Order Value × Purchase Frequency) / Churn Rate

Where:
  Average Order Value  = Segment Total Revenue / Segment Total Orders
  Purchase Frequency   = Average orders per customer in segment
  Churn Rate           = % of customers with no purchase in last 180 days
  Customer Lifespan    = 1 / Churn Rate (in 180-day cycles)
```

> For segments with 0% churn, a floor of 0.001 (0.1%) is applied to allow the formula to compute. Results for these segments should be treated as illustrative rather than predictive.

---

## 👤 Author

Built as a personal portfolio project demonstrating end-to-end customer analytics using SQL, Python, and Tableau.

---

## 📜 License

This project is for portfolio purposes. The underlying dataset is publicly available via the UCI Machine Learning Repository under their standard terms.
