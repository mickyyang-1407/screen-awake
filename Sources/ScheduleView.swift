import AppKit

@MainActor
final class ScheduleView: NSView {
    static let panelSize = NSSize(width: 560, height: 622)
    override var isFlipped: Bool { true }
    var onSaveDaily: ((DailySchedule) -> Bool)?
    var onStartCountdown: ((Int, DisplayAction) -> Bool)?
    var onCancelCountdown: (() -> Void)?
    var onDone: (() -> Void)?

    private let heading = NSTextField(labelWithString: "")
    private let subtitle = NSTextField(labelWithString: "")
    private let mode = NSSegmentedControl(labels: ["", ""], trackingMode: .selectOne, target: nil, action: nil)
    private let dailyPanel = FlippedView()
    private let timerPanel = FlippedView()
    private let presetLabel = NSTextField(labelWithString: "")
    private let preset = NSPopUpButton(frame: .zero, pullsDown: false)
    private let dailyEnabled = NSButton(checkboxWithTitle: "", target: nil, action: nil)
    private let wakeEnabled = NSButton(checkboxWithTitle: "", target: nil, action: nil)
    private let dimEnabled = NSButton(checkboxWithTitle: "", target: nil, action: nil)
    private let wakeTime = NSDatePicker()
    private let dimTime = NSDatePicker()
    private let hold = NSButton(checkboxWithTitle: "", target: nil, action: nil)
    private let save = NSButton(title: "", target: nil, action: nil)
    private let feedback = NSTextField(wrappingLabelWithString: "")
    private let quickLabel = NSTextField(labelWithString: "")
    private let quick = NSSegmentedControl(labels: ["15", "30", "60", "120"], trackingMode: .selectOne, target: nil, action: nil)
    private let durationLabel = NSTextField(labelWithString: "")
    private let minutes = NSTextField(string: "30")
    private let unit = NSTextField(labelWithString: "")
    private let actionLabel = NSTextField(labelWithString: "")
    private let action = NSPopUpButton(frame: .zero, pullsDown: false)
    private let start = NSButton(title: "", target: nil, action: nil)
    private let cancel = NSButton(title: "", target: nil, action: nil)
    private let timerStatus = NSTextField(wrappingLabelWithString: "")
    private let nextLabel = NSTextField(labelWithString: "")
    private let nextValue = NSTextField(wrappingLabelWithString: "")
    private let note = NSTextField(wrappingLabelWithString: "")
    private let done = NSButton(title: "", target: nil, action: nil)
    private var language = AppLanguage.english
    private var loadedDaily: DailySchedule?
    private var countdown: CountdownSchedule?
    private var timeZoneID = TimeZone.current.identifier
    private var labels: [NSTextField] = []
    private var feedbackIsError = false
    private var timerIsError = false

