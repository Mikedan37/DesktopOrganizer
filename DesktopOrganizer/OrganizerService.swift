//
//  OrganizerService.swift
//  DesktopOrganizer
//
//  Created by Michael Danylchuk on 8/1/25.
//

import Foundation
import AppKit
import Sparkle
import Vision

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

            // Skip Organized folder and hidden/system files
            if file.lastPathComponent == "Organized" || file.lastPathComponent.hasPrefix(".") {
                continue
            }

            if isDirectory {
                // Leave folders in place (we can organize later)
                continue
            }

            // Organize files by type
            let ext = file.pathExtension.lowercased()
            let categoryName: String
            switch ext {
            case "png", "jpg", "jpeg", "gif", "heic":
                categoryName = "Images"
            case "pdf", "doc", "docx", "txt", "rtf", "pages", "md":
                categoryName = "Documents"
            case "mp4", "mov", "avi", "mkv":
                categoryName = "Videos"
            case "zip", "rar", "7z", "tar", "gz":
                categoryName = "Archives"
            case "swift", "py", "js", "html", "css", "java", "cpp":
                categoryName = "Code"
            default:
                categoryName = "Miscellaneous"
            }

            let targetFolder = organizedFolder.appendingPathComponent(categoryName)
            try? fm.createDirectory(at: targetFolder, withIntermediateDirectories: true)

            // Handle duplicate name conflicts by appending counter
            var targetURL = targetFolder.appendingPathComponent(file.lastPathComponent)
            var counter = 1
            while fm.fileExists(atPath: targetURL.path) {
                let baseName = file.deletingPathExtension().lastPathComponent
                let newName = "\(baseName)-\(counter).\(ext)"
                targetURL = targetFolder.appendingPathComponent(newName)
                counter += 1
            }

            do {
                try fm.moveItem(at: file, to: targetURL)
                log[file.path] = targetURL.path
                print("Moved:", file.lastPathComponent, "→", targetURL.path)
            } catch {
                print("Move failed for \(file.lastPathComponent): \(error)")
            }
        }


        saveLog(log)
        print("Desktop clean complete. Organized into:", organizedFolder.path)
        saveStats(log)
        
        DispatchQueue.global(qos: .background).async {
            renameScreenshotsWithAI()
        }
        
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Desktop Cleaned"
            alert.informativeText = "\(log.count) files and folders organized/aligned"
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
        
        let remainingItems = (try? fm.contentsOfDirectory(at: activeDesktopPath, includingPropertiesForKeys: [.isDirectoryKey])) ?? []
        let folders = remainingItems.filter { $0.hasDirectoryPath && !$0.lastPathComponent.contains("Organized") }
            .map { $0.lastPathComponent }
        let files = remainingItems.filter { !$0.hasDirectoryPath && !$0.lastPathComponent.contains("Organized") }
            .map { $0.lastPathComponent }

        applyCustomLayout(folders: folders, files: files)
    }

    // MARK: - Custom Desktop Layout
    private static func applyCustomLayout(folders: [String], files: [String]) {
        let folderStartX = 1400
        let folderStartY = 800
        let fileStartX = 100
        let fileStartY = 800
        
        let itemWidth = 100
        let itemHeight = 100
        let margin = 20
        
        var commands = "tell application \"Finder\"\n"
        commands += "tell desktop\n"

        for (index, folder) in folders.enumerated() {
            let y = folderStartY - (index * (itemHeight + margin))
            commands += "set position of item \"\(folder)\" to {\(folderStartX), \(y)}\n"
        }

        for (index, file) in files.enumerated() {
            let col = index % 6
            let row = index / 6
            let x = fileStartX + (col * (itemWidth + margin))
            let y = fileStartY - (row * (itemHeight + margin))
            commands += "set position of item \"\(file)\" to {\(x), \(y)}\n"
        }

        commands += "end tell\n"
        commands += "end tell\n"

        runAppleScript(commands)
    }

    private static func runAppleScript(_ script: String) {
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
            if let error = error {
                print("AppleScript error: \(error)")
                if let num = error[NSAppleScript.errorNumber] as? Int, num == -1743 {
                    showPermissionAlertIfNeeded()
                }
            }
        }
    }

    private static func showPermissionAlertIfNeeded() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Permission Needed"
            alert.informativeText = "Enable DesktopOrganizer in System Settings → Privacy & Security → Automation for Finder."
            alert.addButton(withTitle: "OK")
            alert.runModal()
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
    
    static func saveStats(_ log: [String: String]) {
        let fm = FileManager.default
        var categoryCounts: [String: Int] = [:]
        var totalSize: Int64 = 0

        for (_, newPath) in log {
            let category = URL(fileURLWithPath: newPath).deletingLastPathComponent().lastPathComponent
            categoryCounts[category, default: 0] += 1
            if let attrs = try? fm.attributesOfItem(atPath: newPath),
               let size = attrs[.size] as? Int64 {
                totalSize += size
            }
        }

        // Gather system info
        let processInfo = ProcessInfo.processInfo
        let physicalMemory = ByteCountFormatter.string(fromByteCount: Int64(processInfo.physicalMemory), countStyle: .memory)
        let uptime = String(format: "%.2f hours", processInfo.systemUptime / 3600)

        var freeDisk: Int64 = 0
        if let attrs = try? fm.attributesOfFileSystem(forPath: desktopPath.path),
           let freeSize = attrs[.systemFreeSize] as? Int64 {
            freeDisk = freeSize
        }
        let freeDiskFormatted = ByteCountFormatter.string(fromByteCount: freeDisk, countStyle: .file)

        // Calculate before and after
        let allDesktopItems = (try? fm.contentsOfDirectory(at: desktopPath, includingPropertiesForKeys: nil)) ?? []
        let beforeCount = allDesktopItems.count
        let desktopContents = (try? fm.contentsOfDirectory(at: desktopPath, includingPropertiesForKeys: [.fileSizeKey])) ?? []
        let desktopFiles = desktopContents.filter { !$0.hasDirectoryPath && !$0.lastPathComponent.hasPrefix(".") && $0.lastPathComponent != "DesktopReport.txt" && !$0.lastPathComponent.contains("Organized") }
        let desktopFolders = desktopContents.filter { $0.hasDirectoryPath && !$0.lastPathComponent.contains("Organized") }
        let afterCount = desktopFiles.count + desktopFolders.count
        let foldersSkipped = desktopFolders.count

        // Sizes and largest files
        var remainingSize: Int64 = 0
        var fileSizePairs: [(String, Int64)] = []
        for file in desktopFiles {
            if let attrs = try? fm.attributesOfItem(atPath: file.path),
               let size = attrs[.size] as? Int64 {
                remainingSize += size
                fileSizePairs.append((file.lastPathComponent, size))
            }
        }
        let filteredPairs = fileSizePairs.filter { !$0.0.contains("DesktopReport.txt") && !$0.0.contains("DesktopScreenshot.png") }
        let largestFiles = filteredPairs.sorted(by: { $0.1 > $1.1 }).prefix(5)

        // Metrics
        let clutterScore = min(100, (desktopFiles.count * 2) + Int(remainingSize / (1024 * 1024 * 10)))
        let spaceFreed = ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
        let reductionPercent = beforeCount > 0 ? Int(((Double(beforeCount - afterCount) / Double(beforeCount)) * 100)) : 0

        // Achievements
        var badge = ""
        if clutterScore < 20 {
            badge = "🏆 Clutter Crusher!"
        } else if clutterScore < 50 {
            badge = "✅ Desktop Tamer"
        } else {
            badge = "Keep Going!"
        }

        // History tracking
        let historyPath = logFile.deletingLastPathComponent().appendingPathComponent("history.json")
        var history: [[String: Any]] = []
        if let data = try? Data(contentsOf: historyPath),
           let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            history = json
        }
        let currentEntry: [String: Any] = [
            "date": Date().description,
            "clutterScore": clutterScore
        ]
        history.append(currentEntry)
        if let jsonData = try? JSONSerialization.data(withJSONObject: history, options: .prettyPrinted) {
            try? jsonData.write(to: historyPath)
        }

        // Build report
        var report = """
====================================
      🖥  Desktop Clean Report 🧹
====================================

Date: \(Date())
Impact:
✔ Reduced clutter by \(reductionPercent)%
✔ Freed up \(spaceFreed)
✔ Moved \(log.count) files to Organized

Clutter Score: \(clutterScore)/100
"""
        let filledBars = Int(Double(clutterScore) / 5.0)
        let emptyBars = 20 - filledBars
        let progressBar = String(repeating: "█", count: filledBars) + String(repeating: "░", count: emptyBars)
        report += "\n[\(progressBar)] (\(clutterScore)% clean)\n\n"

        // Categories with ASCII bars
        report += "---------- File Categories ----------\n"
        if categoryCounts.isEmpty {
            report += "No file categories because no files were organized.\n"
        } else {
            let maxCount = categoryCounts.values.max() ?? 1
            for (category, count) in categoryCounts.sorted(by: { $0.key < $1.key }) {
                let barLength = Int((Double(count) / Double(maxCount)) * 20)
                let bar = String(repeating: "█", count: barLength)
                report += String(format: "%-12@ | %@ (%d)\n", category as NSString, bar, count)
            }
        }
        report += "\n"

        // Risk Alerts
        report += "---------- Risk Alerts ----------\n"
        if let cpuUsage = getCPULoad(), cpuUsage > 80 {
            report += "⚠️ CPU load above 80%\n"
        }
        if freeDisk < (10 * 1024 * 1024 * 1024) {
            report += "⚠️ Free disk space below 10 GB\n"
        }
        if foldersSkipped > 20 {
            report += "⚠️ Large number of unorganized folders\n"
        }
        report += "-----------------------------------\n\n"

        // Gamification
        report += "---------- Achievements ----------\n"
        report += "\(badge)\n"
        report += "-----------------------------------\n\n"

        // History
        report += "Previous Runs:\n"
        for entry in history.suffix(3) {
            if let date = entry["date"] as? String, let score = entry["clutterScore"] as? Int {
                report += "\(date.prefix(10)): \(score)/100\n"
            }
        }
        report += "\n"

        // Largest files
        report += "---------- Largest Files (Top 5) ----------\n"
        if largestFiles.isEmpty {
            report += "No remaining large files on Desktop.\n"
        } else {
            for (name, size) in largestFiles {
                let sizeFormatted = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
                report += "• \(name) - \(sizeFormatted)\n"
            }
        }
        report += "\n"

        // Unorganized folders
        if !desktopFolders.isEmpty {
            report += "---------- Unorganized Folders ----------\n"
            for folder in desktopFolders.map({ $0.lastPathComponent }) {
                report += "• \(folder)\n"
            }
            report += "\n"
        }

        // Suggestions
        report += "---------- Suggestions ----------\n"
        report += foldersSkipped > 0 ? "💡 Enable folder organization for a cleaner look.\n" : "🔥 Desktop fully clean!\n"
        report += "-----------------------------------\n\n"

        // System Info
        report += "---------- System Info ----------\n"
        report += "Physical Memory: \(physicalMemory)\n"
        report += "System Uptime: \(uptime)\n"
        report += "Free Disk Space: \(freeDiskFormatted)\n"
        report += "macOS Version: \(processInfo.operatingSystemVersionString)\n"
        report += "CPU Count: \(processInfo.processorCount)\n"
        if let cpuUsage = getCPULoad() {
            report += "Current CPU Load: \(String(format: "%.2f", cpuUsage))%\n"
        }
        if let batteryInfo = getBatteryInfo() {
            report += "Battery Health: \(batteryInfo.health)\n"
            report += "Current Charge: \(batteryInfo.charge)%\n"
        }
        report += "====================================\n"

        // Write report
        let statsFile = desktopPath.appendingPathComponent("DesktopReport.txt")
        try? report.write(to: statsFile, atomically: true, encoding: .utf8)
        // (Optional) Call renameItemsWithAISuggestions() here to auto-suggest better names using ChatGPT.
        /// Call renameItemsWithAISuggestions() after cleanDesktop() to auto-suggest better names using ChatGPT.
    }

    // MARK: - OCR-Only Screenshot Renaming
    static func renameScreenshotsWithAI() {
        let fm = FileManager.default
        let imagesFolder = organizedFolder.appendingPathComponent("Images")
        guard let files = try? fm.contentsOfDirectory(at: imagesFolder, includingPropertiesForKeys: nil) else { return }

        let imageExtensions = ["png", "jpg", "jpeg", "heic"]
        let processorCount = max(ProcessInfo.processInfo.processorCount, 2)
        let maxConcurrent = min(10, max(2, processorCount / 2))
        let renameQueue = DispatchQueue(label: "com.desktoporganizer.rename", qos: .userInitiated, attributes: .concurrent)
        let semaphore = DispatchSemaphore(value: maxConcurrent)
        let dispatchGroup = DispatchGroup()
        let processedCounterQueue = DispatchQueue(label: "com.desktoporganizer.counter")
        var processedCount = 0
        let filesToRename = files.filter {
            !$0.lastPathComponent.hasPrefix(".") &&
            imageExtensions.contains($0.pathExtension.lowercased()) &&
            (
                $0.lastPathComponent.lowercased().contains("screenshot") ||
                $0.lastPathComponent.lowercased().contains("screen shot") ||
                $0.lastPathComponent.lowercased().hasPrefix("img_")
            )
        }
        let totalCount = filesToRename.count

        for file in files where !file.lastPathComponent.hasPrefix(".") {
            let ext = file.pathExtension.lowercased()
            guard imageExtensions.contains(ext) else { continue }
            let name = file.lastPathComponent.lowercased()

            // Skip already renamed descriptive files (except timestamped ones)
            if name.contains("-screenshot") && !name.contains("screenshot-202") {
                processedCounterQueue.sync {
                    processedCount += 1
                    if processedCount % 10 == 0 {
                        let progress = Int((Double(processedCount) / Double(max(totalCount, 1))) * 100)
                        print("Progress: \(processedCount)/\(totalCount) (\(progress)%)")
                    }
                }
                continue
            }

            // Handle previous broken AI names (placeholders)
            if name.contains("please-provide") || name.contains("without-context") {
                let fallbackName = defaultScreenshotName()
                let newURL = file.deletingLastPathComponent().appendingPathComponent(fallbackName)
                do {
                    try? safeMoveItem(file, to: newURL)
                    print("✅ Fallback rename applied: \(file.lastPathComponent) → \(fallbackName)")
                } catch {
                    print("❌ Failed fallback rename for \(file.lastPathComponent): \(error.localizedDescription)")
                }
                processedCounterQueue.sync {
                    processedCount += 1
                    if processedCount % 10 == 0 {
                        let progress = Int((Double(processedCount) / Double(max(totalCount, 1))) * 100)
                        print("Progress: \(processedCount)/\(totalCount) (\(progress)%)")
                    }
                }
                continue
            }

            // Skip if not a screenshot
            if !(name.contains("screenshot") || name.contains("screen shot") || name.hasPrefix("img_")) {
                continue
            }

            // Validate image size before entering OCR queue
            guard let img = NSImage(contentsOf: file) else {
                print("❌ Skipping OCR: Unable to load image \(file.lastPathComponent)")
                processedCounterQueue.sync {
                    processedCount += 1
                    if processedCount % 10 == 0 {
                        let progress = Int((Double(processedCount) / Double(max(totalCount, 1))) * 100)
                        print("Progress: \(processedCount)/\(totalCount) (\(progress)%)")
                    }
                }
                continue
            }
            if img.size.width < 30 || img.size.height < 30 {
                print("⚠️ Skipping OCR for \(file.lastPathComponent): Image too small (\(Int(img.size.width))x\(Int(img.size.height)))")
                let fallbackName = defaultScreenshotName()
                let newURL = file.deletingLastPathComponent().appendingPathComponent(fallbackName)
                if !fm.fileExists(atPath: newURL.path) {
                    do {
                        try? safeMoveItem(file, to: newURL)
                        print("✅ Auto-fallback rename: \(file.lastPathComponent) → \(fallbackName)")
                    } catch {
                        print("❌ Failed fallback rename for \(file.lastPathComponent): \(error.localizedDescription)")
                    }
                }
                processedCounterQueue.sync {
                    processedCount += 1
                    if processedCount % 10 == 0 {
                        let progress = Int((Double(processedCount) / Double(max(totalCount, 1))) * 100)
                        print("Progress: \(processedCount)/\(totalCount) (\(progress)%)")
                    }
                }
                continue
            }

            semaphore.wait()
            dispatchGroup.enter()
            renameQueue.async {
                var ocrCompleted = false
                // --- Begin single-leave mechanism ---
                var didLeave = false
                let leaveGroupSafely: () -> Void = {
                    processedCounterQueue.sync {
                        if !didLeave {
                            didLeave = true
                            processedCount += 1
                            if processedCount % 10 == 0 {
                                let progress = Int((Double(processedCount) / Double(max(totalCount, 1))) * 100)
                                print("Progress: \(processedCount)/\(totalCount) (\(progress)%)")
                            }
                            semaphore.signal()
                            dispatchGroup.leave()
                        }
                    }
                }
                // --- End single-leave mechanism ---
                let ocrTimeout: TimeInterval = 5.0
                let timeoutWorkItem = DispatchWorkItem {
                    if !ocrCompleted {
                        print("⏳ OCR timeout for \(file.lastPathComponent). Skipping to fallback.")
                        let fallbackName = defaultScreenshotName()
                        let newURL = file.deletingLastPathComponent().appendingPathComponent(fallbackName)
                        DispatchQueue.main.async {
                            do {
                                try? safeMoveItem(file, to: newURL)
                                print("✅ Fallback rename (timeout): \(file.lastPathComponent) → \(fallbackName)")
                            } catch {
                                print("❌ Failed fallback rename for \(file.lastPathComponent): \(error.localizedDescription)")
                            }
                            leaveGroupSafely()
                        }
                    }
                }
                DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + ocrTimeout, execute: timeoutWorkItem)

                extractTextFromImage(at: file) { extractedText in
                    if ocrCompleted { return }
                    ocrCompleted = true
                    timeoutWorkItem.cancel()
                    var finalName: String
                    if let text = extractedText, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        // Check for gibberish: less than 3 alpha words or too short
                        let words = text
                            .lowercased()
                            .components(separatedBy: CharacterSet.alphanumerics.inverted)
                            .filter { $0.count > 2 && !$0.contains("am") && !$0.contains("pm") && $0 != "screenshot" && $0 != "window" }
                        let keywords = Array(words.prefix(3))
                        let joined = keywords.joined(separator: "-")
                        if !joined.isEmpty && joined.range(of: "[a-z]", options: .regularExpression) != nil {
                            let truncated = String(joined.prefix(60))
                            finalName = truncated + "-screenshot.png"
                        } else {
                            finalName = defaultScreenshotName()
                        }
                    } else {
                        finalName = defaultScreenshotName()
                    }

                    finalName = sanitizeFileName(finalName)
                    let newURL = file.deletingLastPathComponent().appendingPathComponent(finalName)

                    if !fm.fileExists(atPath: newURL.path) {
                        DispatchQueue.main.async {
                            do {
                                try? safeMoveItem(file, to: newURL)
                                print("✅ OCR Renamed \(file.lastPathComponent) → \(finalName)")
                            } catch {
                                print("❌ Failed to rename \(file.lastPathComponent): \(error.localizedDescription)")
                            }
                            leaveGroupSafely()
                        }
                    } else {
                        DispatchQueue.main.async {
                            leaveGroupSafely()
                        }
                    }
                }
            }
        }
        dispatchGroup.notify(queue: .main) {
            print("OCR screenshot renaming complete. \(processedCount) images processed.")
        }
    }

    // Generate default fallback name
    private static func defaultScreenshotName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return "screenshot-\(formatter.string(from: Date())).png"
    }

    // Sanitize filename: remove illegal chars, ensure .png extension, max 60 chars
    private static func sanitizeFileName(_ name: String) -> String {
        var base = name
        // Remove extension if present
        if let dot = base.lastIndex(of: ".") {
            base = String(base[..<dot])
        }
        // Remove illegal chars
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789-_")
        let cleaned = base.lowercased()
            .map { allowed.contains($0.unicodeScalars.first!) ? $0 : "-" }
            .reduce("") { $0 + String($1) }
        // Replace multiple dashes
        let dashReduced = cleaned.replacingOccurrences(of: "-{2,}", with: "-", options: .regularExpression)
        // Truncate to max 60 chars (before extension)
        let trimmed = String(dashReduced.trimmingCharacters(in: CharacterSet(charactersIn: "-_")).prefix(60))
        // Add .png by default
        return trimmed + ".png"
    }

    // OCR Helper using Vision with timeout and error handling
    private static func extractTextFromImage(at url: URL, completion: @escaping (String?) -> Void) {
        let fm = FileManager.default
        guard fm.fileExists(atPath: url.path) else {
            print("OCR skipped: File not found at \(url.path)")
            DispatchQueue.main.async { completion(nil) }
            return
        }

        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("OCR error for \(url.lastPathComponent): \(error.localizedDescription)")
                DispatchQueue.main.async { completion(nil) }
                return
            }
            let observations = request.results as? [VNRecognizedTextObservation] ?? []
            let recognizedStrings = observations.compactMap { $0.topCandidates(1).first?.string }
            let result = recognizedStrings.joined(separator: " ")
            print("OCR result for \(url.lastPathComponent): \(result.isEmpty ? "No text found" : result.prefix(80))")
            DispatchQueue.main.async {
                completion(result.isEmpty ? nil : result)
            }
        }

        request.recognitionLanguages = ["en-US"]
        request.usesLanguageCorrection = true

        let ocrQueue = DispatchQueue(label: "com.desktoporganizer.ocr", qos: .userInitiated)
        ocrQueue.async {
            do {
                let handler = VNImageRequestHandler(url: url, options: [:])
                try handler.perform([request])
                print("OCR completed for: \(url.lastPathComponent)")
            } catch {
                print("OCR failed for \(url.lastPathComponent): \(error.localizedDescription)")
                DispatchQueue.main.async { completion(nil) }
            }
        }
    }

    // Move file, handling conflicts by appending -N suffix before extension
    private static func safeMoveItem(_ src: URL, to dst: URL) throws {
        let fm = FileManager.default
        var target = dst
        var counter = 1
        let base = dst.deletingPathExtension().lastPathComponent
        let ext = dst.pathExtension
        while fm.fileExists(atPath: target.path) {
            let newName = "\(base)-\(counter).\(ext)"
            target = dst.deletingLastPathComponent().appendingPathComponent(newName)
            counter += 1
        }
        try fm.moveItem(at: src, to: target)
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
    // MARK: - System Info Helpers
    private static func getCPULoad() -> Double? {
        var load = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &load) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        if result == KERN_SUCCESS {
            let totalTicks = Double(load.cpu_ticks.0 + load.cpu_ticks.1 + load.cpu_ticks.2 + load.cpu_ticks.3)
            let idleTicks = Double(load.cpu_ticks.2)
            return (1.0 - (idleTicks / totalTicks)) * 100.0
        }
        return nil
    }

    private static func getBatteryInfo() -> (health: String, charge: Int)? {
        let task = Process()
        task.launchPath = "/usr/bin/pmset"
        task.arguments = ["-g", "batt"]

        let pipe = Pipe()
        task.standardOutput = pipe
        try? task.run()
        task.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            let lines = output.split(separator: "\n")
            guard lines.count > 1 else { return nil }
            let infoLine = lines[1]
            let components = infoLine.split(separator: ";")
            if components.count >= 3 {
                let chargeStr = components[0].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "%", with: "")
                let health = components[2].trimmingCharacters(in: .whitespaces)
                if let charge = Int(chargeStr) {
                    return (health: health, charge: charge)
                }
            }
        }
        return nil
    }
}
