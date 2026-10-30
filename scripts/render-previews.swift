import AppKit

@main
struct RenderPreviews {
    @MainActor static func main() throws {
        let app = NSApplication.shared
        app.setActivationPolicy(.prohibited)
        let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        var report: [String] = []
        var failureCount = 0
        func capture(_ view: NSView, appearance: NSAppearance?, name: String) throws {
            let window = NSWindow(contentRect: NSRect(origin: .zero, size: view.frame.size),
                                  styleMask: .borderless, backing: .buffered, defer: false)
            window.contentView = view
            window.appearance = appearance
            view.layoutSubtreeIfNeeded()
            view.displayIfNeeded()
            guard let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { fatalError("No bitmap") }
            view.cacheDisplay(in: view.bounds, to: bitmap)
            guard let png = bitmap.representation(using: .png, properties: [:]) else { fatalError("No PNG") }
            try png.write(to: output.appendingPathComponent("\(name).png"))
        }
        for language in [AppLanguage.english, .traditionalChinese] {
            for (theme, appearance) in [("light", NSAppearance.Name.aqua), ("dark", .darkAqua)] {
                let cases: [(name: String, enabled: Bool, error: PowerError?, action: DisplayActionState)] = [
                    ("on", true, nil, .idle),
                    ("off", false, nil, .idle),
                    ("error-enabling", false, PowerError(enabling: true, code: Int32.min), .idle),
                    ("error-disabling", true, PowerError(enabling: false, code: Int32.min), .idle),
                    ("waking", true, nil, .running(.wake)),
                    ("dimming", false, nil, .running(.dim)),
                    ("wake-failed", true, nil, .finished(.wake, Int32.min)),
                    ("dim-failed", false, nil, .finished(.dim, Int32.min)),
                    ("wake-done", true, nil, .finished(.wake, 0)),
                    ("dim-done", false, nil, .finished(.dim, 0))
                ]
                for preview in cases {
                    let panel = AwakePanelView()
                    panel.appearance = NSAppearance(named: appearance)
                    panel.update(enabled: preview.enabled, language: language, error: preview.error, actionState: preview.action)
                    let name = "\(language.rawValue)-\(theme)-\(preview.name)"
                    let failures = panel.measuredLayoutFailures()
                    failureCount += failures.count
                    report.append("\(name): \(failures.isEmpty ? "PASS — no measured clipping" : failures.joined(separator: "; "))")
                    try capture(panel, appearance: panel.appearance, name: name)
                }
                for mode in ["daily", "countdown"] {
                    var settings = ScheduleSettings()
                    settings.daily.enabled = true
                    settings.countdown = CountdownSchedule(deadline: Date().addingTimeInterval(1800), action: .dim)
                    let schedule = ScheduleView()
                    schedule.appearance = NSAppearance(named: appearance)
                    schedule.update(language: language, settings: settings, next: SchedulePlanner.next(in: settings, after: Date()), missed: false)
                    if mode == "countdown" { schedule.previewCountdownMode() }
                    let failures = schedule.measuredLayoutFailures()
                    failureCount += failures.count
                    let name = "\(language.rawValue)-\(theme)-schedule-\(mode)"
                    report.append("\(name): \(failures.isEmpty ? "PASS — no measured clipping" : failures.joined(separator: "; "))")
                    try capture(schedule, appearance: schedule.appearance, name: name)
                }
                let guide = SetupGuideView()
                guide.appearance = NSAppearance(named: appearance)
                guide.update(language: language)
                let failures = guide.measuredLayoutFailures()
                failureCount += failures.count
                let name = "\(language.rawValue)-\(theme)-guide"
                report.append("\(name): \(failures.isEmpty ? "PASS — no measured clipping" : failures.joined(separator: "; "))")
                try capture(guide, appearance: guide.appearance, name: name)
            }
        }
        let result = report.joined(separator: "\n") + "\nMeasured layout failures: \(failureCount)\n"
        try result.write(to: output.appendingPathComponent("layout-report.txt"), atomically: true, encoding: .utf8)
        print(result)
        if failureCount > 0 { exit(1) }
    }
}
