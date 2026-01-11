CREATE TABLE customers_clean AS
SELECT
    customer_id,
    STR_TO_DATE(NULLIF(TRIM(signup_date), ''), '%Y-%m-%d') AS signup_date,
    TRIM(segment) AS segment,
    TRIM(country) AS country,
    CASE
        WHEN LOWER(is_enterprise) = 'true' THEN 1
        WHEN LOWER(is_enterprise) = 'false' THEN 0
        ELSE NULL
    END AS is_enterprise
FROM customers_raw;
Select * From customers_clean;


CREATE TABLE subscriptions_clean AS
SELECT
    subscription_id,
    customer_id,
    STR_TO_DATE(NULLIF(TRIM(start_date), ''), '%Y-%m-%d') AS start_date,
    STR_TO_DATE(NULLIF(TRIM(end_date), ''), '%Y-%m-%d') AS end_date,
    CAST(NULLIF(monthly_price, '') AS UNSIGNED) AS monthly_price,
    LOWER(TRIM(status)) AS status
FROM subscriptions_raw;


CREATE TABLE events_clean AS
SELECT
    event_id,
    customer_id,
    LOWER(TRIM(event_type)) AS event_type,
    STR_TO_DATE(NULLIF(TRIM(event_date), ''), '%Y-%m-%d') AS event_date,
    LOWER(TRIM(source)) AS source
FROM events_raw;


SELECT COUNT(*) FROM customers_raw;
SELECT COUNT(*) FROM customers_clean;


SELECT COUNT(*) 
FROM customers_clean
WHERE signup_date IS NULL;

ALTER TABLE customers_clean
ADD PRIMARY KEY (customer_id);

ALTER TABLE subscriptions_clean
ADD PRIMARY KEY (subscription_id);

ALTER TABLE events_clean
ADD PRIMARY KEY (event_id);



CREATE INDEX idx_subscriptions_customer
ON subscriptions_clean (customer_id);

CREATE INDEX idx_events_customer
ON events_clean (customer_id);

CREATE INDEX idx_events_date
ON events_clean (event_date);

CREATE INDEX idx_subscriptions_start_date
ON subscriptions_clean (start_date);

SHOW INDEX FROM customers_clean;
SHOW INDEX FROM subscriptions_clean;
SHOW INDEX FROM events_clean;

SELECT COUNT(DISTINCT customer_id) as cust_count From customers_clean;
SELECT customer_id, COUNT(*)
FROM customers_clean
GROUP BY customer_id
HAVING COUNT(*) > 1;

SELECT COUNT(DISTINCT event_id) as cust_count From events_clean;
SELECT event_id, COUNT(*)
FROM events_clean
GROUP BY event_id
HAVING COUNT(*) > 1;

SELECT COUNT(DISTINCT subscription_id) as cust_count From subscriptions_clean;
SELECT subscription_id, COUNT(*)
FROM subscriptions_clean
GROUP BY 1
HAVING COUNT(*) > 1;

/*Cleaned tables were structured with primary keys and indexed join columns to ensure uniqueness, integrity, 
and efficient analytical queries.
Indexes were added on customer identifiers and date fields to optimize SaaS metric calculations and funnel analysis. */

-- Missing values Validating
SELECT * FROM subscriptions_clean
WHERE monthly_price IS NULL
   OR start_date IS NULL;
   
SELECT * FROM events_clean
WHERE event_type IS NULL
   OR event_date IS NULL;

-- Inconsistent logic checks
-- Active but has end_date
SELECT *
FROM subscriptions_clean
WHERE status = 'active'
  AND end_date IS NOT NULL;


-- Churn event without canceled subscription
SELECT e.customer_id
FROM events_clean e
LEFT JOIN subscriptions_clean s
ON e.customer_id = s.customer_id
WHERE e.event_type = 'churned'
  AND s.status != 'canceled';

  
  /*Show me customers who are marked as churned in the events table,
but who do NOT have a canceled subscription.”
A data quality check identified customers with churn events but non-canceled or missing subscription records.
Due to this inconsistency, churn metrics were derived from subscription status, while churn events were used 
only for funnel analysis. */

-- Assumption: churn is derived from subscription status
-- churned events are used only for funnel analysis

-- Events without customer record
SELECT COUNT(*) AS orphan_events
FROM events_clean e
LEFT JOIN customers_clean c
ON e.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


-- Signup after subscription start (data issue check)
SELECT s.customer_id
FROM subscriptions_clean s
JOIN customers_clean c
ON s.customer_id = c.customer_id
WHERE s.start_date < c.signup_date;
