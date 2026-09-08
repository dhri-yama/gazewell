import AppKit
import Combine
import LookAwayCore

/// Plays the chosen sounds when a break starts and ends.
final class Chime {
    static let systemSounds = ["Glass", "Hero", "Submarine", "Funk", "Ping", "Purr", "Blow", "Tink", "Pop"]
    private var sub: AnyCancellable?

    init(scheduler: BreakScheduler, store: SettingsStore) {
        sub = scheduler.onBreak(start: { Self.play(store.settings.startSound, volume: store.settings.soundVolume) },
                                end: { Self.play(store.settings.endSound, volume: store.settings.soundVolume) })
    }

    /// "" is silent, "file:<path>" a user's file, anything else a macOS system sound name.
    static func play(_ choice: String, volume: Double) {
        let sound: NSSound?
        if choice.isEmpty { return }
        else if choice.hasPrefix("file:") { sound = NSSound(contentsOf: URL(fileURLWithPath: String(choice.dropFirst(5))), byReference: true) }
        else { sound = NSSound(named: choice) }
        sound?.volume = Float(min(max(volume, 0), 1))
        sound?.play()
    }
}
