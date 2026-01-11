-- funnel analysis
/* The events dataset contained duplicate funnel events (e.g., multiple signup records for the same customer on the same date).
Since event timestamps were available only at the date level, duplicates could not be meaningfully ordered.
The subscription dataset contained duplicate active events, for the same customer on the same date.
To avoid double-counting and ensure accurate funnel conversion rates, events were deduplicated by customer and
 event type using distinct records.*/

SELECT
    COUNT(DISTINCT CASE WHEN event_type = 'signup' THEN e.customer_id END) AS signup,
    COUNT(DISTINCT CASE WHEN event_type = 'trial_start' THEN e.customer_id END) AS trial,
    COUNT(DISTINCT CASE WHEN event_type = 'activated' THEN e.customer_id END) AS activated,
    COUNT(DISTINCT s.customer_id) AS paid,
    COUNT(DISTINCT CASE WHEN e.event_type = 'churned' THEN e.customer_id END) AS churned
FROM events_funnel e
LEFT JOIN subscriptions_clean s
  ON e.customer_id = s.customer_id;
  
  -- Funnel Conversion Rates (Stage → Stage)
-- Funnel Conversion Rates including Paid → Churned
WITH funnel AS (
    SELECT
        customer_id,
        MAX(event_type = 'signup') AS signup,
        MAX(event_type = 'trial_start') AS trial,
        MAX(event_type = 'activated') AS activated,
        MAX(event_type = 'churned') AS churned
    FROM events_funnel
    GROUP BY customer_id
),
paid AS (
    SELECT DISTINCT customer_id -- as there are duplicates in this table
    FROM subscriptions_clean
)
SELECT
    -- Signup → Trial
    COUNT(CASE WHEN signup = 1 THEN 1 END) AS signup_users,
    COUNT(CASE WHEN signup = 1 AND trial = 1 THEN 1 END) AS signup_to_trial,
    ROUND(
        COUNT(CASE WHEN signup = 1 AND trial = 1 THEN 1 END)
        / COUNT(CASE WHEN signup = 1 THEN 1 END), 4
    ) AS signup_to_trial_rate,

    -- Trial → Activated
    COUNT(CASE WHEN trial = 1 AND activated = 1 THEN 1 END) AS trial_to_activated,
    ROUND(
        COUNT(CASE WHEN trial = 1 AND activated = 1 THEN 1 END)
        / COUNT(CASE WHEN trial = 1 THEN 1 END), 4
    ) AS trial_to_activated_rate,

    -- Activated → Paid
    COUNT(CASE WHEN activated = 1 AND p.customer_id IS NOT NULL THEN 1 END) AS activated_to_paid,
    ROUND(
        COUNT(CASE WHEN activated = 1 AND p.customer_id IS NOT NULL THEN 1 END)
        / COUNT(CASE WHEN activated = 1 THEN 1 END), 4
    ) AS activated_to_paid_rate,

    -- Paid → Churned (Retention view)
    COUNT(CASE WHEN p.customer_id IS NOT NULL THEN 1 END) AS paid_customers,
    COUNT(CASE WHEN p.customer_id IS NOT NULL AND churned = 1 THEN 1 END) AS paid_to_churned,
    ROUND(
        COUNT(CASE WHEN p.customer_id IS NOT NULL AND churned = 1 THEN 1 END)
        / COUNT(CASE WHEN p.customer_id IS NOT NULL THEN 1 END), 4
    ) AS paid_to_churned_rate

FROM funnel f
LEFT JOIN paid p
  ON f.customer_id = p.customer_id;


-- Drop-Off Analysis (Where Users Are Lost)
  WITH funnel AS (
    SELECT
        customer_id,
        MAX(event_type = 'signup') AS signup,
        MAX(event_type = 'trial_start') AS trial,
        MAX(event_type = 'activated') AS activated
    FROM events_funnel
    GROUP BY customer_id
)
SELECT
    COUNT(CASE WHEN signup = 1 AND trial = 0 THEN 1 END) AS drop_after_signup,
    COUNT(CASE WHEN trial = 1 AND activated = 0 THEN 1 END) AS drop_after_trial
FROM funnel;


-- Funnel by Acquisition Source
WITH funnel AS (
    SELECT
        customer_id,
        MAX(event_type = 'signup') AS signup,
        MAX(event_type = 'trial_start') AS trial,
        MAX(event_type = 'activated') AS activated,
        MAX(source) AS source
    FROM events_funnel
    GROUP BY customer_id
)
SELECT
    source,
    COUNT(DISTINCT customer_id) AS signups,
    COUNT(DISTINCT CASE WHEN trial = 1 THEN customer_id END) AS trials,
    COUNT(DISTINCT CASE WHEN activated = 1 THEN customer_id END) AS activated,
    ROUND(
        COUNT(DISTINCT CASE WHEN activated = 1 THEN customer_id END)
        / COUNT(DISTINCT customer_id), 4
    ) AS signup_to_activated_rate
FROM funnel
GROUP BY source
ORDER BY signup_to_activated_rate DESC;


-- Funnel by Customer Segment
WITH funnel AS (
    SELECT
        e.customer_id,
        MAX(e.event_type = 'signup') AS signup,
        MAX(e.event_type = 'trial_start') AS trial,
        MAX(e.event_type = 'activated') AS activated,
        c.segment
    FROM events_funnel e
    JOIN customers_clean c
      ON e.customer_id = c.customer_id
    GROUP BY e.customer_id, c.segment
)
SELECT
    segment,
    COUNT(DISTINCT customer_id) AS signups,
    COUNT(DISTINCT CASE WHEN activated = 1 THEN customer_id END) AS activated,
    ROUND(
        COUNT(DISTINCT CASE WHEN activated = 1 THEN customer_id END)
        / COUNT(DISTINCT customer_id), 4
    ) AS signup_to_activated_rate
FROM funnel
GROUP BY segment
ORDER BY signup_to_activated_rate DESC;

WITH funnel AS (
    SELECT
        e.customer_id,
        MAX(e.event_type = 'signup') AS signup,
        MAX(e.event_type = 'activated') AS activated,
        c.segment
    FROM events_funnel e
    JOIN customers_clean c
      ON e.customer_id = c.customer_id
    GROUP BY e.customer_id, c.segment
)
SELECT
    segment,
    COUNT(DISTINCT customer_id) AS signups,
    COUNT(DISTINCT CASE WHEN activated = 1 THEN customer_id END) AS activated,
    ROUND(
        COUNT(DISTINCT CASE WHEN activated = 1 THEN customer_id END)
        / COUNT(DISTINCT customer_id), 4
    ) AS signup_to_activated_rate
FROM funnel
WHERE segment IS NOT NULL
  AND TRIM(segment) <> ''
GROUP BY segment
ORDER BY signup_to_activated_rate DESC;


SELECT
    COUNT(*) AS total_rows,
    SUM(segment IS NULL) AS null_segments,
    SUM(segment = '') AS empty_segments
FROM customers_clean;

/*Some customer records contained empty-string values for the segment field. These records were excluded from segment-level 
funnel analysis using explicit NULL and empty-string filtering to avoid misleading groupings. */






