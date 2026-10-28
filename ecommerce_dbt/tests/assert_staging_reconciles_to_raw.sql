-- Staging should contain every raw row except exact duplicates.
-- Compares row count and total value; returns a row only if they don't match.

with raw_deduped as (
    select distinct
        invoice_no, stock_code, invoice_date, description,
        quantity, cast(unit_price as string) as unit_price_str,
        customer_id, country
    from {{ source('ecommerce_events', 'raw_events') }}
),

raw_totals as (
    select
        count(*) as row_count,
        sum(quantity * cast(unit_price_str as float64)) as total_value
    from raw_deduped
),

staging_totals as (
    select
        count(*) as row_count,
        sum(line_value) as total_value
    from {{ ref('stg_events') }}
)

select
    r.row_count as raw_rows,
    s.row_count as staging_rows,
    r.total_value as raw_value,
    s.total_value as staging_value
from raw_totals r
cross join staging_totals s
where r.row_count != s.row_count
   or abs(r.total_value - s.total_value) > 0.01