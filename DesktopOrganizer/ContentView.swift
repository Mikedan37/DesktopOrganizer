//
//  ContentView.swift
//  DesktopOrganizer
//
//  Created by Michael Danylchuk on 8/1/25.
//

import SwiftUI
import AppKit
import Combine

struct MenuContentView: View {
    @Environment(\.openWindow) private var openWindow
    var onRefresh: () -> Void
    var onPreferences: () -> Void
    @State private var previews: [URL] = OrganizerService.previewFiles(limit: 3)
    @State private var animateHeader = false
    @ObservedObject private var moodService = MoodService.shared
    @State private var selectedMoodID: UUID? = nil
    // For overlay dropdown
    @State private var moodPickerButtonFrame: CGRect = .zero
    @State private var moodPickerIsExpanded: Bool = false
    // Match ControlTile width: 320 (tight look)
    @State private var moodPickerButtonWidth: CGFloat = 320

    var body: some View {
        ZStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label {
                        Text("Desktop Organizer")
                            .font(.system(size: 12, weight: .semibold))
                    } icon: {
                        Image(systemName: "rectangle.3.group")
                            .foregroundStyle(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    }
                    .labelStyle(.titleAndIcon)
                    Spacer()
                    AnimatedGearButton {
                        openPreferencesWindow()
                    }
                    .padding(.top, 1)
                }
                .padding(.vertical, 5)
                .padding(.horizontal, 14)
                .shadow(color: Color.black.opacity(0.15), radius: 1, x: 0, y: 1)

                // --- Mood Switcher Custom Glassy Dropdown ---
                PremiumMoodPicker(
                    moods: moodService.moods,
                    selectedMoodID: $selectedMoodID,
                    onSelect: { mood in
                        moodService.restoreMood(mood)
                        selectedMoodID = mood.id
                    },
                    isExpanded: $moodPickerIsExpanded,
                    buttonFrame: $moodPickerButtonFrame,
                    buttonWidth: $moodPickerButtonWidth
                )
                // --- End Mood Switcher ---

                Divider().overlay(Color.white.opacity(0.1)).padding(.horizontal,5)

                VStack(spacing: 8) {
                    Button(action: {
                        print("Button clicked: Clean Desktop")
                        OrganizerService.cleanDesktop()
                        refreshData()
                    }) {
                        ControlTile {
                            HStack {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 14))
                                    .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                Text("Clean Desktop")
                                    .font(.system(size: 12))
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: {
                        print("Button clicked: Undo Last Action")
                        OrganizerService.undoLastAction()
                        refreshData()
                    }) {
                        ControlTile {
                            HStack {
                                Image(systemName: "arrow.uturn.backward")
                                    .font(.system(size: 14))
                                    .foregroundStyle(LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                                Text("Undo Last Action")
                                    .font(.system(size: 12))
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Show Timeline button (added)
                    Button(action: {
                        openWindow(id: "timeline")
                    }) {
                        ControlTile {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 14))
                                    .foregroundStyle(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                                Text("Show Timeline")
                                    .font(.system(size: 12))
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: {
                        print("Button clicked: Check for Updates")
                        if let appDelegate = NSApp.delegate as? AppDelegate {
                            appDelegate.triggerUpdateCheck()
                        }
                    }) {
                        ControlTile {
                            HStack {
                                Image(systemName: "arrow.down.circle")
                                    .font(.system(size: 14))
                                    .foregroundStyle(LinearGradient(colors: [.green, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                                Text("Check for Updates")
                                    .font(.system(size: 12))
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: {
                        print("Button clicked: Quit")
                        NSApplication.shared.terminate(nil)
                    }) {
                        ControlTile {
                            HStack {
                                Image(systemName: "xmark.circle")
                                    .font(.system(size: 14))
                                    .foregroundStyle(LinearGradient(colors: [.red, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                                Text("Quit")
                                    .font(.system(size: 12))
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.bottom, 5)
                }
                .padding(.horizontal, 10)
            }
            .padding(.top, 6)
            .padding(.bottom, 5)
            .background(.ultraThinMaterial)
            .frame(width: 340)

            // --- Overlay Mood Dropdown Floating Above All Controls ---
            if moodPickerIsExpanded {
                // Floating overlay dropdown positioned below the mood picker button
                PremiumMoodDropdownOverlay(
                    moods: moodService.moods,
                    selectedMoodID: $selectedMoodID,
                    onSelect: { mood in
                        moodService.restoreMood(mood)
                        selectedMoodID = mood.id
                        moodPickerIsExpanded = false
                    },
                    width: moodPickerButtonWidth
                )
                .zIndex(1000)
                .position(x: moodPickerButtonFrame.midX, y: moodPickerButtonFrame.maxY + 7)
                .allowsHitTesting(moodPickerIsExpanded)
                // Add transition for dropdown
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    func refreshData() {
        previews = OrganizerService.previewFiles(limit: 3)
        onRefresh() // update badge
    }

    // Show the Preferences window
    func openPreferencesWindow() {
        let hostingController = NSHostingController(rootView: PreferencesWindow())
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 320),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false)
        window.contentView = hostingController.view
        window.title = "Preferences"
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct AnimatedGearButton: View {
    let action: () -> Void
    @State private var animate = false
    @State private var isHovering = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                animate.toggle()
            }
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                animate = false
            }
        }) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 16))
                .rotationEffect(.degrees(animate ? 90 : 0))
                .foregroundStyle(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 20, height: 20)
                .shadow(color: isHovering ? Color.blue.opacity(0.4) : Color.clear, radius: 6)
                .onHover { isHovering = $0 }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.trailing, 4)
    }
}

struct ControlTile<Content: View>: View {
    @ViewBuilder let content: Content
    @State private var isHovering = false
    
    var body: some View {
        content
            .padding(.vertical, 5)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.ultraThinMaterial)
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke(isHovering ? Color.blue.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.15), radius: 1, x: 0, y: 1)
            )
            .overlay(
                LinearGradient(colors: [Color.white.opacity(0.05), Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .cornerRadius(10)
            )
            .brightness(isHovering ? 0.08 : 0)
            .scaleEffect(isHovering ? 1.02 : 1)
            .shadow(color: isHovering ? Color.blue.opacity(0.2) : Color.clear, radius: 3)
            .animation(.easeInOut(duration: 0.15), value: isHovering)
            .onHover { isHovering = $0 }
    }
}

// PreferencesWindow SwiftUI View

// MARK: - Mood Manager View
struct MoodManagerView: View {
    @State private var moodName: String = ""
    @ObservedObject var moodService = MoodService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Desktop Moods")
                .font(.headline)
            HStack {
                TextField("Enter mood name", text: $moodName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 180)
                Button("Save Current Mood") {
                    saveMood()
                }
                .disabled(moodName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            Divider()
            Text("Saved Moods")
                .font(.subheadline)
            if moodService.moods.isEmpty {
                Text("No moods saved.")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                List {
                    ForEach(moodService.moods, id: \.id) { mood in
                        HStack {
                            Text(mood.name)
                            Spacer()
                            Button("Restore") {
                                restoreMood(mood)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            Button(role: .destructive) {
                                deleteMood(mood)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
        }
        .padding()
    }

    private func saveMood() {
        let trimmed = moodName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        moodService.saveCurrentMood(named: trimmed)
        moodName = ""
    }

    private func restoreMood(_ mood: DesktopMood) {
        moodService.restoreMood(mood)
    }

    private func deleteMood(_ mood: DesktopMood) {
        moodService.removeMood(mood)
    }
}


struct PreferencesWindow: View {
    @AppStorage("autoCleanAtLogin") private var autoCleanAtLogin: Bool = false
    @AppStorage("organizeFrequency") private var organizeFrequency: String = "Daily"
    @AppStorage("enableOCR") private var enableOCR: Bool = false
    @AppStorage("enableSparkle") private var enableSparkle: Bool = true
    @AppStorage("enableNotifications") private var enableNotifications: Bool = true
    @AppStorage("openAtLogin") private var openAtLogin: Bool = false

    @State private var selectedTab: Int = 0
    private let frequencyOptions = ["Never", "Hourly", "Daily", "Weekly"]

    @State private var shimmer = false
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 20)
            VStack(spacing: 0) {
                // Sleek Compact Header
                VStack(spacing: 4) {
                    Text("Preferences")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(LinearGradient(colors: [Color.purple, Color.blue], startPoint: .leading, endPoint: .trailing))
                    Text("Manage how Desktop Organizer runs on your Mac.")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 0)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            LinearGradient(colors: [Color.purple.opacity(0.2), Color.blue.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
                )
                .overlay(
                    LinearGradient(colors: [Color.purple.opacity(0.4), Color.blue.opacity(0.4), Color.purple.opacity(0.4)],
                                   startPoint: shimmer ? .leading : .trailing,
                                   endPoint: shimmer ? .trailing : .leading)
                        .opacity(0.15)
                        .animation(Animation.linear(duration: 4).repeatForever(autoreverses: true), value: shimmer)
                )
                .onAppear { shimmer = true }

                // Custom macOS-style animated tab bar
                HStack(spacing: 0) {
                    PremiumTabButton(
                        title: "General",
                        icon: "gearshape.fill",
                        isSelected: selectedTab == 0,
                        gradient: LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                    ) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { selectedTab = 0 }
                    }
                    PremiumTabButton(
                        title: "Advanced",
                        icon: "terminal.fill", // Changed from "slider.horizontal.3" to "terminal.fill"
                        isSelected: selectedTab == 1,
                        gradient: LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                    ) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { selectedTab = 1 }
                    }
                }
                .frame(height: 42)
                .background(
                    Color(.windowBackgroundColor).opacity(0.01)
                )
                .padding(.horizontal, 24)
                .padding(.top, 6)

                // Animated content for each tab
                ZStack {
                    if selectedTab == 0 {
                        PremiumGroupBox(
                            label: {
                                Label {
                                    Text("General Settings")
                                        .font(.system(size: 15, weight: .semibold))
                                } icon: {
                                    Image(systemName: "gear")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(LinearGradient(colors: [.purple, .blue], startPoint: .top, endPoint: .bottomTrailing))
                                }
                            }
                        ) {
                            VStack(alignment: .leading, spacing: 18) {
                                PremiumSettingRow(
                                    icon: "sparkles",
                                    gradient: LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottomTrailing),
                                    label: "Auto-clean at login"
                                ) {
                                    PremiumToggle(isOn: $autoCleanAtLogin)
                                }
                                PremiumSettingRow(
                                    icon: "arrow.triangle.2.circlepath.circle",
                                    gradient: LinearGradient(colors: [.pink, .blue], startPoint: .top, endPoint: .bottomTrailing),
                                    label: "Open at Login"
                                ) {
                                    PremiumToggle(isOn: $openAtLogin)
                                        .onChange(of: openAtLogin) { value in
                                            if value {
                                                addLaunchAgent()
                                            } else {
                                                removeLaunchAgent()
                                            }
                                        }
                                }
                                PremiumSettingRow(
                                    icon: "calendar",
                                    gradient: LinearGradient(colors: [.green, .cyan], startPoint: .top, endPoint: .bottomTrailing),
                                    label: "Organize Frequency"
                                ) {
                                    PremiumPicker(selection: $organizeFrequency, options: frequencyOptions)
                                }
                            }
                        }
                        .transition(.move(edge: .leading).combined(with: .opacity))
                        .padding(.top, 22)
                        .padding(.horizontal, 24)
                    }
                    if selectedTab == 1 {
                        PremiumGroupBox(
                            label: {
                                Label {
                                    Text("Features")
                                        .font(.system(size: 15, weight: .semibold))
                                } icon: {
                                    Image(systemName: "wand.and.stars.inverse")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(LinearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottomTrailing))
                                }
                            }
                        ) {
                            VStack(alignment: .leading, spacing: 18) {
                                PremiumSettingRow(
                                    icon: "text.viewfinder",
                                    gradient: LinearGradient(colors: [.indigo, .purple], startPoint: .top, endPoint: .bottomTrailing),
                                    label: "Enable OCR"
                                ) {
                                    PremiumToggle(isOn: $enableOCR)
                                }
                                PremiumSettingRow(
                                    icon: "arrow.triangle.2.circlepath",
                                    gradient: LinearGradient(colors: [.blue, .green], startPoint: .top, endPoint: .bottomTrailing),
                                    label: "Enable Sparkle Updates"
                                ) {
                                    PremiumToggle(isOn: $enableSparkle)
                                }
                                PremiumSettingRow(
                                    icon: "bell",
                                    gradient: LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottomTrailing),
                                    label: "Enable Notifications"
                                ) {
                                    PremiumToggle(isOn: $enableNotifications)
                                }
                            }
                        }
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                        .padding(.top, 22)
                        .padding(.horizontal, 24)
                    }
                }
                .animation(.spring(response: 0.45, dampingFraction: 0.85), value: selectedTab)
                Spacer()
                // Save & Close modern button
                PremiumCapsuleButton(title: "Save & Close") {
                    NSApp.keyWindow?.close()
                }
                .padding(.bottom, 18)
                .padding(.top, 4)
            }
        }
        .frame(width: 420, height: 400)
        .clipped(antialiased: false)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 20)
        .padding(0)
        .onAppear {
            let bundleID = Bundle.main.bundleIdentifier ?? "com.yourcompany.DesktopOrganizer"
            let agentsPath = ("~/Library/LaunchAgents" as NSString).expandingTildeInPath
            let plistPath = "\(agentsPath)/\(bundleID).plist"
            openAtLogin = FileManager.default.fileExists(atPath: plistPath)
        }
    }
}

// MARK: - Premium Tab Button
struct PremiumTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let gradient: LinearGradient
    let action: () -> Void
    @State private var isHovering = false
    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isSelected ? AnyShapeStyle(gradient) : AnyShapeStyle(Color.secondary))
                Text(title)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(isSelected ? Color.primary : Color.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 36)
            .background(
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(gradient)
                            .opacity(0.19)
                            .shadow(color: Color.blue.opacity(0.13), radius: 4, y: 1)
                            .transition(.opacity.combined(with: .scale))
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isHovering ? 1.035 : 1)
            .rotationEffect(.degrees(0)) // Removed tilt for a cleaner premium look
            .animation(.easeInOut(duration: 0.12), value: isHovering)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { isHovering = $0 }
    }
}

// MARK: - Premium GroupBox
struct PremiumGroupBox<Label: View, Content: View>: View {
    let label: () -> Label
    let content: () -> Content
    @State private var isHovering = false
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 7) {
                label()
                Spacer()
            }
            .padding(.bottom, 2)
            content()
                .padding(.top, 2)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.08), radius: 7, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.25),
                                    Color.blue.opacity(0.16),
                                    Color.purple.opacity(0.13)
                                ],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.4
                        )
                )
        )
        .scaleEffect(isHovering ? 1.01 : 1)
        .shadow(color: Color.black.opacity(0.12), radius: isHovering ? 10 : 6, x: 0, y: isHovering ? 6 : 3)
