-- Normal MRR
SELECT
    DATE_FORMAT(start_date, '%Y-%m-01') AS month_start,
    SUM(monthly_price) AS normal_mrr
FROM subscriptions_clean
GROUP BY month_start
ORDER BY month_start;

-- Normal ARR
WITH monthly_mrr AS (
    SELECT
        DATE_FORMAT(start_date, '%Y-%m-01') AS month_start,
        SUM(monthly_price) AS mrr
    FROM subscriptions_clean
    WHERE end_date IS NULL
       OR end_date >= start_date
    GROUP BY month_start
)

-- Step 2: Calculate Annual Recurring Revenue (ARR)
-- ARR is derived by annualizing MRR (MRR * 12)
SELECT
    month_start,
    mrr,
    mrr * 12 AS new_arr
FROM monthly_mrr
ORDER BY month_start;


-- Normal Churn Rate
WITH churned_customers AS (
    SELECT
        DATE_FORMAT(end_date, '%Y-%m-01') AS churn_month,
        COUNT(DISTINCT customer_id) AS churned_customers
    FROM subscriptions_clean
    WHERE status = 'canceled'
    GROUP BY churn_month
),

-- Step 2: Calculate the total number of active customers by month
-- Active customers are derived based on subscription start month
-- This represents the customer base size used as the churn denominator
active_customers AS (
    SELECT
        DATE_FORMAT(start_date, '%Y-%m-01') AS month_start,
        COUNT(DISTINCT customer_id) AS active_customers
    FROM subscriptions_clean
    GROUP BY month_start
)

-- Step 3: Calculate Customer (Logo) Churn Rate
-- Customer churn rate is calculated as:
-- churned customers in a month / active customers in that month
SELECT
    c.churn_month,
    c.churned_customers,
    a.active_customers,
    ROUND(c.churned_customers / a.active_customers, 4) AS customer_churn_rate
FROM churned_customers c
JOIN active_customers a
  ON c.churn_month = a.month_start
ORDER BY c.churn_month;


-- Normal Revenue Churn Rate
WITH churned_revenue AS (
    SELECT
        DATE_FORMAT(end_date, '%Y-%m-01') AS churn_month,
        SUM(monthly_price) AS churned_mrr
    FROM subscriptions_clean
    WHERE status = 'canceled'
    GROUP BY churn_month
),

-- Step 2: Calculate total revenue based on subscription start month
-- This represents revenue from subscriptions that started in the same month
starting_revenue AS (
    SELECT
        DATE_FORMAT(start_date, '%Y-%m-01') AS month_start,
        SUM(monthly_price) AS starting_mrr
    FROM subscriptions_clean
    GROUP BY month_start
)

-- Step 3: Calculate Normal Revenue Churn Rate
-- Revenue churn rate = churned MRR / starting MRR
SELECT
    c.churn_month,
    c.churned_mrr,
    s.starting_mrr,
    ROUND(c.churned_mrr / s.starting_mrr, 4) AS Start_month_revenue_churn_rate
FROM churned_revenue c
JOIN starting_revenue s
  ON c.churn_month = s.month_start
ORDER BY c.churn_month;


-- Normal New ARPC Normal ARPC (Start-Month Based)

-- Step 1: Calculate monthly revenue based on subscription start month
WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(start_date, '%Y-%m-01') AS month_start,
        SUM(monthly_price) AS revenue
    FROM subscriptions_clean
    GROUP BY month_start
),

-- Step 2: Calculate number of customers based on subscription start month
monthly_customers AS (
    SELECT
        DATE_FORMAT(start_date, '%Y-%m-01') AS month_start,
        COUNT(DISTINCT customer_id) AS customers
    FROM subscriptions_clean
    GROUP BY month_start
)

-- Step 3: Calculate Normal ARPC
-- ARPC = revenue / number of customers (both based on start month)
SELECT
    r.month_start,
    r.revenue,
    c.customers,
    ROUND(r.revenue / c.customers, 2) AS arpc
FROM monthly_revenue r
JOIN monthly_customers c
  ON r.month_start = c.month_start
ORDER BY r.month_start;
