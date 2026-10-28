# Gazewell

A macOS menu bar app that reminds you to rest your eyes, fix your posture and blink, timed around natural pauses. An independent open-source project, not affiliated with any other break-reminder app.

<p align="center"><img src="docs/images/hero.jpg" width="860" alt="Gazewell break screen in the Forest theme: a tree grows while the countdown runs"></p>

## Screenshots

### Seven themes, each with its own break scene
Every theme restyles the whole app, and the break screen plays a scene that advances with the break: a tree grows, stones stack, water rises, dandelion seeds blow away, a moon crosses the sky, a ring breathes.

<table>
  <tr>
    <td align="center"><img src="docs/images/theme-earth.jpg" width="290" alt="Earth theme"><br>Earth</td>
    <td align="center"><img src="docs/images/theme-ocean.jpg" width="290" alt="Ocean theme"><br>Ocean</td>
    <td align="center"><img src="docs/images/theme-air.jpg" width="290" alt="Air theme"><br>Air</td>
  </tr>
  <tr>
    <td align="center"><img src="docs/images/theme-night-sky.jpg" width="290" alt="Night sky theme"><br>Night sky</td>
    <td align="center"><img src="docs/images/theme-medito.jpg" width="290" alt="Medito theme"><br>Medito</td>
    <td align="center"><img src="docs/images/theme-mono-focus.jpg" width="290" alt="Mono focus theme"><br>Mono focus</td>
  </tr>
</table>

Forest is shown at the top of this page.

### Settings, menu bar and heads-up
<table>
  <tr>
    <td valign="top"><img src="docs/images/settings.jpg" width="520" alt="Settings window with a toolbar of tabs and the theme picker"></td>
    <td valign="top"><img src="docs/images/menu.jpg" width="260" alt="Menu bar popover with countdown and actions"></td>
  </tr>
</table>

<p align="center"><img src="docs/images/headsup.png" width="420" alt="Heads-up card shown before a break with Start break now and snooze buttons"></p>

### Full-screen wellness reminders
Gentle animations in your theme, never a full break: rain for water, rising chevrons for posture, slow eyelids for blinking, silk ribbons for stretching.

<table>
  <tr>
    <td align="center"><img src="docs/images/reminder-water.jpg" width="230" alt="Hydration reminder"><br>Hydration</td>
    <td align="center"><img src="docs/images/reminder-posture.jpg" width="230" alt="Posture reminder"><br>Posture</td>
    <td align="center"><img src="docs/images/reminder-blink.jpg" width="230" alt="Blink reminder"><br>Blink</td>
    <td align="center"><img src="docs/images/reminder-stretch.jpg" width="230" alt="Stretch reminder"><br>Stretch</td>
  </tr>
</table>

<sub>Images are rendered by the app itself (`Gazewell --snapshot <folder>`), so the real macOS background blur isn't visible in them.</sub>

## Features
- Eye breaks with a heads-up card (+1m / +5m / +15m), a cursor-following countdown and periodic long breaks
- Break enforcement (casual, balanced, hardcore), a daily snooze limit, a double-Esc action and optional auto-lock
- Smart pause: skips breaks during calls (microphone or camera in use), delays for screen recording, video and fullscreen apps; time away counts as a break
- Office hours and planned breaks (e.g. lunch)
- Full-screen wellness reminders (posture, blink, hydration, stretch) in your theme
- Seven themes (Forest, Earth, Ocean, Air, Night sky, Medito, Mono focus), per-role fonts, sounds, custom messages and backgrounds
- Stats and streaks, global shortcuts, Shortcuts/AppleScript hooks, launch at login

## Build
Requires macOS 13+ and the Swift toolchain (Command Line Tools are enough).

```sh
./bundle.sh && open Gazewell.app   # build and run
./dmg.sh                           # build Gazewell-<version>.dmg for installing
./test.sh                          # scheduler tests
```

Global shortcuts: ⌃⌥B start a break, ⌃⌥S skip next, ⌃⌥P turn breaks off/on.

The app is ad-hoc signed, not notarized: on first launch right-click → Open.

## Versioning
Gazewell follows [Semantic Versioning](https://semver.org/). The single source of truth is the `VERSION` file; `bundle.sh` stamps it into the app, so it shows in Settings → About.

- Note changes under `## [Unreleased]` in [CHANGELOG.md](CHANGELOG.md) as you work.
- Cut a release with `./release.sh patch|minor|major`. It bumps `VERSION`, dates the changelog section, commits and tags `vX.Y.Z`.
- Then `git push && git push --tags`.
