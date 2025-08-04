//
//  PreferenceViewController.swift
//  DesktopOrganizer
//
//  Created by Michael Danylchuk on 8/2/25.
//

import Cocoa

extension NSToolbarItem.Identifier {
    static let general = NSToolbarItem.Identifier("General")
    static let ai = NSToolbarItem.Identifier("AI")
    static let advanced = NSToolbarItem.Identifier("Advanced")
}

class PreferencesViewController: NSViewController, NSToolbarDelegate {
    
    private var currentContentView: NSView?

    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 300))
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let toolbar = NSToolbar(identifier: "PreferencesToolbar")
        toolbar.allowsUserCustomization = false
        toolbar.autosavesConfiguration = false
        toolbar.displayMode = .iconAndLabel
        toolbar.delegate = self
        
        view.window?.toolbar = toolbar
        view.window?.title = "General"
        
        // Select the default pane
        switchToPane(identifier: .general)
        
        // Set the default selected item in the toolbar
        toolbar.selectedItemIdentifier = .general
    }
    
    private func switchToPane(identifier: NSToolbarItem.Identifier) {
        currentContentView?.removeFromSuperview()
        
        let newView: NSView
        var title: String
        
        switch identifier {
        case .general:
            newView = generalTabContent()
            title = "General"
        case .ai:
            newView = aiTabContent()
            title = "AI"
        case .advanced:
            newView = advancedTabContent()
            title = "Advanced"
        default:
            return
        }
        
        newView.frame = view.bounds
        newView.autoresizingMask = [.width, .height]
        view.addSubview(newView)
        currentContentView = newView
        
        view.window?.title = title
    }
    
    // MARK: - NSToolbarDelegate
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.general, .ai, .advanced]
    }
    
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.general, .ai, .advanced]
    }
    
    func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.general, .ai, .advanced]
    }
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        let item = NSToolbarItem(itemIdentifier: itemIdentifier)
        switch itemIdentifier {
        case .general:
            item.label = "General"
            if let sfImage = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "General") {
                item.image = sfImage
            }
        case .ai:
            item.label = "AI"
            if let sfImage = NSImage(systemSymbolName: "brain.head.profile", accessibilityDescription: "AI") {
                item.image = sfImage
            }
        case .advanced:
            item.label = "Advanced"
            if let sfImage = NSImage(systemSymbolName: "wrench.and.screwdriver", accessibilityDescription: "Advanced") {
                item.image = sfImage
            }
        default:
            return nil
        }
        item.target = self
        item.action = #selector(toolbarItemClicked(_:))
        return item
    }
    
    @objc private func toolbarItemClicked(_ sender: NSToolbarItem) {
        switchToPane(identifier: sender.itemIdentifier)
    }
    
    private func generalTabContent() -> NSView {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 250))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        // Automation group box
        let automationBox = NSBox()
        automationBox.title = "Automation"
        automationBox.boxType = .primary
        automationBox.frame = NSRect(x: 20, y: 120, width: 360, height: 110)

        let autoCleanCheckbox = NSButton(checkboxWithTitle: "Auto-clean Desktop at login", target: self, action: #selector(toggleAutoClean))
        autoCleanCheckbox.state = UserDefaults.standard.bool(forKey: "autoClean") ? .on : .off
        autoCleanCheckbox.setButtonType(.switch)
        autoCleanCheckbox.frame = NSRect(x: 20, y: 60, width: 300, height: 22)
        // Consistent spacing under section header
        automationBox.addSubview(autoCleanCheckbox)

        let organizeFrequencyLabel = NSTextField(labelWithString: "Organize Frequency:")
        organizeFrequencyLabel.font = NSFont.boldSystemFont(ofSize: 13)
        organizeFrequencyLabel.frame = NSRect(x: 20, y: 30, width: 150, height: 20)
        automationBox.addSubview(organizeFrequencyLabel)

        let frequencyPopup = NSPopUpButton(frame: NSRect(x: 180, y: 25, width: 150, height: 26))
        frequencyPopup.addItems(withTitles: ["Manual", "Every Hour", "Daily", "Weekly"])
        frequencyPopup.selectItem(withTitle: UserDefaults.standard.string(forKey: "organizeFrequency") ?? "Manual")
        frequencyPopup.action = #selector(changeFrequency)
        frequencyPopup.target = self
        frequencyPopup.bezelStyle = .rounded
        automationBox.addSubview(frequencyPopup)

        view.addSubview(automationBox)

        // Organization Settings group box (example for further preferences)
        let orgBox = NSBox()
        orgBox.title = "Organization Settings"
        orgBox.boxType = .primary
        orgBox.frame = NSRect(x: 20, y: 20, width: 360, height: 90)
        // (Add more controls here in the future, currently left empty for demonstration)
        view.addSubview(orgBox)

        return view
    }
    
    private func aiTabContent() -> NSView {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 250))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        let aiBox = NSBox()
        aiBox.title = "AI Settings"
        aiBox.boxType = .primary
        aiBox.frame = NSRect(x: 20, y: 120, width: 360, height: 110)

        let aiToggle = NSButton(checkboxWithTitle: "Enable AI OCR for screenshots", target: self, action: #selector(toggleAI))
        aiToggle.state = UserDefaults.standard.bool(forKey: "enableAI") ? .on : .off
        aiToggle.setButtonType(.switch)
        aiToggle.frame = NSRect(x: 20, y: 60, width: 300, height: 22)
        aiBox.addSubview(aiToggle)

        let accuracyLabel = NSTextField(labelWithString: "OCR Accuracy Mode:")
        accuracyLabel.font = NSFont.boldSystemFont(ofSize: 13)
        accuracyLabel.frame = NSRect(x: 20, y: 30, width: 150, height: 20)
        aiBox.addSubview(accuracyLabel)

        let accuracyPopup = NSPopUpButton(frame: NSRect(x: 180, y: 25, width: 150, height: 26))
        accuracyPopup.addItems(withTitles: ["Fast", "Balanced", "High Accuracy"])
        accuracyPopup.selectItem(withTitle: UserDefaults.standard.string(forKey: "ocrAccuracy") ?? "Balanced")
        accuracyPopup.action = #selector(changeAccuracy)
        accuracyPopup.target = self
        accuracyPopup.bezelStyle = .rounded
        aiBox.addSubview(accuracyPopup)

        view.addSubview(aiBox)
        return view
    }
    
    private func advancedTabContent() -> NSView {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 250))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        let advBox = NSBox()
        advBox.title = "Updates & Notifications"
        advBox.boxType = .primary
        advBox.frame = NSRect(x: 20, y: 120, width: 360, height: 110)

        let logsCheckbox = NSButton(checkboxWithTitle: "Enable verbose logging", target: self, action: #selector(toggleLogs))
        logsCheckbox.state = UserDefaults.standard.bool(forKey: "enableLogs") ? .on : .off
        logsCheckbox.setButtonType(.switch)
        logsCheckbox.frame = NSRect(x: 20, y: 60, width: 300, height: 22)
        advBox.addSubview(logsCheckbox)

        let resetButton = NSButton(title: "Reset All Preferences", target: self, action: #selector(resetPreferences))
        resetButton.frame = NSRect(x: 20, y: 25, width: 200, height: 32)
        advBox.addSubview(resetButton)

        view.addSubview(advBox)
        return view
    }
    
    @objc private func toggleAutoClean(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .on, forKey: "autoClean")
    }

    @objc private func toggleAI(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .on, forKey: "enableAI")
    }

    @objc private func toggleLogs(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .on, forKey: "enableLogs")
    }

    @objc private func changeFrequency(_ sender: NSPopUpButton) {
        UserDefaults.standard.set(sender.titleOfSelectedItem, forKey: "organizeFrequency")
    }

    @objc private func changeAccuracy(_ sender: NSPopUpButton) {
        UserDefaults.standard.set(sender.titleOfSelectedItem, forKey: "ocrAccuracy")
    }

    @objc private func resetPreferences() {
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        NSApp.presentError(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Preferences have been reset."]))
    }
}
