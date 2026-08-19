-- ============================================================================
-- 01_staging.sql — typed, cleaned staging tables from raw files
-- Prereq: python3 scripts/json_to_csv.py  (converts the two JSON files)
-- Run from repo root:  duckdb bank.duckdb  →  .read sql/01_staging.sql
-- Rebuildable: drops and recreates everything it owns.
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS staging;

-- ----------------------------------------------------------------------------
-- Transactions (expect 13,305,915 rows)
-- quote/escape forced because the errors field contains quoted, comma-joined
-- values ("Bad PIN,Insufficient Balance") that defeat sampled auto-detection.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TABLE staging.transactions AS
SELECT
    id                                              AS transaction_id,
    date                                            AS transaction_ts,
    client_id,
    card_id,
    CAST(replace(amount, '$', '') AS DECIMAL(12,2)) AS amount,         -- '$-77.00' → -77.00 (negatives = refunds)
    replace(use_chip, ' Transaction', '')           AS channel,        -- 'Swipe Transaction' → 'Swipe'
    merchant_id,
    merchant_city,
    merchant_state,                                                    -- NULL for online txns
    mcc                                             AS mcc_code,
    errors                                          AS error_category  -- NULL = clean txn (98.4%)
FROM read_csv('raw/transactions_data.csv', quote='"', escape='"');

-- ----------------------------------------------------------------------------
-- Users (expect 2,000 rows) — money fields arrive as '$59696' strings
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TABLE staging.users AS
SELECT
    id                                                    AS client_id,
    current_age,
    gender,
    CAST(replace(yearly_income, '$', '') AS DECIMAL(12,2)) AS yearly_income,
    CAST(replace(total_debt,    '$', '') AS DECIMAL(12,2)) AS total_debt,
    credit_score,
    num_credit_cards
FROM read_csv('raw/users_data.csv');
-- Excluded by design (see docs/data_dictionary.md): address, lat/long (geo out
-- of scope), per_capita_income (yearly_income suffices), birth fields.

-- ----------------------------------------------------------------------------
-- Cards (expect 6,146 rows) — MM/YYYY dates parsed to first-of-month
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TABLE staging.cards AS
SELECT
    id                                                      AS card_id,
    client_id,
    card_brand,
    card_type,
    CAST(strptime('01/' || expires,        '%d/%m/%Y') AS DATE) AS expiry_date,
    (has_chip = 'YES')                                      AS has_chip,
    num_cards_issued,
    CAST(replace(credit_limit, '$', '') AS DECIMAL(12,2))   AS credit_limit,
    CAST(strptime('01/' || acct_open_date, '%d/%m/%Y') AS DATE) AS acct_open_date
FROM read_csv('raw/cards_data.csv');
-- Excluded by design: card_number, cvv (sensitive-style), card_on_dark_web
-- (constant 'No'), year_pin_last_changed.

-- ----------------------------------------------------------------------------
-- MCC lookup (expect 109) and fraud labels (expect 8,914,963)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TABLE staging.mcc AS
SELECT mcc_code, mcc_description
FROM read_csv('raw/mcc_codes.csv');

CREATE OR REPLACE TABLE staging.fraud_labels AS
SELECT transaction_id, CAST(is_fraud AS BOOLEAN) AS is_fraud
FROM read_csv('raw/fraud_labels.csv');

-- ----------------------------------------------------------------------------
-- Validation — compare against expected counts before moving on
-- ----------------------------------------------------------------------------
SELECT 'transactions' AS t, COUNT(*) AS rows, 13305915 AS expected FROM staging.transactions
UNION ALL SELECT 'users',        COUNT(*), 2000    FROM staging.users
UNION ALL SELECT 'cards',        COUNT(*), 6146    FROM staging.cards
UNION ALL SELECT 'mcc',          COUNT(*), 109     FROM staging.mcc
UNION ALL SELECT 'fraud_labels', COUNT(*), 8914963 FROM staging.fraud_labels;
