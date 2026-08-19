-- ============================================================================
-- 05_export.sql — export star schema to Parquet for Power BI
-- Run:  duckdb bank.duckdb → .read sql/05_export.sql
-- Parquet: columnar, compressed, typed — Power BI reads it natively,
-- and the 13M-row fact shrinks ~10x vs CSV.
-- ============================================================================
COPY model.fact_transactions TO 'model/fact_transactions.parquet' (FORMAT PARQUET, COMPRESSION ZSTD);
COPY model.dim_customer      TO 'model/dim_customer.parquet'      (FORMAT PARQUET);
COPY model.dim_card          TO 'model/dim_card.parquet'          (FORMAT PARQUET);
COPY model.dim_mcc           TO 'model/dim_mcc.parquet'           (FORMAT PARQUET);
COPY model.dim_date          TO 'model/dim_date.parquet'          (FORMAT PARQUET);
COPY model.customer_value    TO 'model/customer_value.parquet'    (FORMAT PARQUET);
COPY model.monthly_trend     TO 'model/monthly_trend.parquet'     (FORMAT PARQUET);
