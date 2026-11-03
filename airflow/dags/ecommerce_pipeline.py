from airflow import DAG
from datetime import datetime, timedelta
from airflow.providers.standard.operators.bash import BashOperator

with DAG(
    dag_id="ecommerce_etl",
    start_date=datetime(2010, 12, 1),
    schedule="@daily", # Daily trigger
    catchup=False,  # No automatic backfilling
    max_active_runs=1,
) as dag:
     
    run_ingestion = BashOperator(
        task_id="run_ingestion",
        bash_command="cd ~/Documents/GitHub/ecommerce-data-pipeline && source .venv/bin/activate && python src/ingestion.py --date {{ ds }}",
        retries=2,
        retry_delay=timedelta(minutes=2),
    )

    run_dbt = BashOperator(
        task_id="run_dbt",
        bash_command="cd ~/Documents/GitHub/ecommerce-data-pipeline/ecommerce_dbt && source ../.venv/bin/activate && dbt run",
    )

    run_dbt_test = BashOperator(
        task_id="run_dbt_test",
        bash_command="cd ~/Documents/GitHub/ecommerce-data-pipeline/ecommerce_dbt && source ../.venv/bin/activate && dbt test",
    )

    run_ingestion >> run_dbt >> run_dbt_test