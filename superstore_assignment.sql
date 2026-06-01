-- ================================================================
--  SUPERSTORE SALES ANALYSIS — ASSIGNMENT SQL SCRIPT
--  Covers: Subqueries · CTEs · Window Functions · JOINs
--  Engine: SQLite  (minor tweaks needed for PostgreSQL / MySQL)
-- ================================================================


-- ================================================================
-- STEP 1 — SETUP DATA
-- ================================================================

-- 1-A  Raw table (loaded via pandas / .import in CLI)
DROP TABLE IF EXISTS superstore_raw;
CREATE TABLE superstore_raw (
    row_id        INTEGER,
    order_id      TEXT,
    order_date    TEXT,
    ship_date     TEXT,
    ship_mode     TEXT,
    customer_id   TEXT,
    customer_name TEXT,
    segment       TEXT,
    country       TEXT,
    city          TEXT,
    state         TEXT,
    postal_code   TEXT,
    region        TEXT,
    product_id    TEXT,
    category      TEXT,
    sub_category  TEXT,
    product_name  TEXT,
    sales         REAL,
    quantity      INTEGER,
    discount      REAL,
    profit        REAL
);
-- SQLite CLI:  .import --csv --skip 1 superstore.csv superstore_raw
-- PostgreSQL:  COPY superstore_raw FROM '/path/superstore.csv' CSV HEADER;

-- 1-B  Normalised tables using SELECT DISTINCT

DROP TABLE IF EXISTS customers;
CREATE TABLE customers AS
    SELECT DISTINCT
        customer_id,
        customer_name,
        segment
    FROM superstore_raw;

DROP TABLE IF EXISTS orders;
CREATE TABLE orders AS
    SELECT DISTINCT
        order_id,
        order_date,
        ship_date,
        ship_mode,
        customer_id,
        city,
        state,
        postal_code,
        region
    FROM superstore_raw;

DROP TABLE IF EXISTS products;
CREATE TABLE products AS
    SELECT DISTINCT
        product_id,
        product_name,
        category,
        sub_category
    FROM superstore_raw;

-- Verify
SELECT 'superstore_raw' AS tbl, COUNT(*) AS rows FROM superstore_raw UNION ALL
SELECT 'customers',  COUNT(*) FROM customers  UNION ALL
SELECT 'orders',     COUNT(*) FROM orders     UNION ALL
SELECT 'products',   COUNT(*) FROM products;


-- ================================================================
-- STEP 2 — REQUIRED QUERIES
-- ================================================================

-- ── Query 1: Orders where Sales > Average Sales  (Subquery) ─────
SELECT
    order_id,
    customer_id,
    ROUND(sales,  2) AS sales,
    ROUND(profit, 2) AS profit,
    category,
    region
FROM superstore_raw
WHERE sales > (SELECT AVG(sales) FROM superstore_raw)   -- scalar subquery
ORDER BY sales DESC
LIMIT 15;


-- ── Query 2: Highest Sales Order for Each Customer  (Subquery) ──
SELECT
    sr.customer_id,
    c.customer_name,
    sr.order_id,
    ROUND(sr.sales, 2) AS highest_order_sales,
    sr.category,
    sr.region
FROM superstore_raw sr
JOIN customers c USING (customer_id)
WHERE (sr.customer_id, sr.sales) IN (       -- row-value subquery
    SELECT customer_id, MAX(sales)
    FROM superstore_raw
    GROUP BY customer_id
)
ORDER BY highest_order_sales DESC
LIMIT 15;


-- ── Query 3: Total Sales for Each Customer  (CTE) ───────────────
WITH customer_total_sales AS (
    SELECT
        sr.customer_id,
        c.customer_name,
        c.segment,
        ROUND(SUM(sr.sales),  2)    AS total_sales,
        ROUND(SUM(sr.profit), 2)    AS total_profit,
        COUNT(DISTINCT sr.order_id) AS total_orders
    FROM superstore_raw sr
    JOIN customers c USING (customer_id)
    GROUP BY sr.customer_id, c.customer_name, c.segment
)
SELECT *
FROM customer_total_sales
ORDER BY total_sales DESC
LIMIT 15;


