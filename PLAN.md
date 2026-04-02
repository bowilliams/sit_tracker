# Sit Tracker — Implementation Plan

## Prerequisites

Before any code is written:

1. **Xcode** — Install Xcode 16+ (required for iOS 17/18 target and SwiftData).
2. **Apple Developer account** — Required for on-device testing of background timers and local notifications. These features do not work reliably in the simulator.
3. **Resolve PRD open question #3** — The open questions list still has a blank item. Confirm nothing is undecided.
4. **Device for testing** — A physical iPhone is needed from Phase 2 onward due to background execution requirements.

---

## Architecture Decisions (made upfront, not mid-build)

| Concern | Decision | Rationale |
|---|---|---|
| UI framework | SwiftUI | Native, modern, iOS 17+ |
| Persistence | SwiftData | Native ORM for iOS 17+, replaces CoreData boilerplate |
| Background timer | Store `startTime` as a `Date`, compute elapsed on resume | Avoids background process limits; survives app kill |
| Notifications | `UNUserNotificationCenter` | Standard local notifications |
| CSV export | `ShareLink` + `MFMailComposeViewController` | Email share sheet |
| Bar chart | Swift Charts (native, iOS 16+) | No third-party dependency |

---

## Data Model

One entity, defined before Phase 1 begins:

```
Session
  id:        UUID
  startTime: Date
  stopTime:  Date?        // nil while active
  type:      SittingType  // enum: supported, legsElevated, unsupported
  date:      Date         // date sitting started (for midnight rollover)
```

`SittingType` is an enum. Total sitting is always derived — never stored.

Settings (stored in `UserDefaults`, not SwiftData):
- `dailyQuotaMinutes: Int?` (nil = no quota)
- `reminderGapMinutes: Int?`
- `reminderMaxDurationMinutes: Int?`

---

## Phases

Each phase ends with a reviewable, installable build on a real device.

---

### Phase 1 — Project scaffold and data layer
**Goal:** App launches, data model is wired up, nothing crashes.

Tasks:
- Create Xcode project (SwiftUI, SwiftData, iOS 17 deployment target)
- Define `Session` model and `SittingType` enum
- Configure SwiftData container
- Stub main screen with placeholder UI (three labeled rows, no functionality)
- Write unit tests for computed properties: session duration in minutes, daily total per type, rolling 7-day average

**Review checkpoint:** App launches on device. Unit tests pass. No user-facing functionality yet.

---

### Phase 2 — Core timer: start, stop, save
**Goal:** A user can time a sitting session end-to-end and see it saved.

Tasks:
- Implement start/stop button for each of the three sitting types
- Enforce single active timer: tapping an inactive timer's button while another is running first stops the active timer, then opens the save/edit sheet, then starts the new timer
- Running timer displays live elapsed time (HH:MM), updating every second via a `Timer` publisher
- Background persistence: on start, write `Session` with `stopTime = nil` to SwiftData; on stop, set `stopTime`; on app foreground, recompute elapsed from stored `startTime`
- Stop flow presents a sheet: editable start time, editable stop time (both default to actual values), uneditable computed total
- "Save" commits the session; "Discard" deletes it
- Daily totals per bucket displayed on main screen (summed from saved sessions for today)

**Testing:**
- Unit test: timer switch flow correctly saves the first session before starting the second
- Unit test: background resume computes correct elapsed time
- Manual test on device: lock phone mid-session, unlock, confirm timer is still correct
- Manual test: kill and relaunch app mid-session, confirm session survives

**Review checkpoint:** Full timer loop works on device. Sessions persist across app restarts. Daily totals update correctly.

---

### Phase 3 — Manual session entry and overlap handling
**Goal:** A user can log a session they forgot to track.

Tasks:
- "Add manual session" button on main screen
- Entry form: date picker, start time, stop time, sitting type; computed total shown inline
- Validate stop time is after start time
- Overlap detection against existing sessions for the same day
- Overlap resolution UI (same type: replace / keep recorded / merge; different type: save both, no prompt)
- Unit tests for all overlap cases: no overlap, partial overlap same type (3 resolution paths), partial overlap different type, full containment

