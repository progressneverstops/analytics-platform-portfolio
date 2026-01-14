//
//  SQLSchemaGenerator.swift
//  DataAnalyticsCore
//
//  Generic SQL schema generator from Swift types
//  Extracted pattern - domain-agnostic implementation
//

import Foundation

/// SQL column definition
struct SQLColumn {
    let name: String
    let type: String
    let nullable: Bool
    let primaryKey: Bool
    let defaultValue: String?
    
    init(name: String, type: String, nullable: Bool = true, primaryKey: Bool = false, defaultValue: String? = nil) {
        self.name = name
        self.type = type
        self.nullable = nullable
        self.primaryKey = primaryKey
        self.defaultValue = defaultValue
    }
}

/// SQL table definition
struct SQLTable {
    let name: String
    let columns: [SQLColumn]
    
    func generateCreateTableSQL() -> String {
        var sql = "CREATE TABLE IF NOT EXISTS \(name) (\n"
        
        let columnDefinitions = columns.map { col -> String in
            var def = "  \(col.name) \(col.type)"
            if !col.nullable {
                def += " NOT NULL"
            }
            if col.primaryKey {
                def += " PRIMARY KEY"
            }
            if let defaultValue = col.defaultValue {
                def += " DEFAULT \(defaultValue)"
            }
            return def
        }
        
        sql += columnDefinitions.joined(separator: ",\n")
        sql += "\n);"
        
        return sql
    }
}

/// Generic SQL schema generator
final class SQLSchemaGenerator {
    /// Generate SQL table from event type
    static func generateTableForEvent<T: LoggableEvent>(eventType: T.Type, tableName: String) -> SQLTable {
        // Generic event table structure
        let columns: [SQLColumn] = [
            SQLColumn(name: "id", type: "TEXT", nullable: false, primaryKey: true),
            SQLColumn(name: "event_id", type: "TEXT", nullable: false),
            SQLColumn(name: "timestamp", type: "DATETIME", nullable: false),
            SQLColumn(name: "event_type", type: "TEXT", nullable: false),
            SQLColumn(name: "event_data", type: "TEXT", nullable: true), // JSON blob
            SQLColumn(name: "created_at", type: "DATETIME", nullable: false, defaultValue: "CURRENT_TIMESTAMP")
        ]
        
        return SQLTable(name: tableName, columns: columns)
    }
    
    /// Generate SQL table for metrics
    static func generateMetricsTable(tableName: String = "metrics") -> SQLTable {
        let columns: [SQLColumn] = [
            SQLColumn(name: "id", type: "INTEGER", nullable: false, primaryKey: true),
            SQLColumn(name: "metric_name", type: "TEXT", nullable: false),
            SQLColumn(name: "timestamp", type: "DATETIME", nullable: false),
            SQLColumn(name: "value", type: "REAL", nullable: false),
            SQLColumn(name: "success", type: "INTEGER", nullable: false, defaultValue: "1"),
            SQLColumn(name: "category", type: "TEXT", nullable: true),
            SQLColumn(name: "created_at", type: "DATETIME", nullable: false, defaultValue: "CURRENT_TIMESTAMP")
        ]
        
        return SQLTable(name: tableName, columns: columns)
    }
    
    /// Generate SQL table for snapshots
    static func generateSnapshotsTable(tableName: String = "snapshots") -> SQLTable {
        let columns: [SQLColumn] = [
            SQLColumn(name: "id", type: "TEXT", nullable: false, primaryKey: true),
            SQLColumn(name: "name", type: "TEXT", nullable: false),
            SQLColumn(name: "created_at", type: "DATETIME", nullable: false),
            SQLColumn(name: "item_count", type: "INTEGER", nullable: false),
            SQLColumn(name: "snapshot_data", type: "TEXT", nullable: true) // JSON blob
        ]
        
        return SQLTable(name: tableName, columns: columns)
    }
    
    /// Generate common analytics queries
    static func generateAnalyticsQueries() -> [String: String] {
        return [
            "events_by_type": """
                SELECT event_type, COUNT(*) as count
                FROM events
                GROUP BY event_type
                ORDER BY count DESC;
            """,
            "events_by_date": """
                SELECT DATE(timestamp) as date, COUNT(*) as count
                FROM events
                GROUP BY DATE(timestamp)
                ORDER BY date DESC;
            """,
            "metrics_summary": """
                SELECT 
                    metric_name,
                    COUNT(*) as total_count,
                    SUM(CASE WHEN success = 1 THEN 1 ELSE 0 END) as success_count,
                    AVG(value) as average_value
                FROM metrics
                GROUP BY metric_name;
            """,
            "daily_metrics": """
                SELECT 
                    DATE(timestamp) as date,
                    metric_name,
                    AVG(value) as avg_value,
                    COUNT(*) as count
                FROM metrics
                GROUP BY DATE(timestamp), metric_name
                ORDER BY date DESC, metric_name;
            """
        ]
    }
}
