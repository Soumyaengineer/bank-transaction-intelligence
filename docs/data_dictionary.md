# Data dictionary

Profiled with DuckDB 1.5.3 on the staged raw files (see docs/data_provenance.md
for row counts). "Raw type" = type as ingested; "Transformation" = what the SQL
layer (sql/) does before the field reaches the star schema.

## transactions_data.csv — 13,305,915 rows → fact_transactions

| Field | Raw type | Transformation / destination | Quality notes |
|---|---|---|---|
| id | BIGINT | fact PK; join key for fraud labels | unique |
| date | TIMESTAMP | fact; date key derived for dim_date | range 2010-01-01 → 2019-10-31, no gaps observed |
| client_id | BIGINT | FK → dim_customer | 1,219 distinct; 0 orphans vs users |
| card_id | BIGINT | FK → dim_card | 4,071 distinct; 0 orphans vs cards |
| amount | VARCHAR | strip `$`, cast DECIMAL(12,2) | `$` prefix on all values; negatives = refunds/credits |
| use_chip | VARCHAR | rename channel ("Chip"/"Swipe"/"Online" from "... Transaction") | 3 clean values |
| merchant_id | BIGINT | kept on fact (no merchant dim — out of scope) | |
| merchant_city / merchant_state | VARCHAR | kept for state-level slicing | state NULL/"ONLINE" for online txns |
| zip | DOUBLE | excluded from model | type-mangled (leading zeros lost); geo beyond state out of scope |
| mcc | BIGINT | FK → dim_mcc | coverage vs 109-code lookup verified at build |
| errors | VARCHAR | kept as error_category on fact | 98.4% NULL (clean); multi-valued in ~600 rows, kept as-is; top value "Insufficient Balance" (130,902) |

## users_data.csv — 2,000 rows → dim_customer

| Field | Raw type | Transformation / destination | Quality notes |
|---|---|---|---|
| id | BIGINT | dim PK | unique, 2,000 |
| current_age | BIGINT | + derived age_band | 18–101 |
| retirement_age, birth_year, birth_month | BIGINT | excluded (not needed for questions) | |
| gender | VARCHAR | kept | Female 1,016 / Male 984 |
| address, latitude, longitude | VARCHAR/DOUBLE | excluded — PII-style + geo out of scope | |
| per_capita_income | VARCHAR | excluded (yearly_income suffices) | `$` prefix |
| yearly_income | VARCHAR | strip `$` → DECIMAL; + derived income_band | `$` prefix |
| total_debt | VARCHAR | strip `$` → DECIMAL; + derived debt_to_income | `$` prefix |
| credit_score | BIGINT | + derived credit_band | 480–850 |
| num_credit_cards | BIGINT | kept | |

Note: 781 of 2,000 customers (39%) have no transactions. KPI denominators use
active customers (1,219) and state so.

## cards_data.csv — 6,146 rows → dim_card

| Field | Raw type | Transformation / destination | Quality notes |
|---|---|---|---|
| id | BIGINT | dim PK | unique, 6,146 |
| client_id | BIGINT | FK → dim_customer | 0 orphans |
| card_brand | VARCHAR | kept | Mastercard, Visa, Amex, Discover |
| card_type | VARCHAR | kept | Credit, Debit, Debit (Prepaid) |
| card_number, cvv | VARCHAR | **excluded — sensitive-style fields, even synthetic** | governance choice, stated in README |
| expires | VARCHAR "MM/YYYY" | cast DATE (first of month) | |
| has_chip | VARCHAR | → BOOLEAN | YES 5,500 / NO 646 |
| num_cards_issued | BIGINT | kept | |
| credit_limit | VARCHAR | strip `$` → DECIMAL | `$` prefix |
| acct_open_date | VARCHAR "MM/YYYY" | cast DATE; + derived account_tenure_years | |
| year_pin_last_changed | BIGINT | excluded | |
| card_on_dark_web | VARCHAR | excluded — constant | "No" for all 6,146 rows (zero variance) |

## mcc_codes.json — 109 entries → dim_mcc

JSON object {code: description}. Unpivoted to two columns (mcc_code BIGINT,
mcc_description VARCHAR). Manual category grouping added for dashboard
readability (109 codes → ~10 groups).

## train_fraud_labels.json — 8,914,963 entries → fact_transactions.is_fraud

JSON object {transaction_id: "Yes"/"No"}. Unpivoted and joined to fact on
transaction id. **Covers 8.91M of 13.31M transactions (67%)** — train split
only. Fact carries is_fraud as three-state: TRUE / FALSE / NULL (unlabelled);
all fraud metrics filter to labelled rows. Labelled fraud rate 0.15%
(13,332 Yes).
