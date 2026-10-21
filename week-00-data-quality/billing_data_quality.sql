-- billing_data_quality.sql
-- Purpose: Run five data quality checks on invoice data before it feeds AR reporting.
-- Check 1-2 (Uniqueness): duplicate invoice IDs and possible double billing.
-- Check 3 (Completeness): invoices missing customer or status.
-- Check 4 (Validity): zero or negative amounts (credit memos should be excluded).
-- Check 5 (Consistency): due dates earlier than invoice dates.
-- Note: "status <> 'VOID'" silently drops NULL statuses; use IS NULL checks explicitly.

-- ------------------------------------------------------------
-- Setup: synthetic invoice data with 6 planted issues
-- ------------------------------------------------------------
DROP TABLE IF EXISTS invoices;

CREATE TABLE invoices (
  invoice_id   TEXT,
  customer_id  TEXT,
  service_code TEXT,
  invoice_date DATE,
  due_date     DATE,
  amount       REAL,
  status       TEXT
);

INSERT INTO invoices VALUES
('INV-1001','C01','SVC-A','2026-09-01','2026-10-01', 1200.00,'PAID'),
('INV-1002','C02','SVC-B','2026-09-01','2026-10-01',  450.00,'OPEN'),
('INV-1003','C03','SVC-A','2026-09-03','2026-10-03',  980.00,'OPEN'),
('INV-1004','C02','SVC-B','2026-09-01','2026-10-01',  450.00,'OPEN'),  -- possible duplicate billing (same as INV-1002)
('INV-1005', NULL,'SVC-C','2026-09-05','2026-10-05',  300.00,'OPEN'),  -- missing customer_id
('INV-1006','C04','SVC-A','2026-09-06','2026-09-01',  760.00,'OPEN'),  -- due_date before invoice_date
('INV-1007','C05','SVC-B','2026-09-07','2026-10-07',    0.00,'OPEN'),  -- zero amount
('INV-1008','C01','SVC-C','2026-09-08','2026-10-08', -150.00,'OPEN'),  -- negative amount
('INV-1009','C06','SVC-A','2026-09-09','2026-10-09',  640.00, NULL),   -- missing status
('INV-1010','C03','SVC-B','2026-09-10','2026-10-10',  520.00,'VOID'),
('INV-1010','C03','SVC-B','2026-09-10','2026-10-10',  520.00,'VOID'),  -- duplicate invoice_id
('INV-1012','C07','SVC-C','2026-09-12','2026-10-12',  890.00,'PAID');

-- ------------------------------------------------------------
-- Checks
-- ------------------------------------------------------------

-- Check 1 (Uniqueness): duplicate invoice_id
SELECT invoice_id, COUNT(*) AS cnt
FROM invoices
GROUP BY invoice_id
HAVING COUNT(*) > 1;

-- Check 2 (Uniqueness): different invoice_ids with the same customer, service, date and amount
SELECT customer_id, service_code, invoice_date, amount,
       GROUP_CONCAT(invoice_id) AS invoice_ids
FROM invoices
GROUP BY customer_id, service_code, invoice_date, amount
HAVING COUNT(DISTINCT invoice_id) > 1;

-- Check 3 (Completeness): missing key fields
SELECT * FROM invoices
WHERE customer_id IS NULL OR status IS NULL;

-- Check 4 (Validity): amount <= 0
SELECT * FROM invoices WHERE amount <= 0;

-- Check 5 (Consistency): due_date before invoice_date
SELECT * FROM invoices WHERE due_date < invoice_date;

-- ------------------------------------------------------------
-- Summary report
-- ------------------------------------------------------------
SELECT '1 Duplicate invoice_id (groups)' AS check_name, COUNT(*) AS issue_count
FROM (SELECT invoice_id FROM invoices GROUP BY invoice_id HAVING COUNT(*) > 1)
UNION ALL
SELECT '2 Possible duplicate billing (groups)', COUNT(*)
FROM (SELECT 1 FROM invoices
      GROUP BY customer_id, service_code, invoice_date, amount
      HAVING COUNT(DISTINCT invoice_id) > 1)
UNION ALL
SELECT '3 Missing key fields (rows)', COUNT(*) FROM invoices WHERE customer_id IS NULL OR status IS NULL
UNION ALL
SELECT '4 Amount <= 0 (rows)', COUNT(*) FROM invoices WHERE amount <= 0
UNION ALL
SELECT '5 Due date before invoice date (rows)', COUNT(*) FROM invoices WHERE due_date < invoice_date;
