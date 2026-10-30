import Foundation

nonisolated struct ScheduleTime: Codable, Equatable {
    var hour: Int
    var minute: Int
    var valid: Bool { (0...23).contains(hour) && (0...59).contains(minute) }
}

nonisolated struct DailySchedule: Codable, Equatable {
    var enabled = false
    var wakeEnabled = true
    var wake = ScheduleTime(hour: 9, minute: 0)
    var dimEnabled = true
    var dim = ScheduleTime(hour: 18, minute: 0)
    var keepAwakeAfterWake = true
    var valid: Bool {
        wake.valid && dim.valid && (!enabled || ((wakeEnabled || dimEnabled) && !(wakeEnabled && dimEnabled && wake == dim)))
    }
}

nonisolated struct CountdownSchedule: Codable, Equatable {
    var id = UUID()
    var deadline: Date
    var action: DisplayAction
}

nonisolated struct ScheduleSettings: Codable, Equatable {
    var daily = DailySchedule()
    var countdown: CountdownSchedule?
    var lastWake: Date?
    var lastDim: Date?
}

nonisolated struct ScheduledEvent: Equatable {
    enum Source: Equatable { case daily; case countdown(UUID) }
    var date: Date
    var action: DisplayAction
    var source: Source
    var keepAwake: Bool
}

nonisolated enum SchedulePlanner {
    static func next(in settings: ScheduleSettings, after now: Date, calendar: Calendar = .current) -> ScheduledEvent? {
        var events: [ScheduledEvent] = []
        if let timer = settings.countdown, timer.deadline > now {
            events.append(ScheduledEvent(date: timer.deadline, action: timer.action,
                                         source: .countdown(timer.id), keepAwake: false))
        }
        let daily = settings.daily
        if daily.enabled && daily.valid {
            for (action, enabled, time, last) in [(DisplayAction.wake, daily.wakeEnabled, daily.wake, settings.lastWake),
                                                 (.dim, daily.dimEnabled, daily.dim, settings.lastDim)] where enabled {
                var searchAfter = now
                for _ in 0..<3 {
                    guard let date = calendar.nextDate(after: searchAfter,
                        matching: DateComponents(hour: time.hour, minute: time.minute, second: 0),
                        matchingPolicy: .nextTime, repeatedTimePolicy: .first, direction: .forward) else { break }
                    if let last, calendar.isDate(date, inSameDayAs: last) {
                        searchAfter = calendar.dateInterval(of: .day, for: date)?.end.addingTimeInterval(-0.001) ?? date.addingTimeInterval(86399)
                        continue
                    }
                    events.append(ScheduledEvent(date: date, action: action, source: .daily,
                                                 keepAwake: action == .wake && daily.keepAwakeAfterWake))
                    break
                }
            }
        }
        // If two events coincide, Dim wins; the next calculation advances past both.
        return events.sorted {
            if $0.date == $1.date { return $0.action == .dim && $1.action != .dim }
            return $0.date < $1.date
        }.first
    }
}