**Testing:**
- Unit test: all overlap detection and resolution scenarios
- Manual test: enter a session that overlaps a timer-tracked session of the same type, exercise all three resolution options

**Review checkpoint:** Manual entry works. Overlap logic is correct and tested. App is now fully usable as a manual log even without the timer.

---

### Phase 4 — Quota and 7-day progress signals
**Goal:** User can see how they're doing against their quota.

Tasks:
- Settings screen (reachable from main screen): daily quota input (optional HH:MM field, clear to disable)
- "Remaining today" display on main screen — total quota minus today's total sitting; hidden if no quota set; turns a warning color if quota is exceeded
- Rolling 7-day average of total sitting time displayed on main screen
- "How I'm doing" button that presents the 7-day bar chart (Swift Charts): one bar per day showing total sitting, a reference line or secondary bar for the daily quota (hidden if no quota set)

**Testing:**
- Unit tests: remaining quota calculation (with quota, without quota, over quota), 7-day average
- Manual test: set quota, run sessions over multiple days (adjust device date), confirm chart and average update correctly

**Review checkpoint:** Progress signals are live. The app now surfaces meaningful information to the user, not just raw totals.

---

### Phase 5 — Notifications and reminders
**Goal:** App proactively prompts the user at the right times.

Tasks:
- Request `UNUserNotificationCenter` authorization on first launch
- Settings screen additions: gap reminder (minutes, optional), max duration reminder (minutes, optional)
- Gap reminder: schedule a local notification when a timer stops; cancel it if a new timer starts within the window
- Max duration reminder: schedule a local notification when a timer starts; cancel it when the timer stops
- Both notifications deep-link back into the app (standard foreground behavior is sufficient)

**Testing:**
- Manual test on device: set a 1-minute gap reminder, stop a timer, wait, confirm notification fires; start a new timer before 1 minute, confirm notification is cancelled
- Manual test: set a 1-minute max duration reminder, start a timer, confirm notification fires at 1 minute, stop timer, confirm no second notification

**Review checkpoint:** Both reminders work on device. No spurious notifications.

---

### Phase 6 — CSV export
**Goal:** User can share all session data with a clinician via email.

Tasks:
- "Export" button in settings screen
- Generate CSV: one row per session, columns: date, start time, stop time, type, minutes
- Present iOS share sheet pre-populated with the CSV as an attachment; user selects Mail or any other share target
- All sessions exported (no date filtering in v1)

**Testing:**
- Unit test: CSV output is correctly formatted for a known set of sessions (spot-check escaping, column order, header row)
- Manual test: export from device, open email, verify CSV is readable and complete

**Review checkpoint:** Clinician-ready export works. This completes all core PRD features.

---

### Phase 7 — HealthKit sitting detection (spike)
**Goal:** Determine whether HealthKit can reliably trigger a "are you sitting?" prompt.

This is a time-boxed technical spike, not a full feature build. Time-box to one session.

Spike tasks:
- Add HealthKit entitlement and request authorization for activity/mobility data
- Investigate `HKWorkout`, `CMMotionActivityManager`, and `HKCategoryTypeIdentifier` for any event that fires when a user transitions to sitting
- Test on a real device: does any HealthKit or CoreMotion API deliver a timely, reliable signal when sitting begins?

**Decision gate:** If a reliable signal exists and can trigger a local notification within ~60 seconds of sitting down, implement it. If not, document the finding and drop the feature from v1 with a note for v2.

---

## Testing Summary

| Layer | When | What |
|---|---|---|
| Unit tests | Written alongside each phase | Time math, overlap logic, aggregations, CSV formatting |
| Manual device tests | End of each phase | Background behavior, notifications, UI flows |
| Regression | Before each new phase begins | Run full unit test suite; smoke-test prior phase on device |

---

## Build Order Rationale

The phases are ordered so that each one delivers a usable app:

- After Phase 2: usable as a timer
- After Phase 3: usable as a complete log (timer + manual)
- After Phase 4: gives the user meaningful feedback
- After Phase 5: proactive and self-managing
- After Phase 6: clinician-ready and shippable
- Phase 7: enhancement, not a blocker

If time is short, Phases 1–3 + Phase 6 are the minimum viable app.
