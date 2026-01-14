-- fact_user_events.sql
-- Grain: one row per user event.
select
  event_id,
  user_id,
  event_ts,
  event_name,
  platform,
  variant
from raw_events;
