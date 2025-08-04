//
//  FrostedWindowController.swift
//  DesktopOrganizer
//
//  Created by Michael Danylchuk on 8/3/25.
//

import SwiftUI
import AppKit

final class FrostedWindowController<Content: View>: NSWindowController, NSWindowDelegate {
    init(@ViewBuilder content: @escaping () -> Content) {
        // Create hosting view for SwiftUI content
        let hosting = NSHostingView(rootView: content())
        
        // Create NSVisualEffectView for true macOS blur
        let effectView = NSVisualEffectView(frame: hosting.bounds)
        effectView.autoresizingMask = [.width, .height]
        effectView.material = .sidebar
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        
        // Add hosting view inside effect view
        effectView.addSubview(hosting)
        hosting.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hosting.leadingAnchor.constraint(equalTo: effectView.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: effectView.trailingAnchor),
            hosting.topAnchor.constraint(equalTo: effectView.topAnchor),
            hosting.bottomAnchor.constraint(equalTo: effectView.bottomAnchor),
        ])
        
        // Create borderless transparent window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 740, height: 480),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.contentView = effectView
        window.hasShadow = true
        window.isMovableByWindowBackground = true
        window.level = .normal
        
        super.init(window: window)
        window.delegate = self
    }
    
    required init?(coder: NSCoder) { fatalError() }
}

struct FrostedWindow<Content: View>: NSViewControllerRepresentable {
    let content: () -> Content
    
    func makeNSViewController(context: Context) -> NSViewController {
        let ctrl = FrostedWindowController(content: content)
        ctrl.showWindow(nil)
        return NSViewController()
    }
    
    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {}
}
