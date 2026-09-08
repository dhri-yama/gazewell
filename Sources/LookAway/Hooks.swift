import Foundation
import Combine
import LookAwayCore

/// Runs a user's Shortcut or AppleScript file when a break starts or ends.
final class Hooks {
    private var sub: AnyCancellable?

    init(scheduler: BreakScheduler, store: SettingsStore) {
        sub = scheduler.onBreak(
            start: {
                if store.settings.lockOnBreakStart { Lock.screen() }
                Self.run(store.settings.startHook)
            },
            end: { Self.run(store.settings.endHook) })
    }

    /// A path to a .scpt/.applescript file runs with osascript; anything else is a Shortcut name.
    static func run(_ hook: String) {
        let hook = hook.trimmingCharacters(in: .whitespaces)
        guard !hook.isEmpty else { return }
        let isScript = hook.hasSuffix(".scpt") || hook.hasSuffix(".applescript")
        let p = Process()
        p.executableURL = URL(fileURLWithPath: isScript ? "/usr/bin/osascript" : "/usr/bin/shortcuts")
        p.arguments = isScript ? [(hook as NSString).expandingTildeInPath] : ["run", hook]
        p.standardOutput = FileHandle.nullDevice
        p.standardError = FileHandle.nullDevice
        DispatchQueue.global().async { try? p.run() }
    }
}
