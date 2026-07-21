# Business rules — data contract

One metric, one definition, applied identically everywhere. These rules are enforced
in the SQL and must be respected in Power BI.

### 1. Order status
Valid order = status **not in** (`canceled`, `unavailable`) — excluded everywhere.
Headline **realized revenue** is computed on `delivered` only; other statuses
(`shipped`, `invoiced`, `processing`, `approved`, `created`) are "in progress" and
reported separately, never summed into the headline figure.

### 2. Revenue definition
Revenue = `order_items.price` on valid orders. `freight_value` is logistics, tracked
separately, never folded into revenue. `payment_value` is used **only** for
payment-method analysis and never as a revenue figure (it doesn't reconcile with
price + freight because of vouchers/installments). Revenue is **never** computed on a
table joined to payments or reviews — that fan-out inflates the total.

### 3. Dates & currency
`order_purchase_timestamp` is the commercial date (drives `dim_date`, YoY, mix).
Approval/carrier/delivery/estimated dates are operational, used for delivery KPIs only.
Timestamps are naive Brazil local time. All amounts are **BRL**; no FX conversion
without a documented rate.

### 4. Customer identity
`customer_unique_id` is the real customer; `customer_id` is per-order. All customer
counts, repeat rate and new-vs-returning logic use `customer_unique_id`. A customer is
"returning" from their 2nd order onward.

### 5. Products & categories
Category is translated PT→EN once, in `stg_products`. Products with a null category are
kept and bucketed as `unknown` (never dropped — dropping breaks revenue reconciliation).

### 6. Geography
Aggregate by `customer_state` (clean 2-letter code). `customer_city` is free-text and
misspelled — not used as a grouping key. `geolocation` (multiple coords per zip) only
for optional maps.

### 7. Delivery & reviews
One review per order (most recent kept). On-time = `delivered_customer_date` ≤
`estimated_delivery_date`, on delivered orders only. Delivery time =
`delivered_customer_date` − `order_purchase_timestamp` (days).

### 8. Out of scope (assumed limitation)
No cost, margin or explicit discount exists in Olist (`price` is already final). Margin
and profitability analysis is therefore **not possible** here — that is Project 2
(dunnhumby). Stating this is a maturity signal, not a weakness.

---

**Reconciliation habit:** after each build, run `sql/04_checks.sql`. Revenue must be
stable across pages; document the excluded-orders percentage and the realized vs
in-progress split in the README.
