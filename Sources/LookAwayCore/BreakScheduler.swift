import Foundation

/// Break state machine over several rules (eyes, posture, blink). Pure logic with an injectable clock so it can be
/// unit tested; the app drives it with a 1s timer calling `tick()`.
public final class BreakScheduler: ObservableObject {
    public enum Phase: Equatable { case working, headsUp, breaking }

    @Published public private(set) var phase: Phase = .working
    /// Seconds until the next phase change (break start while working/headsUp, break end while breaking).
    @Published public private(set) var secondsLeft: Int = 0
    /// The rule that is upcoming (working/headsUp) or running (breaking).
    @Published public private(set) var activeRule: BreakRule

    public var rules: [BreakRule] { didSet { syncDue() } }
    public var headsUpLead: TimeInterval
    private let now: () -> Date
    private var due: [String: Date] = [:]
    private var deadline: Date

    public init(rules: [BreakRule] = BreakRule.defaults, headsUpLead: TimeInterval = 30, now: @escaping () -> Date = Date.init) {
        self.rules = rules
        self.headsUpLead = headsUpLead
        self.now = now
        self.deadline = .distantFuture
        self.activeRule = rules.first ?? BreakRule.defaults[0]
        syncDue()
        refresh()
    }

    /// False when every rule is disabled, so the UI can say so instead of showing a meaningless countdown.
    public var hasUpcoming: Bool { rules.contains { $0.enabled } }

    public func tick() {
        refresh()
        switch phase {
        case .working where secondsLeft > 0 && TimeInterval(secondsLeft) <= headsUpLead && hasUpcoming: phase = .headsUp
        case .working, .headsUp: if secondsLeft == 0 && hasUpcoming { startBreak(rule: activeRule) }
        case .breaking: if secondsLeft == 0 { endBreak() }
        }
    }

    /// Starts a break now. Scheduled breaks pass the rule that came due; on-demand ones may pass a custom length.
    public func startBreak(rule: BreakRule? = nil, duration custom: TimeInterval? = nil) {
        let rule = rule ?? (phase == .working || phase == .headsUp ? activeRule : rules.first ?? activeRule)
        let length = custom ?? rule.duration
        activeRule = rule
        phase = .breaking
        deadline = now().addingTimeInterval(length)
        secondsLeft = Int(length)
    }

    /// Ends a break early or skips the upcoming one. The active rule restarts its full interval, and so does any
    /// rule that was due by now (a long break covers shorter ones).
    public func endBreak() {
        let t = now()
        due[activeRule.id] = t.addingTimeInterval(activeRule.interval)
        for r in rules where (due[r.id] ?? t) <= t { due[r.id] = t.addingTimeInterval(r.interval) }
        phase = .working
        refresh()
    }

    /// Pushes the upcoming break out by `seconds`. Short delays re-enter the heads-up lead on a later tick.
    public func postpone(by seconds: TimeInterval) {
        due[activeRule.id] = now().addingTimeInterval(seconds)
        phase = .working
        refresh()
    }

    private func syncDue() {
        let t = now()
        due = Dictionary(uniqueKeysWithValues: rules.map { r in (r.id, due[r.id] ?? t.addingTimeInterval(r.interval)) })
    }

    private func refresh() {
        if phase != .breaking {
            let next = rules.filter(\.enabled).min { (due[$0.id] ?? .distantFuture) < (due[$1.id] ?? .distantFuture) }
            if let next { activeRule = next; deadline = due[next.id] ?? .distantFuture } else { deadline = .distantFuture }
        }
        secondsLeft = deadline == .distantFuture ? 0 : max(0, Int(deadline.timeIntervalSince(now()).rounded(.up)))
    }
}
