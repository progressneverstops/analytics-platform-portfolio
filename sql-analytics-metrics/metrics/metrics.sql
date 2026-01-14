-- Metric definitions and rollups.

-- Weekly Active Users (WAU)
select
  date_trunc('week', event_ts) as week_start,
  count(distinct user_id) as weekly_active_users
from analytics.fact_user_events
group by 1;

-- Activation Rate
-- Definition: users completing onboarding within 7 days / new users in week.
with new_users as (
  select
    date_trunc('week', first_seen_ts) as week_start,
    user_id
  from analytics.dim_user
),
activations as (
  select
    user_id,
    min(event_ts) as activated_ts
  from analytics.fact_user_events
  where event_name = 'onboarding_complete'
  group by 1
)
select
  n.week_start,
  count(distinct case
    when a.activated_ts <= n.week_start + interval '7 days' then n.user_id
  end) * 1.0 / count(distinct n.user_id) as activation_rate
from new_users n
left join activations a on n.user_id = a.user_id
group by 1;
