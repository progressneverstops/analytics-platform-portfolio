-- Weekly activation rate
with users as (
  select user_id, min(event_ts) as signup_ts
  from sample_events
  where event_name = 'signup'
  group by 1
),
activations as (
  select user_id, min(event_ts) as activated_ts
  from sample_events
  where event_name = 'onboarding_complete'
  group by 1
)
select
  date_trunc('week', u.signup_ts) as week_start,
  count(distinct case
    when a.activated_ts <= u.signup_ts + interval '7 days' then u.user_id
  end) * 1.0 / count(distinct u.user_id) as activation_rate
from users u
left join activations a on u.user_id = a.user_id
group by 1;

-- Drop-off by step
select
  event_name,
  count(distinct user_id) as users
from sample_events
where event_name like 'onboarding_step%'
group by 1
order by 2 desc;
