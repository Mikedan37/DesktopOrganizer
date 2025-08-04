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

# **DesktopOrganizer**
_TimeTravel your macOS Desktop. Snapshots. Timeline. Restore in one click._  

---

## 🔥 **What is DesktopOrganizer?**
DesktopOrganizer is a **macOS utility** that brings **desktop versioning**, **AI-powered cleanup**, and **beautiful UI** to your Mac.  
Think **Time Machine for your Desktop** — but lightweight, fast, and stunning.

✔ Hourly **auto snapshots** with a background daemon  
✔ Interactive **timeline slider** to scroll through history  
✔ **3D flipping previews** for past states  
✔ One-click **restore** to any snapshot  

---

## ✨ **Key Features**
- ✅ **Desktop Timeline** → Navigate history with a smooth animated slider  
- ✅ **3D Flip Previews** → Click a snapshot card to reveal full preview  
- ✅ **Auto Backup Daemon** → Captures hourly snapshots silently in the background  
- ✅ **Instant Restore** → Bring your Desktop back using AppleScript automation  
- ✅ **FAB Quick Actions** → Export, duplicate, or delete snapshots  
- ✅ **AI-Powered Cleanup** → OCR screenshot renaming & smart file categorization  

---

## 🎥 **Demo**
| Timeline Slider | Snapshot Flip | Restore in Action |
|-----------------|---------------|--------------------|
| *(Insert GIF)*  | *(Insert GIF)*| *(Insert GIF)*    |

> Drag the timeline → Flip a snapshot → Restore instantly.

---

## 🛠 **Tech Stack**
| Feature           | Implementation             |
|-------------------|---------------------------|
| UI               | SwiftUI + AppKit         |
| Auto Snapshots   | LaunchAgent + Swift      |
| Restore Engine   | AppleScript + FileManager|
| OCR Renaming     | Vision Framework         |
| Auto Updates     | Sparkle                  |

---

## ⚡ **Installation**
```bash
# Clone the repository
git clone https://github.com/Mikedan37/DesktopOrganizer.git

# Open in Xcode
open DesktopOrganizer.xcodeproj
```

**Requirements:**  
- macOS 15+  
- Xcode 15+  
- Swift 5.10  

---

## ▶ **Quick Start**
### 1. Run the App
Launch from Xcode and explore the **Timeline UI**.

### 2. Enable Auto Snapshot Daemon
```bash
cp com.desktoporganizer.daemon.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.desktoporganizer.daemon.plist
```

### 3. Restore Any Snapshot
Flip a card → Hit **Restore** → Done.

---

## 📊 **Example Snapshot Report**
```
====================================
     🖥 Desktop Snapshot Report
====================================
Date: 2025-08-03
Snapshots Stored: 72
Storage Used: 1.4 GB
Current Clutter Score: 21/100 [█████████░░░░░░░░]
```

---

## 🗺 **Roadmap**
- iCloud sync for snapshots  
- Diff view to compare two desktop states  
- ML-based clutter predictions  

---

## 📜 **License**
MIT License © 2025 Michael Danylchuk  