-- ── Query 4: Customers with Above-Average Total Sales (CTE + Subquery)
WITH customer_total_sales AS (
    SELECT
        sr.customer_id,
        c.customer_name,
        c.segment,
        ROUND(SUM(sr.sales), 2) AS total_sales
    FROM superstore_raw sr
    JOIN customers c USING (customer_id)
    GROUP BY sr.customer_id, c.customer_name, c.segment
)
SELECT *
FROM customer_total_sales
WHERE total_sales > (
    SELECT AVG(total_sales) FROM customer_total_sales   -- subquery on CTE
)
ORDER BY total_sales DESC
LIMIT 15;


-- ── Query 5: Rank All Customers by Total Sales  (Window Function) ─
WITH customer_total_sales AS (
    SELECT
        sr.customer_id,
        c.customer_name,
        c.segment,
        ROUND(SUM(sr.sales), 2) AS total_sales
    FROM superstore_raw sr
    JOIN customers c USING (customer_id)
    GROUP BY sr.customer_id, c.customer_name, c.segment
)
SELECT
    customer_name,
    segment,
    total_sales,
    RANK()       OVER (ORDER BY total_sales DESC) AS sales_rank,
    DENSE_RANK() OVER (ORDER BY total_sales DESC) AS dense_rank
FROM customer_total_sales
ORDER BY sales_rank
LIMIT 20;


-- ── Query 6: Row Numbers per Order Within Each Customer (Window + PARTITION BY)
SELECT
    c.customer_name,
    sr.order_id,
    sr.order_date,
    ROUND(sr.sales, 2) AS sales,
    sr.category,
    ROW_NUMBER() OVER (
        PARTITION BY sr.customer_id     -- restart per customer
        ORDER BY sr.order_date          -- chronological
    ) AS order_row_num
FROM superstore_raw sr
JOIN customers c USING (customer_id)
ORDER BY c.customer_name, order_row_num
LIMIT 20;


-- ── Query 7: Top 3 Customers by Total Sales  (Window Function) ───
WITH customer_total_sales AS (
    SELECT
        sr.customer_id,
        c.customer_name,
        c.segment,
        ROUND(SUM(sr.sales),  2)    AS total_sales,
        ROUND(SUM(sr.profit), 2)    AS total_profit,
        COUNT(DISTINCT sr.order_id) AS total_orders
    FROM superstore_raw sr
    JOIN customers c USING (customer_id)
    GROUP BY sr.customer_id, c.customer_name, c.segment
),
ranked AS (
    SELECT *,
        DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM customer_total_sales
)
SELECT *
FROM ranked
WHERE sales_rank <= 3;


-- ================================================================
-- STEP 3 — FINAL COMBINED QUERY
--          Customer Name · Total Sales · Rank
--          (JOIN + CTE + Window Function)
-- ================================================================

WITH customer_sales AS (
    -- JOIN: link fact table to dimension
    SELECT
        sr.customer_id,
        c.customer_name,
        c.segment,
        COUNT(DISTINCT sr.order_id)   AS total_orders,
        ROUND(SUM(sr.sales),  2)      AS total_sales,
        ROUND(SUM(sr.profit), 2)      AS total_profit,
        ROUND(AVG(sr.discount)*100,1) AS avg_discount_pct
    FROM superstore_raw sr          -- JOIN
    JOIN customers c USING (customer_id)
    GROUP BY sr.customer_id, c.customer_name, c.segment
),
ranked_customers AS (
    SELECT
        customer_name,
        segment,
        total_orders,
        total_sales,
        total_profit,
        avg_discount_pct,
        RANK() OVER (ORDER BY total_sales DESC)                      AS overall_rank,
        RANK() OVER (PARTITION BY segment ORDER BY total_sales DESC) AS segment_rank,
        ROUND(total_sales / SUM(total_sales) OVER () * 100, 2)       AS pct_of_total
    FROM customer_sales
)
SELECT
    overall_rank,
    segment_rank,
    customer_name,
    segment,
    total_orders,
    total_sales,
    total_profit,
    avg_discount_pct,
    pct_of_total
