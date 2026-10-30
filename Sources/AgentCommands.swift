import Foundation

nonisolated enum AgentOperation: Codable, Equatable {
    case show
    case awake(Bool)
    case daily(DailySchedule)
    case dailyOff
    case timer(Int, DisplayAction)
    case cancelTimer
    case dim

    static func parse(_ arguments: [String]) -> AgentOperation? {
        if arguments == ["schedule", "show"] { return .show }
        if arguments == ["schedule", "off"] { return .dailyOff }
        if arguments == ["schedule", "cancel"] { return .cancelTimer }
        if arguments == ["awake", "on"] { return .awake(true) }
        if arguments == ["awake", "off"] { return .awake(false) }
        if arguments.count == 4, arguments.prefix(2) == ["schedule", "timer"],
           let minutes = Int(arguments[2]), (1...1440).contains(minutes),
           let action = DisplayAction(rawValue: arguments[3]) { return .timer(minutes, action) }
        guard (4...5).contains(arguments.count), arguments.prefix(2) == ["schedule", "daily"],
              arguments.count == 4 || arguments[4] == "--no-keep-awake" else { return nil }
        func time(_ value: String) -> ScheduleTime? {
            let parts = value.split(separator: ":", omittingEmptySubsequences: false)
            guard parts.count == 2, parts.allSatisfy({ !$0.isEmpty && $0.allSatisfy({ $0.isASCII && $0.isNumber }) }),
                  let hour = Int(parts[0]), let minute = Int(parts[1]) else { return nil }
            let result = ScheduleTime(hour: hour, minute: minute)
            return result.valid ? result : nil
        }
        guard arguments[2] == "off" || time(arguments[2]) != nil,
              arguments[3] == "off" || time(arguments[3]) != nil else { return nil }
        let daily = DailySchedule(enabled: true, wakeEnabled: arguments[2] != "off",
            wake: time(arguments[2]) ?? ScheduleTime(hour: 9, minute: 0),
            dimEnabled: arguments[3] != "off", dim: time(arguments[3]) ?? ScheduleTime(hour: 18, minute: 0),
            keepAwakeAfterWake: arguments.count == 4)
        return daily.valid ? .daily(daily) : nil
    }
}

nonisolated struct AgentState: Codable {
    var version: String
    var appRunning: Bool
    var keepAwake: Bool
    var settings: ScheduleSettings
    var nextAction: DisplayAction?
    var nextDate: Date?
}

nonisolated struct AgentReply: Codable {
    var success: Bool
    var message: String
    var state: AgentState?
}

@MainActor
enum AgentOffline {
    static func apply(_ operation: AgentOperation, settings: inout ScheduleSettings) -> Bool {
        switch operation {
        case .show, .awake(false): return true
        case .dailyOff: settings.daily.enabled = false; return true
        case .cancelTimer: settings.countdown = nil; return true
        default: return false
        }
    }

    static func store(_ settings: ScheduleSettings, defaults: UserDefaults) -> Bool {
        guard let data = try? JSONEncoder().encode(settings) else { return false }
        defaults.set(data, forKey: ScheduleController.storageKey)
        return defaults.synchronize()
    }
}

@MainActor
final class AgentService {
    let schedules: ScheduleController
    var getAwake: () -> Bool = { false }
    var setAwake: (Bool) -> Bool = { _ in false }
    var wake: (@escaping (Int32) -> Void) -> Bool = { _ in false }
    var dim: (@escaping (Int32) -> Void) -> Bool = { _ in false }
    init(schedules: ScheduleController) { self.schedules = schedules }

    func state() -> AgentState {
        AgentState(version: AppVersion.current, appRunning: true, keepAwake: getAwake(), settings: schedules.settings,
                   nextAction: schedules.nextEvent?.action, nextDate: schedules.nextEvent?.date)
    }

    func handle(_ operation: AgentOperation, completion: @escaping (AgentReply) -> Void) {
        func finish(_ success: Bool, _ message: String) {
            completion(AgentReply(success: success, message: message, state: state()))
        }
        switch operation {
        case .show: finish(true, "Current app state.")
        case .awake(let enabled):
            let success = setAwake(enabled)
            guard success else { finish(false, "Could not change keep-awake. See the app for details."); return }
            guard enabled else { finish(true, "Keep-awake disabled."); return }
            let accepted = wake { [weak self] code in
                guard let self else { return }
                completion(AgentReply(success: code == 0,
                    message: code == 0 ? "Keep-awake enabled and display wake requested." : "Keep-awake enabled, but display wake failed (\(code)).",
                    state: self.state()))
            }
            if !accepted { finish(false, "Keep-awake enabled, but display controls are busy.") }
        case .daily(let daily):
            let success = schedules.saveDaily(daily)
            finish(success, success ? "Daily schedule saved. No immediate display action." : "Invalid daily schedule.")
        case .dailyOff:
            var daily = schedules.settings.daily
            daily.enabled = false
            let success = schedules.saveDaily(daily)
            finish(success, "Daily schedule disabled; countdown unchanged.")
        case .timer(let minutes, let action):
            let success = schedules.startCountdown(minutes: minutes, action: action)
            finish(success, success ? "Countdown started." : "Invalid countdown.")
        case .cancelTimer:
            schedules.cancelCountdown()
            finish(true, "Countdown canceled; daily schedule unchanged.")
        case .dim:
            let accepted = dim { [weak self] code in
                guard let self else { return }
                completion(AgentReply(success: code == 0, message: code == 0 ? "Display sleep requested." : "Display sleep failed (\(code)).", state: self.state()))
            }
            if !accepted { finish(false, "Display controls are busy. Wait for the current action to finish.") }
        }
    }
}
