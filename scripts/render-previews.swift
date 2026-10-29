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
        for language in [AppLanguage.english, .traditionalChinese] {
            for (theme, appearance) in [("light", NSAppearance.Name.aqua), ("dark", .darkAqua)] {
                let cases: [(name: String, enabled: Bool, error: PowerError?)] = [
                    ("on", true, nil),
                    ("off", false, nil),
                    ("error-enabling", false, PowerError(enabling: true, code: Int32.min)),
                    ("error-disabling", true, PowerError(enabling: false, code: Int32.min))
                ]
                for preview in cases {
                    let panel = AwakePanelView()
                    panel.appearance = NSAppearance(named: appearance)
                    panel.update(enabled: preview.enabled, language: language, error: preview.error)
                    let window = NSWindow(contentRect: NSRect(origin: .zero, size: AwakePanelView.panelSize),
                                          styleMask: .borderless, backing: .buffered, defer: false)
                    window.contentView = panel
                    window.appearance = panel.appearance
                    panel.layoutSubtreeIfNeeded()
                    panel.displayIfNeeded()
                    let name = "\(language.rawValue)-\(theme)-\(preview.name)"
                    let failures = panel.measuredLayoutFailures()
                    failureCount += failures.count
                    report.append("\(name): \(failures.isEmpty ? "PASS — no measured clipping" : failures.joined(separator: "; "))")
                    guard let bitmap = panel.bitmapImageRepForCachingDisplay(in: panel.bounds) else {
                        fatalError("Unable to allocate preview bitmap")
                    }
                    panel.cacheDisplay(in: panel.bounds, to: bitmap)
                    guard let png = bitmap.representation(using: .png, properties: [:]) else {
                        fatalError("Unable to encode preview")
                    }
                    try png.write(to: output.appendingPathComponent("\(name).png"))
                }
            }
        }
        let result = report.joined(separator: "\n") + "\nMeasured layout failures: \(failureCount)\n"
        try result.write(to: output.appendingPathComponent("layout-report.txt"), atomically: true, encoding: .utf8)
        print(result)
        if failureCount > 0 { exit(1) }
    }
}
