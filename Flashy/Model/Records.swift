import Foundation
import SwiftData
import FlashyCore

/// A card synced from the repo, plus its review schedule. Records are never
/// deleted: a card removed from the repo is marked inactive so its history comes
/// back if the folder reappears.
@Model
final class CardRecord {
    /// Card folder path relative to `flashcards/`, e.g. `bio/cells/mitosis`.
    @Attribute(.unique) var id: String
    var title: String
    var categoryPath: [String]
    var tags: [String]
    var front: String
    var back: String
    /// Fingerprint of every file in the card folder. Any change resets the schedule.
    var contentHash: String
    var isActive: Bool
    var intervalDays: Int
    /// nil while the card is new.
    var dueDayIndex: Int?
    /// The day the card most recently became new (first synced, or reset by an
    /// edit). Before this day it couldn't have been due.
    var newSinceDayIndex: Int

    init(id: String, newSince day: StudyDay) {
        self.id = id
        self.title = ""
        self.categoryPath = []
        self.tags = []
        self.front = ""
        self.back = ""
        self.contentHash = ""
        self.isActive = true
        self.intervalDays = 0
        self.dueDayIndex = nil
        self.newSinceDayIndex = day.index
    }

    var schedule: Schedule {
        get { Schedule(intervalDays: intervalDays, dueDay: dueDayIndex.map(StudyDay.init)) }
        set {
            intervalDays = newValue.intervalDays
            dueDayIndex = newValue.dueDay?.index
        }
    }

    /// Repo-relative folder, for resolving image paths.
    var directory: String { RepoLayout.root + "/" + id }
    var breadcrumb: String { Naming.breadcrumb(categoryPath) }

    /// Could this card have been waiting for review on `day`?
    func wasDue(on day: StudyDay) -> Bool {
        newSinceDayIndex <= day.index && schedule.isDue(on: day)
    }
}

/// A card's first rating in a daily set.
@Model
final class ReviewRecord {
    var cardID: String
    var dayIndex: Int
    var date: Date
    var ratingRaw: String
    /// The interval the rating produced.
    var intervalDays: Int

    init(cardID: String, day: StudyDay, date: Date, rating: Rating, intervalDays: Int) {
        self.cardID = cardID
        self.dayIndex = day.index
        self.date = date
        self.ratingRaw = rating.rawValue
        self.intervalDays = intervalDays
    }

    var event: ReviewEvent {
        ReviewEvent(cardID: cardID, day: StudyDay(dayIndex), rating: Rating(rawValue: ratingRaw) ?? .bad)
    }
}

/// How a past study day went, for the streak.
@Model
final class DayRecord {
    @Attribute(.unique) var dayIndex: Int
    var outcomeRaw: String

    init(day: StudyDay, outcome: DayOutcome) {
        self.dayIndex = day.index
        self.outcomeRaw = outcome.rawValue
    }

    var outcome: DayOutcome { DayOutcome(rawValue: outcomeRaw) ?? .missed }
}
