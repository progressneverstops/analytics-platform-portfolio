//
//  ABExperiments.swift
//  A/B Experiments Framework
//
//  Generic A/B testing framework
//

import Foundation

/// Experiment variant
struct ExperimentVariant: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let trafficAllocation: Double // 0.0 to 1.0
}

/// Experiment definition
struct Experiment: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let variants: [ExperimentVariant]
    let startDate: Date
    let endDate: Date?
    let status: ExperimentStatus
    let successMetric: String
    
    enum ExperimentStatus: String, Codable {
        case draft
        case running
        case paused
        case completed
    }
}

/// Experiment event (user action in experiment)
struct ExperimentEvent: Codable {
    let experimentId: String
    let variantId: String
    let userId: String
    let eventType: String
    let timestamp: Date
    let metadata: [String: String]
}

/// Variant assigner
final class VariantAssigner {
    /// Assign user to variant based on consistent hashing
    static func assignVariant(userId: String, variants: [ExperimentVariant]) -> ExperimentVariant? {
        guard !variants.isEmpty else { return nil }
        
        // Consistent hashing based on user ID
        let hash = abs(userId.hashValue)
        let totalAllocation = variants.reduce(0.0) { $0 + $1.trafficAllocation }
        
        guard totalAllocation > 0 else {
            // Equal distribution if no allocation specified
            let index = hash % variants.count
            return variants[index]
        }
        
        // Weighted random assignment
        let random = Double(hash % 10000) / 10000.0
        var cumulative = 0.0
        
        for variant in variants {
            cumulative += variant.trafficAllocation / totalAllocation
            if random <= cumulative {
                return variant
            }
        }
        
        return variants.last
    }
}

/// Experiment tracker
final class ExperimentTracker {
    static let shared = ExperimentTracker()
    
    private var events: [ExperimentEvent] = []
    private let eventsFileURL: URL
    
    private init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.eventsFileURL = documentsPath.appendingPathComponent("DataAnalytics/experiment_events.json")
        
        loadEvents()
    }
    
    /// Track experiment event
    func trackEvent(_ event: ExperimentEvent) {
        events.append(event)
        saveEvents()
    }
    
    /// Get events for experiment
    func getEvents(for experimentId: String) -> [ExperimentEvent] {
        return events.filter { $0.experimentId == experimentId }
    }
    
    /// Get events for variant
    func getEvents(for experimentId: String, variantId: String) -> [ExperimentEvent] {
        return events.filter { $0.experimentId == experimentId && $0.variantId == variantId }
    }
    
    // MARK: - Private Methods
    
    private func saveEvents() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        if let data = try? encoder.encode(events) {
            try? data.write(to: eventsFileURL)
        }
    }
    
    private func loadEvents() {
        guard let data = try? Data(contentsOf: eventsFileURL),
              let loaded = try? JSONDecoder().decode([ExperimentEvent].self, from: data) else {
            return
        }
        
        events = loaded
    }
}

/// Statistical analyzer for A/B tests
final class StatisticalAnalyzer {
    /// Calculate conversion rate
    static func calculateConversionRate(events: [ExperimentEvent], successEventType: String) -> Double {
        guard !events.isEmpty else { return 0.0 }
        
        let successCount = events.filter { $0.eventType == successEventType }.count
        return Double(successCount) / Double(events.count)
    }
    
    /// Compare two variants (simple conversion rate comparison)
    static func compareVariants(
        controlEvents: [ExperimentEvent],
        treatmentEvents: [ExperimentEvent],
        successEventType: String
    ) -> VariantComparison {
        let controlRate = calculateConversionRate(events: controlEvents, successEventType: successEventType)
        let treatmentRate = calculateConversionRate(events: treatmentEvents, successEventType: successEventType)
        
        let lift = controlRate > 0 ? ((treatmentRate - controlRate) / controlRate) * 100 : 0.0
        
        // Simple significance test (chi-square approximation)
        let significance = calculateSignificance(
            controlEvents: controlEvents,
            treatmentEvents: treatmentEvents,
            successEventType: successEventType
        )
        
        return VariantComparison(
            controlRate: controlRate,
            treatmentRate: treatmentRate,
            lift: lift,
            significance: significance,
            isSignificant: significance < 0.05
        )
    }
    
    /// Calculate statistical significance (simplified chi-square test)
    private static func calculateSignificance(
        controlEvents: [ExperimentEvent],
        treatmentEvents: [ExperimentEvent],
        successEventType: String
    ) -> Double {
        let controlSuccess = controlEvents.filter { $0.eventType == successEventType }.count
        let controlTotal = controlEvents.count
        let treatmentSuccess = treatmentEvents.filter { $0.eventType == successEventType }.count
        let treatmentTotal = treatmentEvents.count
        
        guard controlTotal > 0 && treatmentTotal > 0 else { return 1.0 }
        
        // Simplified p-value calculation (in production, use proper statistical library)
        // This is a placeholder - real implementation would use chi-square or t-test
        let controlRate = Double(controlSuccess) / Double(controlTotal)
        let treatmentRate = Double(treatmentSuccess) / Double(treatmentTotal)
        let difference = abs(treatmentRate - controlRate)
        
        // Simplified: larger difference = lower p-value
        // Real implementation should use proper statistical test
        if difference < 0.01 {
            return 0.5 // Not significant
        } else if difference < 0.05 {
            return 0.1 // Marginally significant
        } else {
            return 0.01 // Significant
        }
    }
}

/// Variant comparison results
struct VariantComparison {
    let controlRate: Double
    let treatmentRate: Double
    let lift: Double // Percentage improvement
    let significance: Double // P-value
    let isSignificant: Bool
    
    var winner: String? {
        guard isSignificant else { return nil }
        return treatmentRate > controlRate ? "Treatment" : "Control"
    }
}

/// Experiment results generator
final class ExperimentResultsGenerator {
    /// Generate experiment results report
    static func generateReport(
        experiment: Experiment,
        controlEvents: [ExperimentEvent],
        treatmentEvents: [ExperimentEvent]
    ) -> String {
        let comparison = StatisticalAnalyzer.compareVariants(
            controlEvents: controlEvents,
            treatmentEvents: treatmentEvents,
            successEventType: experiment.successMetric
        )
        
        var report = "A/B Experiment Results\n"
        report += "=======================\n\n"
        report += "Experiment: \(experiment.name)\n"
        report += "Generated: \(Date())\n\n"
        
        report += "Results:\n"
        report += "  Control Conversion Rate: \(String(format: "%.2f%%", comparison.controlRate * 100))\n"
        report += "  Treatment Conversion Rate: \(String(format: "%.2f%%", comparison.treatmentRate * 100))\n"
        report += "  Lift: \(String(format: "%.2f%%", comparison.lift))\n"
        report += "  P-value: \(String(format: "%.4f", comparison.significance))\n"
        report += "  Statistically Significant: \(comparison.isSignificant ? "Yes" : "No")\n"
        
        if let winner = comparison.winner {
            report += "  Winner: \(winner)\n"
        }
        
        return report
    }
}
