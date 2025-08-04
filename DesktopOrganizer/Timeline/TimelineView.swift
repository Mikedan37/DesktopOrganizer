import SwiftUI
import AppKit
import Combine

struct TimelineView: View {
    @State private var snapshots: [DesktopSnapshot] = []
    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var hoveredIndex: Int? = nil
    @State private var animateEmptyState = false
    @State private var animateHeaderGradient = false
    @State private var pulseAnimation = false
    @State private var snapshotTimer: AnyCancellable?
    @State private var showMenu = false
    @State private var showActions = false

    var body: some View {
        ZStack {
            DarkMatteBackground()

            VStack(spacing: 0) {
                // FAB and Actions: plus button always centered, actions animate outward from center
                ZStack {
                    // First button (Export)
                    ActionCircleButton(icon: "square.and.arrow.up") {
                        print("Export tapped")
                        showActions = false
                    }
                    .offset(x: showActions ? -140 : 0)
                    .scaleEffect(showActions ? 1 : 0.1)
                    .opacity(showActions ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showActions)

                    // Second button (Duplicate)
                    ActionCircleButton(icon: "doc.on.doc") {
                        print("Duplicate tapped")
                        showActions = false
                    }
                    .offset(x: showActions ? -80 : 0)
                    .scaleEffect(showActions ? 1 : 0.1)
                    .opacity(showActions ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showActions)

                    // Middle button (Settings)
                    ActionCircleButton(icon: "gearshape") {
                        print("Settings tapped")
                        showActions = false
                    }
                    .scaleEffect(showActions ? 1 : 0.1)
                    .opacity(showActions ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showActions)

                    // Fourth button (Info)
                    ActionCircleButton(icon: "info.circle") {
                        print("Info tapped")
                        showActions = false
                    }
                    .offset(x: showActions ? 80 : 0)
                    .scaleEffect(showActions ? 1 : 0.1)
                    .opacity(showActions ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showActions)

                    // Fifth button (Trash)
                    ActionCircleButton(icon: "trash", isDestructive: true) {
                        print("Clear All tapped")
                        showActions = false
                    }
                    .offset(x: showActions ? 140 : 0)
                    .scaleEffect(showActions ? 1 : 0.1)
                    .opacity(showActions ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showActions)

                    // Main plus button
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            showActions.toggle()
                        }
                    }) {
                        Image(systemName: showActions ? "xmark.circle.fill" : "plus.circle.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(14)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
                            .shadow(color: Color.accentColor.opacity(0.4), radius: 14, y: 4)
                            .rotationEffect(.degrees(showActions ? 45 : 0))
                            .animation(.easeInOut(duration: 0.3), value: showActions)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 24)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showActions)

                Spacer(minLength: 0)

                if snapshots.isEmpty {
                    MinimalEmptyStateView(animate: $animateEmptyState)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .transition(.opacity)
                } else {
                    VStack(spacing: 22) {
                        GeometryReader { geo in
                            HStack(spacing: 18) {
                                ForEach(Array(snapshots.enumerated()), id: \.offset) { idx, snap in
                                    ElegantSnapshotCard(
                                        snap: snap,
                                        isCurrent: idx == currentIndex,
                                        size: CGSize(width: 480, height: 320),
                                        isDragging: false,
                                        dragOffset: 0,
                                        pulseAnimation: pulseAnimation
                                    )
                                    .frame(width: 420, height: 280)
                                    .scaleEffect(idx == currentIndex ? 1 : 0.9)
                                    .opacity(idx == currentIndex ? 1 : 0.6)
                                    .blur(radius: idx == currentIndex ? 0 : 2)
                                }
                            }
                            .frame(height: 320)
                            .offset(x: calculateOffset(containerWidth: geo.size.width, currentIndex: currentIndex))
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentIndex)
                        }
                        .frame(height: 320)

                        TimelineScrubber(
                            snapshots: snapshots,
                            currentIndex: $currentIndex
                        )
                        .padding(.top, 12)
                        .padding(.bottom, 18)
                        .onAppear {
                            withAnimation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                                pulseAnimation = true
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
                    .padding(.bottom, 0)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(.top, 24)
            .padding(.horizontal, 10)
        }
        .frame(minWidth: 820, minHeight: 580)
        .onAppear {
            do {
                snapshots = try SnapshotStorage.loadAll()
                currentIndex = snapshots.isEmpty ? 0 : snapshots.count - 1
            } catch {
                print("Failed to load snapshots: \(error)")
            }
            animateEmptyState = true
            // Start hourly snapshot timer (fires every hour)
            snapshotTimer = Timer.publish(every: 3600, on: .main, in: .common)
                .autoconnect()
                .sink { _ in
                    takeAndStoreSnapshot()
                }
        }
        .onDisappear {
            snapshotTimer?.cancel()
        }
    }

    // MARK: - Snapshot Helpers

    func takeAndStoreSnapshot() {
        let snapshot = DesktopSnapshot(files: getFilesForSnapshot())
        if snapshots.last?.files != snapshot.files {
            snapshots.append(snapshot)
            currentIndex = snapshots.count - 1
            try? SnapshotStorage.save(snapshot)
        }
    }

    func getFilesForSnapshot() -> [SnapshotFile] {
        // Stub: return dummy files for testing
        return [
            SnapshotFile(path: "/Users/test/Desktop/File_\(Int.random(in: 100...999)).txt", name: "File_\(Int.random(in: 100...999)).txt"),
            SnapshotFile(path: "/Users/test/Desktop/Presentation.pdf", name: "Presentation.pdf"),
            SnapshotFile(path: "/Users/test/Desktop/Screenshot.png", name: "Screenshot.png")
        ]
    }
}

// Updated ElegantSnapshotCard with 3D flip animation
struct ElegantSnapshotCard: View {
    let snap: DesktopSnapshot
    let isCurrent: Bool
    let size: CGSize
    let isDragging: Bool
    let dragOffset: CGFloat
    let pulseAnimation: Bool
    @State private var flipped = false

