//
//  AppDelegate.swift
//  DesktopOrganizer
//
//  Created by Michael Danylchuk on 8/2/25.
//

import Cocoa
import Sparkle

class AppDelegate: NSObject, NSApplicationDelegate {
    var timelineWindow: FrostedWindow<TimelineView>?
    private var preferencesWindowController: NSWindowController?

    // Sparkle Updater Controller
    private let updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("✅ DesktopOrganizer launched successfully.")

        // Check if user has been asked about login item before
        let defaults = UserDefaults.standard
        let hasAskedForLoginItem = defaults.bool(forKey: "hasAskedForLoginItem")
        if !hasAskedForLoginItem {
            let alert = NSAlert()
            alert.messageText = "Open at Login?"
            alert.informativeText = "Would you like DesktopOrganizer to open automatically when you log in?"
            alert.addButton(withTitle: "Yes")
            alert.addButton(withTitle: "No")
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                addLaunchAgent()
            }
            defaults.set(true, forKey: "hasAskedForLoginItem")
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        print("🛑 DesktopOrganizer is terminating.")
    }

    /// Called by UI actions to show Sparkle's built-in update window.
    func triggerUpdateCheck() {
        updaterController.checkForUpdates(nil)
    }

    /// Show Preferences window with toolbar-based tabs
    @objc func showPreferences() {
        if preferencesWindowController == nil {
            let storyboard = NSStoryboard(name: "Main", bundle: nil)
            guard let windowController = storyboard.instantiateController(withIdentifier: "PreferencesWindowController") as? NSWindowController else {
                fatalError("PreferencesWindowController not found in storyboard")
            }
            preferencesWindowController = windowController
        }
        preferencesWindowController?.showWindow(nil)
        preferencesWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showTimelineWindow() {
        timelineWindow = FrostedWindow {
            TimelineView()
        }
    }

    /// Menu item handler to show the timeline window
    @objc func showTimelineMenuItemClicked(_ sender: Any?) {
        showTimelineWindow()
    }
}

// MARK: - LaunchAgent Helpers for Open at Login
func addLaunchAgent() {
    let fileManager = FileManager.default
    let bundleID = Bundle.main.bundleIdentifier ?? "com.yourcompany.DesktopOrganizer"
    let appPath = Bundle.main.bundlePath
    let plistContent = """
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>Label</key>
        <string>\(bundleID)</string>
        <key>ProgramArguments</key>
        <array>
            <string>\(appPath)/Contents/MacOS/DesktopOrganizer</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
    </dict>
    </plist>
    """
    let agentsPath = ("~/Library/LaunchAgents" as NSString).expandingTildeInPath
    let plistPath = "\(agentsPath)/\(bundleID).plist"
    do {
        if !fileManager.fileExists(atPath: agentsPath) {
            try fileManager.createDirectory(atPath: agentsPath, withIntermediateDirectories: true)
        }
        try plistContent.write(toFile: plistPath, atomically: true, encoding: .utf8)
        print("✅ LaunchAgent created at \(plistPath)")
    } catch {
        print("❌ Failed to create LaunchAgent: \(error)")
    }
}

func removeLaunchAgent() {
    let bundleID = Bundle.main.bundleIdentifier ?? "com.yourcompany.DesktopOrganizer"
    let agentsPath = ("~/Library/LaunchAgents" as NSString).expandingTildeInPath
    let plistPath = "\(agentsPath)/\(bundleID).plist"
    let fileManager = FileManager.default
    if fileManager.fileExists(atPath: plistPath) {
        do {
            try fileManager.removeItem(atPath: plistPath)
            print("✅ LaunchAgent removed at \(plistPath)")
        } catch {
            print("❌ Failed to remove LaunchAgent: \(error)")
        }
    }
}
