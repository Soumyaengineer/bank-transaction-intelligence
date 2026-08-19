-- ============================================================================
-- 02_dimensions.sql — dimension tables for the star schema
-- Prereq: 01_staging.sql
-- Run:  duckdb bank.duckdb  →  .read sql/02_dimensions.sql
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS model;

-- ----------------------------------------------------------------------------
-- dim_customer — one row per customer, with analysis bands.
-- Bands are defined here (not in DAX) so every tool downstream shares one
-- definition. credit_band uses standard FICO ranges — defensible, not invented.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TABLE model.dim_customer AS
SELECT
    client_id,
    current_age,
    CASE
        WHEN current_age < 25 THEN '18-24'
        WHEN current_age < 35 THEN '25-34'
        WHEN current_age < 45 THEN '35-44'
        WHEN current_age < 55 THEN '45-54'
        WHEN current_age < 65 THEN '55-64'
        ELSE '65+'
    END AS age_band,
    gender,
    yearly_income,
    CASE
        WHEN yearly_income < 30000  THEN '<$30K'
        WHEN yearly_income < 50000  THEN '$30-50K'
        WHEN yearly_income < 75000  THEN '$50-75K'
        WHEN yearly_income < 100000 THEN '$75-100K'
        ELSE '$100K+'
    END AS income_band,
    total_debt,
    ROUND(total_debt / NULLIF(yearly_income, 0), 2) AS debt_to_income,
    credit_score,
    CASE                                   -- standard FICO bands
        WHEN credit_score < 580 THEN 'Poor (<580)'
        WHEN credit_score < 670 THEN 'Fair (580-669)'
        WHEN credit_score < 740 THEN 'Good (670-739)'
        WHEN credit_score < 800 THEN 'Very Good (740-799)'
        ELSE 'Excellent (800+)'
    END AS credit_band,
    num_credit_cards
FROM staging.users;

-- ----------------------------------------------------------------------------
-- dim_card — one row per card. Tenure measured at the dataset snapshot date
-- (2019-10-31, the last transaction), not today's date: the data is frozen
-- in 2019, so "years since open" must be too.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TABLE model.dim_card AS
SELECT
    card_id,
    client_id,
    card_brand,
    card_type,
    has_chip,
    num_cards_issued,
    credit_limit,
    expiry_date,
    acct_open_date,
    ROUND(datediff('day', acct_open_date, DATE '2019-10-31') / 365.25, 1)
        AS account_tenure_years
FROM staging.cards;

-- ----------------------------------------------------------------------------
-- dim_mcc — 109 codes grouped into readable categories using standard
-- ISO 18245 MCC ranges (109 slicer values is unusable on a dashboard).
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TABLE model.dim_mcc AS
SELECT
    mcc_code,
    mcc_description,
    CASE
        WHEN mcc_code BETWEEN 4000 AND 4799 THEN 'Transport & Travel'
        WHEN mcc_code BETWEEN 4800 AND 4999 THEN 'Utilities & Telecom'
        WHEN mcc_code BETWEEN 5000 AND 5499 THEN 'Retail & Grocery'
        WHEN mcc_code BETWEEN 5500 AND 5599 THEN 'Automotive'
        WHEN mcc_code BETWEEN 5600 AND 5699 THEN 'Clothing'
        WHEN mcc_code = 5812 OR mcc_code = 5813 OR mcc_code = 5814
                                            THEN 'Dining'
        WHEN mcc_code BETWEEN 5700 AND 5999 THEN 'Specialty Retail'
        WHEN mcc_code BETWEEN 6000 AND 6299 THEN 'Financial Services'
        WHEN mcc_code BETWEEN 7000 AND 7299 THEN 'Personal Services'
        WHEN mcc_code BETWEEN 7300 AND 7999 THEN 'Business & Entertainment'
        WHEN mcc_code BETWEEN 8000 AND 8999 THEN 'Health & Professional'
        ELSE 'Other'
    END AS mcc_group
FROM staging.mcc;

-- ----------------------------------------------------------------------------
-- dim_date — one row per day across the transaction span.
-- Built in SQL (not Power BI auto date) so the grain is explicit and portable.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TABLE model.dim_date AS
SELECT
    CAST(d AS DATE)                       AS date_key,
    EXTRACT(year  FROM d)                 AS year,
    EXTRACT(quarter FROM d)               AS quarter,
    EXTRACT(month FROM d)                 AS month_num,
    strftime(d, '%b')                     AS month_name,
    strftime(d, '%Y-%m')                  AS year_month,
    EXTRACT(dow FROM d)                   AS day_of_week,   -- 0 = Sunday
    strftime(d, '%a')                     AS day_name,
    EXTRACT(dow FROM d) IN (0, 6)         AS is_weekend
FROM range(DATE '2010-01-01', DATE '2019-11-01', INTERVAL 1 DAY) t(d);

-- ----------------------------------------------------------------------------
-- Validation
-- ----------------------------------------------------------------------------
SELECT 'dim_customer' AS t, COUNT(*) AS rows, 2000 AS expected FROM model.dim_customer
UNION ALL SELECT 'dim_card', COUNT(*), 6146 FROM model.dim_card
UNION ALL SELECT 'dim_mcc',  COUNT(*), 109  FROM model.dim_mcc
UNION ALL SELECT 'dim_date', COUNT(*), 3591 FROM model.dim_date;

-- Band sanity — no band should be empty or hold ~everything
SELECT income_band, COUNT(*) AS customers FROM model.dim_customer GROUP BY 1 ORDER BY 2 DESC;
SELECT mcc_group, COUNT(*) AS codes FROM model.dim_mcc GROUP BY 1 ORDER BY 2 DESC;
