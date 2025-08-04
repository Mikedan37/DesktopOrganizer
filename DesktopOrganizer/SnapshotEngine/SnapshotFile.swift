//
//  SnapshotFile.swift
//  DesktopOrganizer
//
//  Created by Michael Danylchuk on 8/3/25.
//



import Foundation
import CoreGraphics

struct SnapshotFile: Codable, Identifiable, Equatable {
    let id: UUID
    let path: String          // Full file path on disk
    let name: String          // File name (for fast access/display)
    let iconData: Data?       // Optional: PNG/JPEG icon data for preview (can be nil)
    let position: CGPoint?    // Optional: Desktop icon position (if you want to support it)
    let size: UInt64?         // Optional: File size in bytes (for display)
    let lastModified: Date?   // Optional: Last modified date

    init(path: String, name: String, iconData: Data? = nil, position: CGPoint? = nil, size: UInt64? = nil, lastModified: Date? = nil) {
        self.id = UUID()
        self.path = path
        self.name = name
        self.iconData = iconData
        self.position = position
        self.size = size
        self.lastModified = lastModified
    }
}