    override init(frame frameRect: NSRect) {
        super.init(frame: NSRect(origin: frameRect.origin, size: Self.panelSize))
        label(heading, in: self, rect: NSRect(x: 24, y: 24, width: 512, height: 34), size: 25, weight: .semibold)
        label(subtitle, in: self, rect: NSRect(x: 24, y: 64, width: 512, height: 22), size: 13)
        mode.frame = NSRect(x: 24, y: 104, width: 512, height: 28)
        mode.selectedSegment = 0
        mode.target = self
        mode.action = #selector(selectScheduleMode)
        addSubview(mode)
        dailyPanel.frame = NSRect(x: 24, y: 154, width: 512, height: 274)
        timerPanel.frame = dailyPanel.frame
        addSubview(dailyPanel)
        addSubview(timerPanel)
        label(presetLabel, in: dailyPanel, rect: NSRect(x: 16, y: 15, width: 146, height: 22), size: 12, weight: .medium)
        control(preset, in: dailyPanel, rect: NSRect(x: 176, y: 9, width: 320, height: 30), action: #selector(choosePreset))
        control(dailyEnabled, in: dailyPanel, rect: NSRect(x: 16, y: 57, width: 480, height: 24), action: #selector(editDaily))
        control(wakeEnabled, in: dailyPanel, rect: NSRect(x: 16, y: 102, width: 310, height: 24), action: #selector(editDaily))
        control(dimEnabled, in: dailyPanel, rect: NSRect(x: 16, y: 144, width: 310, height: 24), action: #selector(editDaily))
        for (picker, y) in [(wakeTime, 98.0), (dimTime, 140.0)] {
            picker.datePickerStyle = .textFieldAndStepper
            picker.datePickerElements = [.hourMinute]
            picker.timeZone = .current
            control(picker, in: dailyPanel, rect: NSRect(x: 362, y: y, width: 134, height: 30), action: #selector(editTime))
        }
        control(hold, in: dailyPanel, rect: NSRect(x: 16, y: 190, width: 480, height: 24), action: #selector(editDaily))
        control(save, in: dailyPanel, rect: NSRect(x: 16, y: 234, width: 174, height: 30), action: #selector(saveDaily))
        label(feedback, in: dailyPanel, rect: NSRect(x: 202, y: 235, width: 294, height: 32), size: 11)
        label(quickLabel, in: timerPanel, rect: NSRect(x: 16, y: 15, width: 480, height: 22), size: 12, weight: .medium)
        control(quick, in: timerPanel, rect: NSRect(x: 16, y: 47, width: 480, height: 28), action: #selector(chooseMinutes))
        quick.selectedSegment = 1
        label(durationLabel, in: timerPanel, rect: NSRect(x: 16, y: 100, width: 270, height: 24), size: 13)
        control(minutes, in: timerPanel, rect: NSRect(x: 308, y: 95, width: 90, height: 28), action: #selector(editMinutes))
        minutes.alignment = .right
        label(unit, in: timerPanel, rect: NSRect(x: 408, y: 100, width: 88, height: 24), size: 12)
        label(actionLabel, in: timerPanel, rect: NSRect(x: 16, y: 144, width: 270, height: 24), size: 13)
        control(action, in: timerPanel, rect: NSRect(x: 308, y: 137, width: 188, height: 30), action: nil)
        control(start, in: timerPanel, rect: NSRect(x: 16, y: 190, width: 222, height: 30), action: #selector(startCountdown))
        control(cancel, in: timerPanel, rect: NSRect(x: 308, y: 190, width: 188, height: 30), action: #selector(cancelCountdown))
        label(timerStatus, in: timerPanel, rect: NSRect(x: 16, y: 238, width: 480, height: 32), size: 12)
        label(nextLabel, in: self, rect: NSRect(x: 24, y: 450, width: 512, height: 18), size: 10, weight: .semibold)
        label(nextValue, in: self, rect: NSRect(x: 24, y: 474, width: 512, height: 42), size: 17, weight: .medium)
        label(note, in: self, rect: NSRect(x: 24, y: 528, width: 512, height: 54), size: 11)
        control(done, in: self, rect: NSRect(x: 424, y: 586, width: 112, height: 28), action: #selector(finish))
        done.keyEquivalent = "\u{1b}"
        update(language: .english, settings: ScheduleSettings(), next: nil, missed: false)
    }

    required init?(coder: NSCoder) { nil }
    convenience init() { self.init(frame: .zero) }

    private func label(_ field: NSTextField, in parent: NSView, rect: NSRect, size: CGFloat, weight: NSFont.Weight = .regular) {
        field.frame = rect
        field.font = .systemFont(ofSize: size, weight: weight)
        field.maximumNumberOfLines = [feedback, timerStatus, nextValue, note].contains(field) ? 0 : 1
        field.lineBreakMode = field.maximumNumberOfLines == 1 ? .byClipping : .byWordWrapping
        parent.addSubview(field)
        labels.append(field)
    }

    private func control(_ control: NSControl, in parent: NSView, rect: NSRect, action: Selector?) {
        control.frame = rect
        control.font = .systemFont(ofSize: 12)
        control.target = self
        control.action = action
        if let button = control as? NSButton, button !== dailyEnabled && button !== wakeEnabled && button !== dimEnabled && button !== hold && !(button is NSPopUpButton) {
            button.bezelStyle = .rounded
        }
        parent.addSubview(control)
    }

    func update(language: AppLanguage, settings: ScheduleSettings, next: ScheduledEvent?, missed: Bool) {
        if self.language != language { feedback.stringValue = "" }
        self.language = language
        if timeZoneID != TimeZone.current.identifier {
            timeZoneID = TimeZone.current.identifier
            wakeTime.timeZone = .current
            dimTime.timeZone = .current
            loadedDaily = nil
        }
        let text = ScheduleText(language: language)
        heading.stringValue = text.title
        subtitle.stringValue = text.subtitle
        for (index, title) in text.modes.enumerated() { mode.setLabel(title, forSegment: index) }
        mode.setAccessibilityLabel(text.title)
        presetLabel.stringValue = text.preset
        let selection = preset.indexOfSelectedItem
        preset.removeAllItems()
        preset.addItems(withTitles: text.presets)
        preset.selectItem(at: max(0, selection))
        preset.setAccessibilityLabel(text.preset)
        dailyEnabled.title = text.dailyEnabled
        wakeEnabled.title = text.wake
        dimEnabled.title = text.dim
        hold.title = text.hold
        wakeTime.setAccessibilityLabel(text.wake)
        dimTime.setAccessibilityLabel(text.dim)
        save.title = text.save
        quickLabel.stringValue = text.quickTimer
        quick.setAccessibilityLabel(text.quickTimer)
        for (i, value) in [15, 30, 60, 120].enumerated() { quick.setLabel("\(value) \(text.minutes)", forSegment: i) }
        durationLabel.stringValue = text.duration
        minutes.setAccessibilityLabel(text.duration + " (1–1440)")
        unit.stringValue = text.minutes
        actionLabel.stringValue = text.action
        let selectedAction = action.indexOfSelectedItem
        action.removeAllItems()
        action.addItems(withTitles: [text.dim, text.wake])
        action.selectItem(at: max(0, selectedAction))
        action.setAccessibilityLabel(text.action)
        countdown = settings.countdown
        start.title = countdown == nil ? text.startTimer : text.replaceTimer
        cancel.title = text.cancelTimer
        cancel.isEnabled = countdown != nil
        timerStatus.stringValue = text.countdown(countdown)
        timerIsError = false
        nextLabel.stringValue = text.next
        nextValue.stringValue = text.event(next)
        note.stringValue = (missed ? text.missed + " " : "") + text.footnote
        done.title = AppText(language: language.resolved).done
        // A timer update must not overwrite edits the user has not saved yet.
        if loadedDaily != settings.daily {
            loadedDaily = settings.daily
            load(settings.daily)
        }
        selectScheduleMode()
        updateEnabledControls()
        needsDisplay = true
    }

    private func load(_ daily: DailySchedule) {
        dailyEnabled.state = daily.enabled ? .on : .off
        wakeEnabled.state = daily.wakeEnabled ? .on : .off
        dimEnabled.state = daily.dimEnabled ? .on : .off
        hold.state = daily.keepAwakeAfterWake ? .on : .off
        for (picker, time) in [(wakeTime, daily.wake), (dimTime, daily.dim)] {
            picker.dateValue = Calendar.current.date(from: DateComponents(year: 2001, month: 1, day: 15, hour: time.hour, minute: time.minute)) ?? Date()
        }
        selectMatchingPreset()
    }

    private func selectedTime(_ picker: NSDatePicker) -> ScheduleTime {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: picker.dateValue)
        return ScheduleTime(hour: parts.hour ?? 0, minute: parts.minute ?? 0)
    }

    private func selectMatchingPreset() {
        let times = [(8, 17), (9, 18), (20, 8)]
        let wake = selectedTime(wakeTime), dim = selectedTime(dimTime)
        preset.selectItem(at: times.firstIndex { wake == ScheduleTime(hour: $0.0, minute: 0) && dim == ScheduleTime(hour: $0.1, minute: 0) } ?? 3)
    }

    private func updateEnabledControls() {
        wakeTime.isEnabled = wakeEnabled.state == .on
        dimTime.isEnabled = dimEnabled.state == .on
        hold.isEnabled = wakeEnabled.state == .on
    }

    @objc private func selectScheduleMode() {
        dailyPanel.isHidden = mode.selectedSegment != 0
        timerPanel.isHidden = mode.selectedSegment != 1
    }
    @objc private func choosePreset() {
        let index = preset.indexOfSelectedItem
        guard index < 3 else { return }
        let hours = [(8, 17), (9, 18), (20, 8)][index]
        var daily = loadedDaily ?? DailySchedule()
        daily.wake = ScheduleTime(hour: hours.0, minute: 0)
        daily.dim = ScheduleTime(hour: hours.1, minute: 0)
        daily.wakeEnabled = true
        daily.dimEnabled = true
        // Choosing a preset fills a draft. Saving is the only activation step.
        daily.enabled = dailyEnabled.state == .on
        load(daily)
        editDaily()
    }
    @objc private func editDaily() {
        feedback.stringValue = ""
        feedbackIsError = false
        updateEnabledControls()
        needsDisplay = true
    }
    @objc private func editTime() { selectMatchingPreset(); editDaily() }
    @objc private func saveDaily() {
        window?.makeFirstResponder(nil)
        let daily = DailySchedule(enabled: dailyEnabled.state == .on, wakeEnabled: wakeEnabled.state == .on,
            wake: selectedTime(wakeTime), dimEnabled: dimEnabled.state == .on, dim: selectedTime(dimTime),
            keepAwakeAfterWake: hold.state == .on)
        let success = daily.valid && onSaveDaily?(daily) == true
        let text = ScheduleText(language: language)
        feedbackIsError = !success
        feedback.stringValue = success ? text.saved : text.invalidDaily
        needsDisplay = true
    }
    @objc private func chooseMinutes() {
        guard (0..<4).contains(quick.selectedSegment) else { return }
        minutes.stringValue = String([15, 30, 60, 120][quick.selectedSegment])
        editMinutes()
    }
    @objc private func editMinutes() {
        quick.selectedSegment = [15, 30, 60, 120].firstIndex(of: Int(minutes.stringValue) ?? 0) ?? -1
        timerStatus.stringValue = ScheduleText(language: language).countdown(countdown)
        timerIsError = false
        needsDisplay = true
    }
    @objc private func startCountdown() {
        window?.makeFirstResponder(nil)
        let value = Int(minutes.stringValue.trimmingCharacters(in: .whitespaces))
        guard let value, (1...1440).contains(value), onStartCountdown?(value, action.indexOfSelectedItem == 1 ? .wake : .dim) == true else {
            timerStatus.stringValue = ScheduleText(language: language).invalidMinutes
            timerIsError = true
            needsDisplay = true
            return
        }
        editMinutes()
    }
    @objc private func cancelCountdown() { onCancelCountdown?() }
    @objc private func finish() { onDone?() }

    override func draw(_ dirtyRect: NSRect) {
        let dark = effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        NSColor(srgbRed: dark ? 0.137 : 0.965, green: dark ? 0.145 : 0.961, blue: dark ? 0.129 : 0.941, alpha: 1).setFill()
        dirtyRect.fill()
        (dark ? NSColor(white: 0.19, alpha: 1) : .white).setFill()
        NSBezierPath(roundedRect: dailyPanel.frame, xRadius: 14, yRadius: 14).fill()
        for field in labels { field.textColor = .secondaryLabelColor }
        for field in [heading, nextValue, presetLabel, quickLabel, durationLabel, actionLabel] { field.textColor = .labelColor }
        feedback.textColor = feedbackIsError ? .systemRed : .secondaryLabelColor
        timerStatus.textColor = timerIsError ? .systemRed : .secondaryLabelColor
    }

    // Source-render fixtures only; never touches power management or preferences.
    func previewCountdownMode() { mode.selectedSegment = 1; selectScheduleMode() }
    func measuredLayoutFailures() -> [String] {
        var failures: [String] = []
        for field in labels where !field.isHiddenOrHasHiddenAncestor && !field.stringValue.isEmpty {
            if let cell = field.cell {
                let measured = cell.cellSize(forBounds: NSRect(x: 0, y: 0, width: field.bounds.width, height: 1000))
                if measured.height > field.bounds.height + 1 { failures.append("Clipped label: \(field.stringValue)") }
            }
        }
        return failures
    }
}

@MainActor
private final class FlippedView: NSView {
    override var isFlipped: Bool { true }
}
