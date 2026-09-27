# Handoff: macOS 26 Notch Widget

## Overview

An interactive widget system that lives in the MacBook camera notch area. When the user hovers over the notch, it expands to reveal a row of live system widgets — Spotify now-playing, battery, clock, weather, Wi-Fi, CPU, RAM, volume, notifications, Focus mode, and microphone. The design follows the macOS 26 "Liquid Glass" visual language: heavy backdrop blur, frosted translucent surfaces, specular edge highlights, and smooth non-bouncy transitions.

---

## About the Design Files

The files in this bundle are **high-fidelity design references built in HTML/React**. They are prototypes demonstrating exact intended look, layout, and behavior — **not production code to copy directly**.

Your task is to **recreate these designs in your target environment** — whether that is a macOS native app (Swift/SwiftUI), an Electron shell, a browser extension, or a web app — using its established patterns, libraries, and system APIs. The HTML prototype is the visual and behavioral spec.

---

## Fidelity

**High-fidelity.** Colors, typography, spacing, corner radii, animations, and interactions are all final. Implement pixel-perfectly against the specs below.

---

## Screens / Views

### 1. Collapsed (Resting) State

The notch sits at the very top-center of the screen, flush with the menu bar.

| Property | Value |
|---|---|
| Width | 158px |
| Height | 30px |
| Border radius | `0 0 16px 16px` (bottom corners only) |
| Background | `rgba(255,255,255,0.07)` |
| Backdrop filter | `blur(56px) saturate(2.4) brightness(1.08)` |
| Top border | none (flush with screen top) |
| Side/bottom border | `1px solid rgba(255,255,255,0.20)` |
| Top inner highlight | `inset 0 1px 0 rgba(255,255,255,0.26)` |
| Drop shadow | `0 24px 64px rgba(0,0,0,0.50), 0 4px 14px rgba(0,0,0,0.30)` |

**Contents:** 4–6 small colored dots (4.5×4.5px, opacity 0.7), one per enabled widget, centered in a row with 5px gap.

Dot colors:
- Spotify: `#1DB954`
- Battery: `#30D158`
- Clock: `rgba(255,255,255,0.5)`
- Weather: `#FF9F0A`
- Wi-Fi: `#0A84FF`
- CPU/RAM: `#64B4FF`
- Notifications: `#FF453A`
- Focus/DND: `#FF9F0A`
- Mic: `#30D158`

---

### 2. Hover Compact State

Triggered on `mouseenter`. Pill widens slightly to show a one-line summary.

| Property | Value |
|---|---|
| Width | 192px |
| Height | 36px |
| Border radius | `0 0 18px 18px` |
| Transition | `width 0.35s cubic-bezier(0.4,0,0.2,1)`, `height 0.32s cubic-bezier(0.4,0,0.2,1)` — **no bounce/spring** |

**Contents (flex row, 7px gap, 12px horizontal padding):**
- If Spotify enabled: Spotify logo (11×11px SVG) + song title (10.5px, weight 500, `rgba(255,255,255,0.82)`, truncated)
- If Battery enabled: percentage (10.5px, weight 600, `#30D158`)
- If Clock enabled: `HH:MM` (10.5px, weight 500, `rgba(255,255,255,0.55)`, tabular nums)

---

### 3. Expanded Widget View

Triggered ~90ms after hover begins. Full content row.

| Property | Value |
|---|---|
| Width | Calculated: sum of all enabled widget widths + dividers + 40px padding. Capped at `min(900, window.innerWidth - 80)`. |
| Height | 160px |
| Border radius | `0 0 24px 24px` |
| Transition | Same smooth cubic-bezier as hover state |
| Content padding | `0 14px` |
| Overflow | **Hidden — no scroll.** Widgets auto-scale down proportionally via `transform: scale(factor)` if total width exceeds available space. |

**Widget widths (full size):**

| Widget | Width |
|---|---|
| Spotify | 228px |
| Battery | 130px |
| Clock | 90px |
| Weather | 118px |
| Wi-Fi | 120px |
| CPU | 100px |
| RAM | 100px |
| Volume | 100px |
| Notifications | 186px |
| Focus/DND | 110px |
| Mic | 96px |

