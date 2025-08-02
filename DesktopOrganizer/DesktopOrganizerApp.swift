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
    
    var body: some Scene {
        MenuBarExtra {
            MenuContentView(onRefresh: updateBadge)
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
    }
    
    func updateBadge() {
        fileCount = OrganizerService.desktopFileCount()
    }
}
