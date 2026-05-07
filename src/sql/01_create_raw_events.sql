-- 01_create_raw_events.sql
-- Raw events table - populated by Python ingestion script (src/ingestion.py)
-- Partitioned by load_date for incremental loading

CREATE TABLE IF NOT EXISTS `ecommerce-events-data-pipeline.ecommerce_events.raw_events`
(
  invoice_no STRING,
  stock_code STRING,
  description STRING,
  quantity INT64,
  invoice_date TIMESTAMP,
  unit_price FLOAT64,
  customer_id STRING,
  country STRING,
  ingested_at TIMESTAMP,
  source_file STRING,
  source_row_number INT64,
  load_date DATE
)
PARTITION BY load_date
OPTIONS(
  description="Raw events from Online Retail dataset - loaded via ingestion.py"
);