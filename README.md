# E-commerce Data Pipeline

An end-to-end data engineering project demonstrating modern practices using Python, BigQuery, dbt, and Airflow.

## Project Overview

Building a production-like data pipeline from a static e-commerce transaction dataset, treating it as streaming event data to simulate real-world batch processing scenarios.

**Dataset:** [Online Retail Dataset](https://archive.ics.uci.edu/dataset/352/online+retail) - UK-based online wholesale retailer transactions (2010-2011)

## Progress

### Week 1: Data Ingestion ✅

**What I Built:**
- Python ingestion script (`src/ingestion.py`) that:
  - Reads from Excel source file
  - Filters transactions by date parameter
  - Adds metadata columns (ingested_at, source_file, source_row_number, load_date)
  - Loads into BigQuery raw_events table
- BigQuery raw_events table (partitioned by load_date)

**Key Decisions:**
- **Parameterized load_date**: Makes the script reusable for loading different dates incrementally
- **Metadata tracking**: Added audit columns to trace data lineage back to source
- **Partitioning by load_date**: Supports incremental loading pattern and efficient querying
- **Data type standardization**: Ensured consistent types before loading to BigQuery

**Learnings:**
- Basic data hygiene (trimming, type casting) should happen at ingestion
- Metadata is cheap to add and valuable for debugging
- Python + pandas worked well for batch ingestion and transformation of this dataset

---

### Week 2: Staging & Dimensional Modeling ✅

**What I Built:**

**Staging Layer:**
- `stg_events` table with data quality improvements:
  - Standardized casing (UPPER for description, country)
  - Cleaned customer_id (removed trailing .0)
  - Trimmed whitespace from text fields
  - Added quality flags (is_negative_quantity, is_missing_customer_id, etc.)
  - Calculated line_value (quantity × unit_price)

**Dimensional Model:**
- `dim_products` - One row per unique stock_code
- `dim_customers` - One row per unique customer_id (excludes NULLs)
- `fct_order_lines` - Transaction-level detail (one row per invoice line)
- `fct_orders` - Aggregated order headers (one row per invoice)

**Key Decisions:**

1. **Staging preserves all rows**: No filtering of bad data yet - just flag it
   - Quality flags let downstream consumers decide how to handle issues
   - Keeps audit trail intact

2. **Price belongs in facts, not dimensions**: 
   - Prices can change over time
   - Stored at transaction level in fct_order_lines (the price paid at that moment)

3. **Exclude NULL customer_ids from dim_customers**:
   - Dimensions represent known entities
   - Guest purchases remain in facts with customer_id = NULL

4. **No metadata in dimensional tables**:
   - Staging contains operational metadata (ingested_at, source_file, etc.)
   - Dimensions/facts contain only business-relevant attributes
   - Exception: load_date in facts (useful for incremental processing)

5. **No quality flags in facts**:
   - Keep fact tables lean
   - Filters (e.g., exclude returns, exclude adjustments) handled in mart layer

6. **Separate fct_orders and fct_order_lines**:
   - Line-level detail for product analysis
   - Order-level aggregates for customer/transaction analysis
   - Avoids repeating order-level attributes across line items

**Data Quality Observations:**
- ~6% of invoices contain special stock codes (POST, M, DOT, D, C2) representing adjustments/fees
- Negative quantities exist (returns/cancellations) - preserved as-is
- Some missing customer_ids (guest purchases)
- Some missing descriptions

**Learnings:**
- Dimensions = "things" (who, what), Facts = "events" (what happened, how much)
- Staging is for cleaning; dimensions/facts are for business logic
- Partitioning by load_date supports incremental patterns and improves query performance

---

## Current Architecture

    Source Data (Excel)
        ↓
    [Python Ingestion Script]
        ↓
    raw_events (partitioned)
        ↓
    stg_events (cleaned + flagged)
        ↓
        ├── dim_products
        ├── dim_customers
        ├── fct_order_lines
        └── fct_orders

---

## Uncertainties & Future Decisions

1. **Special stock codes**: Should POST/M/DOT/D/C2 be filtered out entirely or kept for financial reconciliation?
2. **Negative quantities**: Current approach preserves them - may need separate returns analysis in mart layer
3. **Slowly changing dimensions**: Products/customers assumed static for now - no SCD2 tracking yet
4. **Incremental loading strategy**: Currently loading single dates - need to handle late-arriving data
5. **Data quality thresholds**: At what point do quality issues warrant pipeline alerts?

---

## Next Steps

**Week 3:** Migrate SQL transformations into dbt
- Convert manual SQL scripts to dbt models
- Add tests for data quality
- Establish dependencies between models

---

## Project Structure

    ecommerce-data-pipeline/
    ├── data/
    │   └── Online_Retail.xlsx
    ├── src/
    │   └── ingestion.py
    ├── sql/
    │   ├── 01_create_raw_events.sql
    │   ├── 02_create_stg_events.sql
    │   ├── 03_create_dim_products.sql
    │   ├── 04_create_dim_customers.sql
    │   ├── 05_create_fct_order_lines.sql
    │   └── 06_create_fct_orders.sql
    ├── README.md
    ├── requirements.txt
    └── .gitignore

---

## Technologies

- **Python 3.12** - Data ingestion and transformation
- **Google BigQuery** - Cloud data warehouse
- **Pandas** - Data manipulation
- **SQL** - Data transformation
- Coming: **dbt** (data transformation), **Airflow** (orchestration)