Widgets are separated by **1px vertical dividers** (`rgba(255,255,255,0.09)`), with `14px` padding on each side. A small **gear icon button** (20×20px) sits at the far right to enter configure mode.

**Entry animation:** `fadeUp` — `opacity: 0 → 1`, `translateY: 4px → 0`, `0.22s ease`.

**Dismiss:** `mouseleave` with 280ms delay. If `configuring` is true, do not auto-dismiss.

---

### 4. Configure Mode

Triggered by **right-click** on the notch (or gear icon, or Tweaks toggle).

| Property | Value |
|---|---|
| Width | `min(900, 520)` = 520px |
| Height | 190px |
| Border radius | `0 0 22px 22px` |

**Layout (flex column, 8px gap, padding `12px 16px 10px`):**

**Row 1 — Header:**
- Back arrow button (22×22px circle, `rgba(255,255,255,0.08)` bg, `1px solid rgba(255,255,255,0.16)` border). Clicking returns to expanded widget view.
- Label "Widgets" (11.5px, weight 600, `rgba(255,255,255,0.75)`)
- Right side: "Accent" label (9px, `rgba(255,255,255,0.28)`) + 5 color dot pickers (14×14px circles). **Accent tint is only visible/changeable here.**

**Row 2 — Widget chips (flex wrap, 5px gap):**
Each enabled widget shows as a pill chip:
- Padding: `5px 9px`
- Border radius: `20px` (pill shape)
- ON state: `rgba(255,255,255,0.14)` bg, `1px solid rgba(255,255,255,0.24)` border, white text `rgba(255,255,255,0.88)`, green dot `#30D158`
- OFF state: `rgba(255,255,255,0.05)` bg, `1px solid rgba(255,255,255,0.09)` border, dim text `rgba(255,255,255,0.35)`
- Icon (11px) + label (10.5px, weight 500) + status dot (5px) if on
- Transition: `all 0.16s ease`
- Clicking toggles that widget on/off immediately

**Row 3 — Footer hint:**
"Right-click notch anytime to return here" (9px, `rgba(255,255,255,0.18)`, centered)

---

## Individual Widget Specs

### Spotify Widget (228px wide)

**Top row (flex, 9px gap):**
- Album art: 46×46px, border-radius 10px, gradient placeholder using track accent color, `1px solid rgba(255,255,255,0.13)`, box-shadow `0 4px 14px {color}44`
- Track info: title 12.5px/weight 600/`rgba(255,255,255,0.94)`, artist 10.5px/`rgba(255,255,255,0.46)`, both truncated
- Visualizer bars: 5 bars, 3px wide, border-radius 2px, staggered animation `vizBar` at different speeds when playing

**Progress bar:** 2.5px height, track accent color fill, `rgba(255,255,255,0.10)` track

**Controls row:**
- Time elapsed (left) + time total (right): 9.5px, `rgba(255,255,255,0.30)`, tabular nums
- Prev/Play/Next buttons centered
  - Prev/Next: 22×22px glass circles
  - Play/Pause: 30×30px glass circle (accent = `rgba(255,255,255,0.16)` bg)
  - Hover: background brightens, `scale(1.06)`

### Battery Widget (130px wide)

- SVG battery icon (28×14px) + large % number (20px/weight 700) in status color
- Status colors: `#30D158` (≥50%), `#FF9F0A` (20–49%), `#FF453A` (<20%), `#30D158` (charging)
- Subtitle: "4h 23m left" or "⚡ Charging", 9.5px, `rgba(255,255,255,0.36)`
- 10-segment bar: each segment `flex:1`, height 5px, border-radius 2.5px, filled with status color or `rgba(255,255,255,0.09)`

### Clock Widget (90px wide)

- Analog clock SVG: 60×60px circle
  - Face: `rgba(255,255,255,0.04)` fill, `rgba(255,255,255,0.10)` stroke
  - 12 tick marks: major (every 3) at strokeWidth 1.2, minor at 0.6
  - Hour hand: length 15, strokeWidth 2.2, `rgba(255,255,255,0.90)`
  - Minute hand: length 20, strokeWidth 1.6, `rgba(255,255,255,0.78)`
  - Second hand: length 22, strokeWidth 0.9, `#FF453A`
  - Center dot: radius 1.8, `rgba(255,255,255,0.9)`
