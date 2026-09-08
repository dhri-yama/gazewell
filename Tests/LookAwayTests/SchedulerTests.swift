import Testing
import Foundation
@testable import LookAwayCore

private func rule(_ kind: BreakRule.Kind, _ interval: TimeInterval, _ duration: TimeInterval, enabled: Bool = true) -> BreakRule {
    BreakRule(kind: kind, interval: interval, duration: duration, enabled: enabled, message: "")
}

@Test func workingThenBreakThenWorking() {
    var t = Date(timeIntervalSince1970: 0)
    let s = BreakScheduler(rules: [rule(.eyes, 60, 10)], headsUpLead: 0, now: { t })
    #expect(s.phase == .working)
    t += 59; s.tick()
    #expect(s.phase == .working)
    #expect(s.secondsLeft == 1)
    t += 1; s.tick()
    #expect(s.phase == .breaking)
    #expect(s.secondsLeft == 10)
    t += 10; s.tick()
    #expect(s.phase == .working)
    #expect(s.secondsLeft == 60)
}

@Test func skipRestartsInterval() {
    var t = Date(timeIntervalSince1970: 0)
    let s = BreakScheduler(rules: [rule(.eyes, 60, 10)], now: { t })
    s.startBreak()
    t += 3
    s.endBreak()
    #expect(s.phase == .working)
    #expect(s.secondsLeft == 60)
}

@Test func headsUpThenSnoozeThenBreak() {
    var t = Date(timeIntervalSince1970: 0)
    let s = BreakScheduler(rules: [rule(.eyes, 100, 10)], headsUpLead: 30, now: { t })
    t += 69; s.tick()
    #expect(s.phase == .working)
    t += 1; s.tick()
    #expect(s.phase == .headsUp)
    #expect(s.secondsLeft == 30)
    s.postpone(by: 60)
    #expect(s.phase == .working)
    t += 30; s.tick()
    #expect(s.phase == .headsUp)
    t += 30; s.tick()
    #expect(s.phase == .breaking)
}

@Test func customDurationBreak() {
    let t = Date(timeIntervalSince1970: 0)
    let s = BreakScheduler(rules: [rule(.eyes, 100, 10)], now: { t })
    s.startBreak(duration: 300)
    #expect(s.phase == .breaking)
    #expect(s.secondsLeft == 300)
}

@Test func earliestRuleWinsAndCoveredRulesReset() {
    var t = Date(timeIntervalSince1970: 0)
    let s = BreakScheduler(rules: [rule(.eyes, 100, 10), rule(.posture, 90, 20)], headsUpLead: 0, now: { t })
    #expect(s.activeRule.kind == .posture)
    t += 90; s.tick()
    #expect(s.phase == .breaking)
    #expect(s.activeRule.kind == .posture)
    #expect(s.secondsLeft == 20)
    t += 20; s.tick()
    #expect(s.phase == .working)
    // eyes was due (100 <= 110) so the posture break covered it; both restart their intervals.
    #expect(s.activeRule.kind == .posture)
    #expect(s.secondsLeft == 90)
}

@Test func disabledRulesNeverFire() {
    var t = Date(timeIntervalSince1970: 0)
    let s = BreakScheduler(rules: [rule(.eyes, 10, 5, enabled: false)], headsUpLead: 0, now: { t })
    #expect(!s.hasUpcoming)
    t += 100; s.tick()
    #expect(s.phase == .working)
}
