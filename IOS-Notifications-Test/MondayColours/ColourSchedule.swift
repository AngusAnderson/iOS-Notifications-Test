import Foundation
import UserNotifications

struct MondayEntry: Identifiable {
    let date: Date
    let colours: [String]

    var id: Date { date }

    var colourDescription: String {
        colours.joined(separator: " and ")
    }
}

enum ColourSchedule {
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar
    }

    static let entries: [MondayEntry] = {
        let calendar = Self.calendar

        let start = calendar.date(
            from: DateComponents(year: 2026, month: 11, day: 9)
        )!

        let end = calendar.date(
            from: DateComponents(year: 2027, month: 10, day: 25)
        )!

        let mainColours = ["Green", "Blue", "Black"]

        var result: [MondayEntry] = []
        var week = 0

        while let monday = calendar.date(
            byAdding: .weekOfYear,
            value: week,
            to: start
        ), monday <= end {
            var colours = [mainColours[week % 3]]

            if week.isMultiple(of: 2) {
                colours.append("Brown")
            }

            result.append(
                MondayEntry(date: monday, colours: colours)
            )

            week += 1
        }

        return result
    }()

    static func reminderDate(for entry: MondayEntry) -> Date {
        let sunday = calendar.date(
            byAdding: .day,
            value: -1,
            to: entry.date
        )!

        return calendar.date(
            bySettingHour: 18,
            minute: 0,
            second: 0,
            of: sunday
        )!
    }

    static func dateLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "EEEE d MMMM"
        return formatter.string(from: date)
    }
}

enum ReminderError: LocalizedError {
    case permissionDenied

    var errorDescription: String? {
        "Notifications are disabled. Enable them for this app in Settings."
    }
}

enum ColourNotifications {
    private static let prefix = "monday-colour-"

    private static func authorisedCenter()
        async throws -> UNUserNotificationCenter {
        let center = UNUserNotificationCenter.current()

        let allowed = try await center.requestAuthorization(
            options: [.alert, .sound]
        )

        guard allowed else {
            throw ReminderError.permissionDenied
        }

        return center
    }
    
    static func printScheduledReminders() async {
        let center = UNUserNotificationCenter.current()
        let requests = await center.pendingNotificationRequests()

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.timeZone = ColourSchedule.calendar.timeZone
        formatter.dateFormat = "EEEE d MMMM yyyy 'at' HH:mm:ss z"

        let reminders = requests.compactMap { request
            -> (date: Date, body: String)? in

            guard request.identifier.hasPrefix(prefix),
                  let trigger = request.trigger
                    as? UNCalendarNotificationTrigger,
                  let date = trigger.nextTriggerDate()
            else {
                return nil
            }

            return (date: date, body: request.content.body)
        }
        .sorted { $0.date < $1.date }

        for reminder in reminders {
            print("""
            Scheduled: \(formatter.string(from: reminder.date))
            Message: \(reminder.body)
            ------------------------------
            """)
        }

        print("Total scheduled reminders: \(reminders.count)")
    }

    static func schedule() async throws -> Int {
        let center = try await authorisedCenter()

        let pending = await center.pendingNotificationRequests()
        let oldIDs = pending
            .filter { $0.identifier.hasPrefix(prefix) }
            .map(\.identifier)

        center.removePendingNotificationRequests(
            withIdentifiers: oldIDs
        )

        let now = Date()
        var count = 0

        for entry in ColourSchedule.entries {
            let reminderDate = ColourSchedule.reminderDate(for: entry)

            guard reminderDate > now else { continue }

            let content = UNMutableNotificationContent()
            content.title = "Tomorrow’s colour"
            content.body = """
            \(ColourSchedule.dateLabel(entry.date)): \
            \(entry.colourDescription)
            """
            content.sound = .default

            var components = ColourSchedule.calendar.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: reminderDate
            )

            components.calendar = ColourSchedule.calendar
            components.timeZone = ColourSchedule.calendar.timeZone

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: components,
                repeats: false
            )

            let dateID = ColourSchedule.calendar.dateComponents(
                [.year, .month, .day],
                from: entry.date
            )

            let identifier = """
            \(prefix)\(dateID.year!)-\(dateID.month!)-\(dateID.day!)
            """

            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )

            try await center.add(request)
            count += 1
        }

        return count
    }

    static func sendTest() async throws {
        let center = try await authorisedCenter()

        let content = UNMutableNotificationContent()
        content.title = "Tomorrow’s colour"
        content.body = "Example reminder: Blue and Brown"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 10,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "colour-test",
            content: content,
            trigger: trigger
        )

        try await center.add(request)
    }
}
