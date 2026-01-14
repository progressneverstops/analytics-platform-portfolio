-- Basic data quality checks.

-- No null user_ids in fact table
select count(*) as null_user_ids
from analytics.fact_user_events
where user_id is null;

-- Event timestamps should be present
select count(*) as null_event_ts
from analytics.fact_user_events
where event_ts is null;

-- Dimension uniqueness
select user_id, count(*) as rows_per_user
from analytics.dim_user
group by 1
having count(*) > 1;
