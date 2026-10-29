-- Every line on an invoice falls on the same calendar date.

select
    invoice_no,
    COUNT (*) AS line_count,
    COUNT ( distinct (CAST (invoice_date AS DATE))) AS distinct_dates
from {{ ref('fct_order_lines') }}
group by invoice_no
having distinct_dates > 1