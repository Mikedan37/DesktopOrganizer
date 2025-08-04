//
//  DesktopOrganizerApp.swift
//  DesktopOrganizer
//
//  Created by Michael Danylchuk on 8/1/25.
//

import SwiftUI

@main
struct DesktopOrganizerApp: App {
    @State private var fileCount = OrganizerService.desktopFileCount()
    @State private var showPreferences = false
    
    var body: some Scene {
        MenuBarExtra {
            MenuContentView(
                onRefresh: updateBadge,
                onPreferences: { showPreferences.toggle() }
            )
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "rectangle.stack")
                    .font(.system(size: 16))
                
                if fileCount > 0 {
                    Text("\(fileCount)")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                        .padding(3)
                        .background(Circle().fill(Color.red))
                        .offset(x: 8, y: -8)
                }
            }
            .frame(width: 24, height: 24)
        }
        .menuBarExtraStyle(.window)

        // Preferences Window Scene
        Window("Preferences", id: "preferences") {
            PreferencesView()
                .frame(width: 420, height: 280)
        }
        .defaultPosition(.center)

        // Timeline Window Scene
        Window("Timeline", id: "timeline") {
            TimelineView() // Replace with your real timeline view when ready
                .frame(width: 700, height: 500)
        }
        .defaultPosition(.center)
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
    }
    
    func updateBadge() {
        fileCount = OrganizerService.desktopFileCount()
    }
}