    var body: some View {
        ZStack {
            // 3D flip: front and back views alternate with rotation and opacity
            ZStack {
                frontView
                    .opacity(flipped ? 0 : 1)
                backView
                    .opacity(flipped ? 1 : 0)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            }
            .frame(width: size.width * 0.85, height: size.height * 0.9)
            .cornerRadius(28)
            .shadow(color: Color.black.opacity(isCurrent ? 0.45 : 0.1), radius: 20, y: 10)
            .rotation3DEffect(.degrees(flipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            .animation(.easeOut(duration: 0.4), value: isCurrent)
            .onTapGesture {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    flipped.toggle()
                }
            }
        }
        .opacity(isCurrent ? 1 : 0.5)
    }

    // Front view is the original card UI
    private var frontView: some View {
        ZStack(alignment: .bottomLeading) {
            // Glass panel with glowing edges, gradient overlays, and subtle blur
            RoundedRectangle(cornerRadius: 15)
                .fill(.ultraThinMaterial)
                .overlay(
                    LinearGradient(
                        colors: [Color.accentColor.opacity(0.12), Color.white.opacity(0.08), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(LinearGradient(
                            colors: [
                                Color.white.opacity(0.18),
                                Color.accentColor.opacity(0.35)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ), lineWidth: 1.6)
                )
                .shadow(color: Color.black.opacity(0.35), radius: 14, y: 10)
                .shadow(color: Color.accentColor.opacity(0.15), radius: 18, y: 12)
                .scaleEffect(isCurrent && pulseAnimation ? 1.04 : 1)
                .animation(isCurrent ? Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true) : .default, value: pulseAnimation)

            VStack(alignment: .leading, spacing: 14) {
                // Timestamp at top, slightly smaller, above file info
                Text(snap.timestamp, formatter: dateFormatter)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.92))
                    .padding(.bottom, 6)

                // File count
                Text("\(snap.files.count) files")
                    .font(.headline)
                    .foregroundColor(Color.white.opacity(0.85))

                // File names and icons (up to 3)
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(snap.files.prefix(3), id: \.id) { file in
                        HStack(spacing: 8) {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(Color.accentColor.opacity(0.9))
                            Text(file.name)
                                .font(.callout)
                                .foregroundColor(Color.white.opacity(0.9))
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()

                HStack(spacing: 14) {
                    SnapshotActionButton(icon: "arrow.counterclockwise", label: "Restore") {
                        print("Restore tapped for \(snap.timestamp)")
                    }
                    SnapshotActionButton(icon: "eye", label: "Preview") {
                        print("Preview tapped for \(snap.timestamp)")
                    }
                    SnapshotActionButton(icon: "trash", label: "Delete") {
                        print("Delete tapped for \(snap.timestamp)")
                    }
                }
                .padding(.top, 12)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 20)
        }
        .frame(width: size.width * 0.85, height: size.height * 0.9)
        .cornerRadius(28)
    }

    // Back view is a preview image
    private var backView: some View {
        Image(nsImage: NSImage(contentsOfFile: "/Users/mdanylchuk/Desktop/Screenshot 2025-08-03 at 8.48.44 PM.png") ?? NSImage())
            .resizable()
            .scaledToFill()
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .frame(width: size.width * 0.85, height: size.height * 0.9)
    }

    private var dateFormatter: DateFormatter {
        let fmt = DateFormatter()
        fmt.dateStyle = .long
        fmt.timeStyle = .short
        return fmt
    }
}

// --- TimelineScrubber: New advanced timeline component for snapshots ---
struct SnapshotActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    @State private var hover = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(label)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .foregroundColor(.white.opacity(hover ? 1 : 0.85))
            .shadow(color: Color.accentColor.opacity(hover ? 0.5 : 0.2), radius: hover ? 12 : 6)
            .animation(.easeInOut(duration: 0.25), value: hover)
        }
        .buttonStyle(.plain)
        .onHover { hover in self.hover = hover }
    }
}

// --- CustomMenuButton: reusable dropdown menu button for floating toolbar ---
struct CustomMenuButton: View {
    let label: String
    let icon: String
    let destructive: Bool
    let action: () -> Void

