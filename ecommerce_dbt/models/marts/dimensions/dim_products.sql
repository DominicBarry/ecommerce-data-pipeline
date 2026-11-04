{{
  config(
    materialized='table'
  )
}}

-- Dimension table for products
-- One row per unique product (stock_code)

SELECT DISTINCT
  stock_code,
  -- Take the first non-null description seen for each stock_code
  FIRST_VALUE(description IGNORE NULLS) OVER (
    PARTITION BY stock_code 
    ORDER BY invoice_date
    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING 
   -- Explicit frame so every row sees the product's full history.
   -- Without it, the default frame stops at the current row, and products
   -- whose earliest row has no description came out blank.
  ) AS description
FROM {{ ref('stg_events') }}
WHERE stock_code IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY stock_code ORDER BY invoice_date) = 1