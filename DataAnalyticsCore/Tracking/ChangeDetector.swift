//
//  ChangeDetector.swift
//  DataAnalyticsCore
//
//  Generic change detection system for tracking changes over time
//  Extracted pattern - domain-agnostic implementation
//

import Foundation
import CryptoKit

/// Represents a fingerprint of a data item
struct DataFingerprint: Codable, Hashable {
    let identifier: String
    let hash: String // SHA256 hash
    let modifiedAt: Date
    let size: Int
}

/// Represents a snapshot of data at a point in time
struct DataSnapshot: Codable, Identifiable {
    let id: String
    let createdAt: Date
    let name: String
    let items: [DataFingerprint]
}

/// Types of changes detected
enum ChangeType: String, Codable {
    case added
    case modified
    case deleted
    case unchanged
}

/// Represents a detected change
struct DetectedChange: Identifiable, Codable {
    let id: String
    let identifier: String
    let changeType: ChangeType
    let oldHash: String?
    let newHash: String?
}

/// Generic change detector for any data type
final class ChangeDetector {
    static let shared = ChangeDetector()
    
    private init() {}
    
    /// Create a fingerprint from data
    func createFingerprint(identifier: String, data: Data, modifiedAt: Date = Date()) -> DataFingerprint {
        let digest = SHA256.hash(data: data)
        let hash = digest.map { String(format: "%02x", $0) }.joined()
        
        return DataFingerprint(
            identifier: identifier,
            hash: hash,
            modifiedAt: modifiedAt,
            size: data.count
        )
    }
    
    /// Create a snapshot from a collection of fingerprints
    func createSnapshot(name: String, fingerprints: [DataFingerprint]) -> DataSnapshot {
        return DataSnapshot(
            id: UUID().uuidString,
            createdAt: Date(),
            name: name,
            items: fingerprints.sorted(by: { $0.identifier < $1.identifier })
        )
    }
    
    /// Detect changes between two snapshots
    func detectChanges(current: [DataFingerprint], previous: [DataFingerprint]) -> [DetectedChange] {
        let currentMap = Dictionary(uniqueKeysWithValues: current.map { ($0.identifier, $0) })
        let previousMap = Dictionary(uniqueKeysWithValues: previous.map { ($0.identifier, $0) })
        
        var changes: [DetectedChange] = []
        
        // Check for added and modified items
        for (identifier, currentFingerprint) in currentMap {
            if let previousFingerprint = previousMap[identifier] {
                if currentFingerprint.hash != previousFingerprint.hash {
                    changes.append(DetectedChange(
                        id: identifier,
                        identifier: identifier,
                        changeType: .modified,
                        oldHash: previousFingerprint.hash,
                        newHash: currentFingerprint.hash
                    ))
                } else {
                    changes.append(DetectedChange(
                        id: identifier,
                        identifier: identifier,
                        changeType: .unchanged,
                        oldHash: previousFingerprint.hash,
                        newHash: currentFingerprint.hash
                    ))
                }
            } else {
                changes.append(DetectedChange(
                    id: identifier,
                    identifier: identifier,
                    changeType: .added,
                    oldHash: nil,
                    newHash: currentFingerprint.hash
                ))
            }
        }
        
        // Check for deleted items
        for (identifier, previousFingerprint) in previousMap where currentMap[identifier] == nil {
            changes.append(DetectedChange(
                id: identifier,
                identifier: identifier,
                changeType: .deleted,
                oldHash: previousFingerprint.hash,
                newHash: nil
            ))
        }
        
        // Sort: modified first, then added, then deleted, then unchanged
        return changes.sorted { a, b in
            if a.changeType == b.changeType {
                return a.identifier < b.identifier
            }
            let rank: (ChangeType) -> Int = { type in
                switch type {
                case .modified: return 0
                case .added: return 1
                case .deleted: return 2
                case .unchanged: return 3
                }
            }
            return rank(a.changeType) < rank(b.changeType)
        }
    }
    
    /// Calculate change statistics
    func calculateChangeStats(changes: [DetectedChange]) -> (added: Int, modified: Int, deleted: Int, unchanged: Int) {
        var stats = (added: 0, modified: 0, deleted: 0, unchanged: 0)
        
        for change in changes {
            switch change.changeType {
            case .added: stats.added += 1
            case .modified: stats.modified += 1
            case .deleted: stats.deleted += 1
            case .unchanged: stats.unchanged += 1
            }
        }
        
        return stats
    }
}

/// Version manager for tracking snapshots over time
final class VersionManager {
    static let shared = VersionManager()
    
    private var snapshots: [DataSnapshot] = []
    private let snapshotsFileURL: URL
    
    private init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.snapshotsFileURL = documentsPath.appendingPathComponent("DataAnalytics/snapshots.json")
        
        loadSnapshots()
    }
    
    /// Save a snapshot
    func saveSnapshot(_ snapshot: DataSnapshot) {
        snapshots.removeAll(where: { $0.id == snapshot.id })
        snapshots.insert(snapshot, at: 0)
        persistSnapshots()
    }
    
    /// Get all snapshots
    func getAllSnapshots() -> [DataSnapshot] {
        return snapshots
    }
    
    /// Get snapshot by ID
    func getSnapshot(id: String) -> DataSnapshot? {
        return snapshots.first { $0.id == id }
    }
    
    /// Compare two snapshots
    func compareSnapshots(currentId: String, previousId: String) -> [DetectedChange]? {
        guard let current = getSnapshot(id: currentId),
              let previous = getSnapshot(id: previousId) else {
            return nil
        }
        
        return ChangeDetector.shared.detectChanges(
            current: current.items,
            previous: previous.items
        )
    }
    
    // MARK: - Private Methods
    
    private func persistSnapshots() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        if let data = try? encoder.encode(snapshots) {
            try? data.write(to: snapshotsFileURL)
        }
    }
    
    private func loadSnapshots() {
        guard let data = try? Data(contentsOf: snapshotsFileURL),
              let loaded = try? JSONDecoder().decode([DataSnapshot].self, from: data) else {
            return
        }
        
        snapshots = loaded
    }
}
