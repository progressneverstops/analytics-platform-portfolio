-- Load sample_events.csv into a SQLite table named events before running these queries.

-- 1) Trial-to-paid conversion rate
WITH trials AS (
  SELECT DISTINCT user_id
  FROM events
  WHERE event_name = 'trial_start'
),
conversions AS (
  SELECT DISTINCT user_id
  FROM events
  WHERE event_name = 'convert_paid'
)
SELECT
  COUNT(conversions.user_id) * 1.0 / COUNT(trials.user_id) AS trial_to_paid_rate
FROM trials
LEFT JOIN conversions ON trials.user_id = conversions.user_id;

-- 2) Median time from trial start to conversion (days)
WITH trial_starts AS (
  SELECT user_id, MIN(event_ts) AS trial_start_ts
  FROM events
  WHERE event_name = 'trial_start'
  GROUP BY user_id
),
conversions AS (
  SELECT user_id, MIN(event_ts) AS convert_ts
  FROM events
  WHERE event_name = 'convert_paid'
  GROUP BY user_id
),
lag_days AS (
  SELECT
    trial_starts.user_id,
    (julianday(conversions.convert_ts) - julianday(trial_starts.trial_start_ts)) AS days_to_convert
  FROM trial_starts
  JOIN conversions ON trial_starts.user_id = conversions.user_id
)
SELECT
  AVG(days_to_convert) AS median_days_to_convert
FROM (
  SELECT days_to_convert
  FROM lag_days
  ORDER BY days_to_convert
  LIMIT 2 - (SELECT COUNT(*) FROM lag_days) % 2
  OFFSET (SELECT (COUNT(*) - 1) / 2 FROM lag_days)
);

-- 3) Trials that ended without conversion
WITH trial_users AS (
  SELECT DISTINCT user_id
  FROM events
  WHERE event_name = 'trial_start'
),
converted_users AS (
  SELECT DISTINCT user_id
  FROM events
  WHERE event_name = 'convert_paid'
)
SELECT COUNT(*) AS trials_without_conversion
FROM trial_users
LEFT JOIN converted_users ON trial_users.user_id = converted_users.user_id
WHERE converted_users.user_id IS NULL;

-- 4) Total revenue
SELECT COALESCE(SUM(amount_usd), 0) AS total_revenue_usd
FROM events
WHERE event_name = 'convert_paid';
