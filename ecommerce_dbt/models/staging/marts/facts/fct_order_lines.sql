{{
  config(
    materialized='table',
    partition_by={
      "field": "load_date",
      "data_type": "date"
    }
  )
}}

-- Fact table for order line items
-- One row per invoice line (invoice_no + stock_code combination)
-- Partitioned by load_date for efficient querying

SELECT
  invoice_no,
  stock_code,
  customer_id,
  invoice_date,
  quantity,
  unit_price,
  line_value,
  load_date
FROM {{ ref('stg_events') }}
WHERE stock_code IS NOT NULL
  AND invoice_no IS NOT NULL
