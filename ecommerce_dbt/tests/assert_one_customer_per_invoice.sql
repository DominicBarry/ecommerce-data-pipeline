-- Each invoice should belong to one customer (or be a guest purchase throughout).
-- fct_orders relies on this when it takes MAX(customer_id).
-- Returns any invoice with more than one customer, or a mix of guest and known customer.

select
    invoice_no,
    count(distinct customer_id) as distinct_customers,
    countif(customer_id is null) as guest_lines,
    count(*) as total_lines
from {{ ref('fct_order_lines') }}
group by invoice_no
having count(distinct customer_id) > 1
    or (count(distinct customer_id) = 1 and countif(customer_id is null) > 0)