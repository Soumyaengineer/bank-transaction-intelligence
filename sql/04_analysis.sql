-- ============================================================================
-- 04_analysis.sql — window-function layer: customer value & recency, trends
-- Prereq: 03_fact.sql   Run:  duckdb bank.duckdb → .read sql/04_analysis.sql
-- Snapshot date = 2019-10-31 (last transaction in dataset).
-- ============================================================================

-- One row per ACTIVE customer (1,219). Window functions:
--   NTILE(10)  → value decile (1 = top 10% by spend)
--   SUM() OVER () → share of total value without a second query
CREATE OR REPLACE TABLE model.customer_value AS
SELECT
    client_id,
    COUNT(*)                                        AS txn_count,
    SUM(amount)                                     AS total_value,
    ROUND(AVG(amount), 2)                           AS avg_txn_value,
    MAX(date_key)                                   AS last_txn_date,
    datediff('day', MAX(date_key), DATE '2019-10-31') AS recency_days,
    NTILE(10) OVER (ORDER BY SUM(amount) DESC)      AS value_decile,
    ROUND(100.0 * SUM(amount) / SUM(SUM(amount)) OVER (), 3) AS pct_of_total_value
FROM model.fact_transactions
GROUP BY client_id;

-- Monthly trend with running cumulative value and 3-month moving average
CREATE OR REPLACE TABLE model.monthly_trend AS
SELECT
    strftime(date_key, '%Y-%m')                     AS year_month,
    SUM(amount)                                     AS monthly_value,
    COUNT(*)                                        AS monthly_txns,
    SUM(SUM(amount)) OVER (ORDER BY strftime(date_key, '%Y-%m'))  AS running_value,
    ROUND(AVG(SUM(amount)) OVER (ORDER BY strftime(date_key, '%Y-%m')
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2)             AS moving_avg_3m
FROM model.fact_transactions
GROUP BY 1;

-- Validation
SELECT COUNT(*) AS customers, 1219 AS expected FROM model.customer_value;
SELECT COUNT(*) AS months, 118 AS expected FROM model.monthly_trend;
-- Top-decile share (answers a KPI directly — note this number!)
SELECT ROUND(SUM(pct_of_total_value), 1) AS top_decile_pct_of_value
FROM model.customer_value WHERE value_decile = 1;
