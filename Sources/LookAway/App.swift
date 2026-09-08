import SwiftUI
import Carbon.HIToolbox
import LookAwayCore

/// Owns long-lived objects so timers and overlays exist from launch, not from first menu open.
final class AppModel {
    static let shared = AppModel()
    let scheduler = BreakScheduler()
    let store: SettingsStore
    let stats = StatsStore()
    let overlay: BreakOverlay
    let headsUp: HeadsUp
    let chime: Chime
    let hooks: Hooks
    let nudges: Nudges
    let hotkeys = Hotkeys()
    private var timer: Timer?

    init() {
        store = SettingsStore(scheduler: scheduler)
        let stats = stats
        scheduler.onEvent = { stats.record($0) }
        overlay = BreakOverlay(scheduler: scheduler, store: store, stats: stats)
        headsUp = HeadsUp(scheduler: scheduler, store: store, canSnooze: { [store] in store.settings.snoozesPerDay < 0 || stats.stats.snoozesToday < store.settings.snoozesPerDay })
        chime = Chime(scheduler: scheduler, store: store)
        hooks = Hooks(scheduler: scheduler, store: store)
        nudges = Nudges(scheduler: scheduler, store: store)
        registerHotkeys()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.tick() }
    }

    private func registerHotkeys() {
        let sched = scheduler, store = store
        func on(_ f: @escaping () -> Void) -> () -> Void { { if store.settings.shortcutsEnabled { f() } } }
        hotkeys.register(key: kVK_ANSI_B, action: on { sched.startBreak() })
        hotkeys.register(key: kVK_ANSI_S, action: on { if sched.phase != .breaking { sched.endBreak() } })
        hotkeys.register(key: kVK_ANSI_P, action: on { sched.pausedUntil = sched.pausedUntil == nil ? .distantFuture : nil })
    }

    private func tick() {
        let c = store.settings
        let idle = Blockers.idleSeconds
        scheduler.userActive = idle < 2
        scheduler.blocked = !c.officeHours.contains(Date())
            || (c.pauseForCalls && Blockers.inCall) || (c.pauseForRecording && Blockers.recordingScreen)
            || (c.pauseForVideo && Blockers.displayKeptAwake) || (c.pauseForFullscreen && Blockers.fullscreenApp)
        if c.idleCountsAsBreak { scheduler.registerIdle(idle) }
        scheduler.tick()
        nudges.tick()
    }
}

@main
struct LookAwayApp: App {
    @ObservedObject private var scheduler = AppModel.shared.scheduler
    @ObservedObject private var store = AppModel.shared.store

    init() {
        if let i = CommandLine.arguments.firstIndex(of: "--snapshot"), i + 1 < CommandLine.arguments.count {
            Snapshots.run(into: CommandLine.arguments[i + 1])
            exit(0)
        }
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    private var menuTitle: String {
        guard store.settings.showTimeInMenuBar, scheduler.hasUpcoming, scheduler.pausedUntil == nil else { return "" }
        return String(format: "%d:%02d", scheduler.secondsLeft / 60, scheduler.secondsLeft % 60)
    }

    var body: some Scene {
        MenuBarExtra {
            MenuPopover(scheduler: scheduler, store: store, stats: AppModel.shared.stats)
        } label: {
            Image(systemName: scheduler.pausedUntil != nil ? "eye.slash" : "eye")
            if !menuTitle.isEmpty { Text(menuTitle).monospacedDigit() }
        }
        .menuBarExtraStyle(.window)
    }
}
