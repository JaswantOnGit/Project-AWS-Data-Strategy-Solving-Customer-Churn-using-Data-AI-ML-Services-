-- === Glue Catalog table definitions (adjust S3 paths/columns to your actual data) ===
CREATE EXTERNAL TABLE IF NOT EXISTS churn_db.customers (
    customerid        string,
    email             string,
    subscribedate     date,
    canceldate        date,
    status             string,
    cancellation_reason string
  )
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
LOCATION 's3://<your-bucket>/raw/customers/'
TBLPROPERTIES ('skip.header.line.count'='1');

-- === Phase 1: Validate the churn trend before committing further budget ===
SELECT
  date_trunc('month', canceldate) AS cancel_month,
  count(*)                        AS cancellations,
  count(*) * 100.0 / SUM(count(*)) OVER () AS pct_of_total
FROM churn_db.customers
WHERE status = 'canceled'
GROUP BY date_trunc('month', canceldate)
ORDER BY cancel_month;

-- Sanity check: is churn rising relative to active customer volume, or just volume growth?
SELECT
  date_trunc('month', subscribedate) AS cohort_month,
  count(*) FILTER (WHERE status = 'canceled') * 1.0 / count(*) AS churn_rate
FROM churn_db.customers
GROUP BY date_trunc('month', subscribedate)
ORDER BY cohort_month;

-- === Phase 2: Reveal the gap -- how blank is cancellation_reason really? ===
SELECT
  count(*) AS total_canceled,
  count(*) FILTER (WHERE cancellation_reason IS NULL OR trim(cancellation_reason) = '') AS blank_reason,
  100.0 * count(*) FILTER (WHERE cancellation_reason IS NULL OR trim(cancellation_reason) = '') / count(*) AS pct_blank
FROM churn_db.customers
WHERE status = 'canceled';
