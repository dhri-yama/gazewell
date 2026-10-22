# open-lookaway

An open-source macOS menu bar app that reminds you to rest your eyes, fix your posture and blink, timed around natural pauses. A SwiftUI take on [LookAway](https://lookaway.com); not affiliated with it.

## Features
- 20-20-20 style screen breaks with long breaks, a heads-up card (+1m / +5m / +15m) and a cursor-following countdown
- Break enforcement (casual, balanced, hardcore), daily snooze limit, double-Esc action, optional auto-lock
- Smart pause: skips breaks during calls (mic or camera in use), delays for screen recording, video and fullscreen apps; time away counts as a break
- Office hours and planned breaks (e.g. lunch)
- Animated wellness reminders (posture, blink, hydration, stretch) over a blurred screen
- Themes, wallpaper or custom image, custom messages, per-role fonts, sounds with volume
- Stats, global shortcuts, Shortcuts/AppleScript hooks, launch at login

## Build
Requires macOS 13+ and the Swift toolchain (Command Line Tools are enough).

```sh
./bundle.sh && open LookAway.app   # build and run
./test.sh                          # scheduler tests
```

Global shortcuts: ⌃⌥B start a break, ⌃⌥S skip next, ⌃⌥P turn breaks off/on.

The app is ad-hoc signed, not notarized: on first launch right-click → Open.
