-- Order totals must match invoice type:
-- non-cancellation invoices can't be negative, and cancellation ("C") invoices can't be positive.
-- Returns any invoice that breaks either rule.

select
    invoice_no,
    customer_id,
    invoice_date,
    order_total,
    order_quantity,
    load_date
from {{ ref('fct_orders') }}
where ((not starts_with(invoice_no, 'C')) and order_total < 0 )
or (starts_with(invoice_no, 'C') and order_total > 0)