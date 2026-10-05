import Foundation

/// A review day, counted from a fixed reference. Days roll over at
/// `StudyCalendar.rolloverHour` local time rather than midnight, so a late-night
/// session still counts toward the day it started in.
public struct StudyDay: Hashable, Comparable, Codable, Sendable, CustomStringConvertible {
    public let index: Int

    public init(_ index: Int) {
        self.index = index
    }

    public func adding(_ days: Int) -> StudyDay {
        StudyDay(index + days)
    }

    public func days(until other: StudyDay) -> Int {
        other.index - index
    }

    public static func < (lhs: StudyDay, rhs: StudyDay) -> Bool {
        lhs.index < rhs.index
    }

    public var description: String { "StudyDay(\(index))" }
}

/// Converts between wall-clock dates and `StudyDay`s.
public struct StudyCalendar: Sendable {
    public static let rolloverHour = 4

    public let calendar: Calendar
    private let reference: Date

    public init(calendar: Calendar = .current) {
        self.calendar = calendar
        self.reference = calendar.date(from: DateComponents(year: 2001, month: 1, day: 1))!
    }

    public func day(containing date: Date) -> StudyDay {
        let shifted = calendar.date(byAdding: .hour, value: -Self.rolloverHour, to: date)!
        let start = calendar.startOfDay(for: shifted)
        return StudyDay(calendar.dateComponents([.day], from: reference, to: start).day!)
    }

    /// The moment `day` begins: its rollover hour, local time.
    public func start(of day: StudyDay) -> Date {
        let midnight = calendar.date(byAdding: .day, value: day.index, to: reference)!
        return calendar.date(byAdding: .hour, value: Self.rolloverHour, to: midnight)!
    }
}
