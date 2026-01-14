-- Conversion rate and revenue per exposed user by variant.
select
  variant,
  count(*) as exposed_users,
  sum(converted) as converted_users,
  sum(converted) * 1.0 / count(*) as conversion_rate,
  sum(revenue_usd) * 1.0 / count(*) as revenue_per_exposed
from experiment_events
group by 1
order by 1;
