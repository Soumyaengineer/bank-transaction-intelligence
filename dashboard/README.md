# Dashboard

**Screenshots:** `screenshots/` — the three report pages.

| Page | What it answers |
|---|---|
| 01_executive_overview | Which segments drive transaction value (Q1) |
| 02_segment_detail | Drill-through detail — *shown filtered to the 45-54 age band* |
| 03_fraud_risk | Where fraud concentrates by merchant, channel, card, age (Q2, Q3) |

**Theme:** `bank_theme.json` — applied via View > Themes > Browse for themes.

## The .pbix is not in this repo

The Power BI file is 330 MB (13.3M-row import), over GitHub's 100 MB limit.
To rebuild it:

1. Download the raw data (see `raw/README.md`) into `raw/`.
2. `python3 scripts/json_to_csv.py`
3. Run `sql/01_staging.sql` through `sql/05_export.sql` in DuckDB — this writes
   the star schema to `model/*.parquet`.
4. Power BI Desktop > Get Data > Folder > select `model/` > Transform Data >
   add each parquet file as its own query.
5. Relationships (all many-to-one, single direction, fact on the many side):
   fact_transactions[client_id] > dim_customer[client_id];
   [card_id] > dim_card; [mcc_code] > dim_mcc; [date_key] > dim_date;
   customer_value[client_id] > dim_customer[client_id] (1:1).
   Mark dim_date as the date table.
6. Measures: see `dashboard/measures.md`.