    init(label: String, icon: String, destructive: Bool = false, action: @escaping () -> Void) {
        self.label = label
        self.icon = icon
        self.destructive = destructive
        self.action = action
    }

    @State private var hover = false

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(hover ? Color.white.opacity(0.08) : Color.clear)
            .foregroundColor(destructive ? Color.red.opacity(hover ? 0.9 : 0.8) : Color.white.opacity(hover ? 1 : 0.85))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .onHover { hover = $0 }
    }
}

// --- ActionCircleButton: reusable circular button for FAB radial menu ---
struct ActionCircleButton: View {
    let icon: String
    let isDestructive: Bool
    let action: () -> Void
    @State private var hover = false

    init(icon: String, isDestructive: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.isDestructive = isDestructive
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(isDestructive ? .red : .white)
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
                .shadow(color: Color.accentColor.opacity(hover ? 0.6 : 0.3), radius: hover ? 14 : 10)
                .scaleEffect(hover ? 1.12 : 1)
                .animation(.easeInOut(duration: 0.25), value: hover)
        }
        .buttonStyle(.plain)
        .onHover { hover = $0 }
    }
}
struct TimelineScrubber: View {
    let snapshots: [DesktopSnapshot]
    @Binding var currentIndex: Int
    @State private var knobHover = false
    @State private var dragging = false
    @State private var progress: CGFloat = 0.5

    private let timelineWidth: CGFloat = 360

