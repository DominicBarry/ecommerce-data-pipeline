{% docs __overview__ %}

# E-commerce Data Pipeline

A batch pipeline that turns UK online retail transactions into a tested, documented star schema in BigQuery.

**Source:** [UCI Online Retail dataset](https://archive.ics.uci.edu/dataset/352/online+retail). This build covers December 2010 (42,481 raw rows).

## How data flows

1. **Ingestion (Python):** loads one day at a time into `raw_events`. Re-running a day replaces it rather than duplicating it.
2. **Staging (`stg_events`):** cleans and standardises text, removes exact duplicates, and flags quality issues without dropping rows.
3. **Marts:** a star schema with two dimensions (`dim_customers`, `dim_products`) and two fact tables (`fct_order_lines`, `fct_orders`).

## How it's checked

- **28 tests:** 22 schema tests (keys, required fields) and 6 business logic tests (staging reconciles to raw, totals add up, one customer and one date per invoice).
- **Airflow** runs ingest → transform → test on every load (run locally).
- **CI (GitHub Actions)** rebuilds and tests every code change in a separate dataset, then republishes these docs.

## Finding your way around

Use the **Project** tab on the left to browse models, or the lineage graph button (bottom right) to see how tables connect. Each model lists its columns, tests and SQL.

Source code: [github.com/DominicBarry/ecommerce-data-pipeline](https://github.com/DominicBarry/ecommerce-data-pipeline)

{% enddocs %}