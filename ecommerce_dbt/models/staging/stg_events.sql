{{ config(materialized='table') }}

WITH source AS (
    SELECT * FROM {{ source('ecommerce_events', 'raw_events') }}
),

deduplicated AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY invoice_no, stock_code, invoice_date 
            ORDER BY ingested_at DESC
        ) AS row_num
    FROM source
),

cleaned AS (
    SELECT
        -- Surrogate key
        GENERATE_UUID() AS event_id,
        
        -- Business keys
        TRIM(invoice_no) AS invoice_no,
        TRIM(stock_code) AS stock_code,
        invoice_date,
        
        -- Attributes
        TRIM(UPPER(description)) AS description,
        quantity,
        unit_price,
        quantity * unit_price AS line_value,
        REPLACE(TRIM(customer_id), '.0', '') AS customer_id,
        TRIM(UPPER(country)) AS country,
        
        -- Quality flags
        CASE WHEN quantity < 0 THEN TRUE ELSE FALSE END AS is_negative_quantity,
        CASE WHEN customer_id IS NULL THEN TRUE ELSE FALSE END AS is_missing_customer_id,
        CASE WHEN description IS NULL THEN TRUE ELSE FALSE END AS is_missing_description,
        CASE WHEN unit_price <= 0 THEN TRUE ELSE FALSE END AS is_invalid_price,
        
        -- Overall quality flag
        CASE 
            WHEN quantity >= 0 
             AND customer_id IS NOT NULL 
             AND description IS NOT NULL 
             AND unit_price > 0 
            THEN TRUE 
            ELSE FALSE 
        END AS is_valid_transaction,
        
        -- Metadata
        ingested_at,
        source_file,
        source_row_number,
        load_date
        
    FROM deduplicated
    WHERE row_num = 1  -- Keep only most recent version of each transaction
)

SELECT * FROM cleaned