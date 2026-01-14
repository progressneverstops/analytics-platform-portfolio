-- dim_session.sql
-- One row per session.
select
  session_id,
  user_id,
  session_start_ts,
  session_end_ts,
  platform
from raw_sessions;
