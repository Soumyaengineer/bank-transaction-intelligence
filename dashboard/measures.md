# DAX measures

Defined in a dedicated `_Measures` table.

```dax
Total Value = SUM(fact_transactions[amount])

Txn Count = COUNTROWS(fact_transactions)

Avg Txn Value = DIVIDE([Total Value], [Txn Count])

Active Customers = DISTINCTCOUNT(fact_transactions[client_id])

Txns per Customer = DIVIDE([Txn Count], [Active Customers])

Labelled Txns = CALCULATE([Txn Count], NOT ISBLANK(fact_transactions[is_fraud]))

Fraud Txns = CALCULATE([Txn Count], fact_transactions[is_fraud] = TRUE())

Fraud Rate % = DIVIDE([Fraud Txns], [Labelled Txns])

Fraud $ Exposure = CALCULATE([Total Value], fact_transactions[is_fraud] = TRUE())

Top Decile Value % =
DIVIDE(
    CALCULATE(SUM(customer_value[total_value]), customer_value[value_decile] = 1),
    SUM(customer_value[total_value])
)
```

**Note on the fraud denominator:** `Fraud Rate %` divides by `Labelled Txns`,
not all transactions. Only 8.9M of 13.3M transactions carry a fraud label
(67%), so dividing by the full row count would understate the rate by a third.
This is stated on the Fraud Risk page.
