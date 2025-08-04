
import Foundation
import AppKit

class SnapshotEngine {
    private var snapshotTimer: Timer?
    private let interval: TimeInterval = 600 // Every 10 min; set to 60 for 1 min while testing

    // Path to Desktop (current user)
    private let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!

    func start() {
        // Invalidate if already running
        snapshotTimer?.invalidate()
        // Fire immediately, then every interval
        snapshotTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.takeSnapshot()
        }
        // Take a snapshot right at launch too
        takeSnapshot()
    }

    func stop() {
        snapshotTimer?.invalidate()
        snapshotTimer = nil
    }

    func takeSnapshot() {
        do {
            // Get all files on the Desktop
            let fileURLs = try FileManager.default.contentsOfDirectory(at: desktopURL, includingPropertiesForKeys: [.nameKey, .isDirectoryKey, .contentModificationDateKey, .fileSizeKey], options: .skipsHiddenFiles)
            
            var files: [SnapshotFile] = []
            for fileURL in fileURLs {
                // Ignore folders (for now)
                let resourceValues = try? fileURL.resourceValues(forKeys: [.isDirectoryKey, .nameKey, .contentModificationDateKey, .fileSizeKey])
                if resourceValues?.isDirectory == true { continue }
                let name = resourceValues?.name ?? fileURL.lastPathComponent
                let size = resourceValues?.fileSize != nil ? UInt64(resourceValues!.fileSize!) : nil
                let lastModified = resourceValues?.contentModificationDate

                // Try to get icon data
                var iconData: Data? = nil
                if let icon = NSWorkspace.shared.icon(forFile: fileURL.path).tiffRepresentation,
                   let bitmap = NSBitmapImageRep(data: icon) {
                    iconData = bitmap.representation(using: .png, properties: [:])
                }

                // No position yet; future: read from Finder if you want
                let snapshotFile = SnapshotFile(path: fileURL.path, name: name, iconData: iconData, position: nil, size: size, lastModified: lastModified)
                files.append(snapshotFile)
            }

            let snapshot = DesktopSnapshot(files: files, mood: nil, thumbnail: nil)
            // Save it (implement SnapshotStorage later)
            try SnapshotStorage.save(snapshot)
            print("Snapshot saved at \(snapshot.timestamp) with \(files.count) files.")

        } catch {
            print("Error taking snapshot: \(error)")
        }
    }
}

