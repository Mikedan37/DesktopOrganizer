
import SwiftUI
import AppKit

class CustomBlurView: NSView {
    private let blurLayer = CALayer()
    private let filter = CIFilter(name: "CIGaussianBlur")!

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer = CALayer()
        layer?.backgroundColor = NSColor.clear.cgColor

        blurLayer.frame = bounds
        blurLayer.backgroundColor = NSColor.clear.cgColor
        blurLayer.filters = [filter]
        blurLayer.compositingFilter = "plusL"
        blurLayer.needsDisplayOnBoundsChange = true
        layer?.addSublayer(blurLayer)

        postsFrameChangedNotifications = true
        NotificationCenter.default.addObserver(self, selector: #selector(frameDidChange), name: NSView.frameDidChangeNotification, object: self)
    }

    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        blurLayer.frame = bounds
        updateFilter()
    }

    @objc private func frameDidChange(notification: Notification) {
        blurLayer.frame = bounds
        updateFilter()
    }

    private func updateFilter() {
        filter.setValue(20.0, forKey: kCIInputRadiusKey)
        blurLayer.filters = [filter]
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

