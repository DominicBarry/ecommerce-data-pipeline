import pandas as pd
from datetime import datetime, timezone

# Define parameters
load_date = "2010-12-01"
source_file = "data/Online_Retail.xlsx"

# Convert load_date once
load_date_dt = pd.to_datetime(load_date).date()

# Load the Excel file
df = pd.read_excel(source_file)

print(f"Total rows loaded: {len(df)}")

# Convert InvoiceDate to datetime
df['InvoiceDate'] = pd.to_datetime(df['InvoiceDate'])

# Filter rows where InvoiceDate date = load_date
df_filtered = df[df['InvoiceDate'].dt.date == load_date_dt].copy()

# Add metadata columns
df_filtered['ingested_at'] = datetime.now(timezone.utc)
df_filtered['source_file'] = source_file
df_filtered['source_row_number'] = df_filtered.index + 2  # +2 because Excel rows start at 1 and there's a header
df_filtered['load_date'] = load_date_dt
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
print(f"\nSelected load date: {load_date}")
print(f"Row count for that date: {len(df_filtered)}")
print(f"Min invoice_date: {df_filtered['invoice_date'].min()}")
print(f"Max invoice_date: {df_filtered['invoice_date'].max()}")

# Show first few rows with metadata
print(f"\nFirst 3 rows with metadata:")
print(df_filtered[['invoice_no', 'ingested_at', 'source_file', 'source_row_number', 'load_date']].head(3))
print(df_filtered.columns.tolist())