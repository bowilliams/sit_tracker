# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build, test, and run commands

Regenerate the Xcode project after adding or removing files (`.xcodeproj` is gitignored):
```
xcodegen generate
```

Run the full test suite (no code signing required):
```
xcodebuild test \
  -project SitTracker.xcodeproj \
  -scheme SitTracker \
  -destination "platform=iOS Simulator,name=iPhone 17" \
  CODE_SIGNING_ALLOWED=NO
```

Run a single test class:
```
xcodebuild test \
  -project SitTracker.xcodeproj \
  -scheme SitTracker \
  -destination "platform=iOS Simulator,name=iPhone 17" \
  -only-testing SitTrackerTests/TimerManagerTests \
  CODE_SIGNING_ALLOWED=NO
```

Run a single test method:
```
-only-testing SitTrackerTests/TimerManagerTests/testTimerSwitch_afterSave_startsNewSession
```

Build for device (requires signing):
Open `SitTracker.xcodeproj` in Xcode, set a Development Team under Signing & Capabilities, then build.

## Architecture

**Stack:** SwiftUI · SwiftData · Swift Charts (Phase 4+) · Combine · iOS 17+, iPhone only

**Data model** (`SitTracker/Models/`):
- `Session` — SwiftData `@Model`. One row per sitting session. Fields: `id`, `startTime`, `stopTime` (nil while active), `type`, `date` (start-of-day for midnight rollover).
- `SittingType` — enum with stable raw values (`supported`, `legs_elevated`, `unsupported`) and separate `displayName`. Raw values are persisted; never change them without a migration.
- Aggregation helpers live as extensions on `[Session]`: `totalMinutes(for:)`, `totalMinutes`, `sessions(on:)`, `rollingAverage(days:endingOn:)`.

**Timer state** (`SitTracker/TimerManager.swift`):
- `@Observable` class injected into the SwiftUI environment via `RootView`.
- Owns the active session, 1-second tick (Combine `Timer.publish`), background restore on app relaunch, and the single-active-timer enforcement (pending start type queued across the save/discard sheet).
- `sessionToSave: Session?` drives sheet presentation from `ContentView`.

**App entry** (`SitTracker/SitTrackerApp.swift`):
- Explicitly creates `Library/Application Support/SitTracker/` before initializing the SwiftData container (iOS does not guarantee this directory exists on first launch).
- `RootView` bridges the `ModelContext` from the SwiftData environment into `TimerManager`, then injects `TimerManager` into the environment for all child views.

**Views** (`SitTracker/Views/`):
- `SessionTimerRow` — one row per sitting type: display name, daily total, live elapsed (H:MM), play/stop button.
- `StopSessionSheet` — presented after stopping a timer: editable start/stop pickers, computed total (read-only), Save / Discard actions. `interactiveDismissDisabled` forces an explicit choice.

**Daily totals** are computed from completed sessions (`stopTime != nil`) for the current calendar day. The active session's time is displayed separately in its row as live elapsed.
