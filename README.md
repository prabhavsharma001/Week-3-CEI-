# 🛒 Superstore Sales Analysis — SQL Deep Dive

> **Advanced SQL concepts applied to the Sample Superstore dataset**

![Python](https://img.shields.io/badge/Python-3.10%2B-blue?logo=python)
![SQLite](https://img.shields.io/badge/SQLite-3.45-lightblue?logo=sqlite)
![Jupyter](https://img.shields.io/badge/Jupyter-Notebook-orange?logo=jupyter)
![License](https://img.shields.io/badge/License-MIT-green)

---

## 📌 Objective

Analyse the Superstore dataset using advanced SQL — covering **Subqueries**, **CTEs**, and **Window Functions** — to answer real business questions about customer behaviour, regional performance, and sales trends.

---

## 📁 Repository Structure

```
superstore_sql_analysis/
│
│
├── superstore_analysis.sql           # Pure SQL script (all queries)
├── superstore_analysis.ipynb         # Jupyter Notebook (clean, no outputs)
├── superstore_analysis_executed.ipynb# Notebook WITH all outputs & charts
│
└── README.md                         # This file
```

---

## 🗃️ Dataset

| Field | Value |
|-------|-------|
| **Source** | [Kaggle – Superstore Dataset](https://www.kaggle.com/datasets/vivek468/superstore-dataset-final) |
| **Rows** | 9,994 |
| **Customers** | 793 |
| **Date Range** | 2014 – 2017 |
| **Columns** | 21 (Order ID, Sales, Profit, Segment, Region, Category, …) |

### Normalised Schema

```
superstore_raw   ← master fact table (9,994 rows)
     │
     ├── customers   (793 rows)  customer_id · customer_name · segment
     ├── orders      (9,994 rows) order_id · dates · ship_mode · region
     └── products    (distinct)  product_id · name · category · sub_category
```

---

## 🔑 SQL Concepts Covered

### 2. Subqueries
| Query | Description |
|-------|-------------|
| 2-A | Filter orders with **above-average sales** |
| 2-B | **Highest single order** per customer (correlated subquery) |
| 2-C | Products **never discounted** (NOT IN subquery) |
| 2-D | Customers whose spend **exceeds the per-customer average** |

### 3. CTEs (Common Table Expressions)
| Query | Description |
|-------|-------------|
| 3-A | **Customer summary** — total sales, profit, orders, margin |
| 3-B | **Category & sub-category** breakdown with % of category |
| 3-C | **Monthly trend** with YoY growth using LAG inside CTE |

### 4. Window Functions
| Function | Query | Use Case |
|----------|-------|----------|
| `ROW_NUMBER` | 4-A | Unique rank within segment |
| `RANK` | 4-A | Tie-aware rank, gaps |
| `DENSE_RANK` | 4-A | Tie-aware rank, no gaps |
| `SUM() OVER` | 4-B | Cumulative / running total |
| `AVG() OVER` | 4-B | 3-month moving average |
| `PERCENT_RANK` | 4-C | Customer sales percentile |
| `NTILE(4)` | 4-C | Quartile segmentation |
| `LAG / LEAD` | 4-D | Order-to-order delta |

### 5. Combined: JOIN + CTE + Window
Full **customer leaderboard** with overall rank, segment rank, tier label, and % of total sales.

### 6. Business Queries
| # | Question |
|---|----------|
| BQ-1 | Top 10 customers by revenue |
| BQ-2 | Bottom 10 customers (lowest revenue) |
| BQ-3 | Low-engagement customers (≤3 orders) |
| BQ-4 | Above-average sales orders with context |
| BQ-5 | Region-wise profitability |
| BQ-6 | Year-over-year growth by category |
| BQ-7 | Ship mode efficiency (avg days + revenue) |

---

## 💡 Key Insights

1. **Top 10 customers** generate a disproportionate revenue share — Champions need retention focus.
2. **Low-engagement customers** (≤3 orders) are prime re-engagement targets.
3. **Technology** has the highest per-order value but thinner, volatile margins.
4. **Q4 (Oct–Dec)** is a consistent revenue spike — stock up in September.
5. **Corporate & Home Office** segments produce above-average order values.
6. **West & East** lead in absolute sales; **Standard Class** handles most volume.
7. `LAG/LEAD` windows pinpoint customers with declining spend — trigger win-back flows.

---

## 🚀 How to Run

### Option A — Jupyter Notebook
```bash
# Install dependencies
pip install pandas matplotlib seaborn jupyter

# Launch notebook
jupyter notebook superstore_analysis_executed.ipynb
```

### Option B — Pure SQL (SQLite CLI)
```bash
sqlite3 superstore.db < superstore_analysis.sql
```

### Option C — PostgreSQL
```sql
-- Adjust date functions: STRFTIME('%Y',…) → EXTRACT(YEAR FROM …)
-- JULIANDAY(…) → date_part('day', ship_date - order_date)
\i superstore_analysis.sql
```

---

## 📊 Sample Outputs

### Customer Leaderboard (Section 5)
```
overall_rank | customer_name      | segment   | total_sales | customer_tier
-------------|--------------------|-----------|---------    |---------------
           1 | Sean Miller        | Consumer  |  25,043.05  | 🏆 Champion
           2 | Tamara Chand       | Corporate |  19,052.22  | 🏆 Champion
           …
```

### Region Profitability (BQ-5)
```
region  | total_sales  | profit_margin_pct | profit_rank
--------|--------------|-------------------|------------
West    |  725,457.82  |  12.47%           |  1
East    |  678,781.24  |  11.23%           |  2
Central |  501,239.89  |   4.82%           |  3
South   |  391,721.91  |   6.14%           |  4
```

---

## 🛠️ Tech Stack

- **Database:** SQLite 3.45 (queries also compatible with PostgreSQL / MySQL)
- **Language:** Python 3.10+
- **Libraries:** `pandas` · `matplotlib` · `seaborn` · `sqlite3` (stdlib)
- **Notebook:** Jupyter

---

## 📜 License
MIT — free to use, share, and adapt with attribution.

---

## 📓 Assignment-Specific Files

| File | Description |
|------|-------------|
| `superstore_assignment_executed.ipynb` | ⭐ Assignment notebook with all outputs |
| `superstore_assignment.ipynb` | Assignment notebook (clean, for Git) |
| `superstore_assignment.sql` | Assignment SQL only (all 12 required queries) |

### Assignment Query Map
| # | Task | SQL Technique |
|---|------|---------------|
| Step 2-1 | Sales > average | `WHERE sales > (SELECT AVG…)` — Scalar Subquery |
| Step 2-2 | Highest order/customer | `WHERE (id,sales) IN (SELECT id,MAX…)` — Row-value Subquery |
| Step 2-3 | Total sales/customer | `WITH customer_total_sales AS (…)` — CTE |
| Step 2-4 | Above-avg total sales | CTE + `WHERE > (SELECT AVG … FROM cte)` |
| Step 2-5 | Rank all customers | `RANK() OVER (ORDER BY total_sales DESC)` |
| Step 2-6 | Row# per order/customer | `ROW_NUMBER() OVER (PARTITION BY customer_id …)` |
| Step 2-7 | Top 3 customers | CTE → `DENSE_RANK()` → `WHERE rank <= 3` |
| Step 3 | Name · Sales · Rank | JOIN + chained CTEs + Window |
| Mini 1 | Top 5 customers | CTE + `RANK()` + `LIMIT 5` |
| Mini 2 | Bottom 5 customers | CTE + `RANK() ASC` + `LIMIT 5` |
| Mini 3 | Single-order customers | CTE `HAVING COUNT(order_id)=1` |
| Mini 4 | Above-average customers | CTE + `CROSS JOIN avg_sales` |
| Mini 5 | Highest order/customer | CTE + `ROW_NUMBER() PARTITION BY` + `WHERE rn=1` |

---

## 📦 Dependencies

Install all Python dependencies with:

```bash
pip install -r requirements.txt
```

**`requirements.txt`**
```
pandas>=1.5.0
matplotlib>=3.6.0
seaborn>=0.12.0
jupyter>=1.0.0
ipykernel>=6.0.0
```

---

## 🗂️ GitHub Repository File Guide

| File | Purpose | Open with |
|------|---------|-----------|
| `superstore_assignment_executed.ipynb` | ⭐ **Start here** — full notebook with all outputs & charts | Jupyter / GitHub preview |
| `superstore_assignment.sql` | Clean SQL script — all 13 queries | Any SQL editor |
| `superstore_analysis_executed.ipynb` | Extended analysis notebook | Jupyter |
| `superstore_analysis.sql` | Extended SQL script | Any SQL editor |
| `requirements.txt` | Python dependencies | `pip install -r` |
| `.gitignore` | Git ignore rules | — |

""IF any error comes in preview of github, then please i request you to download the file project""
