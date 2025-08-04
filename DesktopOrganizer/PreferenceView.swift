//
//  PreferenceView.swift
//  DesktopOrganizer
//
//  Created by Michael Danylchuk on 8/2/25.
//

import SwiftUI

struct PreferencesView: View {
    @AppStorage("autoCleanAtLogin") private var autoClean = false
    @AppStorage("organizeFrequency") private var organizeFrequency = "Manual"
    @AppStorage("enableOCR") private var enableOCR = true
    @AppStorage("enableUpdates") private var enableUpdates = true
    @AppStorage("enableNotifications") private var enableNotifications = true
    @AppStorage("theme") private var theme = "System"

    @State private var selectedTab = "General"

    let tabs: [(label: String, icon: String)] = [
        ("General", "gearshape"),
        ("Advanced", "slider.horizontal.3"),
        ("Updates", "arrow.triangle.2.circlepath"),
        ("Appearance", "paintbrush"),
        ("About", "info.circle")
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                ForEach(tabs, id: \.label) { tab in
                    Button(action: {
                        selectedTab = tab.label
                    }) {
                        VStack {
                            Image(systemName: tab.icon)
                                .font(.system(size: 16))
                            Text(tab.label)
                                .font(.system(size: 11))
                        }
                        .padding(6)
                        .frame(maxWidth: .infinity)
                        .background(selectedTab == tab.label ? Color.accentColor.opacity(0.15) : Color.clear)
                        .cornerRadius(8)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)

            Divider().padding(.vertical, 8)

            Group {
                switch selectedTab {
                case "General": generalTab
                case "Advanced": advancedTab
                case "Updates": updatesTab
                case "Appearance": appearanceTab
                case "About": aboutTab
                default: generalTab
                }
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
        }
        .frame(width: 460, height: 300)
    }

    // ✅ General
    var generalTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle("Auto-clean Desktop at login", isOn: $autoClean)
            HStack {
                Text("Organize Frequency:")
                Picker("", selection: $organizeFrequency) {
                    Text("Manual").tag("Manual")
                    Text("Hourly").tag("Hourly")
                    Text("Daily").tag("Daily")
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 120)
            }
        }
    }

    // ✅ Advanced
    var advancedTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle("Enable OCR for Screenshot Renaming", isOn: $enableOCR)
            Toggle("Enable Sparkle Updates", isOn: $enableUpdates)
            Toggle("Enable Notifications", isOn: $enableNotifications)
        }
    }

    // ✅ Updates
    var updatesTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button("Check for Updates Now") {
                // Integrate Sparkle update trigger here
            }
            Text("Current Version: 1.0.0")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    // ✅ Appearance
    var appearanceTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Theme").bold()
            Picker("Theme", selection: $theme) {
                Text("System").tag("System")
                Text("Light").tag("Light")
                Text("Dark").tag("Dark")
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 250)
        }
    }

    // ✅ About
    var aboutTab: some View {
        VStack(alignment: .center, spacing: 12) {
            Image(systemName: "desktopcomputer")
                .resizable()
                .frame(width: 48, height: 48)
                .padding(.bottom, 4)
            Text("Desktop Organizer")
                .font(.title2).bold()
            Text("Version 1.0.0")
                .font(.subheadline)
            Link("View on GitHub", destination: URL(string: "https://github.com/Mikedan37/DesktopOrganizer")!)
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
    }
}
