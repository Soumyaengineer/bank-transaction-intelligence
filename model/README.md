# Model exports (not committed)

Parquet files for the Power BI import. Rebuild from the repo root:

    python3 scripts/json_to_csv.py
    duckdb bank.duckdb -c ".read sql/01_staging.sql" -c ".read sql/02_dimensions.sql" -c ".read sql/03_fact.sql" -c ".read sql/04_analysis.sql" -c ".read sql/05_export.sql"

Star schema: fact_transactions + dim_customer, dim_card, dim_mcc, dim_date
(+ customer_value, monthly_trend analysis tables).
