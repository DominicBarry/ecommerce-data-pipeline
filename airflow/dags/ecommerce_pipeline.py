from airflow import DAG
from datetime import datetime
from airflow.operators.bash import BashOperator

with DAG(
    dag_id="ecommerce_etl",
    start_date=datetime(2024, 5, 16, 9, 0),
    schedule="10 13 * * *",  # Runs at 1:10 PM BST
    catchup=False,
) as dag:
    # tasks will go here
    run_ingestion = BashOperator(
        task_id="run_ingestion",
        bash_command="cd ~/Documents/GitHub/ecommerce-data-pipeline && source .venv/bin/activate && python src/ingestion.py"
    )

    run_dbt = BashOperator(
        task_id="run_dbt",
        bash_command="cd ~/Documents/GitHub/ecommerce-data-pipeline/ecommerce_dbt && source ../.venv/bin/activate && dbt run"
    )

    # Set task dependency
    run_ingestion >> run_dbt