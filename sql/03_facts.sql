-- ============================================================
-- 03_facts.sql  —  fact tables
-- Run after 02_dimensions.sql.
-- ============================================================

-- ---- fact_sales (grain: one row per order item) --------------
-- Rule 1: valid orders only (canceled/unavailable excluded).
-- Rule 2: price + freight at item grain, no payment join -> no fan-out.
-- Rule 4: customer_key resolved to customer_unique_id.
-- order_status is carried so the DAX headline measure can filter
-- to 'delivered' (realized revenue) vs in-progress statuses.
CREATE OR REPLACE TABLE olist_core.fact_sales AS
SELECT
  oi.order_id,
  oi.order_item_id,
  DATE(o.order_purchase_timestamp) AS date_key,
  c.customer_unique_id             AS customer_key,
  oi.product_id                    AS product_key,
  oi.seller_id                     AS seller_key,
  o.order_status,
  oi.price,
  oi.freight_value
FROM olist_core.stg_order_items oi
JOIN olist_core.stg_orders o
  ON oi.order_id = o.order_id
JOIN olist_core.stg_customers c
  ON o.customer_id = c.customer_id
WHERE o.is_valid_order;

-- ---- fact_reviews (grain: one row per order) -----------------
-- Rule 7: one review per order (from stg_reviews); on-time = delivered <= estimated.
-- Delivery metrics are NULL when the order was never delivered.
CREATE OR REPLACE TABLE olist_core.fact_reviews AS
SELECT
  o.order_id,
  DATE(o.order_purchase_timestamp) AS date_key,
  c.customer_unique_id             AS customer_key,
  o.order_status,
  r.review_score,
  DATE_DIFF(
    DATE(o.order_delivered_customer_date),
    DATE(o.order_purchase_timestamp),
    DAY
  ) AS delivery_days,
  CASE
    WHEN o.order_delivered_customer_date IS NOT NULL
    THEN o.order_delivered_customer_date <= o.order_estimated_delivery_date
  END AS is_on_time
FROM olist_core.stg_orders o
JOIN olist_core.stg_customers c
  ON o.customer_id = c.customer_id
LEFT JOIN olist_core.stg_reviews r
  ON o.order_id = r.order_id
WHERE o.is_valid_order;
