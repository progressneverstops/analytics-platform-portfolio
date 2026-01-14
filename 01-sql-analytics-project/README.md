# SQL Analytics Project

A structured SQL analytics project demonstrating event tracking, metrics aggregation, and data analysis using SQLite.

## Purpose

This project demonstrates:
- Structured event logging → SQL database
- SQL schema design from Swift types
- Analytics queries and aggregations
- Data quality validation
- Automated reporting

## Architecture

```
Event Logger → SQLite Database → Analytics Queries → Reports
```

## Features

1. **Event Tracking**
   - Generic event logging system
   - Automatic SQL schema generation
   - Event persistence to SQLite

2. **Metrics Aggregation**
   - Time-series metrics
   - Success/failure rates
   - Distribution tracking

3. **Analytics Queries**
   - Events by type
   - Events by date
   - Metrics summaries
   - Daily aggregations

4. **Data Quality**
   - Schema validation
   - Data integrity checks
   - Missing data detection

## Example Use Case

**Generic Product Analytics** (not domain-specific):
- Track user actions (clicks, views, purchases)
- Aggregate metrics (conversion rates, averages)
- Generate daily/weekly reports
- Monitor data quality

## Setup

1. Build the project
2. Run the example to generate sample data
3. Execute SQL queries to analyze data
4. Generate reports

## SQL Schema

See `schema.sql` for generated table definitions.

## Queries

See `queries.sql` for example analytics queries.
