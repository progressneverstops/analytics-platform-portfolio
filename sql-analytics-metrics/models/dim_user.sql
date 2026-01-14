-- dim_user.sql
-- One row per user.
select
  user_id,
  first_seen_ts,
  country,
  plan_tier
from raw_users;
