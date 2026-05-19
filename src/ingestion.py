from google.cloud import bigquery
import pandas as pd
from datetime import datetime, timezone
import argparse

# Parse command-line arguments
parser = argparse.ArgumentParser(description='Load e-commerce data for a specific date')
parser.add_argument('--date', required=True, help='Date to load (format: YYYY-MM-DD)')
args = parser.parse_args()

# Define parameters
source_event_date = args.date  # Now comes from command line
load_date = datetime.now(timezone.utc).date()
source_file = "data/Online_Retail.xlsx"
project_id = "ecommerce-events-data-pipeline"
dataset_id = "ecommerce_events"
table_id = "raw_events"

# Convert source_event_date once
source_event_date_dt = pd.to_datetime(source_event_date).date()

# Load the Excel file
df = pd.read_excel(source_file)

print(f"Total rows loaded: {len(df)}")

# Convert InvoiceDate to datetime
df['InvoiceDate'] = pd.to_datetime(df['InvoiceDate'])

# Filter rows where InvoiceDate date = source_event_date
df_filtered = df[df['InvoiceDate'].dt.date == source_event_date_dt].copy()

# Add metadata columns
df_filtered['ingested_at'] = datetime.now(timezone.utc)
df_filtered['source_file'] = source_file
df_filtered['source_row_number'] = df_filtered.index + 2  # +2 because Excel rows start at 1 and there's a header
df_filtered['load_date'] = load_date
df_filtered = df_filtered.rename(columns={
    "InvoiceNo": "invoice_no",
    "StockCode": "stock_code",
    "Description": "description",
    "Quantity": "quantity",
    "InvoiceDate": "invoice_date",
    "UnitPrice": "unit_price",
    "CustomerID": "customer_id",
    "Country": "country"
})

# Print results AFTER renaming
print(f"\nSelected source event date: {source_event_date}")
print(f"Pipeline load date: {load_date}")
print(f"Row count for source event date: {len(df_filtered)}")
print(f"Min invoice_date: {df_filtered['invoice_date'].min()}")
print(f"Max invoice_date: {df_filtered['invoice_date'].max()}")

# Show first few rows with metadata
print(f"\nFirst 3 rows with metadata:")
print(df_filtered[['invoice_no', 'ingested_at', 'source_file', 'source_row_number', 'load_date']].head(3))
print(df_filtered.columns.tolist())

# Ensure correct data types before loading to BigQuery

string_columns = [
    "invoice_no",
    "stock_code",
    "description",
    "customer_id",
    "country",
    "source_file",
]

for col in string_columns:
    df_filtered[col] = df_filtered[col].astype("string")

df_filtered["quantity"] = df_filtered["quantity"].astype("int64")
df_filtered["unit_price"] = df_filtered["unit_price"].astype("float64")
df_filtered["invoice_date"] = pd.to_datetime(df_filtered["invoice_date"])
df_filtered["load_date"] = pd.to_datetime(df_filtered["load_date"]).dt.date

print(df_filtered.dtypes)

# Load into BigQuery
client = bigquery.Client(project=project_id)

table_ref = f"{project_id}.{dataset_id}.{table_id}"

job = client.load_table_from_dataframe(df_filtered, table_ref)
job.result()

destination_table = client.get_table(table_ref)
print(f"BigQuery table now has {destination_table.num_rows} rows")

print(f"\nLoaded {len(df_filtered)} rows to {table_ref}")