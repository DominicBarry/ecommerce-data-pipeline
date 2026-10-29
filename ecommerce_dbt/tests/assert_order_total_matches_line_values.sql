-- Each order's total should equal the sum of its line values,
-- and every invoice should appear in both fact tables.
-- Returns any invoice where that isn't true.

with line_totals as (
    select
        invoice_no,
        sum(line_value) as lines_total
    from {{ ref('fct_order_lines') }}
    group by invoice_no
)

select
    coalesce(o.invoice_no, l.invoice_no) as invoice_no,
    o.order_total,
    l.lines_total
from {{ ref('fct_orders') }} o
full outer join line_totals l
    on o.invoice_no = l.invoice_no
where o.invoice_no is null
   or l.invoice_no is null
   or abs(o.order_total - l.lines_total) > 0.01