    var body: some View {
        VStack(spacing: 0) {
            // Label above knob on hover or drag
            ZStack(alignment: .leading) {
                if !knobHover && !dragging {
                    Text(labelForIndex(currentIndex))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.35))
                        .frame(width: timelineWidth, alignment: .center)
                        .offset(y: -8)
                        .allowsHitTesting(false)
                }
                if knobHover || dragging {
                    Text(labelForIndex(currentIndex))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.35), radius: 7, y: 4)
                        .offset(
                            x: min(max(0, timelineWidth * progress - 50), timelineWidth - 100),
                            y: -26
                        )
                        .scaleEffect(knobHover ? 1.08 : 1)
                        .animation(.interactiveSpring(response: 0.35, dampingFraction: 0.8), value: knobHover)
                        .animation(.interactiveSpring(response: 0.35, dampingFraction: 0.8), value: progress)
                        .allowsHitTesting(false)
                }
            }
            .frame(width: timelineWidth, alignment: .leading)

            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 6)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.accentColor.opacity(0.3), Color.clear, Color.accentColor.opacity(0.3)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .opacity(0.7)
                        .blendMode(.overlay)
                    )
                    .clipShape(Capsule())
                    .frame(width: timelineWidth, height: 8)
                    .shadow(color: .black.opacity(0.25), radius: 6, y: 3)

                // Tick marks
                HStack {
                    ForEach(snapshots.indices, id: \.self) { i in
                        let normalized = CGFloat(i) / CGFloat(snapshots.count - 1)
                        let distance = abs(normalized - progress)
                        Capsule()
                            .fill(i == currentIndex ? Color.accentColor : Color.white.opacity(0.82))
                            .frame(width: 4, height: distance < 0.08 ? 26 : 16)
                            .scaleEffect(i == currentIndex ? 1.37 : (distance < 0.1 ? 1.14 : 1))
                            .opacity(distance > 0.38 ? 0.2 : 1)
                            .shadow(color: i == currentIndex ? Color.accentColor.opacity(0.6) : .clear, radius: 4)
                            .animation(.easeInOut(duration: 0.22), value: progress)
                    }
                }
                .frame(width: timelineWidth)

                // Draggable knob
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.accentColor.opacity(knobHover ? 0.60 : 0.45),
                                Color.white.opacity(0.14)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .background(Circle().fill(.ultraThinMaterial))
                    .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 1.3))
                    .shadow(color: Color.accentColor.opacity(knobHover ? 1.0 : 0.55), radius: knobHover ? 20 : 10)
                    .frame(width: knobHover ? 38 : 32, height: knobHover ? 38 : 32)
                    .scaleEffect(knobHover ? 1.13 : 1)
                    .offset(x: max(0, min(timelineWidth, timelineWidth * progress)))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragging = true
                                let clamped = min(max(0, value.location.x), timelineWidth)
                                withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.8)) {
                                    progress = clamped / timelineWidth
                                    currentIndex = Int(round(progress * CGFloat(snapshots.count - 1)))
                                }
                            }
                            .onEnded { value in
                                dragging = false
                                let clamped = min(max(0, value.location.x), timelineWidth)
                                withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.7)) {
                                    let snapIndex = Int(round((clamped / timelineWidth) * CGFloat(snapshots.count - 1)))
                                    progress = CGFloat(snapIndex) / CGFloat(snapshots.count - 1)
                                    currentIndex = snapIndex
                                }
                            }
                    )
                    .onHover { hover in
                        knobHover = hover
                        if hover { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                    }
                    .animation(.easeInOut(duration: 0.32), value: knobHover)
                    .modifier(KnobShimmerEffect(isActive: knobHover))
            }
            .frame(width: timelineWidth)
            .padding(.bottom, 70)
        }
        .onAppear {
            progress = snapshots.isEmpty ? 0 : CGFloat(currentIndex) / CGFloat(snapshots.count - 1)
        }
        .frame(height: 50)
        .padding(.bottom, 4)
    }

    private func labelForIndex(_ idx: Int) -> String {
        guard idx < snapshots.count else { return "" }
        let fmt = DateFormatter()
        fmt.dateStyle = .none
        fmt.timeStyle = .short
        return fmt.string(from: snapshots[idx].timestamp)
    }
}


struct DarkMatteBackground: View {
    var body: some View {
        ZStack {
            Color(NSColor.windowBackgroundColor)
                .opacity(0.85)
                .blur(radius: 8)
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.15),
                    Color.blue.opacity(0.15),
                    Color.black.opacity(0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blendMode(.softLight)
            .ignoresSafeArea()
        }
    }
}

struct MinimalHeaderView: View {
    let date: Date?

    private var headerText: String {
        return "Desktop TimeTravel"
    }

    var body: some View {
        Text(headerText)
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundColor(.white.opacity(0.75))
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity)
    }

    private var dateFormatter: DateFormatter {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .short
        return fmt
    }
}

