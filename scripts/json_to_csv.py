"""Convert the two JSON raw files to CSV so the SQL layer ingests CSV only.

Run from the repo root:  python3 scripts/json_to_csv.py
Outputs land in raw/ (gitignored, like all raw data).
"""
import csv
import json
from pathlib import Path

RAW = Path(__file__).resolve().parent.parent / "raw"

# mcc_codes.json: {"5812": "Eating Places and Restaurants", ...}
with open(RAW / "mcc_codes.json") as f:
    mcc = json.load(f)
with open(RAW / "mcc_codes.csv", "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["mcc_code", "mcc_description"])
    w.writerows(sorted(mcc.items()))
print(f"mcc_codes.csv: {len(mcc):,} rows")

# train_fraud_labels.json: {"target": {"10649266": "No", ...}}
with open(RAW / "train_fraud_labels.json") as f:
    labels = json.load(f)["target"]
with open(RAW / "fraud_labels.csv", "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["transaction_id", "is_fraud"])
    w.writerows((tid, 1 if v == "Yes" else 0) for tid, v in labels.items())
print(f"fraud_labels.csv: {len(labels):,} rows")
