//
//  ContentView.swift
//  DesktopOrganizer
//
//  Created by Michael Danylchuk on 8/1/25.
//

import SwiftUI

struct MenuContentView: View {
    var onRefresh: () -> Void
    @State private var previews: [URL] = OrganizerService.previewFiles(limit: 3)
    @State private var animateHeader = false
    
    var body: some View {
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
                    OrganizerService.openPreferences()
                }
                .padding(.top, 1)
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 14)
            .shadow(color: Color.black.opacity(0.15), radius: 1, x: 0, y: 1)
            
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
        .frame(width: 200)
        .background(.ultraThinMaterial)
    }
    
    func refreshData() {
        previews = OrganizerService.previewFiles(limit: 3)
        onRefresh() // update badge
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
