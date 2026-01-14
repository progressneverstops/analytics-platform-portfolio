//
//  DataQualityPipeline.swift
//  Data Quality Pipeline
//
//  Generic data quality validation and monitoring system
//

import Foundation

/// Validation result
enum ValidationResult {
    case valid
    case invalid(String) // Error message
    
    var isValid: Bool {
        switch self {
        case .valid: return true
        case .invalid: return false
        }
    }
}

/// Generic validation rule
protocol ValidationRule {
    associatedtype DataType
    
    func validate(_ data: DataType) -> ValidationResult
    var ruleName: String { get }
}

/// Required field validation
struct RequiredFieldRule<T>: ValidationRule {
    let fieldName: String
    let ruleName: String
    
    init(fieldName: String) {
        self.fieldName = fieldName
        self.ruleName = "RequiredField_\(fieldName)"
    }
    
    func validate(_ data: [String: T]) -> ValidationResult {
        if data[fieldName] == nil {
            return .invalid("Required field '\(fieldName)' is missing")
        }
        return .valid
    }
}

/// Type validation rule
struct TypeValidationRule: ValidationRule {
    let fieldName: String
    let expectedType: String
    let ruleName: String
    
    init(fieldName: String, expectedType: String) {
        self.fieldName = fieldName
        self.expectedType = expectedType
        self.ruleName = "TypeValidation_\(fieldName)"
    }
    
    func validate(_ data: [String: Any]) -> ValidationResult {
        guard let value = data[fieldName] else {
            return .invalid("Field '\(fieldName)' is missing")
        }
        
        let actualType = String(describing: type(of: value))
        if actualType.contains(expectedType) {
            return .valid
        } else {
            return .invalid("Field '\(fieldName)' has type '\(actualType)', expected '\(expectedType)'")
        }
    }
}

/// Range validation rule
struct RangeValidationRule: ValidationRule {
    let fieldName: String
    let min: Double?
    let max: Double?
    let ruleName: String
    
    init(fieldName: String, min: Double? = nil, max: Double? = nil) {
        self.fieldName = fieldName
        self.min = min
        self.max = max
        self.ruleName = "RangeValidation_\(fieldName)"
    }
    
    func validate(_ data: [String: Any]) -> ValidationResult {
        guard let value = data[fieldName] else {
            return .invalid("Field '\(fieldName)' is missing")
        }
        
        guard let numericValue = value as? Double ?? (value as? Int).map(Double.init) else {
            return .invalid("Field '\(fieldName)' is not numeric")
        }
        
        if let min = min, numericValue < min {
            return .invalid("Field '\(fieldName)' value \(numericValue) is below minimum \(min)")
        }
        
        if let max = max, numericValue > max {
            return .invalid("Field '\(fieldName)' value \(numericValue) is above maximum \(max)")
        }
        
        return .valid
    }
}

/// Format validation rule (e.g., email, date)
struct FormatValidationRule: ValidationRule {
    let fieldName: String
    let format: ValidationFormat
    let ruleName: String
    
    enum ValidationFormat {
        case email
        case date(format: String)
        case regex(pattern: String)
    }
    
    init(fieldName: String, format: ValidationFormat) {
        self.fieldName = fieldName
        self.format = format
        self.ruleName = "FormatValidation_\(fieldName)"
    }
    
    func validate(_ data: [String: Any]) -> ValidationResult {
        guard let value = data[fieldName] as? String else {
            return .invalid("Field '\(fieldName)' is missing or not a string")
        }
        
        switch format {
        case .email:
            if DataCleaner.isValidEmail(value) {
                return .valid
            } else {
                return .invalid("Field '\(fieldName)' is not a valid email address")
            }
        case .date(let format):
            let formatter = DateFormatter()
            formatter.dateFormat = format
            if formatter.date(from: value) != nil {
                return .valid
            } else {
                return .invalid("Field '\(fieldName)' is not a valid date in format '\(format)'")
            }
        case .regex(let pattern):
            let regex = try? NSRegularExpression(pattern: pattern)
            let range = NSRange(location: 0, length: value.utf16.count)
            if regex?.firstMatch(in: value, range: range) != nil {
                return .valid
            } else {
                return .invalid("Field '\(fieldName)' does not match pattern '\(pattern)'")
            }
        }
    }
}

/// Data quality checker
final class DataQualityChecker {
    private var rules: [any ValidationRule] = []
    
