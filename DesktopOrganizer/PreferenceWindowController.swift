//
//  PreferenceWindowController.swift
//  DesktopOrganizer
//
//  Created by Michael Danylchuk on 8/2/25.
//

import Cocoa

class PreferencesWindowController: NSWindowController {
    override var windowNibName: NSNib.Name? { return nil }
    
    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 320),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Preferences"
        super.init(window: window)
        
        let prefsVC = PreferencesViewController()
        window.contentViewController = prefsVC
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
