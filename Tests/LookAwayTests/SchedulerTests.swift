import Testing
import Foundation
@testable import LookAwayCore

@Test func workingThenBreakThenWorking() {
    var t = Date(timeIntervalSince1970: 0)
    let s = BreakScheduler(interval: 60, duration: 10, headsUpLead: 0, now: { t })
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
    let s = BreakScheduler(interval: 60, duration: 10, now: { t })
    s.startBreak()
    t += 3
    s.endBreak()
    #expect(s.phase == .working)
    #expect(s.secondsLeft == 60)
}

@Test func headsUpThenSnoozeThenBreak() {
    var t = Date(timeIntervalSince1970: 0)
    let s = BreakScheduler(interval: 100, duration: 10, headsUpLead: 30, now: { t })
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
    let s = BreakScheduler(interval: 100, duration: 10, now: { t })
    s.startBreak(duration: 300)
    #expect(s.phase == .breaking)
    #expect(s.secondsLeft == 300)
}
