//
//  SQLAnalytics.swift
//  SQL Analytics Project
//
//  Demonstrates structured SQL analytics using generic event tracking
//

import Foundation
import SQLite3

/// SQL Analytics Manager
final class SQLAnalytics {
    private var db: OpaquePointer?
    private let dbPath: String
    
    init(dbPath: String = "analytics.db") {
        self.dbPath = dbPath
        initializeDatabase()
    }
    
    deinit {
        sqlite3_close(db)
    }
    
    /// Initialize database with schema
    private func initializeDatabase() {
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dbURL = documentsPath.appendingPathComponent(dbPath)
        
        if sqlite3_open(dbURL.path, &db) != SQLITE_OK {
            print("Error opening database")
            return
        }
        
        // Create tables
        createTables()
    }
    
    /// Create database tables
    private func createTables() {
        // Events table
        let eventsTable = SQLSchemaGenerator.generateTableForEvent(
            eventType: UserActionEvent.self,
            tableName: "events"
        )
        executeSQL(eventsTable.generateCreateTableSQL())
        
        // Metrics table
        let metricsTable = SQLSchemaGenerator.generateMetricsTable()
        executeSQL(metricsTable.generateCreateTableSQL())
        
        // Create indexes
        executeSQL("CREATE INDEX IF NOT EXISTS idx_events_timestamp ON events(timestamp);")
        executeSQL("CREATE INDEX IF NOT EXISTS idx_events_type ON events(event_type);")
        executeSQL("CREATE INDEX IF NOT EXISTS idx_metrics_timestamp ON metrics(timestamp);")
        executeSQL("CREATE INDEX IF NOT EXISTS idx_metrics_name ON metrics(metric_name);")
    }
    
    /// Execute SQL statement
    private func executeSQL(_ sql: String) {
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) != SQLITE_DONE {
                let error = String(cString: sqlite3_errmsg(db))
                print("Error executing SQL: \(error)")
            }
        } else {
            let error = String(cString: sqlite3_errmsg(db))
            print("Error preparing SQL: \(error)")
        }
        
        sqlite3_finalize(statement)
    }
    
    /// Insert event into database
    func insertEvent(_ event: UserActionEvent) {
        let sql = """
            INSERT INTO events (event_id, timestamp, event_type, event_data)
            VALUES (?, ?, ?, ?);
        """
        
        var statement: OpaquePointer?
        let eventData = try? JSONEncoder().encode(event)
        let eventDataString = eventData.flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (event.eventId as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (ISO8601DateFormatter().string(from: event.timestamp) as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 3, (event.eventType as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 4, (eventDataString as NSString).utf8String, -1, nil)
            
            if sqlite3_step(statement) != SQLITE_DONE {
                let error = String(cString: sqlite3_errmsg(db))
                print("Error inserting event: \(error)")
            }
        }
        
        sqlite3_finalize(statement)
    }
    
    /// Insert metric into database
    func insertMetric(metricName: String, value: Double, success: Bool, category: String? = nil) {
        let sql = """
            INSERT INTO metrics (metric_name, timestamp, value, success, category)
            VALUES (?, ?, ?, ?, ?);
        """
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (metricName as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (ISO8601DateFormatter().string(from: Date()) as NSString).utf8String, -1, nil)
            sqlite3_bind_double(statement, 3, value)
            sqlite3_bind_int(statement, 4, success ? 1 : 0)
            
            if let category = category {
                sqlite3_bind_text(statement, 5, (category as NSString).utf8String, -1, nil)
            } else {
                sqlite3_bind_null(statement, 5)
            }
            
            if sqlite3_step(statement) != SQLITE_DONE {
                let error = String(cString: sqlite3_errmsg(db))
                print("Error inserting metric: \(error)")
            }
        }
        
        sqlite3_finalize(statement)
    }
    
    /// Execute analytics query
    func executeQuery(_ sql: String) -> [[String: Any]] {
        var results: [[String: Any]] = []
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                var row: [String: Any] = [:]
                let columnCount = sqlite3_column_count(statement)
                
                for i in 0..<columnCount {
                    let columnName = String(cString: sqlite3_column_name(statement, i))
                    let columnType = sqlite3_column_type(statement, i)
                    
                    var value: Any?
                    switch columnType {
                    case SQLITE_INTEGER:
                        value = sqlite3_column_int(statement, i)
                    case SQLITE_FLOAT:
                        value = sqlite3_column_double(statement, i)
                    case SQLITE_TEXT:
                        value = String(cString: sqlite3_column_text(statement, i))
                    default:
                        value = nil
                    }
                    
                    if let value = value {
                        row[columnName] = value
                    }
                }
                
                results.append(row)
            }
        }
        
        sqlite3_finalize(statement)
        return results
    }
    
    /// Get events by type
    func getEventsByType() -> [[String: Any]] {
        let query = SQLSchemaGenerator.generateAnalyticsQueries()["events_by_type"]!
        return executeQuery(query)
    }
    
    /// Get events by date
    func getEventsByDate() -> [[String: Any]] {
        let query = SQLSchemaGenerator.generateAnalyticsQueries()["events_by_date"]!
        return executeQuery(query)
    }
    
    /// Get metrics summary
    func getMetricsSummary() -> [[String: Any]] {
        let query = SQLSchemaGenerator.generateAnalyticsQueries()["metrics_summary"]!
        return executeQuery(query)
    }
    
    /// Get daily metrics
    func getDailyMetrics() -> [[String: Any]] {
        let query = SQLSchemaGenerator.generateAnalyticsQueries()["daily_metrics"]!
        return executeQuery(query)
    }
}

// MARK: - Example Usage

func runSQLAnalyticsExample() {
    let analytics = SQLAnalytics()
    
    // Generate sample events
    let events = [
        UserActionEvent(userId: "user1", action: "view_page", metadata: ["page": "home"]),
        UserActionEvent(userId: "user1", action: "click_button", metadata: ["button": "signup"]),
        UserActionEvent(userId: "user2", action: "view_page", metadata: ["page": "products"]),
        UserActionEvent(userId: "user2", action: "purchase", metadata: ["amount": "99.99"])
    ]
    
    // Insert events
    for event in events {
        analytics.insertEvent(event)
    }
    
    // Insert sample metrics
    analytics.insertMetric(metricName: "page_views", value: 100.0, success: true, category: "traffic")
    analytics.insertMetric(metricName: "conversions", value: 5.0, success: true, category: "sales")
    analytics.insertMetric(metricName: "error_rate", value: 0.02, success: false, category: "errors")
    
    // Run analytics queries
    print("Events by Type:")
    print(analytics.getEventsByType())
    
    print("\nEvents by Date:")
    print(analytics.getEventsByDate())
    
    print("\nMetrics Summary:")
    print(analytics.getMetricsSummary())
    
    print("\nDaily Metrics:")
    print(analytics.getDailyMetrics())
}
