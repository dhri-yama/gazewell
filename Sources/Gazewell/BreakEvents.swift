import Combine
import GazewellCore

extension BreakScheduler {
    /// Calls `start` when a break begins and `end` when it finishes or is skipped. Heads-up changes are ignored.
    func onBreak(start: @escaping () -> Void, end: @escaping () -> Void) -> AnyCancellable {
        $phase.removeDuplicates()
            .scan((Phase.working, Phase.working)) { ($0.1, $1) }
            .sink { prev, next in
                if next == .breaking { start() } else if prev == .breaking { end() }
            }
    }
}
