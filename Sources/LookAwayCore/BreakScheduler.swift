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

    /// While set and in the future, no break or heads-up appears (user "Pause" from the menu).
    @Published public var pausedUntil: Date?

    public var rules: [BreakRule] { didSet { syncDue() } }
    public var headsUpLead: TimeInterval
    /// Set by the app each tick: a call, recording, video or fullscreen app is in the way.
    public var blocked = false
    /// Set by the app each tick: the user is typing/clicking right now.
    public var userActive = false
    /// A break waits at most this long for the user to stop typing.
    public var maxTypingDeferral: TimeInterval = 30
    private var deferringSince: Date?
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
        if let p = pausedUntil, p <= now() { pausedUntil = nil }
        if phase != .breaking && (blocked || pausedUntil != nil) { holdOff() }
        refresh()
        if phase == .headsUp && TimeInterval(secondsLeft) > headsUpLead { phase = .working }  // idle reset pushed it out
        switch phase {
        case .working where secondsLeft > 0 && TimeInterval(secondsLeft) <= headsUpLead && hasUpcoming: phase = .headsUp
        case .working, .headsUp:
            guard secondsLeft == 0 && hasUpcoming else { return }
            // Wait (briefly) for a pause in typing so the break doesn't land mid-sentence.
            if userActive, now().timeIntervalSince(deferringSince ?? now()) < maxTypingDeferral {
                deferringSince = deferringSince ?? now()
                return
            }
            startBreak(rule: activeRule)
        case .breaking: if secondsLeft == 0 { endBreak() }
        }
    }

    /// A stretch of inactivity counts as a break: any rule whose duration fits within it starts over.
    public func registerIdle(_ idle: TimeInterval) {
        guard phase != .breaking else { return }
        let t = now()
        for r in rules where r.kind != .planned && idle >= r.duration { due[r.id] = r.nextDue(after: t) }
    }

    /// While blocked or paused, anything about to fire is pushed out so a heads-up (not a surprise break) follows.
    private func holdOff() {
        let t = now()
        for r in rules where (due[r.id] ?? t).timeIntervalSince(t) <= headsUpLead {
            due[r.id] = t.addingTimeInterval(headsUpLead + 1)
        }
        if phase == .headsUp { phase = .working }
    }

    /// Starts a break now. Scheduled breaks pass the rule that came due; on-demand ones may pass a custom length.
    public func startBreak(rule: BreakRule? = nil, duration custom: TimeInterval? = nil) {
        let rule = rule ?? (phase == .working || phase == .headsUp ? activeRule : rules.first ?? activeRule)
        let length = custom ?? rule.duration
        deferringSince = nil
        activeRule = rule
        phase = .breaking
        deadline = now().addingTimeInterval(length)
        secondsLeft = Int(length)
    }

    /// Ends a break early or skips the upcoming one. The active rule restarts its full interval, and so does any
    /// rule that was due by now (a long break covers shorter ones).
    public func endBreak() {
        let t = now()
        due[activeRule.id] = activeRule.nextDue(after: t)
        for r in rules where (due[r.id] ?? t) <= t { due[r.id] = r.nextDue(after: t) }
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
        due = Dictionary(uniqueKeysWithValues: rules.map { r in (r.id, due[r.id] ?? r.nextDue(after: t)) })
    }

    private func refresh() {
        if phase != .breaking {
            // A planned break missed while asleep (or edited to a past time) waits for its next occurrence instead of firing late.
            let t = now()
            for r in rules where r.kind == .planned && (due[r.id] ?? t) < t.addingTimeInterval(-300) { due[r.id] = r.nextDue(after: t) }
            let next = rules.filter(\.enabled).min { (due[$0.id] ?? .distantFuture) < (due[$1.id] ?? .distantFuture) }
            if let next { activeRule = next; deadline = due[next.id] ?? .distantFuture } else { deadline = .distantFuture }
        }
        secondsLeft = deadline == .distantFuture ? 0 : max(0, Int(deadline.timeIntervalSince(now()).rounded(.up)))
    }
}
