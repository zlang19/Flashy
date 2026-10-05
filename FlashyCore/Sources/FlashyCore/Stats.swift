import Foundation

/// A card's first rating in a daily set. Practice reviews and repeat ratings of
/// re-queued cards aren't logged.
public struct ReviewEvent: Equatable, Sendable {
    public var cardID: String
    public var day: StudyDay
    public var rating: Rating

    public init(cardID: String, day: StudyDay, rating: Rating) {
        self.cardID = cardID
        self.day = day
        self.rating = rating
    }
}

/// What happened on a past study day, for the streak.
public enum DayOutcome: String, Codable, Sendable {
    /// The daily set was finished.
    case cleared
    /// Nothing was due. Neither extends nor breaks a streak.
    case empty
    /// Cards were due and not all were reviewed.
    case missed
}

public enum Maturity: String, CaseIterable, Sendable {
    case new, learning, mature

    public static let matureThreshold = 21

    public init(_ schedule: Schedule) {
        if schedule.isNew {
            self = .new
        } else if schedule.intervalDays < Self.matureThreshold {
            self = .learning
        } else {
            self = .mature
        }
    }
}

public struct DailyRatings: Equatable, Sendable {
    public var day: StudyDay
    public var good = 0
    public var okay = 0
    public var bad = 0

    public var total: Int { good + okay + bad }

    public subscript(rating: Rating) -> Int {
        switch rating {
        case .good: return good
        case .okay: return okay
        case .bad: return bad
        }
    }

    mutating func add(_ rating: Rating) {
        switch rating {
        case .good: good += 1
        case .okay: okay += 1
        case .bad: bad += 1
        }
    }
}

public struct CategoryAccuracy: Equatable, Sendable {
    public var categoryPath: [String]
    public var reviews: Int
    /// Fraction of reviews rated okay or good.
    public var accuracy: Double
}

public enum Stats {
    // MARK: Streak

    /// Current and longest runs of cleared days. Empty days are skipped over. A
    /// missed day, or a past day with no outcome, breaks the run. Today without an
    /// outcome is still in progress, so it doesn't break the current streak.
    public static func streak(outcomes: [StudyDay: DayOutcome], today: StudyDay) -> (current: Int, longest: Int) {
        guard let first = outcomes.keys.min() else { return (0, 0) }
        var run = 0
        var longest = 0
        var day = first
        while day <= today {
            switch outcomes[day] {
            case .cleared:
                run += 1
                longest = max(longest, run)
            case .empty:
                break
            case .missed:
                run = 0
            case nil:
                if day != today { run = 0 }
            }
            day = day.adding(1)
        }
        return (run, longest)
    }

    /// Outcomes for past days that haven't been recorded yet, i.e. days after
    /// `lastEvaluated` and before `today` without a `cleared` record. A day counts as
    /// missed if anything was due on it.
    public static func pendingOutcomes(
        after lastEvaluated: StudyDay,
        before today: StudyDay,
        recorded: Set<StudyDay>,
        wasAnythingDue: (StudyDay) -> Bool
    ) -> [StudyDay: DayOutcome] {
        var outcomes: [StudyDay: DayOutcome] = [:]
        var day = lastEvaluated.adding(1)
        while day < today {
            if !recorded.contains(day) {
                outcomes[day] = wasAnythingDue(day) ? .missed : .empty
            }
            day = day.adding(1)
        }
        return outcomes
    }

    // MARK: Reviews

    /// Ratings per day for every day in `range`, including days with none.
    public static func ratingsByDay(_ events: [ReviewEvent], in range: ClosedRange<StudyDay>) -> [DailyRatings] {
        var byDay: [StudyDay: DailyRatings] = [:]
        for event in events where range.contains(event.day) {
            byDay[event.day, default: DailyRatings(day: event.day)].add(event.rating)
        }
        return (0...range.lowerBound.days(until: range.upperBound)).map { offset in
            let day = range.lowerBound.adding(offset)
            return byDay[day] ?? DailyRatings(day: day)
        }
    }

    /// Fraction of reviews rated okay or good, or nil with no reviews.
    public static func retention(_ events: [ReviewEvent]) -> Double? {
        guard !events.isEmpty else { return nil }
        return Double(events.filter { $0.rating != .bad }.count) / Double(events.count)
    }

    /// Retention per bucket of `bucketDays` days across `range`, skipping empty buckets.
    public static func retentionSeries(
        _ events: [ReviewEvent],
        in range: ClosedRange<StudyDay>,
        bucketDays: Int
    ) -> [(start: StudyDay, retention: Double)] {
        let size = max(bucketDays, 1)
        var buckets: [Int: [ReviewEvent]] = [:]
        for event in events where range.contains(event.day) {
            buckets[range.lowerBound.days(until: event.day) / size, default: []].append(event)
        }
        return buckets.keys.sorted().compactMap { bucket in
            retention(buckets[bucket]!).map { (range.lowerBound.adding(bucket * size), $0) }
        }
    }

    public static func maturityCounts(_ schedules: [Schedule]) -> [Maturity: Int] {
        var counts = Dictionary(uniqueKeysWithValues: Maturity.allCases.map { ($0, 0) })
        for schedule in schedules { counts[Maturity(schedule), default: 0] += 1 }
        return counts
    }

    /// Accuracy per category, weakest first. Events for unknown cards are dropped.
    public static func categoryAccuracy(
        _ events: [ReviewEvent],
        categoryOf: (String) -> [String]?
    ) -> [CategoryAccuracy] {
        var grouped: [[String]: [ReviewEvent]] = [:]
        for event in events {
            if let category = categoryOf(event.cardID) { grouped[category, default: []].append(event) }
        }
        return grouped
            .map { CategoryAccuracy(categoryPath: $0.key, reviews: $0.value.count, accuracy: retention($0.value) ?? 0) }
            .sorted {
                ($0.accuracy, -$0.reviews, $0.categoryPath.joined(separator: "/"))
                    < ($1.accuracy, -$1.reviews, $1.categoryPath.joined(separator: "/"))
            }
    }
}
