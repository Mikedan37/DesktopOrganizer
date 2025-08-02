//
//  OrganizerService.swift
//  DesktopOrganizer
//
//  Created by Michael Danylchuk on 8/1/25.
//

import Foundation
import AppKit
import Sparkle

class OrganizerService {
    static let desktopPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
    static let organizedFolder = desktopPath.appendingPathComponent("Organized")
    static let logFile = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Application Support/DesktopOrganizer/lastClean.json")

    // MARK: - Clean Desktop
    static func cleanDesktop() {
        let fm = FileManager.default

#if DEBUG
        let activeDesktopPath = URL(fileURLWithPath: "/Users/\(NSUserName())/Desktop")
#else
        let standardDesktop = fm.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
        let iCloudDesktop = fm.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs/Desktop")
        let activeDesktopPath = fm.fileExists(atPath: iCloudDesktop.path) ? iCloudDesktop : standardDesktop
#endif

        print("Using Desktop path:", activeDesktopPath.path)
        
        guard let contents = try? fm.contentsOfDirectory(at: activeDesktopPath, includingPropertiesForKeys: [.isDirectoryKey]) else {
            print("Failed to list Desktop contents at:", activeDesktopPath.path)
            return
        }

        var log: [String: String] = [:]
        try? fm.createDirectory(at: organizedFolder, withIntermediateDirectories: true)

        if contents.isEmpty {
            print("Desktop is empty at:", activeDesktopPath.path)
            return
        }

        for file in contents {
            let resourceValues = try? file.resourceValues(forKeys: [.isDirectoryKey])
            let isDirectory = resourceValues?.isDirectory ?? false

            if file.lastPathComponent == "Organized" { continue }

            if isDirectory {
                // Align folders neatly: rename with prefix "Folder - " and move to right
                let alignedName = "Folder - \(file.lastPathComponent)"
                let targetURL = activeDesktopPath.appendingPathComponent(alignedName)
                if file.lastPathComponent != alignedName {
                    do {
                        try fm.moveItem(at: file, to: targetURL)
                        log[file.path] = targetURL.path
                        print("Aligned Folder:", file.lastPathComponent, "→", targetURL.path)
                    } catch {
                        print("Align failed for \(file.lastPathComponent): \(error)")
                    }
                }
                continue
            }

            // Organize files by type
            let ext = file.pathExtension.lowercased()
            let categoryName: String
            switch ext {
            case "png", "jpg", "jpeg", "gif", "heic": categoryName = "Images"
            case "pdf", "docx", "txt", "rtf", "pages": categoryName = "Documents"
            case "mp4", "mov", "avi": categoryName = "Videos"
            case "zip", "rar", "7z": categoryName = "Archives"
            case "swift", "py", "js", "html", "css": categoryName = "Code"
            default: categoryName = "Other"
            }

            let targetFolder = organizedFolder.appendingPathComponent(categoryName)
            do {
                try fm.createDirectory(at: targetFolder, withIntermediateDirectories: true)
                let targetURL = targetFolder.appendingPathComponent(file.lastPathComponent)
                try fm.moveItem(at: file, to: targetURL)
                log[file.path] = targetURL.path
                print("Moved:", file.lastPathComponent, "→", targetURL.path)
            } catch {
                print("Move failed for \(file.lastPathComponent): \(error)")
            }
        }

        saveLog(log)
        print("Desktop clean complete. Organized into:", organizedFolder.path)
        
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Desktop Cleaned"
            alert.informativeText = "\(log.count) files and folders organized/aligned"
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
        
        // Refresh Desktop Layout after organizing
        refreshDesktopLayout()
    }

    // MARK: - Refresh Desktop Icon Layout
    /// This script arranges all folders prefixed with "Folder -" neatly on the right side of the screen.
    /// If Automation permission is missing, it shows an alert guiding the user to enable it.
    private static func refreshDesktopLayout() {
        let script = """
        try
            tell application "Finder"
                set desktopWidth to (item 3 of (bounds of window of desktop))
                set desktopHeight to (item 4 of (bounds of window of desktop))
                set iconSize to 80
                set margin to 20
                set startX to (desktopWidth - 300)
                set startY to (desktopHeight - 150)
                set yOffset to 0
                repeat with i from 1 to (count of every item of desktop)
                    set itemRef to item i of desktop
                    if name of itemRef starts with "Folder -" then
                        set position of itemRef to {startX, startY - yOffset}
                        set yOffset to yOffset + iconSize + margin
                    end if
                end repeat
            end tell
        on error errMsg number errNum
            if errNum = -1743 then
                display dialog "Permission Needed: Enable DesktopOrganizer in System Settings → Privacy & Security → Automation for Finder." buttons {"OK"} default button 1
            else
                display dialog "AppleScript Error: " & errMsg buttons {"OK"} default button 1
            end if
        end try
        """
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
        }
        if let error = error {
            print("AppleScript error: \(error)")
        }
    }

    // MARK: - Sparkle Updater
    /// Call this to manually trigger Sparkle update check from the UI.
    static func checkForUpdates() {
        if let updater = SUUpdater.shared() {
            updater.checkForUpdates(nil)
        }
    }

    // MARK: - Undo Last Action
    static func undoLastAction() {
        guard let data = try? Data(contentsOf: logFile),
              let log = try? JSONDecoder().decode([String: String].self, from: data) else {
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Undo Failed"
                alert.informativeText = "No previous organization found to undo."
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
            return
        }

        let fm = FileManager.default
        var undoCount = 0

        for (originalPath, newPath) in log {
            let originalURL = URL(fileURLWithPath: originalPath)
            let newURL = URL(fileURLWithPath: newPath)

            if fm.fileExists(atPath: newURL.path) {
                do {
                    // Handle conflicts by renaming
                    var finalURL = originalURL
                    var counter = 1
                    while fm.fileExists(atPath: finalURL.path) {
                        let newName = "\(originalURL.deletingPathExtension().lastPathComponent)-\(counter)"
                        finalURL = originalURL.deletingLastPathComponent()
                            .appendingPathComponent(newName)
                            .appendingPathExtension(originalURL.pathExtension)
                        counter += 1
                    }
                    try fm.moveItem(at: newURL, to: finalURL)
                    undoCount += 1
                } catch {
                    print("Undo failed for \(newURL.lastPathComponent): \(error)")
                }
            }
        }

        // Clear log
        try? fm.removeItem(at: logFile)

        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Undo Complete"
            alert.informativeText = "\(undoCount) items restored to original locations."
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    // MARK: - Log Helpers
    static func saveLog(_ log: [String: String]) {
        try? FileManager.default.createDirectory(at: logFile.deletingLastPathComponent(), withIntermediateDirectories: true)
        if let data = try? JSONEncoder().encode(log) {
            try? data.write(to: logFile)
        }
    }

    // MARK: - UI Helpers
    static func openPreferences() {
        print("Preferences tapped")
    }

    static func desktopFileCount() -> Int {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(at: desktopPath, includingPropertiesForKeys: nil) else { return 0 }
        return contents.filter { !$0.hasDirectoryPath && $0.lastPathComponent != "Organized" }.count
    }

    static func previewFiles(limit: Int) -> [URL] {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(at: desktopPath, includingPropertiesForKeys: nil) else { return [] }
        return contents.filter { !$0.hasDirectoryPath && $0.lastPathComponent != "Organized" }.prefix(limit).map { $0 }
    }
}
