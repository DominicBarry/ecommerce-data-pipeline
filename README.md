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
- Basic data type standardization should happen at ingestion; data cleaning (trimming, casing) happens in staging
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

### Week 3: Introduce dbt ✅

**What I Built:**

**dbt Project Setup:**
- Installed dbt-bigquery and initialized dbt project
- Configured connection to BigQuery (oauth, EU region, 4 threads)
- Created `sources.yml` to reference raw_events table

**dbt Models:**
Converted all Week 2 SQL transformations into managed dbt models:
- `stg_events.sql` - Staging layer with data quality flags
- `dim_products.sql` - Product dimension
- `dim_customers.sql` - Customer dimension (excludes NULLs)
- `fct_order_lines.sql` - Line-level transaction detail
- `fct_orders.sql` - Aggregated order headers

**Key Decisions:**

1. **Sources vs hardcoded table paths**:
   - Defined raw_events in `sources.yml` using `{{ source() }}`
   - Makes code portable across environments
   - Enables data lineage tracking

2. **Refs for dependencies**:
   - Used `{{ ref('stg_events') }}` instead of hardcoded paths
   - dbt automatically determines run order based on dependencies
   - Single source of truth for table locations

3. **Materialization strategy**:
   - All models materialized as `table` (not views)
   - Facts partitioned by load_date for query performance
   - Dimensions not partitioned (small, queried by key)

4. **Started with full refresh**:
   - All models rebuild from scratch on each run
   - Simpler to implement and validate
   - Incremental loading deferred to Week 6

**Learnings:**
- dbt separation of concerns: config (how to build) vs logic (what to build)
- Build SQL transformations first, then move to dbt for governance
- `{{ config() }}` and `{{ ref() }}` are the core dbt syntax for model management
- Profile credentials stored globally (~/.dbt/), not in project repo

---

### Week 4: Data Modelling & Tests ✅

**What I Built:**

**Model Organization:**
Restructured dbt project into layered architecture:
- `staging/` - Interface to raw data (stg_events)
- `marts/dimensions/` - Business entities (dim_customers, dim_products)
- `marts/facts/` - Business events (fct_order_lines, fct_orders)

**Data Quality Tests:**
Added 22 dbt tests across all models:
- **Staging (4 tests):** Validated critical fields (invoice_no, stock_code, invoice_date, load_date) are not null
- **Dimensions (5 tests):** Primary keys are unique and not null; required attributes present
- **Facts (13 tests):** All critical fields validated for completeness

**Key Decisions:**

1. **Layered model structure**:
   - Staging = clean interface to raw data
   - Marts = business-oriented layer for analysis
   - Clear separation makes it obvious where new models belong

2. **Test strategy - conservative approach**:
   - Only test conditions that should never be violated
   - Primary keys: not_null + unique
   - Foreign keys: not_null (except customer_id in facts - guests allowed)
   - Skip testing obvious things (data types - BigQuery enforces these)

3. **Schema files by layer**:
   - Separate schema.yml in each folder (staging, dimensions, facts)
   - Tests live close to the models they validate
   - Easier to maintain as project grows

4. **What we didn't test**:
   - customer_id in facts (NULLs valid for guest purchases)
   - description in dim_products (8 known nulls exist, not sure if problematic)
   - Data types (redundant - table creation enforces these)
   - Business logic calculations (deferred - can add custom tests later if needed)

**Learnings:**
- Start with simple tests (not_null, unique) - they catch most issues
- Don't test everything - focus on what breaks downstream if violated
- Organized folder structure pays off immediately when adding tests
- dbt's `--select` flag makes it easy to run subset of tests during development

---
## Current Architecture

    Source Data (Excel)
        ↓
    [Python Ingestion Script]
        ↓
    raw_events (partitioned)
        ↓
    [dbt models]
        ↓
    staging/
        └── stg_events (cleaned + flagged)
            ↓
        marts/
            ├── dimensions/
            │   ├── dim_customers
            │   └── dim_products
            └── facts/
                ├── fct_order_lines
                └── fct_orders

---

## Uncertainties & Future Decisions

1. **Special stock codes**: Should POST/M/DOT/D/C2 be filtered out entirely or kept for financial reconciliation?
2. **Negative quantities**: Current approach preserves them - may need separate returns analysis in mart layer
3. **Slowly changing dimensions**: Products/customers assumed static for now - no SCD2 tracking yet
4. **Incremental loading strategy**: Currently loading single dates - need to handle late-arriving data
5. **Data quality thresholds**: At what point do quality issues warrant pipeline alerts?
6. **Custom tests**: Should we add tests for business logic (e.g., line_value = quantity × unit_price)?
7. **Product descriptions**: 8 products have NULL descriptions - acceptable or data quality issue?

---

## Next Steps

**Week 5:** Orchestration with Airflow
- Set up Airflow environment
- Create DAG to run ingestion script + dbt models
- Schedule pipeline execution
- Add basic error handling and logging

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
    ├── ecommerce_dbt/
    │   ├── models/
    │   │   ├── staging/
    │   │   │   ├── stg_events.sql
    │   │   │   ├── sources.yml
    │   │   │   └── schema.yml
    │   │   └── marts/
    │   │       ├── dimensions/
    │   │       │   ├── dim_customers.sql
    │   │       │   ├── dim_products.sql
    │   │       │   └── schema.yml
    │   │       └── facts/
    │   │           ├── fct_order_lines.sql
    │   │           ├── fct_orders.sql
    │   │           └── schema.yml
    │   ├── dbt_project.yml
    │   └── ...
    ├── README.md
    ├── requirements.txt
    └── .gitignore

---

## Technologies

- **Python 3.12** - Data ingestion and transformation
- **Google BigQuery** - Cloud data warehouse
- **Pandas** - Data manipulation
- **SQL** - Data transformation
- **dbt** - Data transformation, testing, and documentation framework
- Coming: **Airflow** (orchestration)