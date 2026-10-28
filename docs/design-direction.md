# Design direction

Gazewell's look is a set of switchable themes on one blurred-glass foundation. Calm and gentle: it should never feel like an alarm.

## Themes
Forest, Earth, Ocean, Air, Night sky, Medito, Mono focus. A theme is a `Style` value in `Theme.swift` (ink, veil, accent, glows, backdrop palette, radii, display font design, material, break layout). Views read `Theme`; nothing else hard-codes colours. Picking a theme in Settings → General restyles every surface live.

## Surfaces
- **Break screen:** the theme's backdrop plus a scene that advances with the break: a growing tree (Forest), stacking stones (Earth), rising water (Ocean), blowing dandelion seeds (Air), a moon crossing the sky (Night sky), a breathing ring (Medito), a large editorial title (Mono focus). Skip / Lock Screen pills, "Press Esc twice" hint, enforcement-aware.
- **Heads-up card:** timer, one line of copy, Start break now and +1m / +5m / +15m; a pill follows the cursor.
- **Wellness reminders:** full-screen scenes on the theme backdrop: rain (hydration), rising chevrons (posture), eyelids (blink), silk ribbons (stretch); message in the centre.
- **Menu popover:** blurred glass, countdown and progress, plain menu rows.
- **Settings:** a toolbar of tabs across the top, a large page title with a one-line description, and a flat list of rows separated by hairlines (no boxes, no sidebar).

## Rules
- Text over blur or imagery keeps 4.5:1 contrast; photos get a dark scrim.
- Respect Reduce Motion everywhere (scenes hold a still frame); animation is time-driven, not state-driven.
- Controls share one height (30pt) so rows line up; all features stay reachable from Settings.
