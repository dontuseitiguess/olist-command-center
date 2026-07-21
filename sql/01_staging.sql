
-- 01_staging.sql  —  clean / cast / filter the raw tables
-- BigQuery Standard SQL. Staging is exposed as lightweight VIEWS.

-- Create the working dataset (run once; ignore error if it exists).
-- bq --location=US mk -f --dataset olist_core

--  Orders
-- Rule 1: is_valid_order excludes canceled/unavailable everywhere downstream.
-- Rule 3: purchase timestamp is the commercial date; the rest are operational.
CREATE OR REPLACE VIEW olist_core.stg_orders AS
SELECT
  order_id,
  customer_id,
  LOWER(order_status) AS order_status,
  SAFE_CAST(order_purchase_timestamp      AS TIMESTAMP) AS order_purchase_timestamp,
  SAFE_CAST(order_approved_at             AS TIMESTAMP) AS order_approved_at,
  SAFE_CAST(order_delivered_carrier_date  AS TIMESTAMP) AS order_delivered_carrier_date,
  SAFE_CAST(order_delivered_customer_date AS TIMESTAMP) AS order_delivered_customer_date,
  SAFE_CAST(order_estimated_delivery_date AS TIMESTAMP) AS order_estimated_delivery_date,
  LOWER(order_status) NOT IN ('canceled', 'unavailable') AS is_valid_order
FROM raw_olist.orders;

-- ---- Order items (grain: one row per item) -------------------
-- Rule 2: price = revenue; freight kept separate. No payment join here.
CREATE OR REPLACE VIEW olist_core.stg_order_items AS
SELECT
  order_id,
  SAFE_CAST(order_item_id AS INT64)   AS order_item_id,
  product_id,
  seller_id,
  SAFE_CAST(price         AS NUMERIC) AS price,
  SAFE_CAST(freight_value AS NUMERIC) AS freight_value
FROM raw_olist.order_items;

-- ---- Customers ----------------------------------------------
-- Rule 4: customer_unique_id is the real person; customer_id is per-order.
CREATE OR REPLACE VIEW olist_core.stg_customers AS
SELECT
  customer_id,
  customer_unique_id,
  customer_state,
  customer_city
FROM raw_olist.customers;

-- ---- Products ------------------------------------------------
-- Rule 5: translate category to EN once; null category -> 'unknown'.
CREATE OR REPLACE VIEW olist_core.stg_products AS
SELECT
  p.product_id,
  COALESCE(t.product_category_name_english, 'unknown') AS product_category
FROM raw_olist.products p
LEFT JOIN raw_olist.category_translation t
  ON p.product_category_name = t.product_category_name;

-- ---- Sellers -------------------------------------------------
CREATE OR REPLACE VIEW olist_core.stg_sellers AS
SELECT
  seller_id,
  seller_state,
  seller_city
FROM raw_olist.sellers;

-- ---- Reviews -------------------------------------------------
-- Rule 7: keep one review per order (the most recent).
CREATE OR REPLACE VIEW olist_core.stg_reviews AS
SELECT * EXCEPT (rn)
FROM (
  SELECT
    review_id,
    order_id,
    SAFE_CAST(review_score         AS INT64)     AS review_score,
    SAFE_CAST(review_creation_date AS TIMESTAMP) AS review_creation_date,
    ROW_NUMBER() OVER (
      PARTITION BY order_id
      ORDER BY SAFE_CAST(review_creation_date AS TIMESTAMP) DESC
    ) AS rn
  FROM raw_olist.order_reviews
)
WHERE rn = 1;
