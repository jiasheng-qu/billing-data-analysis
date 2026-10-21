# Billing Data Quality Checks

A reusable SQL script that runs five data quality checks on invoice data
(uniqueness, completeness, validity, consistency) and summarizes the results
in one table.

**Tools:** SQLite
**Data:** 12 rows of synthetic invoice data with 6 planted issues (no real company data)

## Checks

| # | Dimension | Rule |
|---|---|---|
| 1 | Uniqueness | Duplicate invoice_id |
| 2 | Uniqueness | Same customer, service, date and amount under different invoice IDs |
| 3 | Completeness | Missing customer_id or status |
| 4 | Validity | Amount <= 0 |
| 5 | Consistency | due_date earlier than invoice_date |

## Expected summary

| check_name | issue_count |
|---|---|
| 1 Duplicate invoice_id (groups) | 1 |
| 2 Possible duplicate billing (groups) | 1 |
| 3 Missing key fields (rows) | 2 |
| 4 Amount <= 0 (rows) | 2 |
| 5 Due date before invoice date (rows) | 1 |

## How to run

```bash
sqlite3 :memory: < billing_data_quality.sql
```

## Key takeaway

`WHERE status <> 'VOID'` excludes rows where status is NULL, so completeness
checks must use `IS NULL` explicitly.

## Next step

Credit memos are legitimately negative. Add a `document_type` column and
exclude `'CREDIT'` from Check 4 so the report flags only real problems.
