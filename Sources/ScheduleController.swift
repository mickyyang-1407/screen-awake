import AppKit

@MainActor
final class ScheduleController {
    static let storageKey = "displaySchedule.v1"
    private let defaults: UserDefaults
    private var timer: Timer?
    private var generation = 0
    private var observers: [NSObjectProtocol] = []
    private(set) var settings: ScheduleSettings
    private(set) var nextEvent: ScheduledEvent?
    private(set) var missedEvent = false
    var onChange: (() -> Void)?
    // Return false only while display controls are busy; retries are bounded to 30 seconds.
    var onEvent: ((ScheduledEvent) -> Bool)?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        settings = Self.loadSettings(defaults: defaults)
    }

    static func loadSettings(defaults: UserDefaults) -> ScheduleSettings {
        if let data = defaults.data(forKey: storageKey),
           let loaded = try? JSONDecoder().decode(ScheduleSettings.self, from: data), loaded.daily.valid {
            return loaded
        }
        return ScheduleSettings()
    }

    func start() {
        guard observers.isEmpty else { return }
        let center = NotificationCenter.default
        for name in [NSNotification.Name.NSSystemTimeZoneDidChange, NSNotification.Name.NSSystemClockDidChange] {
            observers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.reschedule() }
            })
        }
        let workspace = NSWorkspace.shared.notificationCenter
        observers.append(workspace.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.pause() }
        })
        observers.append(workspace.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.reschedule() }
        })
        reschedule()
    }

    func stop() {
        pause()
        nextEvent = nil
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        observers.removeAll()
    }

    func saveDaily(_ daily: DailySchedule) -> Bool {
        guard daily.valid else { return false }
        settings.daily = daily
        settings.lastWake = nil
        settings.lastDim = nil
        missedEvent = false
        persist()
        reschedule()
        return true
    }

    func startCountdown(minutes: Int, action: DisplayAction) -> Bool {
        guard (1...1440).contains(minutes) else { return false }
        settings.countdown = CountdownSchedule(deadline: Date().addingTimeInterval(Double(minutes) * 60), action: action)
        missedEvent = false
        persist()
        reschedule()
        return true
    }

    func cancelCountdown() {
        settings.countdown = nil
        persist()
        reschedule()
    }

    func reschedule() {
        pause()
        let now = Date()
        // Expired countdowns are never replayed after launch, wake, or clock changes.
        if let countdown = settings.countdown, countdown.deadline <= now {
            settings.countdown = nil
            missedEvent = true
            persist()
        }
        nextEvent = SchedulePlanner.next(in: settings, after: now)
        if let nextEvent { arm(nextEvent, after: max(0.05, nextEvent.date.timeIntervalSince(now)), generation: generation) }
        onChange?()
    }

    private func pause() {
        generation += 1
        timer?.invalidate()
        timer = nil
    }

    private func arm(_ event: ScheduledEvent, after delay: TimeInterval, generation token: Int) {
        timer = Timer(timeInterval: delay, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { self?.fire(event, generation: token) }
        }
        timer?.tolerance = min(1, delay / 10)
        if let timer { RunLoop.main.add(timer, forMode: .common) }
    }

    private func fire(_ event: ScheduledEvent, generation token: Int) {
        guard token == generation else { return }
        let late = Date().timeIntervalSince(event.date)
        if late < -0.1 { reschedule(); return }
        if late <= 30, onEvent?(event) != true {
            arm(event, after: 1, generation: token)
            return
        }
        if late > 30 { missedEvent = true }
        // Consume all coincident events, including a daily Wake suppressed by a Dim timer.
        var dailyOnly = settings
        dailyOnly.countdown = nil
        if let dailyEvent = SchedulePlanner.next(in: dailyOnly, after: event.date.addingTimeInterval(-0.01)),
           abs(dailyEvent.date.timeIntervalSince(event.date)) < 0.01 {
            if dailyEvent.action == .wake { settings.lastWake = dailyEvent.date }
            else { settings.lastDim = dailyEvent.date }
        }
        if let countdown = settings.countdown, abs(countdown.deadline.timeIntervalSince(event.date)) < 0.01 {
            settings.countdown = nil
        }
        persist()
        reschedule()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(settings) { defaults.set(data, forKey: Self.storageKey) }
    }
}
