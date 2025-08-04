<h1 align="center">DesktopOrganizer</h1>
<p align="center">
Organize your macOS Desktop like a pro — AI-powered cleanup, OCR screenshot renaming, and instant reports.
</p>

<p align="center">
  <img src="https://img.shields.io/github/stars/Mikedan37/DesktopOrganizer?style=flat" />
  <img src="https://img.shields.io/github/forks/Mikedan37/DesktopOrganizer?style=flat" />
  <img src="https://img.shields.io/github/issues/Mikedan37/DesktopOrganizer" />
  <img src="https://img.shields.io/badge/swift-5.10-orange" />
  <img src="https://img.shields.io/badge/macOS-15+-black" />
  <img src="https://img.shields.io/badge/build-Xcode%2015-blue" />
  <img src="https://img.shields.io/github/license/Mikedan37/DesktopOrganizer" />
  <img src="https://img.shields.io/github/last-commit/Mikedan37/DesktopOrganizer?color=brightgreen" />
</p>

⸻

DesktopOrganizer

TimeTravel your macOS Desktop. Snapshots. Timeline. Restore in one click.


⸻

🔥 What is DesktopOrganizer?

A macOS utility that combines desktop versioning, AI-powered cleanup, and beautiful UI.
Think Time Machine, but made for your Desktop — lightweight, fast, and stunning.

✔ Hourly auto snapshots with a background daemon.
✔ An interactive timeline slider to scroll through history.
✔ 3D flipping previews of past desktop states.
✔ One-click restore to any point in time.

⸻

✨ Key Features

✅ Desktop Timeline → Navigate history with a smooth animated slider.
✅ 3D Flip Previews → Click a snapshot card to flip between details and actual screenshot.
✅ Auto Backup Daemon → Runs in the background; takes hourly snapshots with zero lag.
✅ Instant Restore → Uses AppleScript automation to bring your Desktop back in seconds.
✅ FAB Quick Actions → Sleek floating action button with export, duplicate, delete.
✅ AI-Powered Cleanup → OCR screenshot renaming & smart file categorization.

⸻

🎥 Demo

Timeline Slider	Snapshot Flip	Restore in Action
		

(Drag timeline → Flip snapshot → Restore instantly.)

⸻

🛠 Tech Stack

Feature	Implementation
UI	SwiftUI + AppKit
Auto Snapshot	LaunchAgent + Swift
Restore Engine	AppleScript + FileManager
OCR Renaming	Vision Framework
Updates	Sparkle


⸻

⚡ Installation

# Clone the repo
git clone https://github.com/Mikedan37/DesktopOrganizer.git

# Open in Xcode
open DesktopOrganizer.xcodeproj

Requirements:
	•	macOS 15+
	•	Xcode 15+
	•	Swift 5.10

⸻

▶ Quick Start

1. Run the App
	•	Launch from Xcode and explore the Timeline UI.

2. Enable Auto Snapshot Daemon

cp com.desktoporganizer.daemon.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.desktoporganizer.daemon.plist

3. Restore Any Snapshot
	•	Flip a card → Hit Restore → Done.

⸻

📊 Example Snapshot Report

====================================
     🖥  Desktop Snapshot Report
====================================
Date: 2025-08-03
Snapshots Stored: 72
Storage Used: 1.4 GB
Current Clutter Score: 21/100 [█████████░░░░░░░░]


⸻

🗺 Roadmap
	•	iCloud sync for snapshots.
	•	Diff view to compare two snapshots visually.
	•	ML-based clutter predictions.

⸻

📜 License

MIT License © 2025 Michael Danylchuk

⸻
