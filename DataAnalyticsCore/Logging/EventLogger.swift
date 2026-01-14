//
//  EventLogger.swift
//  DataAnalyticsCore
//
//  Generic event logging system for tracking any type of structured events
//  Extracted pattern - domain-agnostic implementation
//

import Foundation

/// Generic event that can be logged
protocol LoggableEvent: Codable {
    var eventId: String { get }
    var timestamp: Date { get }
    var eventType: String { get }
}

/// Generic event logger for any event type
final class EventLogger<T: LoggableEvent> {
    static func shared(storagePath: String) -> EventLogger<T> {
        return EventLogger<T>(storagePath: storagePath)
    }
    
    private let eventsDirectory: URL
    private let fileCopiesDirectory: URL?
    
    private init(storagePath: String) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let baseDirectory = documentsPath.appendingPathComponent(storagePath, isDirectory: true)
        
        self.eventsDirectory = baseDirectory.appendingPathComponent("events", isDirectory: true)
        self.fileCopiesDirectory = baseDirectory.appendingPathComponent("file_copies", isDirectory: true)
        
        // Create directories if they don't exist
        try? FileManager.default.createDirectory(at: eventsDirectory, withIntermediateDirectories: true)
        if let fileCopiesDir = fileCopiesDirectory {
            try? FileManager.default.createDirectory(at: fileCopiesDir, withIntermediateDirectories: true)
        }
    }
    
    /// Log an event
    func logEvent(_ event: T) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestampStr = formatter.string(from: event.timestamp)
        
        let fileName = "\(timestampStr)_\(event.eventId)_\(event.eventType).json"
        let fileURL = eventsDirectory.appendingPathComponent(fileName)
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        if let data = try? encoder.encode(event) {
            try? data.write(to: fileURL)
        }
    }
    
    /// Get all events, sorted by timestamp (newest first)
    func getAllEvents() -> [T] {
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(at: eventsDirectory, includingPropertiesForKeys: [.creationDateKey]) else {
            return []
        }
        
        let events = files.compactMap { file -> T? in
            guard let data = try? Data(contentsOf: file),
                  let event = try? JSONDecoder().decode(T.self, from: data) else {
                return nil
            }
            return event
        }
        
        return events.sorted { $0.timestamp > $1.timestamp }
    }
    
    /// Export all events to a single JSON file
    func exportAllEvents() -> URL? {
        let events = getAllEvents()
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        guard let data = try? encoder.encode(events) else { return nil }
        
        let exportURL = eventsDirectory.appendingPathComponent("export_all_events_\(Date().timeIntervalSince1970).json")
        try? data.write(to: exportURL)
        
        return exportURL
    }
    
    /// Get events filtered by type
    func getEvents(ofType eventType: String) -> [T] {
        return getAllEvents().filter { $0.eventType == eventType }
    }
    
    /// Get events in date range
    func getEvents(from startDate: Date, to endDate: Date) -> [T] {
        return getAllEvents().filter { event in
            event.timestamp >= startDate && event.timestamp <= endDate
        }
    }
}

/// Example event type - User Action Event
/// This is a placeholder example, not domain-specific
struct UserActionEvent: LoggableEvent {
    let eventId: String
    let timestamp: Date
    let eventType: String
    let userId: String
    let action: String
    let metadata: [String: String]
    
    init(userId: String, action: String, metadata: [String: String] = [:]) {
        self.eventId = UUID().uuidString
        self.timestamp = Date()
        self.eventType = "user_action"
        self.userId = userId
        self.action = action
        self.metadata = metadata
    }
}