FROM ranked_customers
ORDER BY overall_rank
LIMIT 20;


-- ================================================================
-- MINI PROJECT — CUSTOMER SALES INSIGHTS
-- ================================================================

-- ── Mini Q1: Top 5 Customers ──────────────────────────────────────
WITH sales_agg AS (
    SELECT sr.customer_id, c.customer_name, c.segment,
           ROUND(SUM(sr.sales),  2)    AS total_sales,
           ROUND(SUM(sr.profit), 2)    AS total_profit,
           COUNT(DISTINCT sr.order_id) AS total_orders
    FROM superstore_raw sr JOIN customers c USING (customer_id)
    GROUP BY sr.customer_id, c.customer_name, c.segment
)
SELECT
    RANK() OVER (ORDER BY total_sales DESC) AS rank,
    customer_name, segment, total_sales, total_profit, total_orders
FROM sales_agg
ORDER BY rank
LIMIT 5;


-- ── Mini Q2: Bottom 5 Customers ─────────────────────────────────
WITH sales_agg AS (
    SELECT sr.customer_id, c.customer_name, c.segment,
           ROUND(SUM(sr.sales),  2)    AS total_sales,
           ROUND(SUM(sr.profit), 2)    AS total_profit,
           COUNT(DISTINCT sr.order_id) AS total_orders
    FROM superstore_raw sr JOIN customers c USING (customer_id)
    GROUP BY sr.customer_id, c.customer_name, c.segment
)
SELECT
    RANK() OVER (ORDER BY total_sales ASC) AS rank,
    customer_name, segment, total_sales, total_profit, total_orders
FROM sales_agg
ORDER BY rank
LIMIT 5;


-- ── Mini Q3: Customers with Only One Order ───────────────────────
WITH order_counts AS (
    SELECT customer_id,
           COUNT(DISTINCT order_id) AS num_orders
    FROM superstore_raw
    GROUP BY customer_id
)
SELECT
    c.customer_id,
    c.customer_name,
    c.segment,
    ROUND(SUM(sr.sales),  2) AS total_sales,
    ROUND(SUM(sr.profit), 2) AS total_profit,
    MIN(sr.order_id)         AS order_id,
    MIN(sr.order_date)       AS order_date
FROM order_counts oc
JOIN customers c      USING (customer_id)
JOIN superstore_raw sr USING (customer_id)
WHERE oc.num_orders = 1
GROUP BY c.customer_id, c.customer_name, c.segment
ORDER BY total_sales DESC;


-- ── Mini Q4: Customers with Above-Average Sales ──────────────────
WITH customer_totals AS (
    SELECT
        sr.customer_id,
        c.customer_name,
        c.segment,
        ROUND(SUM(sr.sales), 2) AS total_sales
    FROM superstore_raw sr JOIN customers c USING (customer_id)
    GROUP BY sr.customer_id, c.customer_name, c.segment
),
avg_sales AS (
    SELECT AVG(total_sales) AS avg_total FROM customer_totals
)
SELECT
    ct.customer_name,
    ct.segment,
    ct.total_sales,
    ROUND(av.avg_total, 2)                    AS avg_customer_sales,
    ROUND(ct.total_sales - av.avg_total, 2)   AS above_avg_by
FROM customer_totals ct
CROSS JOIN avg_sales av
WHERE ct.total_sales > av.avg_total
ORDER BY ct.total_sales DESC
LIMIT 15;


-- ── Mini Q5: Highest Order Value per Customer ────────────────────
WITH order_totals AS (
    SELECT
        customer_id,
        order_id,
        order_date,
        ROUND(SUM(sales), 2) AS order_value
    FROM superstore_raw
    GROUP BY customer_id, order_id, order_date
),
ranked_orders AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY order_value DESC
        ) AS rn
    FROM order_totals
)
SELECT
    c.customer_name,
    c.segment,
    ro.order_id,
    ro.order_date,
    ro.order_value AS highest_order_value
FROM ranked_orders ro
JOIN customers c USING (customer_id)
WHERE ro.rn = 1
ORDER BY ro.order_value DESC
LIMIT 15;

