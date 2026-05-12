-- dbt model configuration block
-- Tells dbt how to materialize this model and how to partition the resulting table
{{
  config(
    materialized='table',
    partition_by={
      "field": "load_date",
      "data_type": "date"
    }
  )
}}

SELECT
  -- Original columns with data hygiene
  TRIM(invoice_no) AS invoice_no,
  TRIM(stock_code) AS stock_code,
  TRIM(UPPER(description)) AS description,
  quantity,
  invoice_date,
  unit_price,
  TRIM(REPLACE(customer_id, '.0', '')) AS customer_id,
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
  
  (stock_code IN ('POST', 'M', 'DOT', 'D', 'C2') 
   OR quantity < 0 
   OR UPPER(description) LIKE '%DISCOUNT%'
   OR UPPER(description) LIKE '%POSTAGE%'
   OR UPPER(description) LIKE '%CARRIAGE%'
   OR UPPER(description) LIKE '%MANUAL%') AS is_adjustment_like_line,
  
  quantity * unit_price AS line_value
  
FROM {{ source('ecommerce_events', 'raw_events') }}