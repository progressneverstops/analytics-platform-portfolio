# Data Analytics Portfolio - Architecture Overview

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    DataAnalyticsCore Library                      │
│                    (Generic Patterns)                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Logging     │  │  Analytics   │  │   Tracking   │          │
│  │   Patterns    │  │   Patterns   │  │   Patterns   │          │
│  └──────┬────────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                   │                  │                  │
│         └───────────────────┼──────────────────┘                  │
│                             │                                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  Processing  │  │   Storage     │  │ Visualization │          │
│  │   Patterns   │  │   Patterns    │  │   Patterns    │          │
│  └──────────────┘  └───────────────┘  └───────────────┘          │
└─────────────────────────────────────────────────────────────────┘
                            │
                            │ Used By
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Portfolio Projects                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────┐  ┌──────────────────┐                    │
│  │ SQL Analytics    │  │ Dashboard +      │                    │
│  │                  │  │ Report           │                    │
│  │ • Event Tracking │  │ • Metrics Viz    │                    │
│  │ • SQL Schema     │  │ • Auto Reports   │                    │
│  │ • Analytics      │  │ • Data → Insight │                    │
│  └──────────────────┘  └──────────────────┘                    │
│                                                                   │
│  ┌──────────────────┐  ┌──────────────────┐                    │
│  │ Data Quality     │  │ A/B Experiments │                    │
│  │ Pipeline         │  │                  │                    │
│  │ • Validation     │  │ • Experiment Mgmt│                    │
│  │ • Quality Checks │  │ • Statistical    │                    │
│  │ • Quality Reports│  │   Analysis       │                    │
│  └──────────────────┘  └──────────────────┘                    │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow Architecture

### SQL Analytics Project

```
Events → EventLogger → SQLite → Analytics Queries → Reports
```

### Dashboard + Report

```
Metrics → MetricsAggregator → Dashboard Components → Automated Reports
```

### Data Quality Pipeline

```
Data Source → Validation Rules → Quality Checks → Quality Metrics → Reports
```

### A/B Experiments

```
Experiment Definition → Variant Assignment → Event Tracking → Statistical Analysis → Results
```

## Component Relationships

```
┌─────────────────┐
│  EventLogger    │──┐
└─────────────────┘  │
                     │
┌─────────────────┐  │    ┌─────────────────┐
│ MetricsAggregator│──┼───▶│  SQL Analytics  │
└─────────────────┘  │    └─────────────────┘
                     │
┌─────────────────┐  │    ┌─────────────────┐
│ ChangeDetector  │──┘    │   Dashboard     │
└─────────────────┘       └─────────────────┘
         │
         │
         ▼
┌─────────────────┐
│ Data Quality    │
│ Pipeline        │
└─────────────────┘
```

## Technology Stack

```
┌─────────────────────────────────────┐
│         Application Layer            │
│  Swift / SwiftUI / TypeScript        │
├─────────────────────────────────────┤
│         Analytics Layer              │
│  Metrics Aggregation / Statistics    │
├─────────────────────────────────────┤
│         Storage Layer                │
│  SQLite / JSON / File System         │
├─────────────────────────────────────┤
│         Visualization Layer          │
│  SwiftUI Charts / Custom Components  │
└─────────────────────────────────────┘
```

## Key Design Patterns

1. **Singleton Pattern** - Shared managers (EventLogger, MetricsAggregator)
2. **Observer Pattern** - Reactive updates (@Published properties)
3. **Strategy Pattern** - Validation rules, ETL stages
4. **Factory Pattern** - SQL schema generation
5. **Repository Pattern** - Data persistence abstraction

## Data Models

```
Event
├── eventId: String
├── timestamp: Date
├── eventType: String
└── metadata: Dictionary

Metric
├── metricName: String
├── value: Double
├── timestamp: Date
└── category: String?

Snapshot
├── id: String
├── createdAt: Date
├── name: String
└── items: [Fingerprint]

ValidationResult
├── isValid: Bool
└── errors: [String]
```
