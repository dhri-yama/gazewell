import Foundation
import Combine
import ServiceManagement
import LookAwayCore

enum Enforcement: String, Codable, CaseIterable {
    case casual, balanced, hardcore
    var title: String { rawValue.capitalized }
    var detail: String { self == .casual ? "Skip anytime" : self == .balanced ? "Skip after a pause" : "No skips allowed" }
}

enum EscAction: String, Codable, CaseIterable {
    case skip, snooze, nothing
    var title: String { self == .skip ? "Skip the break" : self == .snooze ? "Snooze for 5 minutes" : "Do nothing" }
}

enum BreakTheme: String, Codable, CaseIterable {
    case olive, dusk, ocean, rose, slate, wallpaper, image
    var title: String {
        switch self {
        case .wallpaper: "Desktop wallpaper"
        case .image: "Custom image"
        default: rawValue.capitalized
        }
    }
}

/// A light reminder shown as a small toast (posture, blinking, water, stretching).
struct Nudge: Codable, Identifiable, Equatable {
    var id: String
    var enabled: Bool
    var minutes: Int
    var message: String

    var symbol: String {
        switch id { case "posture": "figure.stand"; case "blink": "eye"; case "water": "drop"; default: "figure.flexibility" }
    }
    var name: String {
        switch id { case "posture": "Posture"; case "blink": "Blink"; case "water": "Hydration"; default: "Stretch" }
    }

    static let defaults = [
        Nudge(id: "posture", enabled: true, minutes: 45, message: "Sit tall and let your shoulders drop."),
        Nudge(id: "blink", enabled: false, minutes: 10, message: "Blink slowly, ten times."),
        Nudge(id: "water", enabled: false, minutes: 60, message: "Time for a glass of water."),
        Nudge(id: "stretch", enabled: false, minutes: 90, message: "Stand up and stretch your back."),
    ]
}

struct AppSettings: Codable, Equatable {
    // Screen breaks
    var breaksEnabled = true
    var breakEvery: TimeInterval = 20 * 60
    var breakDuration: TimeInterval = 20
    var longBreakEvery = 3                 // 0 = off
    var longBreakDuration: TimeInterval = 300
    var enforcement = Enforcement.balanced
    var snoozesPerDay = 3                  // -1 = unlimited
    var doubleEscape = EscAction.snooze
    var allowEarlyEnd = true
    var lockOnBreakStart = false
    var officeHours = OfficeHours()
    var planned: [BreakRule] = []
    // Smart pause
    var pauseForCalls = true
    var pauseForRecording = true
    var pauseForVideo = true
    var pauseForFullscreen = true
    var idleCountsAsBreak = true
    // Wellness
    var nudges = Nudge.defaults
    // Alerts
    var headsUpEnabled = true
    var headsUpLead: TimeInterval = 30
    var cursorCountdown = true
    // Break screen
    var theme = BreakTheme.olive
    var imagePath = ""
    var showClock = true
    var showLockButton = true
    var customMessages = ""                // one per line, "Title | Subtitle" or just a subtitle
    // Sounds: "" none, a system sound name, or "file:<path>"
    var startSound = ""
    var endSound = ""
    // Automation
    var startHook = ""
    var endHook = ""
    var shortcutsEnabled = true
    // General
    var showTimeInMenuBar = false

    init() {}

    // Missing keys (older saves, new fields) fall back to defaults instead of discarding everything.
    init(from d: Decoder) throws {
        let c = try d.container(keyedBy: CodingKeys.self)
        func v<T: Decodable>(_ k: CodingKeys, _ def: T) -> T { (try? c.decodeIfPresent(T.self, forKey: k)) ?? def }
        breaksEnabled = v(.breaksEnabled, breaksEnabled); breakEvery = v(.breakEvery, breakEvery)
        breakDuration = v(.breakDuration, breakDuration); longBreakEvery = v(.longBreakEvery, longBreakEvery)
        longBreakDuration = v(.longBreakDuration, longBreakDuration); enforcement = v(.enforcement, enforcement)
        snoozesPerDay = v(.snoozesPerDay, snoozesPerDay); doubleEscape = v(.doubleEscape, doubleEscape)
        allowEarlyEnd = v(.allowEarlyEnd, allowEarlyEnd); lockOnBreakStart = v(.lockOnBreakStart, lockOnBreakStart)
        officeHours = v(.officeHours, officeHours); planned = v(.planned, planned)
        pauseForCalls = v(.pauseForCalls, pauseForCalls); pauseForRecording = v(.pauseForRecording, pauseForRecording)
        pauseForVideo = v(.pauseForVideo, pauseForVideo); pauseForFullscreen = v(.pauseForFullscreen, pauseForFullscreen)
        idleCountsAsBreak = v(.idleCountsAsBreak, idleCountsAsBreak); nudges = v(.nudges, nudges)
        headsUpEnabled = v(.headsUpEnabled, headsUpEnabled); headsUpLead = v(.headsUpLead, headsUpLead)
        cursorCountdown = v(.cursorCountdown, cursorCountdown); theme = v(.theme, theme)
        imagePath = v(.imagePath, imagePath); showClock = v(.showClock, showClock)
        showLockButton = v(.showLockButton, showLockButton); customMessages = v(.customMessages, customMessages)
        startSound = v(.startSound, startSound); endSound = v(.endSound, endSound)
        startHook = v(.startHook, startHook); endHook = v(.endHook, endHook)
        shortcutsEnabled = v(.shortcutsEnabled, shortcutsEnabled); showTimeInMenuBar = v(.showTimeInMenuBar, showTimeInMenuBar)
    }
}

/// Persists settings to UserDefaults and pushes them into the scheduler on every change.
final class SettingsStore: ObservableObject {
    private static let key = "settings.v2"
    @Published var settings: AppSettings { didSet { save(); apply() } }
    let scheduler: BreakScheduler
    /// System state, not saved by us. Only works from a bundled .app (see bundle.sh).
    @Published var launchAtLogin: Bool {
        didSet {
            do { launchAtLogin ? try SMAppService.mainApp.register() : try SMAppService.mainApp.unregister() }
            catch { launchAtLogin = SMAppService.mainApp.status == .enabled }
        }
    }

    init(scheduler: BreakScheduler) {
        self.scheduler = scheduler
        launchAtLogin = SMAppService.mainApp.status == .enabled
        let saved = UserDefaults.standard.data(forKey: Self.key).flatMap { try? JSONDecoder().decode(AppSettings.self, from: $0) }
        settings = saved ?? AppSettings()
        apply()
    }

    func reset() { settings = AppSettings() }

    private func save() {
        if let data = try? JSONEncoder().encode(settings) { UserDefaults.standard.set(data, forKey: Self.key) }
    }

    private func apply() {
        let s = settings
        let eyes = BreakRule(kind: .eyes, interval: s.breakEvery, duration: s.breakDuration, enabled: s.breaksEnabled, message: "")
        scheduler.rules = [eyes] + s.planned
        scheduler.headsUpLead = s.headsUpEnabled ? s.headsUpLead : 0
        scheduler.longBreakEvery = s.longBreakEvery
        scheduler.longBreakDuration = s.longBreakDuration
    }
}
