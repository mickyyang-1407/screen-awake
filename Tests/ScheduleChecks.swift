import AppKit

// A standalone fixture harness, matching the repository's CLI checks.
// It never links DisplayCommand or IOKit; every event is a local callback.
@main
struct ScheduleChecks {
    @MainActor static func main() throws {
        var checks = 0
        func expect(_ condition: Bool, _ message: String) {
            guard condition else { fatalError(message) }
            checks += 1
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Taipei")!
        func date(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
            calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
        }
        func next(_ settings: ScheduleSettings, _ now: Date) -> ScheduledEvent? {
            SchedulePlanner.next(in: settings, after: now, calendar: calendar)
        }
        var settings = ScheduleSettings()
        expect(next(settings, date(30, 8)) == nil, "New installs have no active schedules")
        settings.daily.enabled = true
        expect(next(settings, date(30, 8))?.date == date(30, 9), "Morning Wake")
        expect(next(settings, date(30, 8))?.keepAwake == true, "Daily Wake holds awake when selected")
        expect(next(settings, date(30, 9))?.action == .dim, "No immediate replay at exact saved time")
        expect(next(settings, date(30, 19))?.date == date(31, 9), "After-hours moves to tomorrow")
        settings.daily.wake = ScheduleTime(hour: 20, minute: 0)
        settings.daily.dim = ScheduleTime(hour: 8, minute: 0)
        expect(next(settings, date(30, 21))?.date == date(31, 8), "Overnight preset dims next morning")
        settings.daily.dimEnabled = false
        expect(next(settings, date(30, 7))?.action == .wake, "Wake-only schedule")
        settings.daily.wakeEnabled = false
        expect(!settings.daily.valid && next(settings, date(30, 7)) == nil, "Empty daily schedule is invalid")
        settings.daily = DailySchedule(enabled: true)
        settings.daily.dim = settings.daily.wake
        expect(!settings.daily.valid, "Equal Wake/Dim times rejected")
        settings.daily.wake.hour = 25
        expect(!settings.daily.valid, "Invalid hour rejected")
        settings.daily = DailySchedule(enabled: true, wake: ScheduleTime(hour: 0, minute: 0), dimEnabled: false)
        settings.lastWake = date(30, 0)
        expect(next(settings, date(29, 23, 59))?.date == date(31, 0), "Clock rollback never duplicates completed midnight or skips the next day")
        settings.lastWake = nil
        expect(next(settings, date(30, 23, 59))?.date == date(31, 0), "Midnight boundary")
        settings.daily = DailySchedule(enabled: true)
        settings.countdown = CountdownSchedule(deadline: date(30, 8, 30), action: .dim)
        expect(next(settings, date(30, 8))?.source == .countdown(settings.countdown!.id), "Countdown precedes daily")
        settings.countdown = CountdownSchedule(deadline: date(30, 9), action: .dim)
        expect(next(settings, date(30, 8))?.action == .dim, "Dim wins a simultaneous Wake")
        settings.countdown = CountdownSchedule(deadline: date(30, 7), action: .dim)
        expect(next(settings, date(30, 8))?.action == .wake, "Expired countdown ignored")
        let encoded = try JSONEncoder().encode(settings)
        expect(try JSONDecoder().decode(ScheduleSettings.self, from: encoded) == settings, "Settings round trip")

        var pacific = Calendar(identifier: .gregorian)
        pacific.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        func dst(_ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
            pacific.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute))!
        }
        var spring = ScheduleSettings()
        spring.daily = DailySchedule(enabled: true, wake: ScheduleTime(hour: 2, minute: 30), dimEnabled: false)
        let springEvent = SchedulePlanner.next(in: spring, after: dst(3, 8, 0), calendar: pacific)
        expect(springEvent?.date == dst(3, 8, 3), "Missing spring time advances to the next valid time")
        spring.daily.wake = ScheduleTime(hour: 1, minute: 30)
        let firstFall = SchedulePlanner.next(in: spring, after: dst(11, 1, 0), calendar: pacific)!
        spring.lastWake = firstFall.date
        let secondFall = SchedulePlanner.next(in: spring, after: firstFall.date.addingTimeInterval(1), calendar: pacific)
        expect(secondFall?.date == dst(11, 2, 1, 30), "Repeated fall hour executes once per local day")

