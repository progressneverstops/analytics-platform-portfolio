//
//  MetricsAggregator.swift
//  DataAnalyticsCore
//
//  Generic metrics aggregation system for time-series data
//  Extracted pattern - domain-agnostic implementation
//

import Foundation

/// Generic metrics structure for any metric type
struct MetricData: Codable {
    let metricName: String
    var totalCount: Int
    var successfulCount: Int
    var failedCount: Int
    var averageValue: Double
    var totalValue: Double
    var distribution: [String: Int] // For categorical distributions
    
    init(metricName: String) {
        self.metricName = metricName
        self.totalCount = 0
        self.successfulCount = 0
        self.failedCount = 0
        self.averageValue = 0.0
        self.totalValue = 0.0
        self.distribution = [:]
    }
}

/// Generic metrics aggregator for tracking and aggregating metrics
final class MetricsAggregator: ObservableObject {
    static let shared = MetricsAggregator()
    
    @Published var metrics: [String: MetricData] = [:]
    @Published var totalEvents: Int = 0
    @Published var overallSuccessRate: Double = 0.0
    @Published var overallAverageValue: Double = 0.0
    
    private let metricsFileURL: URL
    
    private init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.metricsFileURL = documentsPath.appendingPathComponent("DataAnalytics/metrics.json")
        
        loadMetrics()
    }
    
    /// Record a metric event
    func recordMetric(
        metricName: String,
        success: Bool,
        value: Double = 0.0,
        category: String? = nil
    ) {
        if metrics[metricName] == nil {
            metrics[metricName] = MetricData(metricName: metricName)
        }
        
        guard var metric = metrics[metricName] else { return }
        
        metric.totalCount += 1
        if success {
            metric.successfulCount += 1
        } else {
            metric.failedCount += 1
        }
        
        // Update average value
        metric.totalValue += value
        if metric.totalCount > 0 {
            metric.averageValue = metric.totalValue / Double(metric.totalCount)
        }
        
        // Update distribution if category provided
        if let category = category {
            metric.distribution[category, default: 0] += 1
        }
        
        metrics[metricName] = metric
        
        // Update overall metrics
        updateOverallMetrics()
        
        // Save to disk
        saveMetrics()
    }
    
    /// Get metrics for a specific metric name
    func getMetrics(for metricName: String) -> MetricData? {
        return metrics[metricName]
    }
    
    /// Calculate success rate for a metric
    func getSuccessRate(for metricName: String) -> Double {
        guard let metric = metrics[metricName], metric.totalCount > 0 else {
            return 0.0
        }
        return Double(metric.successfulCount) / Double(metric.totalCount)
    }
    
    /// Reset all metrics
    func resetMetrics() {
        metrics.removeAll()
        totalEvents = 0
        overallSuccessRate = 0.0
        overallAverageValue = 0.0
        saveMetrics()
    }
    
    // MARK: - Private Methods
    
    private func updateOverallMetrics() {
        totalEvents = metrics.values.reduce(0) { $0 + $1.totalCount }
        
        let totalSuccessful = metrics.values.reduce(0) { $0 + $1.successfulCount }
        overallSuccessRate = totalEvents > 0 ? Double(totalSuccessful) / Double(totalEvents) : 0.0
        
        let totalValue = metrics.values.reduce(0.0) { $0 + ($1.averageValue * Double($1.totalCount)) }
        overallAverageValue = totalEvents > 0 ? totalValue / Double(totalEvents) : 0.0
    }
    
    private func saveMetrics() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        if let data = try? encoder.encode(metrics) {
            try? data.write(to: metricsFileURL)
        }
    }
    
    private func loadMetrics() {
        guard let data = try? Data(contentsOf: metricsFileURL),
              let loaded = try? JSONDecoder().decode([String: MetricData].self, from: data) else {
            return
        }
        
        metrics = loaded
        updateOverallMetrics()
    }
}

/// Time-series aggregator for windowed metrics
final class TimeSeriesAggregator {
    struct TimeWindow {
        let startDate: Date
        let endDate: Date
        let metricName: String
        var count: Int
        var sum: Double
        var average: Double
        
        init(startDate: Date, endDate: Date, metricName: String) {
            self.startDate = startDate
            self.endDate = endDate
            self.metricName = metricName
            self.count = 0
            self.sum = 0.0
            self.average = 0.0
        }
    }
    
    /// Aggregate events into time windows (e.g., hourly, daily)
    static func aggregateByTimeWindow<T: LoggableEvent>(
        events: [T],
        windowSize: TimeInterval,
        valueExtractor: (T) -> Double
    ) -> [TimeWindow] {
        guard !events.isEmpty else { return [] }
        
        let sortedEvents = events.sorted { $0.timestamp < $1.timestamp }
        let startDate = sortedEvents.first!.timestamp
        let endDate = sortedEvents.last!.timestamp
        
        var windows: [TimeWindow] = []
        var currentWindowStart = startDate
        
        while currentWindowStart <= endDate {
            let currentWindowEnd = currentWindowStart.addingTimeInterval(windowSize)
            let window = TimeWindow(
                startDate: currentWindowStart,
                endDate: currentWindowEnd,
                metricName: "time_series"
            )
            windows.append(window)
            currentWindowStart = currentWindowEnd
        }
        
        // Distribute events into windows
        for event in sortedEvents {
            if let windowIndex = windows.firstIndex(where: { event.timestamp >= $0.startDate && event.timestamp < $0.endDate }) {
                let value = valueExtractor(event)
                windows[windowIndex].count += 1
                windows[windowIndex].sum += value
                windows[windowIndex].average = windows[windowIndex].sum / Double(windows[windowIndex].count)
            }
        }
        
        return windows
    }
}
