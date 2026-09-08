# Design direction (shape brief)

Mode: Operate (settings, menu, heads-up) + one Experience-like moment (break overlay).

## World: "Dusk window"
The break overlay is a soft twilight sky you look out of: deep indigo fading to warm peach at the horizon, slow-drifting, grain-free. Settings and menu stay calmer and more neutral so the overlay is the one expressive moment.

## Break overlay (focal moment)
- Full screen on every display, fades in 400ms (instant under Reduce Motion).
- Centered: breathing ring (4s in / 4s out), inside it the remaining seconds in SF Rounded, huge, light weight. Above the ring: break type label (small caps). Below: one custom message line.
- Bottom center: quiet "Skip" text button (Esc also skips). No other chrome.
- Background: gradient by default; user image/wallpaper gets a dark scrim so text passes 4.5:1.

## Heads-up panel
Small rounded card, top-right, vibrancy material. Title "Break in 30s", primary "Start now", secondary menu "Later: 1 / 5 / 15 min". Auto-dismisses into the break. Cursor-following countdown is a tiny pill, 60% opacity.

## Menu bar
Template icon (eye). Title shows time-to-next break only when enabled. Menu: status line, Start break now, Skip next, Pause for…, Settings…, Quit.

## Settings
Standard macOS Settings tabs (Breaks, Planned, Smart Pause, Appearance, Automation, General). Native controls; brand shows only as the accent colour and previews of the overlay.

## Tokens (Theme.swift)
- Ink indigo #1B1B3A, dusk violet #4A3F8F, horizon peach #FFB88C, glow #FFE3CF, accent coral #FF7A59.
- Type: countdown `.system(size: 160, weight: .ultraLight, design: .rounded)`; label `.caption` uppercase tracking; message `.title3`.
- Spacing scale 4/8/12/16/24/40. Radii 12 (cards), full (pills, ring).
- Motion: ease-in-out 0.4s; breathing 4s; all disabled by Reduce Motion.

## Anti-goals
No stock-photo wellness cliches, no emoji, no confetti, no sound by default, no counters/streak guilt.
