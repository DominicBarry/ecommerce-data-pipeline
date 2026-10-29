-- line_value should always equal quantity × unit_price.
-- Returns any order line where it doesn't.

select
    invoice_no,
    stock_code,
    quantity,
    unit_price,
    line_value
from {{ ref('fct_order_lines') }}
where abs(line_value - quantity * unit_price) > 0.001