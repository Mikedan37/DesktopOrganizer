//
//  SnapshotStorage.swift
//  DesktopOrganizer
//
//  Created by Michael Danylchuk on 8/3/25.
//

import Foundation

class SnapshotStorage {
    // Directory to store snapshots (in App Support)
    static var snapshotsDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("DesktopOrganizer/Snapshots")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        return dir
    }

    // Save a snapshot to disk as JSON (filename = snapshot.id)
    static func save(_ snapshot: DesktopSnapshot) throws {
        let url = snapshotsDirectory.appendingPathComponent("\(snapshot.id.uuidString).json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(snapshot)
        try data.write(to: url)
    }

    // Load all snapshots from disk, sorted by timestamp (newest last)
    static func loadAll() throws -> [DesktopSnapshot] {
        let files = try FileManager.default.contentsOfDirectory(at: snapshotsDirectory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        var snapshots: [DesktopSnapshot] = []
        for fileURL in files where fileURL.pathExtension == "json" {
            do {
                let data = try Data(contentsOf: fileURL)
                let snapshot = try decoder.decode(DesktopSnapshot.self, from: data)
                snapshots.append(snapshot)
            } catch {
                print("Failed to load snapshot at \(fileURL.lastPathComponent): \(error)")
            }
        }
        // Sort by timestamp ascending
        return snapshots.sorted(by: { $0.timestamp < $1.timestamp })
    }

    // (Optional) Delete old or all snapshots
    static func delete(_ snapshot: DesktopSnapshot) throws {
        let url = snapshotsDirectory.appendingPathComponent("\(snapshot.id.uuidString).json")
        try FileManager.default.removeItem(at: url)
    }

    static func deleteAll() throws {
        let files = try FileManager.default.contentsOfDirectory(at: snapshotsDirectory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        for fileURL in files where fileURL.pathExtension == "json" {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }
}