        let suite = "ScreenAwake.ScheduleChecks.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        func store(_ value: ScheduleSettings) throws {
            defaults.set(try JSONEncoder().encode(value), forKey: ScheduleController.storageKey)
        }
        func wait(_ seconds: Double) { RunLoop.current.run(until: Date().addingTimeInterval(seconds)) }
        var fixture = ScheduleSettings()
        fixture.countdown = CountdownSchedule(deadline: Date().addingTimeInterval(0.25), action: .dim)
        try store(fixture)
        let controller = ScheduleController(defaults: defaults)
        var events: [ScheduledEvent] = []
        controller.onEvent = { events.append($0); return true }
        controller.start()
        wait(0.65)
        expect(events.count == 1 && events.first?.action == .dim, "Real one-shot timer reaches fixture once")
        expect(controller.settings.countdown == nil, "Executed countdown consumed")
        wait(0.15)
        expect(events.count == 1, "Timer does not repeat")
        controller.stop()
        expect(ScheduleController(defaults: defaults).settings.countdown == nil, "Consumed countdown persisted")
        expect(!controller.startCountdown(minutes: 0, action: .dim) && !controller.startCountdown(minutes: 1441, action: .wake), "Countdown range validated")
        expect(controller.startCountdown(minutes: 15, action: .dim), "Preset countdown saves")
        expect(controller.nextEvent?.date.timeIntervalSinceNow ?? 0 > 890, "Countdown deadline uses minutes")
        controller.cancelCountdown()
        expect(controller.nextEvent == nil && controller.settings.countdown == nil, "Cancel removes armed timer")
        controller.stop()

        fixture.countdown = CountdownSchedule(deadline: Date().addingTimeInterval(-60), action: .dim)
        try store(fixture)
        let overdue = ScheduleController(defaults: defaults)
        overdue.onEvent = { _ in fatalError("Expired timer must not run") }
        overdue.start()
        expect(overdue.settings.countdown == nil && overdue.missedEvent, "Relaunch clears expired countdown without replay")
        overdue.stop()
        fixture.countdown = CountdownSchedule(deadline: Date().addingTimeInterval(0.25), action: .wake)
        try store(fixture)
        let busy = ScheduleController(defaults: defaults)
        var attempts = 0
        busy.onEvent = { _ in attempts += 1; return attempts > 1 }
        busy.start()
        wait(1.7)
        expect(attempts == 2 && busy.settings.countdown == nil, "Busy display action retries and consumes once accepted")
        busy.stop()
        fixture.countdown = CountdownSchedule(deadline: Date().addingTimeInterval(0.25), action: .dim)
        try store(fixture)
        let canceled = ScheduleController(defaults: defaults)
        canceled.onEvent = { _ in fatalError("Canceled timer must not run") }
        canceled.start()
        canceled.cancelCountdown()
        wait(0.5)
        expect(canceled.nextEvent == nil, "Canceled timer cannot fire a stale generation")
        canceled.stop()
        defaults.set(Data("broken".utf8), forKey: ScheduleController.storageKey)
        expect(ScheduleController(defaults: defaults).settings == ScheduleSettings(), "Corrupt settings fail closed")

        // Native controls are exercised in a hidden source-view fixture, not the real app.
        let app = NSApplication.shared
        app.setActivationPolicy(.prohibited)
        for language in [AppLanguage.english, .traditionalChinese] {
            let view = ScheduleView()
            var saved: DailySchedule?
            var countdownMinutes: Int?
            var cancelCalled = false
            view.onSaveDaily = { saved = $0; return true }
            view.onStartCountdown = { minutes, _ in countdownMinutes = minutes; return true }
            view.onCancelCountdown = { cancelCalled = true }
            view.update(language: language, settings: ScheduleSettings(), next: nil, missed: false)
            func descendants(_ root: NSView) -> [NSView] { root.subviews.flatMap { [$0] + descendants($0) } }
            let controls = descendants(view)
            func button(_ title: String) -> NSButton { controls.compactMap { $0 as? NSButton }.first { $0.title == title }! }
            let text = ScheduleText(language: language)
            let enabled = button(text.dailyEnabled)
            enabled.performClick(nil)
            let preset = controls.compactMap { $0 as? NSPopUpButton }.first { $0.itemTitles == text.presets }!
            preset.selectItem(at: 2)
            _ = preset.sendAction(preset.action, to: preset.target)
            button(text.save).performClick(nil)
            expect(saved?.enabled == true && saved?.wake.hour == 20 && saved?.dim.hour == 8, "Native preset and Save callback (\(language))")
            // This update must preserve an unsaved custom edit.
            let pickers = controls.compactMap { $0 as? NSDatePicker }
            pickers[0].dateValue = Calendar.current.date(from: DateComponents(year: 2001, month: 1, day: 15, hour: 7, minute: 45))!
            view.update(language: language, settings: ScheduleSettings(), next: nil, missed: false)
            button(text.save).performClick(nil)
            expect(saved?.wake == ScheduleTime(hour: 7, minute: 45), "Unsaved custom edit survives status refresh (\(language))")
            view.previewCountdownMode()
            let input = controls.compactMap { $0 as? NSTextField }.first { $0.isEditable }!
            input.stringValue = "47"
            button(text.startTimer).performClick(nil)
            expect(countdownMinutes == 47, "Custom countdown callback (\(language))")
            input.stringValue = "0"
            countdownMinutes = nil
            button(text.startTimer).performClick(nil)
            expect(countdownMinutes == nil, "Invalid countdown never reaches callback (\(language))")
            var active = ScheduleSettings()
            active.countdown = CountdownSchedule(deadline: Date().addingTimeInterval(60), action: .dim)
            view.update(language: language, settings: active, next: nil, missed: false)
            button(text.cancelTimer).performClick(nil)
            expect(cancelCalled, "Cancel callback (\(language))")
        }
        print("PASS: \(checks) schedule checks; private UserDefaults, local timers, native view callbacks; no power commands or live settings.")
    }
}
