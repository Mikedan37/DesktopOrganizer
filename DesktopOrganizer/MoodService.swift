//
//  MoodService.swift
//  DesktopOrganizer
//
//  Created by Michael Danylchuk on 8/3/25.
//

import Foundation

struct DesktopMood: Codable, Identifiable {
    let id: UUID
    var name: String
    var items: [DesktopItem]
    var wallpaperPath: String
}

struct DesktopItem: Codable {
    var filePath: String
    var position: CGPoint
}

import Foundation
import AppKit

class MoodService: ObservableObject {
    static let shared = MoodService()
    private let moodsFileURL: URL

    @Published var moods: [DesktopMood] = []

    private init() {
        // Save moods in Application Support
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("DesktopOrganizer")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        moodsFileURL = dir.appendingPathComponent("moods.json")
        loadMoods()
        // Add preset moods if none exist yet
        if moods.isEmpty {
            let presets: [DesktopMood] = [
                DesktopMood(id: UUID(), name: "Zen Mode", items: [], wallpaperPath: ""),
                DesktopMood(id: UUID(), name: "Meeting Mode", items: [], wallpaperPath: ""),
                DesktopMood(id: UUID(), name: "Screenshare Mode", items: [], wallpaperPath: "")
            ]
            moods.append(contentsOf: presets)
            saveMoods()
        }
    }

    // MARK: - Mood Persistence

    func saveMoods() {
        do {
            let data = try JSONEncoder().encode(moods)
            try data.write(to: moodsFileURL)
        } catch {
            print("Failed to save moods: \(error)")
        }
    }

    func loadMoods() {
        guard FileManager.default.fileExists(atPath: moodsFileURL.path) else { return }
        do {
            let data = try Data(contentsOf: moodsFileURL)
            moods = try JSONDecoder().decode([DesktopMood].self, from: data)
        } catch {
            print("Failed to load moods: \(error)")
        }
    }

    // MARK: - Add/Remove Moods

    func addMood(_ mood: DesktopMood) {
        moods.append(mood)
        saveMoods()
    }

    func removeMood(_ mood: DesktopMood) {
        moods.removeAll { $0.id == mood.id }
        saveMoods()
    }

    // MARK: - Desktop and Wallpaper Utilities

    /// Fetches all current desktop items and their positions using AppleScript.
    static func fetchCurrentDesktopItems() -> [DesktopItem] {
        let appleScript = """
        set output to ""
        tell application "Finder"
            set desktopItems to every item of desktop
            repeat with i from 1 to count of desktopItems
                set thisItem to item i of desktopItems
                set p to position of thisItem
                set filePath to POSIX path of (thisItem as alias)
                set output to output & filePath & "|" & (item 1 of p as integer) & "," & (item 2 of p as integer) & "\n"
            end repeat
        end tell
        return output
        """
        var items: [DesktopItem] = []
        if let script = NSAppleScript(source: appleScript) {
            var error: NSDictionary?
            if let result = script.executeAndReturnError(&error).stringValue {
                let lines = result.split(separator: "\n")
                for line in lines {
                    let parts = line.split(separator: "|", maxSplits: 1)
                    if parts.count == 2 {
                        let filePath = String(parts[0])
                        let posParts = parts[1].split(separator: ",")
                        if posParts.count == 2,
                            let x = Double(posParts[0]), let y = Double(posParts[1]) {
                            items.append(DesktopItem(filePath: filePath, position: CGPoint(x: x, y: y)))
                        }
                    }
                }
            } else {
                print("AppleScript error in fetchCurrentDesktopItems: \(error ?? [:])")
            }
        }
        return items
    }

    /// Sets the positions of desktop items using AppleScript.
    static func setDesktopItemsPositions(_ items: [DesktopItem]) {
        let setPosScript = items.map { item in
            let escapedPath = item.filePath.replacingOccurrences(of: "\"", with: "\\\"")
            return """
            try
                tell application "Finder"
                    set theItem to (POSIX file "\(escapedPath)") as alias
                    set position of theItem to {\(Int(item.position.x)), \(Int(item.position.y))}
                end tell
            end try
            """
        }.joined(separator: "\n")
        if let script = NSAppleScript(source: setPosScript) {
            var error: NSDictionary?
            script.executeAndReturnError(&error)
            if let error = error {
                print("AppleScript error in setDesktopItemsPositions: \(error)")
            }
        }
    }

    /// Gets the current wallpaper file path for the main screen.
    static func getCurrentWallpaperPath() -> String? {
        if let screen = NSScreen.main {
            if let url = NSWorkspace.shared.desktopImageURL(for: screen) {
                return url.path
            }
        }
        return nil
    }

    /// Sets the desktop wallpaper for the main screen.
    static func setWallpaper(path: String) {
        guard let screen = NSScreen.main else { return }
        let url = URL(fileURLWithPath: path)
        do {
            try NSWorkspace.shared.setDesktopImageURL(url, for: screen, options: [:])
        } catch {
            print("Failed to set wallpaper: \(error)")
        }
    }

    // MARK: - Mood Creation and Restoration

    /// Saves the current desktop state as a new mood.
    func saveCurrentMood(named name: String) {
        let items = MoodService.fetchCurrentDesktopItems()
        let wallpaperPath = MoodService.getCurrentWallpaperPath() ?? ""
        let mood = DesktopMood(id: UUID(), name: name, items: items, wallpaperPath: wallpaperPath)
        addMood(mood)
    }

    /// Restores the desktop to the given mood (files, positions, wallpaper).
    func restoreMood(_ mood: DesktopMood) {
        let fileManager = FileManager.default
        let desktopPath = fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Desktop").path
        let currentItems = MoodService.fetchCurrentDesktopItems()
        let moodPaths = Set(mood.items.map { $0.filePath })
        let currentPaths = Set(currentItems.map { $0.filePath })

        // Hide files not in mood (move to hidden folder)
        let hiddenDir = (desktopPath as NSString).appendingPathComponent(".DesktopOrganizerHidden")
        try? fileManager.createDirectory(atPath: hiddenDir, withIntermediateDirectories: true)
        for path in currentPaths.subtracting(moodPaths) {
            let fileName = (path as NSString).lastPathComponent
            let destPath = (hiddenDir as NSString).appendingPathComponent(fileName)
            try? fileManager.moveItem(atPath: path, toPath: destPath)
        }

        // Move files in mood to Desktop if not present
        for item in mood.items {
            let fileName = (item.filePath as NSString).lastPathComponent
            let destPath = (desktopPath as NSString).appendingPathComponent(fileName)
            if !fileManager.fileExists(atPath: destPath) {
                do {
                    try fileManager.copyItem(atPath: item.filePath, toPath: destPath)
                } catch {
                    // Ignore if already exists or cannot copy
                }
            }
        }

        // Set positions for mood items
        MoodService.setDesktopItemsPositions(mood.items)

        // Set wallpaper
        MoodService.setWallpaper(path: mood.wallpaperPath)
    }

    // TODO: Handle special logic for preset moods (e.g. Zen Mode = hide all files, etc.)
}
