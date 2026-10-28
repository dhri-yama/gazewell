import Foundation
import SwiftUI
import AppKit
import Combine
import ServiceManagement
import GazewellCore

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
        case .olive: "Signature"      // follows the app theme
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

/// A font family (or one of the system designs: "system", "rounded", "serif", "mono") plus a weight 0...5 (light...heavy).
struct FontSpec: Codable, Equatable {
    var family: String
    var weight: Int

    static let weights = ["Light", "Regular", "Medium", "Semibold", "Bold", "Heavy"]
    private static let swiftWeights: [Font.Weight] = [.light, .regular, .medium, .semibold, .bold, .heavy]

    static let systemFamilies: [(String, String)] = [
        ("system", "SF Pro"), ("rounded", "SF Rounded"), ("serif", "New York"), ("mono", "SF Mono"),
    ]
    /// Well-known faces that ship with macOS; only the ones installed are offered.
    static let installedFamilies: [(String, String)] = {
        let have = Set(NSFontManager.shared.availableFontFamilies)
        return ["Helvetica Neue", "Avenir Next", "Futura", "Optima", "Gill Sans", "Georgia", "Palatino", "Baskerville", "Didot",
                "Hoefler Text", "Times New Roman", "American Typewriter", "Menlo", "Courier New", "Marker Felt", "Chalkboard SE",
                "Snell Roundhand", "Copperplate", "Avenir", "Charter", "Iowan Old Style"]
            .filter { have.contains($0) }.map { ($0, $0) }
    }()
    static var allFamilies: [(String, String)] { systemFamilies + installedFamilies }

    func font(_ size: CGFloat) -> Font {
        let w = Self.swiftWeights[min(max(weight, 0), 5)]
        switch family {
        case "system": return .system(size: size, weight: w)
        case "rounded": return .system(size: size, weight: w, design: .rounded)
        case "serif": return .system(size: size, weight: w, design: .serif)
        case "mono": return .system(size: size, weight: w, design: .monospaced)
        default: return Font.custom(family, size: size).weight(w)
        }
    }
}

struct FontPreset {
    var name: String
    var title: FontSpec, subtitle: FontSpec, timer: FontSpec

    static let all: [FontPreset] = [
        .init(name: "Serif + Sans", title: .init(family: "serif", weight: 3), subtitle: .init(family: "system", weight: 1), timer: .init(family: "system", weight: 2)),
        .init(name: "Sans", title: .init(family: "system", weight: 4), subtitle: .init(family: "system", weight: 1), timer: .init(family: "system", weight: 3)),
        .init(name: "Didot + Avenir", title: .init(family: "Didot", weight: 4), subtitle: .init(family: "Avenir Next", weight: 1), timer: .init(family: "Avenir Next", weight: 2)),
        .init(name: "Serif + Mono", title: .init(family: "serif", weight: 4), subtitle: .init(family: "system", weight: 1), timer: .init(family: "mono", weight: 1)),
        .init(name: "Soft", title: .init(family: "rounded", weight: 4), subtitle: .init(family: "rounded", weight: 1), timer: .init(family: "rounded", weight: 3)),
        .init(name: "Typewriter", title: .init(family: "American Typewriter", weight: 4), subtitle: .init(family: "American Typewriter", weight: 1), timer: .init(family: "Courier New", weight: 4)),
        .init(name: "Mono", title: .init(family: "mono", weight: 2), subtitle: .init(family: "mono", weight: 0), timer: .init(family: "mono", weight: 1)),
    ]
}

struct AppSettings: Codable, Equatable {
    var enabled = true                     // master switch for everything
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
    var skipDuringCalls = true             // false = delay the break until the call ends
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
    var titleFont = FontPreset.all[0].title
    var subtitleFont = FontPreset.all[0].subtitle
    var timerFont = FontPreset.all[0].timer
    var customMessages = ""                // one per line, "Title | Subtitle" or just a subtitle
    // Sounds: "" none, a system sound name, or "file:<path>"
    var startSound = ""
    var endSound = ""
    var soundVolume = 0.25                 // 0...1, relative to system volume
    // Automation
    var startHook = ""
    var endHook = ""
    var shortcutsEnabled = true
    // General
    var showTimeInMenuBar = false
    var appStyle = "Forest"                // visual theme: one of Style.all

    init() {}

