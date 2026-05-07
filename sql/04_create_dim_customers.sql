-- 04_create_dim_customers.sql
-- Dimension table for customers
-- One row per unique customer (excludes NULLs)

CREATE OR REPLACE TABLE `ecommerce-events-data-pipeline.ecommerce_events.dim_customers` AS
SELECT DISTINCT
  customer_id,
  MAX(country) AS country
FROM `ecommerce-events-data-pipeline.ecommerce_events.stg_events`
WHERE customer_id IS NOT NULL
GROUP BY customer_id;