-- Creates stg_events from raw_events
-- Preserves raw event grain while applying standardisation,
-- helper flags, and derived analytical fields
-- Layer: staging

CREATE OR REPLACE TABLE `ecommerce-events-data-pipeline.ecommerce_events.stg_events`
PARTITION BY load_date
AS
SELECT
  -- Original columns with data hygiene
  TRIM(invoice_no) AS invoice_no,
  TRIM(stock_code) AS stock_code,
  TRIM(UPPER(description)) AS description,
  quantity,
  invoice_date,
  unit_price,
  TRIM(REPLACE(customer_id, '.0', '')) AS customer_id,  -- Removes trailing .0 from string
  TRIM(UPPER(country)) AS country,
  
  -- Metadata columns (unchanged)
  ingested_at,
  source_file,
  source_row_number,
  load_date,
  
  -- Annotation fields
  stock_code IN ('POST', 'M', 'DOT', 'D', 'C2') AS is_special_stock_code,
  description IS NULL AS is_missing_description,
  quantity IS NULL AS is_missing_quantity,
  customer_id IS NULL AS is_missing_customer_id,
  quantity < 0 AS is_negative_quantity,
  
  -- is_adjustment_like_line: special codes OR negative quantity OR certain keywords
  (stock_code IN ('POST', 'M', 'DOT', 'D', 'C2') 
   OR quantity < 0 
   OR UPPER(description) LIKE '%DISCOUNT%'
   OR UPPER(description) LIKE '%POSTAGE%'
   OR UPPER(description) LIKE '%CARRIAGE%'
   OR UPPER(description) LIKE '%MANUAL%') AS is_adjustment_like_line,
  
  -- Calculated line value
  quantity * unit_price AS line_value
  
FROM `ecommerce-events-data-pipeline.ecommerce_events.raw_events`;