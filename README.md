<h1 align="center">DesktopOrganizer</h1>
<p align="center">
Organize your macOS Desktop like a pro — AI-powered cleanup, OCR screenshot renaming, and instant reports.
</p>


<p align="center">
<img src="https://img.shields.io/github/stars/Mikedan37/DesktopOrganizer?style=flat&logo=github" />
<img src="https://img.shields.io/github/forks/Mikedan37/DesktopOrganizer?style=flat&logo=github" />
<img src="https://img.shields.io/github/issues/Mikedan37/DesktopOrganizer?color=brightgreen" />
<img src="https://img.shields.io/badge/Swift-5.10-orange?logo=swift" />
<img src="https://img.shields.io/badge/macOS-15%2B-black?logo=apple" />
<img src="https://img.shields.io/badge/Build-Xcode%2015-blue?logo=xcode" />
<img src="https://img.shields.io/github/license/Mikedan37/DesktopOrganizer" />
<img src="https://img.shields.io/badge/PRs-Welcome-brightgreen.svg" />
<img src="https://img.shields.io/github/last-commit/Mikedan37/DesktopOrganizer?color=yellow" />
</p>


📖 Table of Contents
	•	Overview
	•	Features
	•	Tech Stack
	•	Installation
	•	Usage
	•	Example Report
	•	Roadmap
	•	License

🔍 Overview

DesktopOrganizer is a macOS utility built with Swift + AppKit that uses AI OCR, multithreading, and automation to keep your desktop spotless.
It renames screenshots intelligently, organizes files by type, and generates a detailed cleanup report with clutter metrics.

🚀 Features
	•	Smart File Categorization → Documents, Images, Videos, Archives, Code, and more.
	•	AI-Powered OCR Screenshot Renaming (Vision Framework).
	•	Instant Undo with conflict-safe handling.
	•	Multi-threaded Performance for fast cleanup.
	•	Clutter Score & Historical Stats for gamification.
	•	Sparkle OTA Updates for smooth upgrades.
	•	Custom Desktop Layout Automation using AppleScript.

🛠 Tech Stack

Component	Technology
Language	Swift 5.10
macOS UI	AppKit
AI / OCR	Vision Framework
Auto Updates	Sparkle
Concurrency	GCD (Grand Central Dispatch)

📦 Installation

# Clone the repository
git clone https://github.com/Mikedan37/DesktopOrganizer.git

# Open in Xcode
open DesktopOrganizer.xcodeproj

# Build & Run (macOS 15+)

▶️ Usage
	•	Click Clean Desktop → Auto-organizes files into ~/Desktop/Organized/.
	•	Screenshots renamed using AI OCR or fallback timestamps.
	•	Generate DesktopReport.txt with cleanup metrics.
	•	Undo last action anytime.

📊 Example Report

====================================
      🖥  Desktop Clean Report
====================================

Date: 2025-08-02
Impact:
✔ Reduced clutter by 85%
✔ Freed up 1.3 GB
✔ Moved 147 files to Organized

Clutter Score: 18/100 [██████░░░░░░░░░░░░░░] (18% clean)

🔮 Roadmap
	•	Context-aware AI categorization
	•	Menu bar quick actions
	•	iCloud auto-sync support

📜 License

MIT License © 2025 Michael Danylchuk
	•	Shields for downloads
	•	Demo GIF placeholder
	•	Homebrew install instructions (future-proof)