- Digital time below: 12.5px/weight 600/`rgba(255,255,255,0.88)`
- Date below: 9.5px/`rgba(255,255,255,0.36)`

### Weather Widget (118px wide)

- Large weather emoji (32px, drop-shadow)
- Temperature: 24px/weight 700/`rgba(255,255,255,0.93)`
- Condition + city: 9.5px/`rgba(255,255,255,0.38)`
- 5-day mini forecast row: day initial, emoji, temp (8.5px each)

### Wi-Fi Widget (120px wide)

- Icon container: 34×34px, border-radius 9px, `rgba(10,132,255,0.18)` bg, `rgba(10,132,255,0.30)` border
- SSID: 11.5px/weight 600
- "Connected" label: `#0A84FF`
- Stats row: Download ↓ / Upload ↑ / Ping — 9.5px each

### CPU Widget (100px wide)

- Large % value (20px/weight 700) + "CPU" label
- Live sparkline graph (80×40px SVG): blue line `rgba(100,180,255,0.70)` with gradient fill
- Updates every ~1.8s with simulated data
- "Peak X% · M3 Pro" footnote

### RAM Widget (100px wide)

- Used GB (20px/weight 700) + "RAM" label
- Single progress bar (height 6px)
- Color: `rgba(100,180,255,0.85)` normal, `#FF9F0A` >65%, `#FF453A` >85%
- Total/free footnote

### Volume Widget (100px wide)

- Volume % (20px/weight 700) + "Volume" label
- 12 vertical bars: stepped heights 30–100%, filled `rgba(255,255,255,0.70)` or dim `rgba(255,255,255,0.10)`
- Range slider (native HTML input) below

### Notifications Widget (186px wide)

- Header: "Notifications" (11px/weight 600) + count
- 3 notification rows: colored dot + app name (10px/weight 600) + message (9.5px truncated) + time (9px)

### Focus / DND Widget (110px wide)

- "Focus" label + status subtitle (`#FF9F0A` when on)
- Toggle button: 32×32px rounded square, moon/bell emoji
- When on: 3 duration chips ("1 hour", "Tonight", "All Day") — selected chip uses `rgba(255,159,10,0.28)` bg

### Microphone Widget (96px wide)

- "Mic" label + "Active"/"Muted" status (`#30D158` when active)
- 32×32px mic icon button with pulse animation when active
- Level bar (height 4px): `#30D158` fill, updates at 150ms intervals

---

## Interactions & Behavior

| Trigger | Action |
|---|---|
| `mouseenter` notch | After 90ms, expand to full widget view |
| `mouseleave` notch | After 280ms, collapse. Cancelled if configuring. |
| `contextmenu` (right-click) | Open configure mode immediately |
| Click gear icon | Open configure mode |
| Click back arrow | Return to expanded widget view |
| Click widget chip | Toggle that widget on/off |
| Click outside (optional) | Collapse if expanded |

### Transition Spec

All size transitions use: `cubic-bezier(0.4, 0, 0.2, 1)` — smooth ease-in-out, **no spring/bounce**.

- Width: `0.35s`
- Height: `0.32s`
- Border-radius: `0.28s ease`

---

## Ambient Glow

A `radial-gradient` ellipse sits just below the notch, using the selected accent color. It blurs via `filter: blur(6px)`. Opacity is 0.15 collapsed, 0.35 expanded.

---

## Design Tokens

### Glass Surface
```
background:       rgba(255,255,255,0.07)
backdrop-filter:  blur(56px) saturate(2.4) brightness(1.08)
border:           1px solid rgba(255,255,255,0.20)
inner top shine:  inset 0 1px 0 rgba(255,255,255,0.26)
drop shadow:      0 24px 64px rgba(0,0,0,0.50), 0 4px 14px rgba(0,0,0,0.30)
```

### Typography
```
Font stack:  -apple-system, 'Inter', BlinkMacSystemFont, 'Helvetica Neue', sans-serif
Antialiasing: -webkit-font-smoothing: antialiased
```

### Status Colors
```
Green  (ok/active):  #30D158
Amber  (warning):    #FF9F0A
Red    (critical):   #FF453A
Blue   (info):       #0A84FF
Spotify green:       #1DB954
```

