import Foundation
import UserNotifications
import FlashyCore

/// The app badge and scheduled local notifications. iOS won't run the app at the
/// daily rollover, so future badge counts are scheduled ahead of time as
/// badge-only notifications.
enum Notifications {
    private static var center: UNUserNotificationCenter { .current() }
    /// iOS keeps at most 64 pending notifications: 30 badge updates plus up to 30 reminders.
    static let daysAhead = 30

    static func requestAuthorization() async {
        _ = try? await center.requestAuthorization(options: [.badge, .alert, .sound])
    }

    static func setBadge(_ count: Int) {
        center.setBadgeCount(count) { _ in }
    }

    /// Replaces every pending notification.
    /// - Parameter reminder: hour and minute of the daily reminder, or nil if off.
    static func reschedule(
        schedules: [Schedule],
        today: StudyDay,
        calendar: StudyCalendar,
        reminder: (hour: Int, minute: Int)?
    ) {
        center.removeAllPendingNotificationRequests()
        let counts = DailySet.outstandingCounts(schedules, from: today, days: daysAhead + 1)

        for offset in 1...daysAhead {
            let content = UNMutableNotificationContent()
            content.badge = NSNumber(value: counts[offset])
            add("badge-\(offset)", content, at: calendar.start(of: today.adding(offset)), calendar: calendar.calendar)
        }

        guard let reminder else { return }
        for offset in 0..<daysAhead {
            guard let fire = calendar.calendar.date(
                bySettingHour: reminder.hour, minute: reminder.minute, second: 0,
                of: calendar.start(of: today.adding(offset))
            ), fire > .now else { continue }
            // A reminder before the rollover hour belongs to the previous study day.
            let dayOffset = today.days(until: calendar.day(containing: fire))
            guard counts.indices.contains(dayOffset), counts[dayOffset] > 0 else { continue }
            let count = counts[dayOffset]
            let content = UNMutableNotificationContent()
            content.title = "Flashy"
            content.body = count == 1 ? "1 card is waiting for review." : "\(count) cards are waiting for review."
            content.sound = .default
            content.badge = NSNumber(value: count)
            add("reminder-\(offset)", content, at: fire, calendar: calendar.calendar)
        }
    }

    private static func add(_ id: String, _ content: UNNotificationContent, at date: Date, calendar: Calendar) {
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}
