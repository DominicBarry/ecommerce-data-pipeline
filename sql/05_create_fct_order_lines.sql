-- 05_create_fct_order_lines.sql
-- Fact table for order line items
-- One row per invoice line (invoice_no + stock_code combination)
-- Partitioned by load_date for efficient querying

CREATE OR REPLACE TABLE `ecommerce-events-data-pipeline.ecommerce_events.fct_order_lines`
PARTITION BY load_date
AS
SELECT
  invoice_no,
  stock_code,
  customer_id,
  invoice_date,
  quantity,
  unit_price,
  line_value,
  load_date
FROM `ecommerce-events-data-pipeline.ecommerce_events.stg_events`
WHERE stock_code IS NOT NULL
  AND invoice_no IS NOT NULL;
