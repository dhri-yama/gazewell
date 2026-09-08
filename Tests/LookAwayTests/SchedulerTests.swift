import Testing
import Foundation
@testable import LookAwayCore

@Test func workingThenBreakThenWorking() {
    var t = Date(timeIntervalSince1970: 0)
    let s = BreakScheduler(interval: 60, duration: 10, now: { t })
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
