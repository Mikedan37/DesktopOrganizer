//
//  AppDelegate.swift
//  DesktopOrganizer
//
//  Created by Michael Danylchuk on 8/3/25.
//


import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var snapshotEngine: SnapshotEngine?

    func applicationDidFinishLaunching(_ notification: Notification) {
        snapshotEngine = SnapshotEngine()
        snapshotEngine?.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        snapshotEngine?.stop()
    }
}
