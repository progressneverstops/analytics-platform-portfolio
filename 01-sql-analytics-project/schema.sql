-- SQL Analytics Project - Database Schema
-- Generic event tracking and metrics database

-- Events table for tracking user actions and system events
CREATE TABLE IF NOT EXISTS events (
    id TEXT PRIMARY KEY,
    event_id TEXT NOT NULL,
    timestamp DATETIME NOT NULL,
    event_type TEXT NOT NULL,
    user_id TEXT,
    action TEXT,
    event_data TEXT, -- JSON blob for flexible metadata
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Metrics table for tracking aggregated metrics
CREATE TABLE IF NOT EXISTS metrics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    metric_name TEXT NOT NULL,
    timestamp DATETIME NOT NULL,
    value REAL NOT NULL,
    success INTEGER NOT NULL DEFAULT 1, -- 1 for success, 0 for failure
    category TEXT,
    metadata TEXT, -- JSON blob for additional context
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Snapshots table for version tracking
CREATE TABLE IF NOT EXISTS snapshots (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    created_at DATETIME NOT NULL,
    item_count INTEGER NOT NULL,
    snapshot_data TEXT -- JSON blob containing snapshot details
);

-- Experiment events table for A/B testing
CREATE TABLE IF NOT EXISTS experiment_events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    experiment_id TEXT NOT NULL,
    variant_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    event_type TEXT NOT NULL,
    timestamp DATETIME NOT NULL,
    metadata TEXT, -- JSON blob
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Data quality checks table
CREATE TABLE IF NOT EXISTS quality_checks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    check_name TEXT NOT NULL,
    data_source TEXT NOT NULL,
    timestamp DATETIME NOT NULL,
    quality_score REAL NOT NULL, -- 0.0 to 1.0
    passed_checks INTEGER NOT NULL,
    failed_checks INTEGER NOT NULL,
    error_details TEXT, -- JSON blob with error messages
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_events_timestamp ON events(timestamp);
CREATE INDEX IF NOT EXISTS idx_events_type ON events(event_type);
CREATE INDEX IF NOT EXISTS idx_events_user ON events(user_id);
CREATE INDEX IF NOT EXISTS idx_metrics_timestamp ON metrics(timestamp);
CREATE INDEX IF NOT EXISTS idx_metrics_name ON metrics(metric_name);
CREATE INDEX IF NOT EXISTS idx_experiment_events_exp ON experiment_events(experiment_id);
CREATE INDEX IF NOT EXISTS idx_experiment_events_variant ON experiment_events(variant_id);
CREATE INDEX IF NOT EXISTS idx_quality_checks_source ON quality_checks(data_source);
CREATE INDEX IF NOT EXISTS idx_quality_checks_timestamp ON quality_checks(timestamp);
