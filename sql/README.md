# sql/

- `01_create_raw_events.sql`: creates the raw table. Still required; run it once before the first load.
- `02`–`06`: the original SQL models, run by hand in BigQuery before the project moved to dbt. Kept for reference; the live versions are in `ecommerce_dbt/models/`.