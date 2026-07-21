#!/usr/bin/env bash
# Charge les 9 CSV Olist dans le dataset raw_olist (méthode CLI, alternative à l'UI).
# Prérequis : gcloud + bq authentifiés, CSV dans ./data/.
set -euo pipefail
DATASET="raw_olist"
DATA_DIR="./data"

load() {
  bq load --replace --autodetect --source_format=CSV --skip_leading_rows=1 \
    "${DATASET}.$1" "${DATA_DIR}/$2"
}

load orders               olist_orders_dataset.csv
load order_items          olist_order_items_dataset.csv
load order_payments       olist_order_payments_dataset.csv
load order_reviews        olist_order_reviews_dataset.csv
load customers            olist_customers_dataset.csv
load products             olist_products_dataset.csv
load sellers              olist_sellers_dataset.csv
load geolocation          olist_geolocation_dataset.csv
load category_translation product_category_name_translation.csvload_raw.sh
