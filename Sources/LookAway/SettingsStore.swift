import Foundation
import Combine
import LookAwayCore

struct AppSettings: Codable, Equatable {
    var rules = BreakRule.defaults
    var headsUpLead: TimeInterval = 30
}

/// Persists settings to UserDefaults and pushes them into the scheduler on every change.
final class SettingsStore: ObservableObject {
    private static let key = "settings.v1"
    @Published var settings: AppSettings { didSet { save(); apply() } }
    private let scheduler: BreakScheduler

    init(scheduler: BreakScheduler) {
        self.scheduler = scheduler
        let saved = UserDefaults.standard.data(forKey: Self.key).flatMap { try? JSONDecoder().decode(AppSettings.self, from: $0) }
        settings = saved ?? AppSettings()
        apply()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(settings) { UserDefaults.standard.set(data, forKey: Self.key) }
    }

    private func apply() {
        scheduler.rules = settings.rules
        scheduler.headsUpLead = settings.headsUpLead
    }
}