### Accent Tints (glow + ambient only, not in main UI)
```
blue:   oklch(0.68 0.18 240)
purple: oklch(0.68 0.18 300)
green:  oklch(0.72 0.18 145)
rose:   oklch(0.68 0.18 340)
amber:  oklch(0.78 0.16 65)
```

### Text Hierarchy
```
Primary:    rgba(255,255,255,0.94)
Secondary:  rgba(255,255,255,0.70)
Tertiary:   rgba(255,255,255,0.40)
Muted:      rgba(255,255,255,0.26)
Ghost:      rgba(255,255,255,0.16)
```

### Spacing
```
Widget padding horizontal:  14px each side
Divider between widgets:    1px
Widget internal gap:        7–10px
Notch outer padding:        14px left/right
```

---

## State Management

```ts
// Global app state
tweaks: {
  enabled_spotify:       boolean  // default: true
  enabled_battery:       boolean  // default: true
  enabled_clock:         boolean  // default: true
  enabled_weather:       boolean  // default: true
  enabled_wifi:          boolean  // default: false
  enabled_cpu:           boolean  // default: false
  enabled_ram:           boolean  // default: false
  enabled_volume:        boolean  // default: false
  enabled_notifications: boolean  // default: false
  enabled_dnd:           boolean  // default: false
  enabled_mic:           boolean  // default: false
  accentTint:            string   // 'blue' | 'purple' | 'green' | 'rose' | 'amber'
  blurStrength:          number   // default: 56
}

// Notch UI state
expanded:    boolean
configuring: boolean
hovered:     boolean

// Widget runtime state
playing:     boolean   // Spotify play/pause
trackIdx:    number    // current track index
volume:      number    // 0–100
dnd:         boolean   // Focus mode on/off
micActive:   boolean   // microphone active
now:         Date      // ticks every 1s for clock
cpuHistory:  number[]  // rolling 16-point history, updates every 1.8s
```

Persist `tweaks` to `localStorage` key `notch_tweaks_v2`.

---

## Data Sources (Production)

Replace mock data with real system APIs:

| Widget | macOS API |
|---|---|
| Spotify | Spotify Connect API / AppleScript `tell app "Spotify"` |
| Battery | `IOKit` framework / `pmset` |
| Clock | System clock |
| Weather | WeatherKit / OpenMeteo |
| Wi-Fi | `CoreWLAN` framework |
| CPU | `host_statistics64` / `top` |
| RAM | `vm_statistics64` |
| Volume | `CoreAudio` / `osascript` |
| Notifications | `UNUserNotificationCenter` |
| Focus | `Focus` framework / `moonPhase` status |
| Mic | `AVFoundation` |

---

## Assets

- **Spotify icon**: Inline SVG (included in HTML file)
- **All other icons**: Inline SVG drawn in code — no external assets required
- **Wallpaper**: CSS `radial-gradient` + `linear-gradient` layers with `animation` — no image file

---

## Files in This Package

| File | Purpose |
|---|---|
| `Notch Widget.html` | Full hi-fi interactive prototype (React/Babel, self-contained) |
| `screenshots/01-collapsed.png` | Notch in resting state |
| `screenshots/02-expanded.png` | Notch expanded showing widgets |
| `README.md` | This document |

---

## Implementation Notes for Claude Code

1. **Framework**: For a real macOS app, use **SwiftUI** with `NSStatusItem` or a custom `NSWindow` positioned at the notch frame. For Electron/web shell, an `<iframe>` or frameless window overlay works.

2. **Positioning**: The notch is at `x: (screenWidth - notchWidth) / 2`, `y: 0`. On MacBook Pro 14"/16" the hardware notch is ~160px wide and ~32px tall — match the collapsed state exactly.

3. **Backdrop blur**: On macOS native, use `NSVisualEffectView` with `.behindWindow` blending mode and `.hudWindow` material. In web/Electron, `backdrop-filter: blur()` requires a transparent window with `hasShadow: false` and `vibrancy` set.

4. **Right-click**: Use `NSMenu` or intercept `contextmenu` event. Should open configure mode inline (expand + slide to config view), not a separate popover.

5. **No scroll**: The widget row must never scroll. Compute total natural width at render time; if it exceeds available space, apply a uniform `scale()` transform to all widgets together.

6. **Persistence**: Save enabled widget state and accent tint to `UserDefaults` (native) or `localStorage` (web).