    /// Add validation rule
    func addRule<R: ValidationRule>(_ rule: R) {
        rules.append(rule)
    }
    
    /// Validate data against all rules
    func validate(_ data: [String: Any]) -> [ValidationResult] {
        return rules.map { rule in
            if let typedRule = rule as? any ValidationRule {
                // Type erasure workaround - in real implementation, use proper generics
                return validateWithRule(rule, data: data)
            }
            return .valid
        }
    }
    
    private func validateWithRule(_ rule: any ValidationRule, data: [String: Any]) -> ValidationResult {
        // Simplified validation - in real implementation, use proper type system
        if let requiredRule = rule as? RequiredFieldRule<Any> {
            return requiredRule.validate(data)
        } else if let typeRule = rule as? TypeValidationRule {
            return typeRule.validate(data)
        } else if let rangeRule = rule as? RangeValidationRule {
            return rangeRule.validate(data)
        } else if let formatRule = rule as? FormatValidationRule {
            return formatRule.validate(data)
        }
        return .valid
    }
    
    /// Calculate quality score (0.0 to 1.0)
    func calculateQualityScore(results: [ValidationResult]) -> Double {
        guard !results.isEmpty else { return 1.0 }
        let validCount = results.filter { $0.isValid }.count
        return Double(validCount) / Double(results.count)
    }
}

/// Quality metrics tracker
final class QualityMetrics {
    static let shared = QualityMetrics()
    
    private var qualityScores: [String: [Double]] = [:] // Rule name -> scores
    private var errorCounts: [String: Int] = [:] // Rule name -> error count
    
    private init() {}
    
    /// Record validation results
    func recordValidation(ruleName: String, results: [ValidationResult], qualityScore: Double) {
        qualityScores[ruleName, default: []].append(qualityScore)
        
        let errorCount = results.filter { !$0.isValid }.count
        errorCounts[ruleName, default: 0] += errorCount
    }
    
    /// Get average quality score for a rule
    func getAverageQualityScore(ruleName: String) -> Double {
        guard let scores = qualityScores[ruleName], !scores.isEmpty else {
            return 1.0
        }
        return scores.reduce(0, +) / Double(scores.count)
    }
    
    /// Get total error count for a rule
    func getErrorCount(ruleName: String) -> Int {
        return errorCounts[ruleName] ?? 0
    }
    
    /// Get overall quality score
    func getOverallQualityScore() -> Double {
        guard !qualityScores.isEmpty else { return 1.0 }
        
        let allScores = qualityScores.values.flatMap { $0 }
        guard !allScores.isEmpty else { return 1.0 }
        
        return allScores.reduce(0, +) / Double(allScores.count)
    }
}

/// Quality report generator
final class QualityReportGenerator {
    /// Generate quality report
    static func generateReport(
        dataSource: String,
        results: [ValidationResult],
        qualityScore: Double,
        metrics: QualityMetrics
    ) -> String {
        var report = "Data Quality Report\n"
        report += "===================\n\n"
        report += "Data Source: \(dataSource)\n"
        report += "Generated: \(Date())\n\n"
        
        report += "Overall Quality Score: \(String(format: "%.2f%%", qualityScore * 100))\n\n"
        
        report += "Validation Results:\n"
        let validCount = results.filter { $0.isValid }.count
        let invalidCount = results.count - validCount
        report += "  Passed: \(validCount)\n"
        report += "  Failed: \(invalidCount)\n\n"
        
        if invalidCount > 0 {
            report += "Errors:\n"
            for result in results {
                if case .invalid(let message) = result {
                    report += "  - \(message)\n"
                }
            }
        }
        
        report += "\nQuality Metrics:\n"
        report += "  Overall Score: \(String(format: "%.2f%%", metrics.getOverallQualityScore() * 100))\n"
        
        return report
    }
    
    /// Export quality report to JSON
    static func exportReportJSON(
        dataSource: String,
        results: [ValidationResult],
        qualityScore: Double
    ) -> Data? {
        let report: [String: Any] = [
            "dataSource": dataSource,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "qualityScore": qualityScore,
            "totalChecks": results.count,
            "passedChecks": results.filter { $0.isValid }.count,
            "failedChecks": results.filter { !$0.isValid }.count,
            "errors": results.compactMap { result -> String? in
                if case .invalid(let message) = result {
                    return message
                }
                return nil
            }
        ]
        
        return try? JSONSerialization.data(withJSONObject: report, options: .prettyPrinted)
    }
}