//        .rotation3DEffect(.degrees(isHovering ? 2 : 0), axis: (x: 0, y: 1, z: 0))
        .animation(.easeInOut(duration: 0.13), value: isHovering)
        .onHover { isHovering = $0 }
    }
}

// MARK: - Premium Setting Row
struct PremiumSettingRow<Content: View>: View {
    let icon: String
    let gradient: LinearGradient
    let label: String
    let content: () -> Content
    @State private var isHovering = false
    var body: some View {
        HStack(spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(gradient)
                    .frame(width: 28, height: 28)
                    .shadow(color: Color.blue.opacity(0.18), radius: 3, y: 1)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }
            Text(label)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
            Spacer()
            content()
        }
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isHovering ? Color.primary.opacity(0.04) : Color.clear)
        )
        .scaleEffect(isHovering ? 1.02 : 1)
        .animation(.easeInOut(duration: 0.13), value: isHovering)
        .onHover { isHovering = $0 }
    }
}

// MARK: - Premium Toggle (Simplified Glassy Toggle)
struct PremiumToggle: View {
    @Binding var isOn: Bool
    @State private var isHovering = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                isOn.toggle()
            }
        }) {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                LinearGradient(
                                    colors: isOn ? [Color.purple.opacity(0.6), Color.blue.opacity(0.6)] : [Color.gray.opacity(0.3), Color.gray.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.4
                            )
                    )
                    .background(
                        isOn ?
                        LinearGradient(colors: [Color.purple.opacity(0.5), Color.blue.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            .clipShape(Capsule()) : nil
                    )
                    .frame(width: 48, height: 26)
                    .shadow(color: isOn ? Color.blue.opacity(0.3) : Color.clear, radius: 6)
                
                Circle()
                    .fill(.thinMaterial)
                    .frame(width: 22, height: 22)
                    .overlay(
                        Circle().strokeBorder(Color.white.opacity(0.6), lineWidth: 1)
                    )
                    .shadow(color: Color.white.opacity(0.4), radius: 4)
                    .padding(2)
            }
            .scaleEffect(isHovering ? 1.08 : 1)
            .animation(.easeInOut(duration: 0.15), value: isHovering)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { isHovering = $0 }
    }
}

