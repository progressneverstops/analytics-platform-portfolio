# Take-Home Prompt

You are given a sample event log for a subscription product.

## Questions

1. What is the trial-to-paid conversion rate?
2. What is the median time from trial start to conversion (in days)?
3. How many trials ended without conversion (including cancellations and natural trial_end)?
4. What is total revenue in the period?

## Notes

- Use `event_name` to determine conversion and trial end states.
- Assume `amount_usd` is recorded only on `convert_paid` events.
