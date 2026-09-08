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

@Test func everyThirdEyesBreakIsLong() {
    var t = Date(timeIntervalSince1970: 0)
    let s = BreakScheduler(rules: [rule(.eyes, 10, 5)], headsUpLead: 0, now: { t })
    s.longBreakEvery = 3; s.longBreakDuration = 60
    var lengths: [Int] = []
    for _ in 0..<3 { t += 10; s.tick(); lengths.append(s.breakLength); t += 100; s.tick() }
    #expect(lengths == [5, 5, 60])
}

@Test func eventsAreReported() {
    var t = Date(timeIntervalSince1970: 0)
    let s = BreakScheduler(rules: [rule(.eyes, 10, 5)], headsUpLead: 0, now: { t })
    var events: [BreakScheduler.Event] = []
    s.onEvent = { events.append($0) }
    t += 10; s.tick(); t += 5; s.tick()          // taken
    t += 10; s.tick(); s.endBreak()               // skipped
    s.postpone(by: 60)                            // snoozed
    #expect(events == [.taken, .skipped, .snoozed])
}

@Test func officeHoursIncludingOvernightRange() {
    var cal = Calendar(identifier: .gregorian); cal.timeZone = TimeZone(identifier: "UTC")!
    var h = OfficeHours(); h.enabled = true; h.start = 8 * 60; h.end = 2 * 60; h.days = [2]   // Mondays 08:00 to 02:00
    func d(_ day: Int, _ hour: Int) -> Date { cal.date(from: DateComponents(timeZone: cal.timeZone, year: 2026, month: 1, day: day, hour: hour))! }
    #expect(h.contains(d(5, 9), calendar: cal))      // Mon 09:00
    #expect(h.contains(d(6, 1), calendar: cal))      // Tue 01:00 (Monday's shift)
    #expect(!h.contains(d(6, 3), calendar: cal))     // Tue 03:00
    #expect(!h.contains(d(7, 9), calendar: cal))     // Wed
}

@Test func statsCountAndStreak() {
    let cal = Calendar.current
    let today = Date()
    var st = Stats()
    st.record(.taken, on: today); st.record(.skipped, on: today)
    st.record(.taken, on: cal.date(byAdding: .day, value: -1, to: today)!)
    #expect(st.day(today).taken == 1 && st.day(today).skipped == 1)
    #expect(st.streak() == 2)
    #expect(st.recent(7).count == 7)
}
