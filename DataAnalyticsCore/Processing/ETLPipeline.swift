//
//  ETLPipeline.swift
//  DataAnalyticsCore
//
//  Generic ETL (Extract, Transform, Load) pipeline pattern
//  Extracted pattern - domain-agnostic implementation
//

import Foundation

/// Generic ETL pipeline stage
protocol ETLStage {
    associatedtype Input
    associatedtype Output
    
    func process(_ input: Input) throws -> Output
    func validate(_ input: Input) -> Bool
}

/// Generic ETL pipeline
final class ETLPipeline<ExtractOutput, TransformOutput, LoadOutput> {
    typealias ExtractStage = any ETLStage where Input == Void, Output == ExtractOutput
    typealias TransformStage = any ETLStage where Input == ExtractOutput, Output == TransformOutput
    typealias LoadStage = any ETLStage where Input == TransformOutput, Output == LoadOutput
    
    private let extractStage: ExtractStage
    private let transformStage: TransformStage
    private let loadStage: LoadStage
    
    init(extract: ExtractStage, transform: TransformStage, load: LoadStage) {
        self.extractStage = extract
        self.transformStage = transform
        self.loadStage = load
    }
    
    /// Run the complete ETL pipeline
    func run() throws -> LoadOutput {
        // Extract
        guard extractStage.validate(()) else {
            throw ETLPipelineError.validationFailed(stage: "Extract")
        }
        let extracted = try extractStage.process(())
        
        // Transform
        guard transformStage.validate(extracted) else {
            throw ETLPipelineError.validationFailed(stage: "Transform")
        }
        let transformed = try transformStage.process(extracted)
        
        // Load
        guard loadStage.validate(transformed) else {
            throw ETLPipelineError.validationFailed(stage: "Load")
        }
        let loaded = try loadStage.process(transformed)
        
        return loaded
    }
}

enum ETLPipelineError: Error {
    case validationFailed(stage: String)
    case processingFailed(stage: String, error: Error)
}

/// Generic data cleaner for normalization
final class DataCleaner {
    /// Normalize string data
    static func normalizeString(_ input: String) -> String {
        return input.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
    }
    
    /// Remove duplicates from array
    static func removeDuplicates<T: Hashable>(_ items: [T]) -> [T] {
        return Array(Set(items))
    }
    
    /// Validate email format (example validation)
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    /// Validate required fields
    static func validateRequiredFields<T>(_ data: [String: T], required: [String]) -> [String] {
        var missing: [String] = []
        for field in required {
            if data[field] == nil {
                missing.append(field)
            }
        }
        return missing
    }
}

/// Batch processor for handling large datasets in chunks
final class BatchProcessor {
    /// Process items in batches
    static func processInBatches<T, R>(
        items: [T],
        batchSize: Int,
        processor: ([T]) throws -> [R]
    ) throws -> [R] {
        var results: [R] = []
        
        for i in stride(from: 0, to: items.count, by: batchSize) {
            let endIndex = min(i + batchSize, items.count)
            let batch = Array(items[i..<endIndex])
            let batchResults = try processor(batch)
            results.append(contentsOf: batchResults)
        }
        
        return results
    }
}
