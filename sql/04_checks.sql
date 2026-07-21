-- ============================================================
-- 04_checks.sql  —  reconciliation & data-quality checks
-- Run each query and read the result. These are what prove rigour.
-- ============================================================

-- 1) Excluded orders (Rule 1): how many, and what share?
SELECT
  COUNTIF(NOT is_valid_order)                         AS excluded_orders,
  COUNT(*)                                            AS total_orders,
  ROUND(100 * COUNTIF(NOT is_valid_order) / COUNT(*), 2) AS excluded_pct
FROM olist_core.stg_orders;

-- 2) Fan-out guard (Rule 2): fact_sales must equal the item count of valid orders.
--    Both numbers must match exactly — if fact_sales is larger, a join fanned out.
SELECT
  (SELECT COUNT(*) FROM olist_core.fact_sales) AS fact_sales_rows,
  (SELECT COUNT(*)
     FROM olist_core.stg_order_items oi
     JOIN olist_core.stg_orders o ON oi.order_id = o.order_id
    WHERE o.is_valid_order)                    AS expected_item_rows;

-- 3) Revenue reconciliation: fact total vs raw price total for valid orders.
SELECT
  (SELECT SUM(price) FROM olist_core.fact_sales) AS fact_revenue_all_valid,
  (SELECT SUM(oi.price)
     FROM olist_core.stg_order_items oi
     JOIN olist_core.stg_orders o ON oi.order_id = o.order_id
    WHERE o.is_valid_order)                      AS raw_revenue_valid;

-- 4) Realized vs in-progress revenue split (Rule 1).
SELECT
  ROUND(SUM(IF(order_status = 'delivered', price, 0)), 2) AS revenue_delivered,
  ROUND(SUM(IF(order_status <> 'delivered', price, 0)), 2) AS revenue_in_progress
FROM olist_core.fact_sales;

-- 5) Category coverage (Rule 5): share mapped to 'unknown'.
SELECT
  COUNTIF(product_category = 'unknown')                          AS unknown_products,
  COUNT(*)                                                       AS total_products,
  ROUND(100 * COUNTIF(product_category = 'unknown') / COUNT(*), 2) AS unknown_pct
FROM olist_core.dim_product;

-- 6) Review dedupe (Rule 7): must be exactly 1 review per order, max.
SELECT MAX(cnt) AS max_reviews_per_order
FROM (
  SELECT order_id, COUNT(*) AS cnt
  FROM olist_core.stg_reviews
  GROUP BY order_id
);

-- 7) Delivery coverage: share of valid orders with a delivery date (drives KPI base).
SELECT
  COUNTIF(delivery_days IS NOT NULL)                            AS delivered_with_date,
  COUNT(*)                                                      AS valid_orders,
  ROUND(100 * COUNTIF(delivery_days IS NOT NULL) / COUNT(*), 2) AS delivered_pct
FROM olist_core.fact_reviews;

-- 8) Sanity headline: the numbers you should quote in the README.
SELECT
  (SELECT ROUND(SUM(price), 2) FROM olist_core.fact_sales WHERE order_status = 'delivered') AS revenue_realized_brl,
  (SELECT COUNT(DISTINCT order_id) FROM olist_core.fact_sales)      AS orders,
  (SELECT COUNT(DISTINCT customer_key) FROM olist_core.fact_sales)  AS customers,
  (SELECT ROUND(AVG(review_score), 2) FROM olist_core.fact_reviews) AS avg_review_score;
