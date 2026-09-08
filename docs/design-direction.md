# Design direction (revision 2: match real LookAway)

The user supplied LookAway reference screenshots and asked for the same look plus more features. This replaces the earlier "Dusk window" direction. Brand commitment in PRODUCT.md changes from "custom branded" to "faithful to LookAway's look".

Mode: Operate (settings, menu, heads-up) + one Experience moment (break screen).

## Break screen
- Full screen, dark blurred organic backdrop: soft colour blobs (default olive/amber on near-black) drifting slowly; static under Reduce Motion.
- Top: "Current time is HH:MM" (small, dim, time in brighter weight).
- Centre stack: big bold title ("Catch a quick rest"), regular subtitle, 400pt hairline divider, dim `mm:ss` countdown.
- Bottom: pills **Skip** (icon `forward` / progress ring while locked) and **Lock Screen**, then "Press Esc twice to skip".
- Enforcement: Casual (skip anytime), Balanced (Skip unlocks after 5s), Hardcore (no skip; End break only near the end if allowed).
- No breathing ring, no coral accent.

## Heads-up card
Dark translucent rounded card: timer icon tile, bold `00:40`, line "Almost time. Your eyes will appreciate this.", then orange pill **Start break now** and outline pills **+1m +5m +15m**. Cursor-following pill: leaf icon + "Short break in 5".

## Wellness nudges
Small toast, top centre, icon + one line, auto-dismiss.

## Settings window
Dark, sidebar + detail (not tabs). Sidebar groups: General · Focus & Wellbeing (Screen Breaks, Smart Pause, Wellness Reminders, Stats) · Behavior & Feedback (Alerts / Nudges, Sounds, Keyboard Shortcuts) · Integrations (Automation) · LookAway (About). Each item has a rounded-square gradient icon tile with a white SF symbol. Detail: title with tile, section headers, rounded grouped cards of rows (label left, control right, hairline dividers). Enforcement shown as three selectable preview tiles.

## Menu bar
Popover (window style): header with next-break countdown and elapsed bar, action row (Start break, Skip next, Pause), then Settings and Quit. Optional time in the menu bar title.

## Tokens (Theme.swift)
- Window bg #171826, sidebar #1D1E30, card #252739, hairline white 8%, text white / white 60%.
- Olive blobs #8C8446, #5A5A32, base #141A14. Other themes: Dusk, Ocean, Rose, Slate.
- Accent orange #FF6B2C (Start break now), toggle blue system.
- Sidebar tile gradients: pink/magenta, red/orange, orange/yellow, yellow.
- Type: SF Pro Rounded not used; title 64 bold, subtitle 28 regular, countdown 64 semibold dim.

## Anti-goals
No confetti, no streak guilt copy, no emoji.
