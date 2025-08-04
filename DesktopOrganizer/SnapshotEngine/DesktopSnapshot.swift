//
//  DesktopSnapshot.swift
//  DesktopOrganizer
//
//  Created by Michael Danylchuk on 8/3/25.
//



import Foundation

struct DesktopSnapshot: Codable, Identifiable, Equatable {
    let id: UUID
    let timestamp: Date
    let files: [SnapshotFile]
    let mood: String?           // Optional: Mood or label for the snapshot
    let thumbnail: Data?        // Optional: Small PNG/JPEG for fast timeline preview

    init(files: [SnapshotFile], mood: String? = nil, thumbnail: Data? = nil) {
        self.id = UUID()
        self.timestamp = Date()
        self.files = files
        self.mood = mood
        self.thumbnail = thumbnail
    }
}
