import SwiftUI
import LookAwayCore

/// Owns long-lived objects so timers and overlays exist from launch, not from first menu open.
final class AppModel {
    static let shared = AppModel()
    let scheduler: BreakScheduler
    let overlay: BreakOverlay
    let headsUp: HeadsUp
    private var timer: Timer?

    init() {
        // Env overrides (seconds) make manual testing quick.
        let env = ProcessInfo.processInfo.environment
        scheduler = BreakScheduler(interval: TimeInterval(env["LOOKAWAY_INTERVAL"] ?? "") ?? 20 * 60,
                              duration: TimeInterval(env["LOOKAWAY_DURATION"] ?? "") ?? 20)
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
            Text(scheduler.phase == .breaking ? "On a break" : String(format: "Next break in %d:%02d", m, s))
            Divider()
            Button("Start break now") { scheduler.startBreak() }
            Menu("Start a longer break") {
                Button("1 minute") { scheduler.startBreak(duration: 60) }
                Button("5 minutes") { scheduler.startBreak(duration: 300) }
                Button("15 minutes") { scheduler.startBreak(duration: 900) }
            }
            Button("Skip next break") { scheduler.endBreak() }
                .disabled(scheduler.phase == .breaking)
            Button("Quit LookAway") { NSApp.terminate(nil) }.keyboardShortcut("q")
        }
    }
}
