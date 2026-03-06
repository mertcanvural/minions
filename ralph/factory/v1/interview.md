# Interview Log - Mission Control macOS App

## Round 1: Core Decisions (Fast-tracked)

**Q: Platform & Framework?**
A: macOS 15 Sequoia, SwiftUI, Swift 5.9+

**Q: Project structure?**
A: Swift Package (Package.swift, no .xcodeproj)

**Q: Architecture pattern?**
A: MVVM with @Observable macro, no external dependencies

**Q: Data strategy?**
A: Full UI with mock backend, structured for real API swap-in later

**Q: Window model?**
A: Multi-window (pop-out Blueprint & Audit Log) + Menu bar extra

## Round 2: Screen Details

**Q: Blueprint Viewer approach?**
A: Custom SwiftUI Canvas with full cinematic animations (particles, glows, animated data flow between nodes)

**Q: Audit Log data source?**
A: Toggle between real ~/.minion/audit/*.jsonl files and mock data

**Q: Settings screen scope?**
A: Bridge URL, API key, refresh intervals, theme toggle, audit path, terminal preference

**Q: Terminal integration?**
A: Auto-detect iTerm2 vs Terminal.app preference

**Q: Testing strategy?**
A: Unit tests for ViewModels + XCUITest for key navigation flows

**Q: Quick Launch feature?**
A: Full submission form with live complexity estimation display

**Q: Menu bar extra?**
A: Status indicator showing bridge connection status and active task count

## Round 3: Design System

**Q: Color scheme?**
A: Accent: Electric indigo (#6366F1). Dark mode primary, light mode support. Semantic colors: green=success, red=failure, blue=running, gray=pending, amber=warning

**Q: Typography?**
A: SF Pro for UI, SF Mono for code/logs

**Q: Card styling?**
A: 16pt rounded corners, subtle shadows, glass-morphism accents

**Q: Iconography?**
A: SF Symbols throughout

## Summary

All gaps filled. Fast-tracked through 3 rounds. Ready for spec generation.
