# Data provenance

**Source:** Kaggle — "Financial Transactions Dataset: Analytics" by computingvictor
https://www.kaggle.com/datasets/computingvictor/transactions-fraud-datasets

**Downloaded:** June 2026 <!-- TODO: exact date -->
**Licence:** <!-- TODO: copy licence name from the Kaggle page sidebar -->
**Nature of data:** Synthetic banking data (no real customer PII).

## Verified at staging (raw/)

| File | Size | Rows / entries | Notes |
|---|---|---|---|
| transactions_data.csv | 1.2 GB | 13,305,915 data rows | 12 columns; fact source |
| users_data.csv | 161 KB | 2,000 data rows | customer demographics |
| cards_data.csv | 498 KB | 6,146 data rows | card attributes, FK client_id |
| mcc_codes.json | 4.7 KB | 109 codes | merchant category lookup |
| train_fraud_labels.json | 152 MB | 8,914,963 labels | "Yes"/"No" keyed by transaction id |

## Known caveats (recorded before analysis)

- Fraud labels cover **8.91M of 13.31M transactions (67%)** — the labelled
  training split only. Fraud metrics will be computed on labelled
  transactions and this will be stated on the dashboard.
- Labelled fraud rate ≈ **0.15%** (13,332 of 8.91M) — heavy class imbalance,
  expected for card fraud.
- File timestamps show the dataset was published 2024-10-31.