struct MinimalEmptyStateView: View {
    @Binding var animate: Bool
    @State private var hovering = false
    @State private var buttonHover = false
    @State private var breathe = false

    @State private var selectedFilter = "Today"
    private let filterOptions = ["Today", "Yesterday", "Last 7 Days", "All Time"]

    @State private var selectedIndex = 0
    @State private var knobHover = false
    @State private var progress: CGFloat = 0.5
    private let timelinePoints = ["10:00 AM", "12:00 PM", "2:00 PM", "4:00 PM", "6:00 PM", "8:00 PM"]

    var body: some View {
        ZStack {
            VStack(spacing: 18) {
                EmptyStateIconView(hovering: $hovering, breathe: $breathe)
                EmptyStateTextsView()
                Spacer(minLength: 0)
                EmptyStateTimelineScrubber(
                    selectedIndex: $selectedIndex,
                    knobHover: $knobHover,
                    progress: $progress,
                    timelinePoints: timelinePoints
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 20)
            .padding(.bottom, 36) // <-- raises everything up from window edge!
        }
    }
}

struct EmptyStateIconView: View {
    @Binding var hovering: Bool
    @Binding var breathe: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .frame(width: 110, height: 110)
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.15), lineWidth: 1))
                .shadow(color: Color.black.opacity(0.35), radius: 14, y: 6)

            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 44, weight: .semibold))
                .foregroundColor(.white.opacity(0.95))
        }
        .scaleEffect(breathe ? 1.03 : 0.97)
        .animation(Animation.easeInOut(duration: 3).repeatForever(autoreverses: true), value: breathe)
        .scaleEffect(hovering ? 1.15 : 1)
        .animation(.easeInOut(duration: 0.25), value: hovering)
        .onHover { hover in hovering = hover }
        .onAppear { breathe = true }
    }
}

struct EmptyStateTextsView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("No Snapshots Yet")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .shadow(color: .black.opacity(0.2), radius: 1, y: 1)

            Text("Your timeline is empty — start by saving your first snapshot.")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
        }
    }
}

struct EmptyStateTimelineScrubber: View {
    @Binding var selectedIndex: Int
    @Binding var knobHover: Bool
    @Binding var progress: CGFloat
    let timelinePoints: [String]
    @State private var dragging = false

    private let timelineWidth: CGFloat = 360