// MARK: - Size Preference Key for PremiumPicker dropdown
private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}

// MARK: - Premium Picker (Glassy Dropdown) - Refactored to render dropdown below button in ZStack
struct PremiumPicker: View {
    @Binding var selection: String
    let options: [String]
    @State private var isHovering = false
    @State private var isExpanded = false
    @State private var buttonWidth: CGFloat = 112

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 0) {
                pickerButton
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .onAppear { buttonWidth = geo.size.width }
                                .onChange(of: geo.size.width) { newValue in
                                    buttonWidth = newValue
                                }
                        }
                    )
                if isExpanded {
                    // Overlay a transparent background to catch outside taps
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.23, dampingFraction: 0.82)) {
                                isExpanded = false
                            }
                        }
                        .zIndex(1)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .allowsHitTesting(true)
                        .overlay(
                            dropdownMenu
                                .zIndex(2)
                                .frame(width: buttonWidth)
                                .fixedSize(horizontal: false, vertical: true)
                                .transition(.scale.combined(with: .opacity))
                                .padding(.top, 4)
                            , alignment: .topLeading
                        )
                        .offset(y: -30) // Move overlay up so dropdown appears below button
                }
            }
            .zIndex(isExpanded ? 10000 : 1)
        }
    }

    // MARK: - Picker Button
    private var pickerButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.23, dampingFraction: 0.82)) {
                isExpanded.toggle()
            }
        }) {
            HStack(spacing: 8) {
                Text(selection)
                    .foregroundColor(.primary)
                    .font(.system(size: 13.5, weight: .medium, design: .rounded))
                    .padding(.vertical, 4)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(colors: [Color.purple, Color.blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .animation(.easeInOut(duration: 0.19), value: isExpanded)
            }
            .padding(.horizontal, 11)
            .frame(width: 112, height: 30)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        LinearGradient(
                            colors: isHovering ? [Color.purple.opacity(0.18), Color.blue.opacity(0.18)] : [Color.white.opacity(0.08), Color.clear],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    )
                    .shadow(color: isHovering ? Color.blue.opacity(0.16) : Color.clear, radius: 7)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isHovering ? Color.blue.opacity(0.36) : Color.gray.opacity(0.13), lineWidth: 1.2)
            )
            .scaleEffect(isHovering ? 1.03 : 1)
            .animation(.easeInOut(duration: 0.14), value: isHovering)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { isHovering = $0 }
    }

    // MARK: - Dropdown Menu
    private var dropdownMenu: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(options, id: \.self) { opt in
                DropdownOptionRow(
                    option: opt,
                    isSelected: selection == opt
                ) {
                    withAnimation(.spring(response: 0.23, dampingFraction: 0.82)) {
                        selection = opt
                        isExpanded = false
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    LinearGradient(colors: [Color.purple.opacity(0.13), Color.blue.opacity(0.13)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .clipShape(RoundedRectangle(cornerRadius: 13))
                )
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .stroke(Color.blue.opacity(0.17), lineWidth: 1)
        )
    }
}

struct DropdownOptionRow: View {
    let option: String
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                Text(option)
                    .font(.system(size: 13.5, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(colors: [Color.purple, Color.blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                }
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected
                          ? AnyShapeStyle(LinearGradient(colors: [Color.purple.opacity(0.13), Color.blue.opacity(0.13)], startPoint: .topLeading, endPoint: .bottomTrailing))
                          : AnyShapeStyle(Color.clear))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Premium Capsule Button (Glassy Control Center Style)
struct PremiumCapsuleButton: View {
    let title: String
    let action: () -> Void
    @State private var isHovering = false

    @State private var sweep = false
    var body: some View {
        Button(action: action) {
            ZStack {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .frame(width: 150, height: 34)
                    .overlay(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .blur(radius: 2)
                        .opacity(isHovering ? 0.6 : 0.4)
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.purple.opacity(0.5), Color.blue.opacity(0.5)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.4
                            )
                    )
                    .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.purple.opacity(isHovering ? 0.7 : 0.4),
                                             Color.blue.opacity(isHovering ? 0.7 : 0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.8
                            )
                            .blur(radius: isHovering ? 8 : 5)
                            .opacity(isHovering ? 0.9 : 0.6)
                    )
                    .overlay(
                        LinearGradient(colors: [Color.purple, Color.blue, Color.purple],
                                       startPoint: isHovering ? .leading : .trailing,
                                       endPoint: isHovering ? .trailing : .leading)
                            .opacity(0.3)
                            .animation(.linear(duration: 2).repeatForever(autoreverses: true), value: isHovering)
                    )
                    // Removed glowing circle overlay here
                    .clipShape(Capsule())
                    .contentShape(Capsule())

                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: isHovering ? Color.blue.opacity(0.2) : Color.clear, radius: 3)
            }
            .scaleEffect(isHovering ? 1.03 : 1)
            .animation(.easeInOut(duration: 0.18), value: isHovering)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { isHovering = $0 }
    }
}


// For quick demo, add MoodManagerView at the bottom of your main ContentView
struct ContentView: View {
    var body: some View {
        VStack {
            // ... Your main content here ...
            Spacer()
            Divider()
            MoodManagerView()
        }
        .frame(minWidth: 400, minHeight: 400)
    }
}

// MARK: - PremiumMoodPicker (Glassy Dropdown for Moods) - Refactored for overlay dropdown
struct PremiumMoodPicker: View {
    let moods: [DesktopMood]
    @Binding var selectedMoodID: UUID?
    var onSelect: (DesktopMood) -> Void
    // Overlay control
    @Binding var isExpanded: Bool
    @Binding var buttonFrame: CGRect
    @Binding var buttonWidth: CGFloat
    @State private var isHovering = false

    var groupedMoods: [(String, [DesktopMood])] {
        let presets = moods.filter { $0.name.localizedCaseInsensitiveContains("Mode") }
        let saved = moods.filter { !$0.name.localizedCaseInsensitiveContains("Mode") }
        var groups: [(String, [DesktopMood])] = []
        if !presets.isEmpty { groups.append(("Presets", presets)) }
        if !saved.isEmpty { groups.append(("Saved", saved)) }
        return groups
    }

    var selectedMood: DesktopMood? {
        moods.first(where: { $0.id == selectedMoodID })
    }

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.23, dampingFraction: 0.82)) {
                isExpanded.toggle()
            }
        }) {
            HStack(spacing: 7) {
                Image(systemName: selectedMood?.sfSymbol ?? "face.smiling")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(LinearGradient(colors: [.yellow, .orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .shadow(color: Color.orange.opacity(0.12), radius: 2)
                Text(selectedMood?.name ?? "Switch Mood")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(colors: [Color.purple, Color.blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .animation(.easeInOut(duration: 0.19), value: isExpanded)
            }
            .padding(.vertical, 2)
            .padding(.horizontal, 10)
            .frame(width: buttonWidth, height: 26)
            .background(
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            LinearGradient(
                                colors: isHovering ? [Color.purple.opacity(0.15), Color.blue.opacity(0.15)] : [Color.white.opacity(0.08), Color.clear],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 9))
                        )
                        .shadow(color: isHovering ? Color.orange.opacity(0.10) : Color.black.opacity(0.10), radius: 2, x: 0, y: 1)
                        .background(
                            Color.clear
                                .preference(key: MoodPickerButtonFramePreferenceKey.self, value: geo.frame(in: .global))
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(isHovering ? Color.blue.opacity(0.24) : Color.white.opacity(0.10), lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 9))
            .scaleEffect(isHovering ? 1.03 : 1)
            .animation(.easeInOut(duration: 0.14), value: isHovering)
            .padding(.horizontal, 10)
            .padding(.vertical,0)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { isHovering = $0 }
        .disabled(moods.isEmpty)
        // Listen for the button frame
        .onPreferenceChange(MoodPickerButtonFramePreferenceKey.self) { value in
            buttonFrame = value
        }
    }
}

// Used to pass the button frame up for overlay positioning
private struct MoodPickerButtonFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

// The dropdown overlay rendered at the top ZStack level
private struct PremiumMoodDropdownOverlay: View {
    let moods: [DesktopMood]
    @Binding var selectedMoodID: UUID?
    var onSelect: (DesktopMood) -> Void
    var width: CGFloat

    var groupedMoods: [(String, [DesktopMood])] {
        let presets = moods.filter { $0.name.localizedCaseInsensitiveContains("Mode") }
        let saved = moods.filter { !$0.name.localizedCaseInsensitiveContains("Mode") }
        var groups: [(String, [DesktopMood])] = []
        if !presets.isEmpty { groups.append(("Presets", presets)) }
        if !saved.isEmpty { groups.append(("Saved", saved)) }
        return groups
    }

    var body: some View {
        Group {
            if moods.isEmpty {
                VStack {
                    Text("No moods saved")
                        .foregroundColor(.secondary)
                        .font(.system(size: 13, weight: .regular))
                        .padding(.horizontal, 13)
                        .padding(.vertical, 9)
                }
                .frame(width: width, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            LinearGradient(colors: [Color.purple.opacity(0.13), Color.blue.opacity(0.13)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                .clipShape(RoundedRectangle(cornerRadius: 13))
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 6)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 13)
                        .stroke(Color.blue.opacity(0.17), lineWidth: 1)
                )
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(groupedMoods, id: \.0) { group in
                        if !group.1.isEmpty {
                            Text(group.0)
                                .font(.system(size: 11.5, weight: .semibold))
                                .foregroundColor(.secondary)
                                .padding(.top, groupedMoods.first?.0 == group.0 ? 8 : 10)
                                .padding(.bottom, 2)
                                .padding(.horizontal, 13)
                            ForEach(group.1, id: \.id) { mood in
                                PremiumMoodDropdownRow(
                                    mood: mood,
                                    isSelected: mood.id == selectedMoodID,
                                    onSelect: {
                                        onSelect(mood)
                                    }
                                )
                                .frame(width: width, height: 32)
                            }
                        }
                    }
                }
                .frame(width: width)
                .background(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            LinearGradient(colors: [Color.purple.opacity(0.13), Color.blue.opacity(0.13)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                .clipShape(RoundedRectangle(cornerRadius: 13))
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 6)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 13)
                        .stroke(Color.blue.opacity(0.17), lineWidth: 1)
                )
            }
        }
    }
}

private struct PremiumMoodDropdownRow: View {
    let mood: DesktopMood
    let isSelected: Bool
    let onSelect: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: mood.sfSymbol)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(LinearGradient(colors: [.yellow, .orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                Text(mood.name)
                    .font(.system(size: 13.5, weight: .medium, design: .rounded))
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(colors: [Color.purple, Color.blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                }
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected
                          ? AnyShapeStyle(LinearGradient(colors: [Color.purple.opacity(0.13), Color.blue.opacity(0.13)], startPoint: .topLeading, endPoint: .bottomTrailing))
                          : isHovering
                            ? AnyShapeStyle(Color.primary.opacity(0.04))
                            : AnyShapeStyle(Color.clear))
            )
            .scaleEffect(isHovering ? 1.025 : 1)
            .animation(.easeInOut(duration: 0.13), value: isHovering)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { isHovering = $0 }
    }
}

// MARK: - DesktopMood SF Symbol Extension
extension DesktopMood {
    var sfSymbol: String {
        switch name.lowercased() {
        case let n where n.contains("zen"):
            return "face.smiling"
        case let n where n.contains("meeting"):
            return "person.2.fill"
        case let n where n.contains("screenshare"):
            return "rectangle.on.rectangle"
        default:
            return "sparkles"
        }
    }
}
