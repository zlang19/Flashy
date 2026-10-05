import Foundation

/// One pass through the daily set. A card rated bad goes back to the end of the
/// queue until it's rated okay or good. Only a card's first rating counts toward
/// its schedule.
public struct ReviewSession<ID: Hashable>: Sendable where ID: Sendable {
    public private(set) var queue: [ID]
    public private(set) var firstRatings: [ID: Rating] = [:]
    public let totalCards: Int

    public init(cards: [ID]) {
        var seen = Set<ID>()
        queue = cards.filter { seen.insert($0).inserted }
        totalCards = queue.count
    }

    public var current: ID? { queue.first }
    public var isFinished: Bool { queue.isEmpty }

    /// Cards that still need their first rating. This is the badge count.
    public var unratedCount: Int { totalCards - firstRatings.count }

    /// Rates the current card and advances. Returns the card and whether this was
    /// its first rating.
    @discardableResult
    public mutating func rate(_ rating: Rating) -> (id: ID, isFirst: Bool)? {
        guard !queue.isEmpty else { return nil }
        let id = queue.removeFirst()
        let isFirst = firstRatings[id] == nil
        if isFirst { firstRatings[id] = rating }
        if rating == .bad { queue.append(id) }
        return (id, isFirst)
    }

    public var summary: [Rating: Int] {
        firstRatings.values.reduce(into: [:]) { $0[$1, default: 0] += 1 }
    }
}
