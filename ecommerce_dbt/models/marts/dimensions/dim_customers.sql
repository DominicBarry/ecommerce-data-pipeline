{{
  config(
    materialized='table'
  )
}}

-- Dimension table for customers
-- One row per unique customer (excludes NULLs)

SELECT DISTINCT
  customer_id,
  MAX(country) AS country
FROM {{ ref('stg_events') }}
WHERE customer_id IS NOT NULL
GROUP BY customer_id