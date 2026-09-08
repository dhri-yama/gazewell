import SwiftUI
import LookAwayCore

/// Owns long-lived objects so timers and overlays exist from launch, not from first menu open.
final class AppModel {
    static let shared = AppModel()
    let scheduler = BreakScheduler()
    let store: SettingsStore
    let overlay: BreakOverlay
    let headsUp: HeadsUp
    private var timer: Timer?

    init() {
        store = SettingsStore(scheduler: scheduler)
        overlay = BreakOverlay(scheduler: scheduler)
        headsUp = HeadsUp(scheduler: scheduler)
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [scheduler] _ in scheduler.tick() }
    }
}

@main
struct LookAwayApp: App {
    @ObservedObject private var scheduler = AppModel.shared.scheduler

    init() { NSApplication.shared.setActivationPolicy(.accessory) }

    var body: some Scene {
        MenuBarExtra("LookAway", systemImage: "eye") {
            let m = scheduler.secondsLeft / 60, s = scheduler.secondsLeft % 60
            Text(!scheduler.hasUpcoming ? "No breaks enabled"
                 : scheduler.phase == .breaking ? "On a break" : String(format: "Next break in %d:%02d", m, s))
            Divider()
            Button("Start break now") { scheduler.startBreak() }
            Menu("Start a longer break") {
                Button("1 minute") { scheduler.startBreak(duration: 60) }
                Button("5 minutes") { scheduler.startBreak(duration: 300) }
                Button("15 minutes") { scheduler.startBreak(duration: 900) }
            }
            Button("Skip next break") { scheduler.endBreak() }
                .disabled(scheduler.phase == .breaking)
            Button("Settings…") { SettingsWindow.show(store: AppModel.shared.store) }.keyboardShortcut(",")
            Button("Quit LookAway") { NSApp.terminate(nil) }.keyboardShortcut("q")
        }
    }
}
