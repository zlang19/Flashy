import Foundation

public enum Rating: String, Codable, CaseIterable, Sendable {
    case bad, okay, good
}

/// A card's place in the spaced-repetition cycle. A card with no `dueDay` is new
/// and due immediately.
public struct Schedule: Equatable, Codable, Sendable {
    public var intervalDays: Int
    public var dueDay: StudyDay?

    public init(intervalDays: Int, dueDay: StudyDay?) {
        self.intervalDays = intervalDays
        self.dueDay = dueDay
    }

    public static let new = Schedule(intervalDays: 0, dueDay: nil)

    public var isNew: Bool { dueDay == nil }

    public func isDue(on day: StudyDay) -> Bool {
        dueDay.map { $0 <= day } ?? true
    }
}

/// Simplified SM-2 without per-card ease: good grows the interval, okay nudges it,
/// bad starts over.
public enum Scheduler {
    public static let initialInterval = 1
    public static let goodMultiplier = 2.5
    public static let okayMultiplier = 1.2
    public static let maxInterval = 180

    public static func nextInterval(after current: Int, rating: Rating) -> Int {
        let base = max(current, initialInterval)
        let next: Int
        switch rating {
        case .bad:
            next = initialInterval
        case .okay:
            next = max(Int((Double(base) * okayMultiplier).rounded()), base + 1)
        case .good:
            next = Int((Double(base) * goodMultiplier).rounded())
        }
        return min(next, maxInterval)
    }

    public static func review(_ schedule: Schedule, rating: Rating, on day: StudyDay) -> Schedule {
        let interval = nextInterval(after: schedule.intervalDays, rating: rating)
        return Schedule(intervalDays: interval, dueDay: day.adding(interval))
    }
}
