⸻



<p align="center">
<b>Organize your macOS Desktop like a pro — AI-powered cleanup, OCR screenshot renaming, and instant reports.</b>
</p>



⸻


<p align="center">
  <a href="https://github.com/Mikedan37/DesktopOrganizer/stargazers">
    <img src="https://img.shields.io/github/stars/Mikedan37/DesktopOrganizer?style=flat-square&logo=github" alt="Stars" />
  </a>
  <a href="https://github.com/Mikedan37/DesktopOrganizer/network/members">
    <img src="https://img.shields.io/github/forks/Mikedan37/DesktopOrganizer?style=flat-square&logo=github" alt="Forks" />
  </a>
  <a href="https://github.com/Mikedan37/DesktopOrganizer/issues">
    <img src="https://img.shields.io/github/issues/Mikedan37/DesktopOrganizer?style=flat-square&logo=github" alt="Issues" />
  </a>
  <a href="https://github.com/Mikedan37/DesktopOrganizer/pulls">
    <img src="https://img.shields.io/github/issues-pr/Mikedan37/DesktopOrganizer?style=flat-square&logo=github" alt="PRs" />
  </a>
  <img src="https://img.shields.io/badge/Swift-5.10-orange?logo=swift&style=flat-square" alt="Swift" />
  <img src="https://img.shields.io/badge/macOS-15%2B-black?logo=apple&style=flat-square" alt="macOS" />
  <img src="https://img.shields.io/badge/Build-Xcode_15-lightblue?logo=xcode&style=flat-square" alt="Xcode" />
</p>



⸻

📖 Table of Contents
	•	Overview
	•	Features
	•	Tech Stack
	•	Installation
	•	Usage
	•	Example Report
	•	Roadmap
	•	License

⸻

Overview

DesktopOrganizer is a macOS utility that uses AI OCR, multithreading, and automation to keep your desktop spotless. It renames screenshots intelligently, organizes files by type, and gives you a detailed cleanup report with clutter metrics.

⸻

Features

✔ Smart file categorization into Documents, Images, Videos, Archives, Code, and more.
✔ AI-powered OCR screenshot renaming (Vision Framework).
✔ Instant Undo with conflict handling.
✔ Performance-first multi-threaded design.
✔ Gamified Clutter Score and historical stats.
✔ Sparkle-based OTA updates.
✔ Custom Desktop icon layout automation.

⸻

Tech Stack

Component	Technology
Language	Swift 5.10
macOS UI	AppKit
AI / OCR	Vision Framework
Auto Updates	Sparkle
Concurrency	GCD


⸻

Installation

# Clone the repository
git clone https://github.com/Mikedan37/DesktopOrganizer.git

# Open in Xcode
open DesktopOrganizer.xcodeproj

# Build & run (macOS 15+)


⸻

Usage
	•	Click Clean Desktop → Auto-organizes files into ~/Desktop/Organized/
	•	Screenshots renamed using AI OCR or fallback timestamps
	•	Generate DesktopReport.txt with cleanup metrics
	•	Undo last action anytime

⸻

Example Report

====================================
      Desktop Clean Report
====================================

Date: 2025-08-02
Impact:
✔ Reduced clutter by 85%
✔ Freed up 1.3 GB
✔ Moved 147 files to Organized

Clutter Score: 18/100
[██████████░░░░░░░░░░] (18% clean)


⸻

Roadmap
	•	Context-aware AI categorization
	•	Menu bar quick actions
	•	iCloud auto-sync support

⸻

License

MIT License © 2025 Michael Danylchuk

⸻
