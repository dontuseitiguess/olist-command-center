# Commercial Performance Command Center — Olist

End-to-end commercial analytics on the **Olist Brazilian E-Commerce** public dataset
(~100k real orders, 2016–2018). Raw CSVs are loaded into BigQuery, transformed with
SQL into a documented **star schema**, and consumed in Power BI.

> Business context: this is a **B2C e-commerce marketplace** dataset — completed,
> post-sale transactions. There is no sales pipeline, win rate or opportunity funnel;
> those B2B/CRM concepts do not apply here. KPIs focus on realized revenue, product and
> geographic mix, customer repeat behaviour and delivery satisfaction.

## Validated results (BigQuery, EU region)

| Metric | Value |
|---|---|
| Realized revenue (delivered) | **13,221,498 BRL** |
| Orders | 98,199 |
| Unique customers | 94,983 |
| Average review score | 4.12 / 5 |
| Orders excluded (canceled / unavailable) | 1,234 — 1.24 % |
| Products with unknown category | 623 — 1.89 % |
| Fan-out check (fact_sales rows = expected item rows) | 112,101 = 112,101 ✅ |

## Architecture

```
9 raw CSVs  ─►  raw_olist.*      (loaded as-is via BigQuery UI)
            ─►  olist_core.stg_* (staging VIEWS: clean, cast, filter)
            ─►  olist_core.dim_* / fact_*  (star schema TABLES)
            ─►  Power BI  (relationships + DAX + dashboard)
```

Star schema (grain in parentheses):

- `fact_sales` (one row per **order item**) — measures: `price`, `freight_value`
- `fact_reviews` (one row per **order**) — measures: `review_score`, `delivery_days`, `is_on_time`
- `dim_date`, `dim_customer`, `dim_product`, `dim_seller`, `dim_order` (conformed dimensions)

`fact_sales` and `fact_reviews` sit at **different grains** — hence two fact tables
sharing conformed `dim_date` and `dim_customer`. Never merge them.

## Reproduce

1. Download the dataset from Kaggle (see Data & license below).
2. Load the 9 CSVs into a `raw_olist` BigQuery dataset. Two real-world gotchas:
   - `order_reviews`: enable **Allow quoted newlines** (comments contain line breaks).
   - `category_translation`: the file has a BOM — load with an explicit schema
     (`product_category_name:STRING,product_category_name_english:STRING`) and skip 1 header row.
3. Create an `olist_core` dataset (**same region as raw_olist**).
4. Run the SQL in order: `sql/01_staging.sql` → `02_dimensions.sql` → `03_facts.sql`,
   then read the results of `04_checks.sql`.

All SQL is **BigQuery Standard SQL**.

## Business rules

See `docs/business_rules.md` for the full data contract (order status, revenue definition,
customer identity, dates/currency, category handling, geography, reviews, and scope).

## Data & license

Dataset: *Brazilian E-Commerce Public Dataset by Olist* — https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
Licensed **CC BY-NC-SA 4.0** (attribution, non-commercial, share-alike).
Credit: data provided by Olist. This project is non-commercial (portfolio use).
**The raw CSVs are not committed to this repository** — download them from Kaggle to reproduce.

## Limitations

- Only one full calendar year (2017); compare **equivalent periods**, never partial-2018 vs full-2017.
- Single marketplace, Brazil only, currency BRL.
- No cost data → no margin/profitability (that is a separate pricing project).
- A customer's location is taken as a representative value when they span several cities.
