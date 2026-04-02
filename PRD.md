# Product Requirements Document: Sit Tracker

## Overview

**One-liner:** _Easily time spent sitting in various positions, including total time spent sitting_

**Problem statement:** _People with ME/CFS/Long Covid/POTS often struggle with not sitting enough, or sitting too much. This time can vary in different positions. Providers often ask patients to track time to optimize sitting time, but this is onerous and requires a lot of manual work._

**Target user:** _This is for ME/CFS/Long COVID/POTS patients working with an OT or PT_

---

## Sitting Buckets

The app tracks time across four buckets. Add any clarifications, constraints, or alternate names below each.

| Bucket | Notes |
|---|---|
| Supported sitting | _sitting with back and knees supported_ |
| Legs elevated | _sitting with legs above heart_ |
| Unsupported sitting | _sitting without back supported and without legs vertical - not just stools but also a kitchen chair, a desk chair, any "normal" chair_ |
| Total sitting | _derived from above- total time tracked across each tracked type of sitting_ |

**Can sessions overlap?** (e.g., can "legs elevated" also count toward "supported"?) _No- each type of sitting is independent of each other type. The only overlap is in total time sitting_

**What is the definition of a day?** A new day starts at 12:01 AM. If a timer rolls over between days, it is recorded and associated with the date the sitting started.

**When does the daily quota reset?** When a new day begins.

---

## Core User Flows

### Starting and stopping a session
_Each type of sitting has a dedicated timer with a start/stop button. The user starts a session by clicking the start/stop button next to the type of sitting they wish to track. They stop a session by clicking the start/stop button. Only one timer may be active at a time, so pressing "start/stop" on a currently inactive timer stops the active timer and runs the user through the save/edit flow for that timer before starting the new timer._

### Reviewing history
_After a session, the user wants to see an editable time with a "save" button. In addition, the UI should display the total time tracked that day in each of the buckets. At this time, reviewing past data from previous days is not necessary, but the data should be saved to enable future viewing/editing/reporting features._

### Editing or correcting entries
_When the user clicks the start/stop button to end a session, the time tracked in that session should be presented as an editable start time and stop time (defaults to when the start/stop button was clicked) plus an uneditable total time indicator_

### Adding a manually tracked session
_The user should also be able to enter a manually tracked session if they forgot to use the app to start a timer. This is a distinct flow that starts with clicking an "add manual session" button, and then prompts the user to enter the start time, stop time, type of sitting, and date for the session they want to track. If the manually entered session overlaps with a recorded session of the same sitting type, warn the user, and ask them if they want to discard the recorded session and replace it with the manual session, keep the recorded session and discard the manual session, or keep both (this records the earlier start time of the two sessions that overlap, and the later stop time of the two sessions that overlap). If the manually entered session overlaps with a recorded session of a different sitting type, tell the user we will save both._

---

## Goals and Success Metrics

**What does success look like for the user?**
_Success looks like building up tolerance for longer and more frequent sitting sessions_

**Are there targets or quotas?**
_There are not targets but there should be an editable and optional quota. This could be displayed as "Remaining sitting time" in the UI. For now, let's assume this is only a quote of total time, not a quota for each type of sitting. For now, we will ignore the use case of a minimum amount of setting- making sure a user doesn't exceed their maximum is the primary use case, so let's not distract from that._

**How will the user know they're making progress?**
_The app should present a bar chart of the last 7 days with one bar for total time sitting on that day, and a second bar with with the total time sitting quota. This can be behind a "how I'm doing" prompt. In addition, a rolling 7-day average of total sitting time should be presented on the main screen of the app._

---

## Notifications and Reminders

_If HealthKit provides any kind of hook when a user appears to be sitting, we should present the user a notification at that time to ask if sitting has started. Clicking the notification should bring one to timer selection. The implementation plan should include a technical spike to determine whether this is feasible_

_The user should be able to set two optional reminders:_
* _minutes between sitting sessions- if there is no active timer, and the last timer was stopped more than the value of this setting minutes ago, notify the user "You've gone \<value of this setting\> minutes without sitting"_
* _maximum duration of a sitting session- the user should be able to set this value as a number of minutes, and get a reminder if a timer has been running for more than that number of minutes_


---

## Data and Privacy

**Where is data stored?** _on-device only. The export needs define what data needs to be stored._

**Does anyone else need to see this data?** _this data will be shared with clinicians via email_

**Export needs?** _email a CSV of all data to a clinician. each row of the CSV represents a sitting session. Columns are date, start time, stop time, type of sitting, and # of minutes._

---

## Platform and Device

**Minimum iOS version:** _iOS 17 and 18_

**iPhone only, or iPad too?** _iPhone only_

**Apple Watch support?** _not needed_

**Runs in background / with screen off?** _yes, the timer should continue until stopped, even if the phone screen is turned off or the app is sent to the background_

---

## Out of Scope (for v1)

_Any kind of data visualation other than the simple bar chart discussed above is out of scope. Configuring or adding different types of activity is out of scope._

---

## Open Questions

_List anything you haven't decided yet._

1. Should we track medication in the same app/UI? Medication could correlate with sitting quality. (Decision- this is in scope for v2)
2. Should we track other activities? (Decision- this is in scope for v2)
