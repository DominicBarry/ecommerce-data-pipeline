-- 06_create_fct_orders.sql
-- Fact table for orders (invoice header level)
-- One row per invoice - aggregated from line items
-- Partitioned by load_date for efficient querying

CREATE OR REPLACE TABLE `ecommerce-events-data-pipeline.ecommerce_events.fct_orders`
PARTITION BY load_date
AS
SELECT
  invoice_no,
  MAX(customer_id) AS customer_id,  -- Same customer per invoice
  MAX(invoice_date) AS invoice_date,  -- Same date per invoice
  SUM(line_value) AS order_total,
  SUM(quantity) AS order_quantity,
  MAX(load_date) AS load_date  -- Same load_date per invoice
FROM `ecommerce-events-data-pipeline.ecommerce_events.stg_events`
WHERE invoice_no IS NOT NULL
GROUP BY invoice_no;