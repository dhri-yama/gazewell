import AppKit
import Combine
import LookAwayCore

/// Plays the chosen sounds when a break starts and ends.
final class Chime {
    static let systemSounds = ["Glass", "Hero", "Submarine", "Funk", "Ping", "Purr", "Blow", "Tink", "Pop"]
    private var sub: AnyCancellable?

    init(scheduler: BreakScheduler, store: SettingsStore) {
        sub = scheduler.onBreak(start: { Self.play(store.settings.startSound) }, end: { Self.play(store.settings.endSound) })
    }

    /// "" is silent, "file:<path>" a user's file, anything else a macOS system sound name.
    static func play(_ choice: String) {
        let sound: NSSound?
        if choice.isEmpty { return }
        else if choice.hasPrefix("file:") { sound = NSSound(contentsOf: URL(fileURLWithPath: String(choice.dropFirst(5))), byReference: true) }
        else { sound = NSSound(named: choice) }
        sound?.play()
    }
}