    // Missing keys (older saves, new fields) fall back to defaults instead of discarding everything.
    init(from d: Decoder) throws {
        let c = try d.container(keyedBy: CodingKeys.self)
        func v<T: Decodable>(_ k: CodingKeys, _ def: T) -> T { (try? c.decodeIfPresent(T.self, forKey: k)) ?? def }
        enabled = v(.enabled, enabled); breaksEnabled = v(.breaksEnabled, breaksEnabled); breakEvery = v(.breakEvery, breakEvery)
        breakDuration = v(.breakDuration, breakDuration); longBreakEvery = v(.longBreakEvery, longBreakEvery)
        longBreakDuration = v(.longBreakDuration, longBreakDuration); enforcement = v(.enforcement, enforcement)
        snoozesPerDay = v(.snoozesPerDay, snoozesPerDay); doubleEscape = v(.doubleEscape, doubleEscape)
        allowEarlyEnd = v(.allowEarlyEnd, allowEarlyEnd); lockOnBreakStart = v(.lockOnBreakStart, lockOnBreakStart)
        officeHours = v(.officeHours, officeHours); planned = v(.planned, planned)
        pauseForCalls = v(.pauseForCalls, pauseForCalls); skipDuringCalls = v(.skipDuringCalls, skipDuringCalls); pauseForRecording = v(.pauseForRecording, pauseForRecording)
        pauseForVideo = v(.pauseForVideo, pauseForVideo); pauseForFullscreen = v(.pauseForFullscreen, pauseForFullscreen)
        idleCountsAsBreak = v(.idleCountsAsBreak, idleCountsAsBreak); nudges = v(.nudges, nudges)
        headsUpEnabled = v(.headsUpEnabled, headsUpEnabled); headsUpLead = v(.headsUpLead, headsUpLead)
        cursorCountdown = v(.cursorCountdown, cursorCountdown); theme = v(.theme, theme)
        imagePath = v(.imagePath, imagePath); showClock = v(.showClock, showClock)
        showLockButton = v(.showLockButton, showLockButton); customMessages = v(.customMessages, customMessages)
        titleFont = v(.titleFont, titleFont); subtitleFont = v(.subtitleFont, subtitleFont); timerFont = v(.timerFont, timerFont)
        startSound = v(.startSound, startSound); endSound = v(.endSound, endSound); soundVolume = v(.soundVolume, soundVolume)
        startHook = v(.startHook, startHook); endHook = v(.endHook, endHook)
        shortcutsEnabled = v(.shortcutsEnabled, shortcutsEnabled); showTimeInMenuBar = v(.showTimeInMenuBar, showTimeInMenuBar); appStyle = v(.appStyle, appStyle)
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

    /// The app was renamed in 1.0.0 (bundle id local.lookaway -> local.gazewell); carry settings and stats over once.
    static func migrateLegacyDefaults() {
        let std = UserDefaults.standard
        guard let old = UserDefaults(suiteName: "local.lookaway") else { return }
        for k in [key, "stats.v1"] { if std.data(forKey: k) == nil, let d = old.data(forKey: k) { std.set(d, forKey: k) } }
    }

    init(scheduler: BreakScheduler) {
        Self.migrateLegacyDefaults()
        self.scheduler = scheduler
        launchAtLogin = SMAppService.mainApp.status == .enabled
        let saved = UserDefaults.standard.data(forKey: Self.key).flatMap { try? JSONDecoder().decode(AppSettings.self, from: $0) }
        var loaded = saved ?? AppSettings()
        // Earlier builds defaulted to all-sans type; anyone still on exactly that moves to the new serif + sans default.
        let sans = FontPreset.all[1], def = FontPreset.all[0]
        if loaded.titleFont == sans.title && loaded.subtitleFont == sans.subtitle && loaded.timerFont == sans.timer {
            loaded.titleFont = def.title; loaded.subtitleFont = def.subtitle; loaded.timerFont = def.timer
        }
        settings = loaded
        if !Style.all.contains(where: { $0.name == loaded.appStyle }) { loaded.appStyle = Style.forest.name }   // e.g. a theme that was removed
        Theme.style = Style.named(loaded.appStyle)   // before any view is built
        apply()
    }

    func reset() { settings = AppSettings() }

    private func save() {
        if let data = try? JSONEncoder().encode(settings) { UserDefaults.standard.set(data, forKey: Self.key) }
    }

    private func apply() {
        let s = settings
        Theme.style = Style.named(s.appStyle)
        let eyes = BreakRule(kind: .eyes, interval: s.breakEvery, duration: s.breakDuration, enabled: s.breaksEnabled, message: "")
        scheduler.rules = [eyes] + s.planned
        scheduler.headsUpLead = s.headsUpEnabled ? s.headsUpLead : 0
        scheduler.enabled = s.enabled
        scheduler.longBreakEvery = s.longBreakEvery
        scheduler.longBreakDuration = s.longBreakDuration
    }
}
