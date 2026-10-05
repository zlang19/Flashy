import Foundation
import XCTest
@testable import FlashyCore

final class SchedulerTests: XCTestCase {
    func testNewCardIntervals() {
        XCTAssertEqual(Scheduler.nextInterval(after: 0, rating: .bad), 1)
        XCTAssertEqual(Scheduler.nextInterval(after: 0, rating: .okay), 2)
        XCTAssertEqual(Scheduler.nextInterval(after: 0, rating: .good), 3)
    }

    func testGoodProgression() {
        var interval = 0
        var seen: [Int] = []
        for _ in 0..<7 {
            interval = Scheduler.nextInterval(after: interval, rating: .good)
            seen.append(interval)
        }
        XCTAssertEqual(seen, [3, 8, 20, 50, 125, 180, 180])
    }

    func testOkayAlwaysAdvancesAtLeastOneDay() {
        XCTAssertEqual(Scheduler.nextInterval(after: 2, rating: .okay), 3)
        XCTAssertEqual(Scheduler.nextInterval(after: 10, rating: .okay), 12)
        XCTAssertEqual(Scheduler.nextInterval(after: 180, rating: .okay), 180)
    }

    func testBadResets() {
        XCTAssertEqual(Scheduler.nextInterval(after: 125, rating: .bad), 1)
    }

    func testReviewSetsDueDay() {
        let reviewed = Scheduler.review(.new, rating: .good, on: StudyDay(100))
        XCTAssertEqual(reviewed, Schedule(intervalDays: 3, dueDay: StudyDay(103)))
        XCTAssertFalse(reviewed.isDue(on: StudyDay(102)))
        XCTAssertTrue(reviewed.isDue(on: StudyDay(103)))
    }
}

final class StudyCalendarTests: XCTestCase {
    let studyCalendar: StudyCalendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return StudyCalendar(calendar: calendar)
    }()

    func date(_ string: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.timeZone = studyCalendar.calendar.timeZone
        return formatter.date(from: string)!
    }

    func testDayRollsOverAtFourAM() {
        let evening = studyCalendar.day(containing: date("2026-10-05 22:00"))
        let lateNight = studyCalendar.day(containing: date("2026-10-06 03:59"))
        let morning = studyCalendar.day(containing: date("2026-10-06 04:00"))
        XCTAssertEqual(evening, lateNight)
        XCTAssertEqual(morning, evening.adding(1))
    }

    func testStartOfDayRoundTrips() {
        let day = studyCalendar.day(containing: date("2026-10-05 12:00"))
        XCTAssertEqual(studyCalendar.start(of: day), date("2026-10-05 04:00"))
        XCTAssertEqual(studyCalendar.day(containing: studyCalendar.start(of: day)), day)
    }

    func testAcrossDaylightSavingChange() {
        // US clocks fall back on 2026-11-01.
        let before = studyCalendar.day(containing: date("2026-10-31 12:00"))
        let after = studyCalendar.day(containing: date("2026-11-02 12:00"))
        XCTAssertEqual(before.days(until: after), 2)
        XCTAssertEqual(studyCalendar.start(of: after), date("2026-11-02 04:00"))
    }
}

final class DailySetTests: XCTestCase {
    struct SeededGenerator: RandomNumberGenerator {
        var state: UInt64
        mutating func next() -> UInt64 {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return state
        }
    }

    let today = StudyDay(50)

    func testOrdersMostOverdueFirstThenNew() {
        let cards: [(id: String, schedule: Schedule)] = [
            ("new1", .new),
            ("today", Schedule(intervalDays: 3, dueDay: today)),
            ("future", Schedule(intervalDays: 3, dueDay: today.adding(1))),
            ("old", Schedule(intervalDays: 3, dueDay: today.adding(-5))),
            ("new2", .new),
        ]
        var rng = SeededGenerator(state: 1)
        let set = DailySet.build(from: cards, on: today, using: &rng)
        XCTAssertEqual(Array(set.prefix(2)), ["old", "today"])
        XCTAssertEqual(Set(set.suffix(2)), ["new1", "new2"])
        XCTAssertFalse(set.contains("future"))
    }

    func testOutstandingCountsAccumulate() {
        let schedules = [
            Schedule.new,
            Schedule(intervalDays: 1, dueDay: today.adding(1)),
            Schedule(intervalDays: 1, dueDay: today.adding(3)),
        ]
        XCTAssertEqual(DailySet.outstandingCounts(schedules, from: today, days: 4), [1, 2, 2, 3])
    }

    func testArrivalsFoldOverdueAndNewIntoFirstDay() {
        let schedules = [
            Schedule.new,
            Schedule(intervalDays: 1, dueDay: today.adding(-2)),
            Schedule(intervalDays: 1, dueDay: today.adding(2)),
            Schedule(intervalDays: 1, dueDay: today.adding(30)),
        ]
        XCTAssertEqual(DailySet.arrivals(schedules, from: today, days: 3), [2, 0, 1])
    }
}

final class ReviewSessionTests: XCTestCase {
    func testBadCardsRequeueAndOnlyFirstRatingCounts() {
        var session = ReviewSession(cards: ["a", "b", "a"])
        XCTAssertEqual(session.totalCards, 2)

        XCTAssertEqual(session.rate(.bad)?.isFirst, true)   // a → requeued
        XCTAssertEqual(session.unratedCount, 1)
        XCTAssertEqual(session.rate(.good)?.id, "b")
        XCTAssertEqual(session.current, "a")
        let again = session.rate(.bad)                      // a again → requeued again
        XCTAssertEqual(again?.isFirst, false)
        XCTAssertEqual(session.current, "a")
        session.rate(.okay)

        XCTAssertTrue(session.isFinished)
        XCTAssertEqual(session.unratedCount, 0)
        XCTAssertEqual(session.summary, [.bad: 1, .good: 1])
        XCTAssertNil(session.rate(.good))
    }
}
