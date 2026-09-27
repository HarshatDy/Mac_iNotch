# Notcheee

A focus and productivity panel that lives in the MacBook notch. At rest it shows your next
reminder and running timers beside the notch; hover over it and it expands into a panel
with your day, a Pomodoro timer, reminders, an inbox, screen snips and the task you're
working on.

Built with SwiftUI + AppKit. Everything is stored locally on your Mac; the only outside data
source is Apple Calendar (read-only).

---

## Features

| Area | What it does |
|---|---|
| **Resting notch** | Two styles, chosen in Settings: **Short bar** (next reminder on the left, timer minutes + ring on the right) or **Progress outline** (the running timer traces the notch edge). |
| **Today** | Timeline from 7 AM to 11 PM with today's events from **Apple Calendar**, reminder dots and a now-line. Click the card to open Calendar. |
| **Focus** | Pomodoro: 4 × 25-minute focus cycles, 5-minute breaks, 15-minute long break. Start / Pause / Resume / Reset, and a Sound or Watch alert. A full-width alarm drops down when a session ends. |
| **Up Next** | Reminders typed in plain language, e.g. `Drink water 5pm`, `Pay fees in 40 min`, `Submit report on friday at 10:30am`. Hover a reminder to delete it. |
| **Inbox** | Quick capture for stray thoughts. Hover a row to turn it into a reminder or mark it done. |
| **Screen Snip** | Area / window / screen capture UI with a drag-to-select overlay and the four most recent snips. *(UI only for now — no pixels are captured yet.)* |
| **Working On** | Add tasks with a planned time (5–120 min). Click a task to start it; you get a macOS notification when the time runs out. While a task and a Pomodoro run together, the notch shows both timers as two layers — Pomodoro in orange/green, work in teal (yellow once time's up). |
| **Settings** | Right-click the notch, or click the gear in the expanded panel. |

Works on Macs without a notch too — it draws its own notch at the top centre of the screen.

---

## Requirements

- **macOS 26** or later (the deployment target is macOS 26.0)
- **Xcode 26** or later, to build
- No Apple Developer account is needed to build and run it on your own Mac

---

## Project layout

```
design_handoff_notch_widget/
├── NotchWidget/
│   ├── NotchWidget.xcodeproj        Xcode project (scheme: NotchWidget, product: Notcheee.app)
│   └── NotchWidget/
│       ├── NotchWidgetApp.swift     App entry point
│       ├── AppDelegate.swift        Launch, menu bar item, notification delegate
│       ├── NotchWindowController.swift  Transparent panel over the notch, hover + click handling
│       ├── NotchState.swift         All app state: timers, reminders, inbox, tasks, persistence
│       ├── NotchContainerView.swift Glass shell, resting bar, header, progress outline, grid
│       ├── Theme.swift              Design tokens + shared controls (buttons, rings, cards…)
│       ├── Formatting.swift         Natural-language reminder parser + date formatting
│       ├── CalendarService.swift    Apple Calendar (EventKit) access
│       ├── Alerts.swift             Break chime / haptics, "Working On" notifications
│       ├── SnipCapture.swift        Snip selection overlay and flash
│       ├── Cards/                   One file per panel card (DayStrip, Focus, Reminders, Inbox,
│       │                            Snips, Work, Alarm, Settings)
│       ├── Info.plist
│       └── NotchWidget.entitlements
├── mac-os-widgets/                  Design handoff (V2) the app is built from
└── docs/design-handoff-v1.md        Earlier (V1) design handoff, kept for reference
```

---

## Build

### Option A — Xcode

1. Open `NotchWidget/NotchWidget.xcodeproj`.
2. Select the **NotchWidget** scheme and **My Mac** as the destination.
3. *(Optional)* To build a release copy: **Product → Scheme → Edit Scheme… → Run → Build Configuration → Release**.
4. Press **⌘B** to build, or **⌘R** to build and run.
5. Find the app with **Product → Show Build Folder in Finder**, then open `Products/Release/Notcheee.app`
   (or `Products/Debug/` for a debug build).

### Option B — Terminal

From the repository root:

```bash
xcodebuild -project NotchWidget/NotchWidget.xcodeproj \
           -scheme NotchWidget \
           -configuration Release \
           -derivedDataPath build \
           build
```

The app is written to:

```
build/Build/Products/Release/Notcheee.app
```

> **Debug vs Release:** Debug builds add *Prototype controls* to the menu bar icon —
> "End current timer in 3s", "Start last task, ending in 6s", "Finish working-on task" —
> so you can test alarms and notifications without waiting. Release builds only have **Quit**.

---

## Install

1. Quit any running copy: click the timer icon in the menu bar → **Quit Notcheee**.
2. Copy the app into Applications:

   ```bash
   ditto build/Build/Products/Release/Notcheee.app /Applications/Notcheee.app
   ```

   (or drag `Notcheee.app` into `/Applications` in Finder).
3. Launch it:

   ```bash
   open /Applications/Notcheee.app
   ```

4. Allow the permission prompts:
   - **Calendar** — appears on first launch; needed for the Today timeline.
   - **Notifications** — appears the first time you start a *Working On* task.

   You can change either later in **System Settings → Privacy & Security → Calendars** and
   **System Settings → Notifications → Notcheee**.

Notcheee has no Dock icon or window. It lives in the notch, with a timer icon in the
menu bar for quitting.

### Start at login

**System Settings → General → Login Items & Extensions → Open at Login → +** → choose
`/Applications/Notcheee.app`.

### Update to a newer build

Quit Notcheee, rebuild, and run the `ditto` command again. Your data and permissions carry over.

---

## Using it

| Action | How |
|---|---|
| Expand the panel | Hover over the notch |
| Open Settings | Right-click the notch, or click the gear in the expanded panel |
| Add a reminder | Type in **Up Next** and press Return; the chip on the right shows the parsed time |
| Delete a reminder | Hover it in **Up Next** → ✕ |
| Start a task timer | **Working On** → **+** to add a task, then click its chip; **Done** to finish |
| Open Calendar | Click the **Today** card |
| Quit | Menu bar timer icon → **Quit Notcheee** |

The panel stays open while you're typing in a field, even if the pointer leaves it.

---

## Running it on another Mac

The app is **ad-hoc signed** (no Apple Developer ID), so it runs on the Mac that built it
without any warnings. The simplest way to use it on another Mac is to clone this repository
and build it there.

If you copy the built `Notcheee.app` to another Mac instead, macOS will block the first launch
because it comes from an unidentified developer. To open it anyway:

- **Finder:** try to open it once, then go to **System Settings → Privacy & Security** and
  click **Open Anyway** next to the Notcheee message; or
- **Terminal:** remove the quarantine flag, then open it:

  ```bash
  xattr -dr com.apple.quarantine /Applications/Notcheee.app
  open /Applications/Notcheee.app
  ```

---

## Uninstall

```bash
# 1. Quit the app
osascript -e 'quit app "Notcheee"'

# 2. Remove it
rm -rf /Applications/Notcheee.app

# 3. (Optional) Delete saved reminders, inbox, tasks and settings
defaults delete com.harshat.NotchWidget

# 4. (Optional) Reset the Calendar permission
tccutil reset Calendar com.harshat.NotchWidget
```

---

## Troubleshooting

| Problem | Fix |
|---|---|
| Today card says *Connect Apple Calendar* | Click it and allow access. |
| Today card says *Allow Calendar access in Settings* | Access was denied earlier. Click the link, turn on **Notcheee** under Calendars, then relaunch the app. |
| No notification when a task's time is up | Check **System Settings → Notifications → Notcheee** is allowed. |
| Nothing appears at the top of the screen | Make sure it's running (`pgrep -x Notcheee`); relaunch with `open /Applications/Notcheee.app`. |
| Build fails with a signing error | In Xcode, select the **NotchWidget** target → **Signing & Capabilities**, and choose **Sign to Run Locally** (or your personal team). |

---

## Notes

- Data (reminders, inbox, tasks, snip history, settings) is stored in the app's user defaults,
  domain `com.harshat.NotchWidget`. Nothing is sent anywhere.
- The Xcode project, scheme and source folder are still named `NotchWidget`; only the built
  app is called **Notcheee**. The bundle identifier `com.harshat.NotchWidget` is kept so
  existing permissions and data carry over.
- *Screen Snip* is interface only: snip thumbnails show the matching crop of your desktop
  wallpaper as a stand-in.
- The *Watch* break alert taps the Force Touch trackpad; macOS has no public API for
  Apple Watch haptics.
