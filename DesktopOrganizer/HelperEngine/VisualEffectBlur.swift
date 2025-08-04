//
//  VisualEffectBlur.swift
//  DesktopOrganizer
//
//  Created by Michael Danylchuk on 8/3/25.
//


import SwiftUI
import AppKit

struct VisualEffectBlur: NSViewRepresentable {
    typealias NSViewType = CustomBlurView

    func makeNSView(context: Context) -> CustomBlurView {
        CustomBlurView()
    }

    func updateNSView(_ nsView: CustomBlurView, context: Context) {
        // No update needed for now
    }
}
