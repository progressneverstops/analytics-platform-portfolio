//
//  DashboardComponents.swift
//  Dashboard + Report Project
//
//  Generic dashboard components for metrics visualization
//

import SwiftUI
import Charts

/// Metric Card Component - Displays a single KPI
struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let trend: Trend?
    let color: Color
    
    enum Trend {
        case up(Double)
        case down(Double)
        case stable
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let trend = trend {
                HStack {
                    Image(systemName: trendIcon(trend))
                        .foregroundColor(trendColor(trend))
                    Text(trendText(trend))
                        .font(.caption2)
                        .foregroundColor(trendColor(trend))
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func trendIcon(_ trend: Trend) -> String {
        switch trend {
        case .up: return "arrow.up"
        case .down: return "arrow.down"
        case .stable: return "minus"
        }
    }
    
    private func trendColor(_ trend: Trend) -> Color {
        switch trend {
        case .up: return .green
        case .down: return .red
        case .stable: return .gray
        }
    }
    
    private func trendText(_ trend: Trend) -> String {
        switch trend {
        case .up(let value): return "+\(String(format: "%.1f", value))%"
        case .down(let value): return "-\(String(format: "%.1f", value))%"
        case .stable: return "No change"
        }
    }
}

/// Time Series Chart Component
struct TimeSeriesChart: View {
    let data: [TimeSeriesDataPoint]
    let title: String
    
    struct TimeSeriesDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
            
            Chart(data) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(.blue)
                .interpolationMethod(.catmullRom)
                
                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue.opacity(0.3), .blue.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
            .frame(height: 200)
            .padding()
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

/// Distribution Chart Component
struct DistributionChart: View {
    let data: [DistributionDataPoint]
    let title: String
    
    struct DistributionDataPoint: Identifiable {
        let id = UUID()
        let category: String
        let count: Int
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
            
            Chart(data) { point in
                BarMark(
                    x: .value("Category", point.category),
                    y: .value("Count", point.count)
                )
                .foregroundStyle(.blue)
            }
            .frame(height: 200)
            .padding()
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

/// Dashboard View
struct DashboardView: View {
    @StateObject private var metricsAggregator = MetricsAggregator.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Metric Cards
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    MetricCard(
                        title: "Total Events",
                        value: "\(metricsAggregator.totalEvents)",
                        subtitle: "All time",
                        trend: nil,
                        color: .blue
                    )
                    
                    MetricCard(
                        title: "Success Rate",
                        value: String(format: "%.1f%%", metricsAggregator.overallSuccessRate * 100),
                        subtitle: "Overall",
                        trend: .up(5.2),
                        color: .green
                    )
                    
                    MetricCard(
                        title: "Average Value",
                        value: String(format: "%.2f", metricsAggregator.overallAverageValue),
                        subtitle: "Mean",
                        trend: .stable,
                        color: .orange
                    )
                }
                .padding(.horizontal)
                
                // Time Series Chart
                if let timeSeriesData = generateTimeSeriesData() {
                    TimeSeriesChart(data: timeSeriesData, title: "Metrics Over Time")
                        .padding(.horizontal)
                }
                
                // Distribution Chart
                if let distributionData = generateDistributionData() {
                    DistributionChart(data: distributionData, title: "Metrics by Category")
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
    
    private func generateTimeSeriesData() -> [TimeSeriesChart.TimeSeriesDataPoint]? {
        // Example data generation
        let calendar = Calendar.current
        var data: [TimeSeriesChart.TimeSeriesDataPoint] = []
        
        for i in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                let value = Double.random(in: 50...150)
                data.append(TimeSeriesChart.TimeSeriesDataPoint(date: date, value: value))
            }
        }
        
        return data.sorted { $0.date < $1.date }
    }
    
    private func generateDistributionData() -> [DistributionChart.DistributionDataPoint]? {
        // Example data from metrics aggregator
        var data: [DistributionChart.DistributionDataPoint] = []
        
        for (metricName, metric) in metricsAggregator.metrics {
            data.append(DistributionChart.DistributionDataPoint(
                category: metricName,
                count: metric.totalCount
            ))
        }
        
        return data.isEmpty ? nil : data
    }
}

/// Report Generator
final class ReportGenerator {
    /// Generate daily report
    static func generateDailyReport(metrics: [String: MetricData]) -> String {
        var report = "Daily Metrics Report\n"
        report += "Generated: \(Date())\n\n"
        
        report += "Summary:\n"
        report += "Total Metrics Tracked: \(metrics.count)\n\n"
        
        report += "Metrics Breakdown:\n"
        for (name, metric) in metrics.sorted(by: { $0.key < $1.key }) {
            report += "\n\(name):\n"
            report += "  Total Count: \(metric.totalCount)\n"
            report += "  Success Rate: \(String(format: "%.1f%%", (Double(metric.successfulCount) / Double(metric.totalCount)) * 100))\n"
            report += "  Average Value: \(String(format: "%.2f", metric.averageValue))\n"
        }
        
        return report
    }
    
    /// Export report to JSON
    static func exportReportJSON(metrics: [String: MetricData]) -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        return try? encoder.encode(metrics)
    }
    
    /// Export report to CSV
    static func exportReportCSV(metrics: [String: MetricData]) -> String {
        var csv = "Metric Name,Total Count,Success Count,Failed Count,Average Value\n"
        
        for (name, metric) in metrics.sorted(by: { $0.key < $1.key }) {
            csv += "\(name),\(metric.totalCount),\(metric.successfulCount),\(metric.failedCount),\(String(format: "%.2f", metric.averageValue))\n"
        }
        
        return csv
    }
}
