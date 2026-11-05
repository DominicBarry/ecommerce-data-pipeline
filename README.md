# E-commerce Data Pipeline

> End-to-end batch pipeline: loads e-commerce transactions into BigQuery, transforms them into a tested star schema with dbt, and orchestrates daily loads with Airflow. Built as a portfolio project.

**Tech Stack:** Python • BigQuery • dbt • Apache Airflow

**Dataset:** [Online Retail Dataset](https://archive.ics.uci.edu/dataset/352/online+retail) - 541,000+ transactions from a UK online retailer (2010-2011). The pipeline has been run on December 2010 (42,481 rows, 20 trading days); the same backfill process loads any date range.

---

## Architecture

### System Diagram
![Architecture Diagram](screenshots/architecture_diagram.png)

### Data Flow

**1. Ingestion Layer**
Python script extracts transactions for a specific date from Excel source, adds metadata (ingested_at, source_file, load_date), and loads to BigQuery raw_events table (partitioned by load_date). Re-running a date replaces it (idempotent load).

**2. Staging Layer**
dbt standardizes text (UPPER, TRIM), flags quality issues (negative quantities, missing customer IDs), calculates line_value, and removes exact duplicates.

**3. Marts Layer**
dbt builds dimensional model:
- **Dimensions:** dim_products (one row per stock_code), dim_customers (one row per customer_id, excludes guests)
- **Facts:** fct_order_lines (transaction-level detail), fct_orders (order-level aggregates)

### Warehouse Design

**Dimensional Model:**

Raw → Staging → Marts (Dimensions + Facts)

**Key Design Principles:**
- Raw layer accepts all data (no filtering)
- Staging layer cleans and flags issues (removes exact duplicates)
- Dimensions contain descriptive attributes (who, what, where)
- Facts contain metrics and foreign keys (how much, when)
- Quality flags enable filtered analysis without data loss

---

## Key Features

### ✅ Incremental Data Ingestion
Loads one date per run, mirroring production batch jobs. Re-running a date replaces it (idempotent load), and Airflow backfills date ranges in sequence.

### ✅ Deduplication Logic
Staging removes exact duplicates (500 in December 2010) using `ROW_NUMBER()` over all business columns, covering source duplicates and re-runs while keeping genuine repeat lines. An earlier, narrower key wrongly removed 170 genuine lines; see BUILD_NOTES.md.

### ✅ Automated Data Quality Testing
28 dbt tests run on every pipeline run:
- **22 schema tests:** primary key uniqueness and completeness, required fields
- **6 business logic tests:** staging reconciles to raw, line values and order totals add up, one customer and one date per invoice, totals have the right sign for the invoice type

Airflow runs them as the final pipeline step; a failure stops the run before the data is used.

### ✅ Workflow Orchestration
Three dependent tasks: ingest → transform → test. Ingestion retries twice; tests don't, as a failure means bad data, not a temporary fault. Runs are manual or by backfill (daily schedule off, as Airflow runs locally).

### ✅ CI/CD and Published Documentation
Every push to `main` runs a GitHub Actions workflow that rebuilds and tests all models in a separate CI dataset, then publishes the dbt docs to GitHub Pages. [View the live docs](https://dominicbarry.github.io/ecommerce-data-pipeline/).

### ✅ Dimensional Modeling
Star schema: 2 dimensions (products, customers) and 2 fact tables (order lines, orders), with fact tables partitioned by load date.

---

## Design Decisions & Trade-offs

**Why dimensional modeling?**
Separates descriptive attributes from metrics, enabling efficient aggregation queries. Trade-off: More complex setup, simpler long-term analysis.

**Why deduplicate in staging, not ingestion?**
Raw layer = immutable audit trail. Staging handles deduplication, allowing reprocessing with different rules. Trade-off: raw keeps source duplicates, so anything reading raw directly must deduplicate.

**Why full-refresh dbt?**
Rebuilds take seconds at this volume and always match raw. Trade-off: rebuild time grows with data; incremental models would be the next step at scale.

**Other choices:**
- Local Airflow (zero cost for learning; production would use cloud)
- Quality flags vs. dropping bad rows (preserves data, requires analyst filtering)

---

## Technologies

| Component | Technology | Purpose |
|-----------|-----------|---------|
| Ingestion | Python + Pandas | Extract and load from Excel to BigQuery |
| Warehouse | Google BigQuery | Cloud data warehouse |
| Transformation | dbt | SQL-based transformations, testing, documentation |
| Orchestration | Apache Airflow | Workflow scheduling and monitoring |
| Version Control | Git | Code management |
| CI/CD | GitHub Actions | Builds and tests every push in a separate dataset |
| Documentation | dbt docs + GitHub Pages | Model, column and lineage docs, republished on every push |

---

## Repository Structure
```
ecommerce-data-pipeline/
├── .github/workflows/      # CI: build, test and publish docs on every push
├── src/                    # Python ingestion script
├── ecommerce_dbt/          # dbt project
│   ├── models/
│   │   ├── staging/        # Cleaning and deduplication
│   │   └── marts/          # Dimensional model (dims + facts)
│   ├── tests/              # Business logic tests
│   └── ci/                 # dbt profile used by CI
├── airflow/dags/           # Orchestration DAG
├── data/                   # Source data (Excel)
├── screenshots/            # Images used in this README
└── sql/                    # Legacy SQL scripts (pre-dbt)
```

## Running It Locally

Requires Python 3.12 and a Google Cloud project with BigQuery (EU location).

```bash
# 1. Set up the environment
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# 2. Log in to Google Cloud
gcloud auth application-default login

# 3. Create the raw table: run sql/01_create_raw_events.sql in BigQuery

# 4. Load one day and build the warehouse
python src/ingestion.py --date 2010-12-01
cd ecommerce_dbt
dbt build      # builds all models and runs all tests
```

Airflow is installed separately; see the [Airflow installation guide](https://airflow.apache.org/docs/apache-airflow/stable/installation/). This project uses Airflow 3.

dbt needs a profile named `ecommerce_dbt` in `~/.dbt/profiles.yml` (BigQuery, `oauth`, dataset `ecommerce_events`).

To run through Airflow instead, set `AIRFLOW_HOME` to the repo's `airflow/` folder, run `airflow standalone`, and backfill a date range:
```bash
airflow backfill create --dag-id ecommerce_etl --from-date 2010-12-01 --to-date 2010-12-31 --max-active-runs 1
```

Note: the project ID is set in `src/ingestion.py` and `sources.yml`, and the DAG uses local paths, so these need changing to run it elsewhere.

---

## Screenshots

### Airflow DAG Execution
![Airflow DAG](screenshots/airflow_dag.png)
*Ingestion, transformation and testing run in sequence; a failed test fails the run*

### dbt Lineage Graph
![dbt Lineage](screenshots/dbt_lineage.png)
*Data flow from staging through dimensional model*

### BigQuery Dimensional Model
![BigQuery Tables](screenshots/bigquery_tables.png)
*Dimensional model in BigQuery*

---

## Contact

Dominic Barry  
[LinkedIn](https://www.linkedin.com/in/dom-barry/) • [Portfolio](https://dominicbarry.github.io/portfolio) • [GitHub](https://github.com/DominicBarry)