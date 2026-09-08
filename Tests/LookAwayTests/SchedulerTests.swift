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

@Test func idleCountsAsNaturalBreak() {
    var t = Date(timeIntervalSince1970: 0)
    let s = BreakScheduler(rules: [rule(.eyes, 100, 20)], headsUpLead: 0, now: { t })
    t += 90
    s.registerIdle(10)            // shorter than the break: ignored
    s.tick(); #expect(s.secondsLeft == 10)
    s.registerIdle(25)            // long enough: interval restarts
    s.tick(); #expect(s.secondsLeft == 100)
}

@Test func blockedDefersThenHeadsUpFollows() {
    var t = Date(timeIntervalSince1970: 0)
    let s = BreakScheduler(rules: [rule(.eyes, 100, 10)], headsUpLead: 30, now: { t })
    s.blocked = true
    t += 100; s.tick()
    t += 20; s.tick()
    #expect(s.phase == .working)
    s.blocked = false
    t += 1; s.tick()
    #expect(s.phase == .headsUp)      // a heads-up, not an instant break
    t += 31; s.tick()
    #expect(s.phase == .breaking)
}

@Test func typingDefersBreakUpToLimit() {
    var t = Date(timeIntervalSince1970: 0)
    let s = BreakScheduler(rules: [rule(.eyes, 10, 5)], headsUpLead: 0, now: { t })
    s.userActive = true
    t += 10; s.tick()
    #expect(s.phase == .working)
    t += 29; s.tick()
    #expect(s.phase == .working)
    t += 2; s.tick()
    #expect(s.phase == .breaking)
}

@Test func pauseBlocksUntilExpiry() {
    var t = Date(timeIntervalSince1970: 0)
    let s = BreakScheduler(rules: [rule(.eyes, 10, 5)], headsUpLead: 0, now: { t })
    s.pausedUntil = t.addingTimeInterval(60)
    t += 30; s.tick()
    #expect(s.phase == .working)
    t += 31; s.tick()
    #expect(s.pausedUntil == nil)
}

@Test func idleDuringHeadsUpCancelsIt() {
    var t = Date(timeIntervalSince1970: 0)
    let s = BreakScheduler(rules: [rule(.eyes, 100, 20)], headsUpLead: 30, now: { t })
    t += 80; s.tick()
    #expect(s.phase == .headsUp)
    s.registerIdle(25); s.tick()
    #expect(s.phase == .working)
}

@Test func plannedBreakFiresAtClockTimeAndRepeatsDaily() {
    let cal = Calendar.current
    var t = cal.date(from: DateComponents(year: 2026, month: 1, day: 5, hour: 11, minute: 59, second: 0))!
    let lunch = BreakRule(kind: .planned, interval: 86400, duration: 60, message: "", name: "Lunch", minuteOfDay: 12 * 60)
    let s = BreakScheduler(rules: [lunch], headsUpLead: 0, now: { t })
    t += 59; s.tick()
    #expect(s.phase == .working)
    t += 1; s.tick()
    #expect(s.phase == .breaking)
    #expect(s.activeRule.title == "Lunch")
    t += 60; s.tick()
    #expect(s.phase == .working)
    #expect(s.secondsLeft > 23 * 3600)   // next one is tomorrow
}

@Test func missedPlannedBreakIsSkippedNotFiredLate() {
    let cal = Calendar.current
    var t = cal.date(from: DateComponents(year: 2026, month: 1, day: 5, hour: 11, minute: 0))!
    let lunch = BreakRule(kind: .planned, interval: 86400, duration: 60, message: "", name: "Lunch", minuteOfDay: 12 * 60)
    let s = BreakScheduler(rules: [lunch], headsUpLead: 0, now: { t })
    t += 3 * 3600; s.tick()           // Mac slept through noon
    #expect(s.phase == .working)
}
