# SQL Analytics Metrics

## Business Question
Which onboarding actions drive weekly activation, and how does conversion vary by segment?

## Decision Supported
Prioritize the top two activation steps for engineering time and measure impact by segment.

## Assumptions
- Events are de-duplicated at ingest.
- Each user can have multiple sessions per day.
- Conversion is defined as completion of the onboarding checklist within 7 days.

## Contents
- models/: fact and dimension tables
- metrics/: metric definitions and rollups
- quality/: basic data quality checks
- experiments/: queries for A/B evaluation
