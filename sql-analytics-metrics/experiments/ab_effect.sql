-- Simple A/B conversion comparison.
with exposures as (
  select distinct user_id, variant
  from analytics.fact_user_events
  where event_name = 'experiment_exposed'
),
conversions as (
  select distinct user_id
  from analytics.fact_user_events
  where event_name = 'onboarding_complete'
)
select
  e.variant,
  count(distinct e.user_id) as exposed_users,
  count(distinct c.user_id) as converted_users,
  count(distinct c.user_id) * 1.0 / count(distinct e.user_id) as conversion_rate
from exposures e
left join conversions c on e.user_id = c.user_id
group by 1
order by 1;
