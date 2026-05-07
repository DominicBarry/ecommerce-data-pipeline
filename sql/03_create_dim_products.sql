-- 03_create_dim_products.sql
-- Dimension table for products
-- One row per unique product (stock_code)

CREATE OR REPLACE TABLE `ecommerce-events-data-pipeline.ecommerce_events.dim_products` AS
SELECT DISTINCT
  stock_code,
  -- Take the first non-null description seen for each stock_code
  FIRST_VALUE(description IGNORE NULLS) OVER (
    PARTITION BY stock_code 
    ORDER BY invoice_date
  ) AS description
FROM `ecommerce-events-data-pipeline.ecommerce_events.stg_events`
WHERE stock_code IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY stock_code ORDER BY invoice_date) = 1;