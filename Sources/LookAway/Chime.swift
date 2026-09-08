import AppKit
import Combine
import LookAwayCore

/// Plays the chosen sound when a break starts and ends.
final class Chime {
    static let systemSounds = ["Glass", "Hero", "Submarine", "Funk", "Ping", "Purr", "Blow"]
    private var sub: AnyCancellable?
    private var current: NSSound?

    init(scheduler: BreakScheduler, store: SettingsStore) {
        sub = scheduler.$phase.removeDuplicates().scan(BreakScheduler.Phase.working) { prev, next in
            // Fires on entering and leaving .breaking only, not on working <-> headsUp.
            if next == .breaking || prev == .breaking { store.playChime() }
            return next
        }.sink { _ in }
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
