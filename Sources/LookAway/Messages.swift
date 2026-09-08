import Foundation
import LookAwayCore

struct BreakCopy: Equatable {
    var title: String
    var subtitle: String

    private static let short: [BreakCopy] = [
        .init(title: "Catch a quick rest", subtitle: "Focus on a distant point until it's time to resume"),
        .init(title: "A blink break", subtitle: "Find a distant spot to rest your eyes on while you wait"),
        .init(title: "Eyes off the screen", subtitle: "Look at something 20 feet away"),
    ]
    private static let long: [BreakCopy] = [
        .init(title: "Time for a long break", subtitle: "Stand up, stretch and get some water"),
        .init(title: "Step away for a bit", subtitle: "Walk around and let your eyes and back reset"),
    ]

    /// Picks the text for a break. Custom lines ("Title | Subtitle", or just a subtitle) join the short-break pool.
    static func pick(rule: BreakRule, long isLong: Bool, custom: String) -> BreakCopy {
        if rule.kind == .planned { return .init(title: rule.title, subtitle: rule.message) }
        if isLong { return long.randomElement()! }
        let mine = custom.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }.map { line -> BreakCopy in
            let parts = line.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
            return parts.count > 1 ? .init(title: parts[0], subtitle: parts[1]) : .init(title: "Catch a quick rest", subtitle: parts[0])
        }
        return (mine.isEmpty ? short : mine).randomElement()!
    }
}
