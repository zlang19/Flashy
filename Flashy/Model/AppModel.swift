import Foundation
import Observation
import SwiftData
import FlashyCore

/// App-wide state and actions. Views read card data through `@Query` and come
/// here to change it.
@MainActor
@Observable
final class AppModel {
    let container: ModelContainer
    let studyCalendar: StudyCalendar
    private(set) var today: StudyDay
    private(set) var syncState: SyncState
    private(set) var isSyncing = false
    private(set) var syncError: String?
    private(set) var reminderEnabled: Bool
    /// Minutes after midnight.
    private(set) var reminderMinutes: Int

    @ObservationIgnored private let defaults = UserDefaults.standard
    @ObservationIgnored private let syncService = SyncService()

    private enum Keys {
        static let syncState = "syncState"
        static let reminderEnabled = "reminderEnabled"
        static let reminderMinutes = "reminderMinutes"
        static let lastEvaluatedDay = "lastEvaluatedDay"
    }

    init(container: ModelContainer) {
        let studyCalendar = StudyCalendar()
        self.container = container
        self.studyCalendar = studyCalendar
        self.today = studyCalendar.day(containing: .now)
        self.syncState = UserDefaults.standard.data(forKey: Keys.syncState)
            .flatMap { try? JSONDecoder().decode(SyncState.self, from: $0) } ?? SyncState()
        self.reminderEnabled = UserDefaults.standard.bool(forKey: Keys.reminderEnabled)
        self.reminderMinutes = UserDefaults.standard.object(forKey: Keys.reminderMinutes) as? Int ?? 19 * 60
    }

    private var context: ModelContext { container.mainContext }

    // MARK: Lifecycle

    func becameActive() {
        today = studyCalendar.day(containing: .now)
        // Settle past days before syncing, so new cards don't look like they were
        // due on days before they existed.
        recordPastOutcomes()
        updateBadge()
        Task { await sync() }
    }

    func enteredBackground() {
        rescheduleNotifications()
    }

    // MARK: Cards

    func activeCards() -> [CardRecord] {
        (try? context.fetch(FetchDescriptor<CardRecord>(predicate: #Predicate { $0.isActive }))) ?? []
    }

    /// Today's set in review order.
    func dailySet() -> [CardRecord] {
        let cards = activeCards()
        let byID = Dictionary(cards.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return DailySet.build(from: cards.map { (id: $0.id, schedule: $0.schedule) }, on: today)
            .compactMap { byID[$0] }
    }

    /// Applies a card's first rating of the day: reschedules it, logs the review,
    /// and updates the badge and streak.
    func record(_ rating: Rating, for card: CardRecord) {
        card.schedule = Scheduler.review(card.schedule, rating: rating, on: today)
        context.insert(ReviewRecord(cardID: card.id, day: today, date: .now, rating: rating, intervalDays: card.intervalDays))
        let remaining = activeCards().filter { $0.schedule.isDue(on: today) }.count
        if remaining == 0 { setOutcome(.cleared, for: today) }
        try? context.save()
        Notifications.setBadge(remaining)
    }

    func updateBadge() {
        Notifications.setBadge(activeCards().filter { $0.schedule.isDue(on: today) }.count)
    }

    // MARK: Streak

    /// Records missed or empty outcomes for days that ended since the last check.
    private func recordPastOutcomes() {
        guard let last = defaults.object(forKey: Keys.lastEvaluatedDay) as? Int else {
            defaults.set(today.index - 1, forKey: Keys.lastEvaluatedDay)
            return
        }
        let recorded = Set(((try? context.fetch(FetchDescriptor<DayRecord>())) ?? []).map { StudyDay($0.dayIndex) })
        let cards = activeCards()
        let pending = Stats.pendingOutcomes(after: StudyDay(last), before: today, recorded: recorded) { day in
            cards.contains { $0.wasDue(on: day) }
        }
        for (day, outcome) in pending {
            context.insert(DayRecord(day: day, outcome: outcome))
        }
        try? context.save()
        defaults.set(max(last, today.index - 1), forKey: Keys.lastEvaluatedDay)
    }

    private func setOutcome(_ outcome: DayOutcome, for day: StudyDay) {
        let index = day.index
        let existing = try? context.fetch(FetchDescriptor<DayRecord>(predicate: #Predicate { $0.dayIndex == index }))
        if let record = existing?.first {
            record.outcomeRaw = outcome.rawValue
        } else {
            context.insert(DayRecord(day: day, outcome: outcome))
        }
    }

    // MARK: Sync

    func sync() async {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }
        do {
            syncState = try await syncService.sync(context: context, from: syncState, today: today)
            syncError = nil
            if let data = try? JSONEncoder().encode(syncState) {
                defaults.set(data, forKey: Keys.syncState)
            }
        } catch let error as GitHubError {
            syncError = error.description
        } catch {
            syncError = error.localizedDescription
        }
        updateBadge()
    }

    // MARK: Reminder

    func setReminder(enabled: Bool) {
        reminderEnabled = enabled
        defaults.set(enabled, forKey: Keys.reminderEnabled)
        rescheduleNotifications()
    }

    func setReminder(time: Date) {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: time)
        reminderMinutes = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
        defaults.set(reminderMinutes, forKey: Keys.reminderMinutes)
        rescheduleNotifications()
    }

    var reminderTime: Date {
        Calendar.current.date(bySettingHour: reminderMinutes / 60, minute: reminderMinutes % 60, second: 0, of: .now) ?? .now
    }

    func rescheduleNotifications() {
        Notifications.reschedule(
            schedules: activeCards().map(\.schedule),
            today: today,
            calendar: studyCalendar,
            reminder: reminderEnabled ? (reminderMinutes / 60, reminderMinutes % 60) : nil
        )
    }
}
