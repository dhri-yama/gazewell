import Foundation
import GazewellCore

final class StatsStore: ObservableObject {
    private static let key = "stats.v1"
    @Published private(set) var stats: Stats

    /// `preset` supplies fixed data (used by the screenshot harness so it never shows or touches real stats).
    init(preset: Stats? = nil) {
        SettingsStore.migrateLegacyDefaults()   // StatsStore is built before SettingsStore
        if let preset { stats = preset; return }
        stats = UserDefaults.standard.data(forKey: Self.key).flatMap { try? JSONDecoder().decode(Stats.self, from: $0) } ?? Stats()
    }

    func record(_ event: BreakScheduler.Event) {
        stats.record(event)
        if let data = try? JSONEncoder().encode(stats) { UserDefaults.standard.set(data, forKey: Self.key) }
    }

    func clear() {
        stats = Stats()
        UserDefaults.standard.removeObject(forKey: Self.key)
    }
}
