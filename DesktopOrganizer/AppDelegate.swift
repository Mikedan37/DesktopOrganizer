//
//  AppDelegate.swift
//  DesktopOrganizer
//
//  Created by Michael Danylchuk on 8/2/25.
//

import Cocoa
import Sparkle

class AppDelegate: NSObject, NSApplicationDelegate {
    // Sparkle Updater Controller
    private let updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("DesktopOrganizer launched successfully.")
    }

    func applicationWillTerminate(_ notification: Notification) {
        print("DesktopOrganizer is terminating.")
    }

    /// Called by UI actions to show Sparkle's built-in update window.
    func triggerUpdateCheck() {
        updaterController.checkForUpdates(nil)
    }
}
