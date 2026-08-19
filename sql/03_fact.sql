-- ============================================================================
-- 03_fact.sql — fact_transactions: one row per transaction (grain: transaction)
-- Prereq: 01_staging.sql, 02_dimensions.sql
-- Run:  duckdb bank.duckdb  →  .read sql/03_fact.sql
-- ============================================================================

-- LEFT JOIN keeps all 13.3M transactions; is_fraud is deliberately
-- three-state:  TRUE = labelled fraud, FALSE = labelled legit,
-- NULL = unlabelled (33% of rows — the untrained split).
-- Fraud measures downstream must filter to labelled rows only.
CREATE OR REPLACE TABLE model.fact_transactions AS
SELECT
    t.transaction_id,
    CAST(t.transaction_ts AS DATE) AS date_key,      -- FK → dim_date
    t.transaction_ts,
    t.client_id,                                     -- FK → dim_customer
    t.card_id,                                       -- FK → dim_card
    t.mcc_code,                                      -- FK → dim_mcc
    t.amount,
    t.channel,
    t.merchant_id,
    t.merchant_city,
    t.merchant_state,
    t.error_category,
    f.is_fraud
FROM staging.transactions t
LEFT JOIN staging.fraud_labels f USING (transaction_id);

-- ----------------------------------------------------------------------------
-- Validation 1: row count unchanged by the join (a fan-out here would mean
-- duplicate transaction_ids in the labels — must be exactly 13,305,915)
-- ----------------------------------------------------------------------------
SELECT COUNT(*) AS fact_rows, 13305915 AS expected FROM model.fact_transactions;

-- Validation 2: label coverage and fraud rate
SELECT
    COUNT(*) FILTER (WHERE is_fraud IS NOT NULL)               AS labelled,
    COUNT(*) FILTER (WHERE is_fraud)                           AS fraud_yes,
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_fraud)
        / COUNT(*) FILTER (WHERE is_fraud IS NOT NULL), 3)     AS fraud_rate_pct
FROM model.fact_transactions;
-- expect: labelled 8,914,963 | fraud_yes 13,332 | rate ~0.150

-- Validation 3: every FK resolves (expect all zeros)
SELECT
    (SELECT COUNT(*) FROM model.fact_transactions f
     LEFT JOIN model.dim_customer d USING (client_id) WHERE d.client_id IS NULL) AS bad_customer_fk,
    (SELECT COUNT(*) FROM model.fact_transactions f
     LEFT JOIN model.dim_card d USING (card_id) WHERE d.card_id IS NULL)          AS bad_card_fk,
    (SELECT COUNT(*) FROM model.fact_transactions f
     LEFT JOIN model.dim_mcc d USING (mcc_code) WHERE d.mcc_code IS NULL)         AS bad_mcc_fk,
    (SELECT COUNT(*) FROM model.fact_transactions f
     LEFT JOIN model.dim_date d USING (date_key) WHERE d.date_key IS NULL)        AS bad_date_fk;
