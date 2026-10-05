import Foundation

public enum DailySet {
    /// Today's review order: due cards, most overdue first, then every new card.
    /// Cards are shuffled within each due day and within the new group.
    public static func build<ID: Hashable, G: RandomNumberGenerator>(
        from cards: [(id: ID, schedule: Schedule)],
        on day: StudyDay,
        using rng: inout G
    ) -> [ID] {
        var dueByDay: [StudyDay: [ID]] = [:]
        var new: [ID] = []
        for card in cards {
            if let due = card.schedule.dueDay {
                if due <= day { dueByDay[due, default: []].append(card.id) }
            } else {
                new.append(card.id)
            }
        }
        var ordered: [ID] = []
        for due in dueByDay.keys.sorted() {
            ordered += dueByDay[due]!.shuffled(using: &rng)
        }
        return ordered + new.shuffled(using: &rng)
    }

    public static func build<ID: Hashable>(from cards: [(id: ID, schedule: Schedule)], on day: StudyDay) -> [ID] {
        var rng = SystemRandomNumberGenerator()
        return build(from: cards, on: day, using: &rng)
    }

    /// How many cards will be waiting on each of `days` days starting at `start`,
    /// assuming nothing is reviewed in between. Drives the future badge counts.
    public static func outstandingCounts(_ schedules: [Schedule], from start: StudyDay, days: Int) -> [Int] {
        (0..<days).map { offset in
            let day = start.adding(offset)
            return schedules.filter { $0.isDue(on: day) }.count
        }
    }

    /// How many cards come due on each of `days` days starting at `start`. New and
    /// overdue cards are counted on the first day.
    public static func arrivals(_ schedules: [Schedule], from start: StudyDay, days: Int) -> [Int] {
        var counts = Array(repeating: 0, count: days)
        guard days > 0 else { return counts }
        for schedule in schedules {
            let offset = schedule.dueDay.map { max(start.days(until: $0), 0) } ?? 0
            if offset < days { counts[offset] += 1 }
        }
        return counts
    }
}
