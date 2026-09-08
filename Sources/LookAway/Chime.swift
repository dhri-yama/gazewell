import AppKit
import Combine
import LookAwayCore

/// Plays the chosen sound when a break starts and ends.
final class Chime {
    static let systemSounds = ["Glass", "Hero", "Submarine", "Funk", "Ping", "Purr", "Blow"]
    private var sub: AnyCancellable?

    init(scheduler: BreakScheduler, store: SettingsStore) {
        sub = scheduler.onBreak(start: { store.playChime() }, end: { store.playChime() })
    }
}

extension SettingsStore {
    static func sound(for s: AppSettings) -> NSSound? {
        switch s.sound {
        case "": return nil
        case "custom": return s.soundPath.isEmpty ? nil : NSSound(contentsOf: URL(fileURLWithPath: s.soundPath), byReference: true)
        default: return NSSound(named: s.sound)
        }
    }

    func playChime() { Self.sound(for: settings)?.play() }
}
