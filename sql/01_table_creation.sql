CREATE DATABASE emergence_saas;
USE emergence_saas;

/* Raw CSVs were ingested as VARCHAR-only tables to prevent silent data loss during import.
Cleaned tables were created with explicit type casting, normalization, and documented assumptions. */


DROP TABLE IF EXISTS customers_raw;
CREATE TABLE customers_raw (
    customer_id VARCHAR(20),
    signup_date VARCHAR(20),
    segment VARCHAR(50),
    country VARCHAR(10),
    is_enterprise VARCHAR(10)
);


DROP TABLE subscriptions_raw;
CREATE TABLE subscriptions_raw (
    subscription_id VARCHAR(10),
    customer_id VARCHAR(10),
    start_date Varchar(20),
    end_date VARCHAR(20),
    monthly_price Varchar(20),
    status VARCHAR(20)
);

Select * From subscriptions_raw;

DROP TABLE events_raw;
CREATE TABLE events_raw (
    event_id VARCHAR(10),
    customer_id VARCHAR(10),
    event_type VARCHAR(20),
    event_date VARCHAR(20),
    source VARCHAR(20)
);

Select * From events_raw;
Select * From customers_raw;

/* Empty strings in date columns caused parsing errors during normalization.
These were explicitly converted to NULL using NULLIF before applying STR_TO_DATE, ensuring no rows were dropped during cleaning */

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
