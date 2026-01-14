# Data Dictionary Template

## Overview

This document describes the data models, fields, and their meanings used in the analytics system.

## Data Models

### Model: [ModelName]

**Purpose:** What this model represents

**Table/Collection:** Database table or collection name

| Field Name | Type | Required | Description | Example |
|------------|------|----------|-------------|---------|
| field1 | String | Yes | Description of field1 | "example" |
| field2 | Int | No | Description of field2 | 123 |
| field3 | Date | Yes | Description of field3 | 2024-01-01 |

**Relationships:**
- Related to: OtherModel (One-to-Many)
- Referenced by: AnotherModel (Many-to-One)

**Business Rules:**
- Rule 1: Validation or constraint
- Rule 2: Calculation or derivation
- Rule 3: Data quality requirement

---

### Model: [AnotherModel]

[Same structure as above]

## Event Types

### Event: [EventName]

**Purpose:** What this event represents

**Triggered By:** When this event occurs

| Field Name | Type | Required | Description |
|------------|------|----------|-------------|
| eventId | String | Yes | Unique event identifier |
| timestamp | Date | Yes | When event occurred |
| userId | String | Yes | User who triggered event |
| metadata | Dictionary | No | Additional event data |

**Example:**
```json
{
  "eventId": "evt_123",
  "timestamp": "2024-01-01T12:00:00Z",
  "userId": "user_456",
  "metadata": {
    "action": "click",
    "page": "home"
  }
}
```

## Metrics Definitions

### Metric: [MetricName]

**Purpose:** What this metric measures

**Calculation:**
```
Formula: [Mathematical formula]
Example: [Example calculation]
```

**Unit:** Unit of measurement (e.g., percentage, count, seconds)

**Aggregation:** How metric is aggregated (sum, average, count, etc.)

**Time Granularity:** Time period (hourly, daily, weekly)

**Data Source:** Where metric data comes from

**Business Context:** Why this metric matters

---

### Metric: [AnotherMetric]

[Same structure as above]

## Data Quality Rules

### Rule: [RuleName]

**Purpose:** What this rule validates

**Validation Logic:**
- Check 1: Description
- Check 2: Description
- Check 3: Description

**Error Handling:** What happens when validation fails

**Severity:** Critical / Warning / Info

---

### Rule: [AnotherRule]

[Same structure as above]

## Data Lineage

### Data Flow: [ProcessName]

**Source:** Where data originates

**Transformations:**
1. Step 1: Description
2. Step 2: Description
3. Step 3: Description

**Destination:** Where data ends up

**Frequency:** How often data flows (real-time, hourly, daily)

## Glossary

**Term 1:** Definition
**Term 2:** Definition
**Term 3:** Definition
