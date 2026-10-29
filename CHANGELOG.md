# Changelog

All notable changes to Gazewell are recorded here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and the project uses [Semantic Versioning](https://semver.org/): MAJOR for breaking changes to saved settings or behaviour,
MINOR for new features, PATCH for fixes.

## [Unreleased]

### Added
- Marketing website in `website/` (Next.js and Tailwind), themed like the app. It is not part of the app or the DMG.
- "Buy me a coffee" button in Settings → About, and a badge in the README.

## [1.0.1] - 2026-10-28

### Added
- Universal binary (Apple silicon and Intel), a DMG installer, a Homebrew tap (`dhri-yama/tap`) and GitHub releases via `./publish.sh`.
- README screenshots of the themes, settings, menu, heads-up card and reminders, and install instructions.

## [1.0.0] - 2026-10-28

First release, under the name Gazewell (previously a working title).

### Added
- Menu bar break reminder with heads-up card (+1m / +5m / +15m), cursor-following countdown and long breaks.
- Break enforcement (casual, balanced, hardcore), daily snooze limit, double-Esc action, optional auto-lock.
- Smart pause: skips breaks during calls (microphone or camera in use); delays for screen recording, video and fullscreen apps.
- Office hours, planned breaks, idle time counted as a break, global shortcuts, Shortcuts/AppleScript hooks, launch at login.
- Full-screen wellness reminders (posture, blink, hydration, stretch) drawn in the active theme.
- Seven themes: Forest, Earth, Ocean, Air, Night sky, Medito, Mono focus, each with its own break-screen scene.
- Per-role fonts, sounds with volume, custom messages, break-screen backgrounds, stats with streaks.
- Settings window with a top toolbar and flat list layout; master on/off switch.
- Settings and stats from earlier builds (bundle id local.lookaway) are carried over on first launch.