    var body: some View {
        VStack(spacing: 0) {
            // --- Label ZStack replacement ---
            ZStack(alignment: .leading) {
                if !knobHover && !dragging {
                    Text(timelinePoints[selectedIndex])
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.35))
                        .frame(width: timelineWidth, alignment: .center)
                        .offset(y: -8)
                        .allowsHitTesting(false)
                }
                if knobHover || dragging {
                    Text(timelinePoints[selectedIndex])
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.35), radius: 7, y: 4)
                        .offset(
                            x: min(max(0, timelineWidth * progress - 50), timelineWidth - 100),
                            y: -26
                        )
                        .scaleEffect(knobHover ? 1.08 : 1)
                        .animation(.interactiveSpring(response: 0.35, dampingFraction: 0.8), value: knobHover)
                        .animation(.interactiveSpring(response: 0.35, dampingFraction: 0.8), value: progress)
                        .allowsHitTesting(false)
                }
            }
            .frame(width: timelineWidth, alignment: .leading)

            ZStack(alignment: .leading) {
                // Timeline slider track, ticks, knob, etc.
                RoundedRectangle(cornerRadius: 6)
                    .fill(.ultraThinMaterial)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.accentColor.opacity(0.3), Color.clear, Color.accentColor.opacity(0.3)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .opacity(0.7)
                        .blendMode(.overlay)
                    )
                    .clipShape(Capsule())
                    .frame(width: timelineWidth, height: 8)
                    .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
                    .onHover { hovering in
                        if hovering {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                    .focusable(false)
                    .allowsHitTesting(false)

                HStack {
                    ForEach(timelinePoints.indices, id: \.self) { i in
                        let normalized = CGFloat(i) / CGFloat(timelinePoints.count - 1)
                        let distance = abs(normalized - progress)
                        Capsule()
                            .fill(i == selectedIndex ? Color.accentColor : Color.white.opacity(0.82))
                            .frame(width: 4, height: distance < 0.08 ? 26 : 16)
                            .scaleEffect(i == selectedIndex ? 1.37 : (distance < 0.1 ? 1.14 : 1))
                            .opacity(distance > 0.38 ? 0.2 : 1)
                            .shadow(color: i == selectedIndex ? Color.accentColor.opacity(0.6) : .clear, radius: 4)
                            .animation(.easeInOut(duration: 0.22), value: progress)
                    }
                }
                .frame(width: timelineWidth)

                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.accentColor.opacity(knobHover ? 0.60 : 0.45),
                                Color.white.opacity(0.14)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .background(Circle().fill(.ultraThinMaterial))
                    .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 1.3))
                    .shadow(color: Color.accentColor.opacity(knobHover ? 1.0 : 0.55), radius: knobHover ? 20 : 10)
                    .frame(width: knobHover ? 38 : 32, height: knobHover ? 38 : 32)
                    .scaleEffect(knobHover ? 1.13 : 1)
                    .offset(x: max(0, min(timelineWidth, timelineWidth * progress)))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragging = true
                                let clamped = min(max(0, value.location.x), timelineWidth)
                                withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.8)) {
                                    progress = clamped / timelineWidth
                                    selectedIndex = Int(round(progress * CGFloat(timelinePoints.count - 1)))
                                }
                            }
                            .onEnded { value in
                                dragging = false
                                let clamped = min(max(0, value.location.x), timelineWidth)
                                withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.7)) {
                                    let snapIndex = Int(round((clamped / timelineWidth) * CGFloat(timelinePoints.count - 1)))
                                    progress = CGFloat(snapIndex) / CGFloat(timelinePoints.count - 1)
                                    selectedIndex = snapIndex
                                }
                            }
                    )
                    .onHover { hover in
                        knobHover = hover
                        if hover {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                    .animation(.easeInOut(duration: 0.32), value: knobHover)
                    .modifier(KnobShimmerEffect(isActive: knobHover))
                    .focusable(false)
            }
            .focusable(false)
            .frame(width: timelineWidth)
            .padding(.bottom, 10)
            .contentShape(Rectangle())
            // Removed tap/drag gestures and onTapGesture as per instructions
        }
        .onAppear { progress = 0.5 }
        .frame(height: 150)
        // .drawingGroup() // Removed as per instruction
    }
}

// Modifier for animated gradient shimmer
struct AnimatedGradientMask: ViewModifier {
    @State private var animateGradient = false
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [Color.white.opacity(0.3), Color.clear, Color.white.opacity(0.3)]),
                    startPoint: animateGradient ? .trailing : .leading,
                    endPoint: animateGradient ? .leading : .trailing
                )
                .blendMode(.overlay)
                .animation(Animation.linear(duration: 2).repeatForever(autoreverses: true), value: animateGradient)
            )
            .onAppear { animateGradient = true }
    }
}

// Knob shimmer pop on hover
struct KnobShimmerEffect: ViewModifier {
    var isActive: Bool
    @State private var shimmer = false
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [Color.white.opacity(isActive ? 0.45 : 0), Color.clear, Color.white.opacity(isActive ? 0.45 : 0)]),
                    startPoint: shimmer ? .leading : .trailing,
                    endPoint: shimmer ? .trailing : .leading
                )
                .blendMode(.overlay)
                .opacity(isActive ? 1 : 0)
                .animation(isActive ?
                    Animation.linear(duration: 0.65).repeatForever(autoreverses: true) : .default,
                    value: shimmer
                )
            )
            .onAppear {
                if isActive { shimmer = true }
            }
            .onDisappear {
                shimmer = false
            }
    }
}

    // Helper for carousel offset
func calculateOffset(containerWidth: CGFloat, currentIndex: Int) -> CGFloat {
    let cardWidth: CGFloat = 420
    let spacing: CGFloat = 18
    let xOffset = (containerWidth - cardWidth) / 2
    return xOffset - CGFloat(currentIndex) * (cardWidth + spacing)
}
