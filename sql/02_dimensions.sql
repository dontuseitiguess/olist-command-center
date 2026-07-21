-- ============================================================
-- 02_dimensions.sql  —  star-schema dimension tables
-- Run after 01_staging.sql.
-- ============================================================

-- ---- dim_date ------------------------------------------------
-- Rule 3: built on the purchase-date range. Enables DAX time intelligence.
CREATE OR REPLACE TABLE olist_core.dim_date AS
WITH bounds AS (
  SELECT
    DATE(MIN(order_purchase_timestamp)) AS min_d,
    DATE(MAX(order_purchase_timestamp)) AS max_d
  FROM olist_core.stg_orders
  WHERE is_valid_order
)
SELECT
  d                                        AS date_key,
  EXTRACT(YEAR    FROM d)                   AS year,
  EXTRACT(QUARTER FROM d)                   AS quarter,
  EXTRACT(MONTH   FROM d)                   AS month,
  FORMAT_DATE('%B', d)                      AS month_name,
  FORMAT_DATE('%Y-%m', d)                   AS year_month,
  EXTRACT(DAY       FROM d)                 AS day,
  EXTRACT(DAYOFWEEK FROM d)                 AS day_of_week,   -- 1 = Sunday
  FORMAT_DATE('%A', d)                      AS day_name,
  EXTRACT(DAYOFWEEK FROM d) IN (1, 7)       AS is_weekend
FROM bounds, UNNEST(GENERATE_DATE_ARRAY(min_d, max_d)) AS d;

-- ---- dim_customer (grain: customer_unique_id) ----------------
-- Rule 4 + Rule 6: identity = unique_id; geography = state (city messy).
-- A customer spanning several cities gets one representative location.
CREATE OR REPLACE TABLE olist_core.dim_customer AS
SELECT
  customer_unique_id,
  ANY_VALUE(customer_state) AS customer_state,
  ANY_VALUE(customer_city)  AS customer_city
FROM olist_core.stg_customers
GROUP BY customer_unique_id;

-- ---- dim_product ---------------------------------------------
CREATE OR REPLACE TABLE olist_core.dim_product AS
SELECT
  product_id,
  product_category
FROM olist_core.stg_products;

-- ---- dim_seller ----------------------------------------------
CREATE OR REPLACE TABLE olist_core.dim_seller AS
SELECT
  seller_id,
  seller_state,
  seller_city
FROM olist_core.stg_sellers;

-- ---- dim_order (grain: order_id) -----------------------------
-- Degenerate/order-level attributes. Valid orders only.
CREATE OR REPLACE TABLE olist_core.dim_order AS
SELECT
  order_id,
  order_status,
  DATE(order_purchase_timestamp) AS purchase_date
FROM olist_core.stg_orders
WHERE is_valid_order;
