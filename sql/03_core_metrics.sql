-- True MRR Metric
WITH months AS (
    SELECT DISTINCT DATE_FORMAT(start_date, '%Y-%m-01') AS month_start
    FROM subscriptions_clean
)
SELECT
    m.month_start,
    SUM(s.monthly_price) AS true_mrr
FROM months m
JOIN subscriptions_clean s
  ON s.start_date <= LAST_DAY(m.month_start)
 AND (s.end_date IS NULL OR s.end_date >= m.month_start)
GROUP BY m.month_start
ORDER BY m.month_start;


-- True ARR Metric
WITH months AS (
    SELECT DISTINCT DATE_FORMAT(start_date, '%Y-%m-01') AS month_start
    FROM subscriptions_clean
)
SELECT
    m.month_start,
    SUM(s.monthly_price) * 12 AS true_arr
FROM months m
JOIN subscriptions_clean s
  ON s.start_date <= LAST_DAY(m.month_start)
 AND (s.end_date IS NULL OR s.end_date >= m.month_start)
GROUP BY m.month_start
ORDER BY m.month_start;


-- True Churn Rate Metric
WITH months AS (
    SELECT DISTINCT DATE_FORMAT(start_date, '%Y-%m-01') AS month_start
    FROM subscriptions_clean
),
active_start AS (
    SELECT
        m.month_start,
        COUNT(DISTINCT s.customer_id) AS active_customers
    FROM months m
    JOIN subscriptions_clean s
      ON s.start_date < m.month_start
     AND (s.end_date IS NULL OR s.end_date >= m.month_start)
    GROUP BY m.month_start
),
churned AS (
    SELECT
        DATE_FORMAT(end_date, '%Y-%m-01') AS churn_month,
        COUNT(DISTINCT customer_id) AS churned_customers
    FROM subscriptions_clean
    WHERE status = 'canceled'
    GROUP BY churn_month
)
SELECT
    a.month_start,
    COALESCE(c.churned_customers,0) / a.active_customers AS true_customer_churn_rate
FROM active_start a
LEFT JOIN churned c
  ON a.month_start = c.churn_month
ORDER BY a.month_start;


-- True Revenue Churn Rate Metric
WITH months AS (
    SELECT DISTINCT DATE_FORMAT(start_date, '%Y-%m-01') AS month_start
    FROM subscriptions_clean
),
active_mrr_start AS (
    SELECT
        m.month_start,
        SUM(s.monthly_price) AS active_mrr
    FROM months m
    JOIN subscriptions_clean s
      ON s.start_date < m.month_start
     AND (s.end_date IS NULL OR s.end_date >= m.month_start)
    GROUP BY m.month_start
),
churned_mrr AS (
    SELECT
        DATE_FORMAT(end_date, '%Y-%m-01') AS churn_month,
        SUM(monthly_price) AS churned_mrr
    FROM subscriptions_clean
    WHERE status = 'canceled'
    GROUP BY churn_month
)
SELECT
    a.month_start,
    COALESCE(c.churned_mrr,0) / a.active_mrr AS true_revenue_churn_rate
FROM active_mrr_start a
LEFT JOIN churned_mrr c
  ON a.month_start = c.churn_month
ORDER BY a.month_start;


-- -- TRUE ARPC (Average Revenue per Active Customer)
Create view vw_arpc as
WITH months AS (
    SELECT DISTINCT DATE_FORMAT(start_date, '%Y-%m-01') AS month_start
    FROM subscriptions_clean
),
active_base AS (
    SELECT
        m.month_start,
        SUM(s.monthly_price) AS mrr,
        COUNT(DISTINCT s.customer_id) AS customers
    FROM months m
    JOIN subscriptions_clean s
      ON s.start_date <= LAST_DAY(m.month_start)
     AND (s.end_date IS NULL OR s.end_date >= m.month_start)
    GROUP BY m.month_start
)
SELECT
    month_start,
    mrr / customers AS true_arpc
FROM active_base
ORDER BY month_start;
Select * From vw_arpc;
-- Churn event without canceled subscription
SELECT COUNT(DISTINCT e.customer_id)
FROM events_raw e
LEFT JOIN subscriptions_raw s
  ON e.customer_id = s.customer_id
WHERE e.event_type = 'churned'
  AND (s.status IS NULL OR s.status != 'canceled');

/*Multiple churn-related counts were observed due to differing data grains.
Event-based churn identified 237 unique customers, while subscription cancellations identified 223 customers.
A subset of 184 customers had churn events without corresponding canceled subscriptions, highlighting inconsistencies between behavioral and billing data.
For this reason, subscription status was used as the source of truth for churn metrics, and churn events were used only for funnel analysis. */
