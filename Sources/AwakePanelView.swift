import AppKit

@MainActor
final class AwakePanelView: NSView {
    static let panelSize = NSSize(width: 420, height: 414)
    override var isFlipped: Bool { true }
    let awakeSwitch = NSSwitch(frame: NSRect(x: 336, y: 211, width: 42, height: 28))
    let languagePopup = NSPopUpButton(frame: NSRect(x: 244, y: 24, width: 154, height: 28), pullsDown: false)
    let guideButton = NSButton(title: "", target: nil, action: nil)
    var onToggle: ((Bool) -> Void)?
    var onLanguageChange: ((AppLanguage) -> Void)?
    var onGuide: (() -> Void)?
    private let product = NSTextField(labelWithString: "")
    private let eyebrow = NSTextField(labelWithString: "")
    private let state = NSTextField(labelWithString: "")
    private let detail = NSTextField(wrappingLabelWithString: "")
    private let switchLabel = NSTextField(labelWithString: "")
    private let languageLabel = NSTextField(labelWithString: "")
    private let footer = NSTextField(wrappingLabelWithString: "")
    private let errorLabel = NSTextField(wrappingLabelWithString: "")
    private var enabled = false

    override init(frame frameRect: NSRect) {
        super.init(frame: NSRect(origin: frameRect.origin, size: Self.panelSize))
        configure(product, rect: NSRect(x: 24, y: 24, width: 210, height: 22), size: 15, weight: .semibold)
        configure(eyebrow, rect: NSRect(x: 24, y: 49, width: 210, height: 18), size: 11)
        configure(state, rect: NSRect(x: 94, y: 97, width: 302, height: 34), size: 25, weight: .semibold)
        configure(detail, rect: NSRect(x: 24, y: 156, width: 372, height: 21), size: 13)
        configure(errorLabel, rect: NSRect(x: 24, y: 270, width: 372, height: 35), size: 11)
        configure(switchLabel, rect: NSRect(x: 40, y: 206, width: 282, height: 22), size: 14, weight: .medium)
        configure(languageLabel, rect: NSRect(x: 40, y: 231, width: 282, height: 18), size: 11)
        configure(footer, rect: NSRect(x: 24, y: 360, width: 372, height: 36), size: 11)
        awakeSwitch.target = self
        awakeSwitch.action = #selector(toggle)
        addSubview(awakeSwitch)
        languagePopup.controlSize = .regular
        languagePopup.font = .systemFont(ofSize: 12)
        languagePopup.target = self
        languagePopup.action = #selector(changeLanguage)
        addSubview(languagePopup)
        guideButton.frame = NSRect(x: 24, y: 311, width: 372, height: 30)
        guideButton.bezelStyle = .rounded
        guideButton.font = .systemFont(ofSize: 12)
        guideButton.target = self
        guideButton.action = #selector(showGuide)
        addSubview(guideButton)
        awakeSwitch.nextKeyView = languagePopup
        languagePopup.nextKeyView = guideButton
        guideButton.nextKeyView = awakeSwitch
        update(enabled: false, language: .english, error: nil)
    }

    required init?(coder: NSCoder) { nil }
    convenience init() { self.init(frame: .zero) }

    private func configure(_ field: NSTextField, rect: NSRect, size: CGFloat, weight: NSFont.Weight = .regular) {
        field.frame = rect
        field.font = .systemFont(ofSize: size, weight: weight)
        field.lineBreakMode = field === footer || field === errorLabel ? .byWordWrapping : .byClipping
        field.maximumNumberOfLines = field === footer || field === errorLabel ? 0 : 1
        addSubview(field)
    }

    func update(enabled: Bool, language: AppLanguage, error: PowerError?) {
        self.enabled = enabled
        let text = AppText(language: language.resolved)
        product.stringValue = text.productName
        eyebrow.stringValue = text.eyebrow
        state.stringValue = text.state(enabled)
        detail.stringValue = text.detail(enabled)
        switchLabel.stringValue = text.switchTitle
        languageLabel.stringValue = text.sessionNote
        guideButton.title = text.guideButton
        guideButton.toolTip = text.guideTitle
        footer.stringValue = text.footer
        errorLabel.stringValue = error.map(text.error) ?? ""
        awakeSwitch.state = enabled ? .on : .off
        awakeSwitch.setAccessibilityLabel(text.switchTitle)
        awakeSwitch.setAccessibilityHelp(text.switchHelp)
        languagePopup.removeAllItems()
        languagePopup.addItems(withTitles: [text.systemOption, "English", "繁體中文"])
        languagePopup.selectItem(at: AppLanguage.allCases.firstIndex(of: language) ?? 0)
        languagePopup.setAccessibilityLabel(text.languageLabel)
        languagePopup.setAccessibilityHelp(text.languageHelp)
        needsDisplay = true
    }

    @objc private func toggle() { onToggle?(awakeSwitch.state == .on) }
    @objc private func showGuide() { onGuide?() }
    @objc private func changeLanguage() {
        let index = languagePopup.indexOfSelectedItem
        guard AppLanguage.allCases.indices.contains(index) else { return }
        onLanguageChange?(AppLanguage.allCases[index])
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        let dark = effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        let background = color(dark ? 0x232521 : 0xF6F5F0)
        let foreground = color(dark ? 0xF1F1E8 : 0x292D26)
        let secondary = color(dark ? 0xB9BEB0 : 0x656B5E)
        let amber = color(dark ? 0xE5BC6A : 0x8B5B16)
        background.setFill()
        dirtyRect.fill()
        color(dark ? 0x30352B : 0xE8EBDD).setFill()
        NSBezierPath(roundedRect: NSRect(x: 24, y: 87, width: 56, height: 56), xRadius: 16, yRadius: 16).fill()
        color(dark ? 0x30332B : 0xFFFFFF).setFill()
        let control = NSBezierPath(roundedRect: NSRect(x: 24, y: 191, width: 372, height: 70), xRadius: 14, yRadius: 14)
        control.fill()
        color(dark ? 0x484D40 : 0xDFE2D6).setStroke()
        control.lineWidth = NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast ? 2 : 0.7
        control.stroke()
        product.textColor = foreground
        state.textColor = enabled ? amber : foreground
        switchLabel.textColor = foreground
        for label in [eyebrow, detail, languageLabel, footer] { label.textColor = secondary }
        errorLabel.textColor = .systemRed
        drawMonitor(in: NSRect(x: 32, y: 96, width: 40, height: 40), ink: foreground,
                    accent: enabled ? amber : secondary, active: enabled)
    }

    private func color(_ rgb: UInt32) -> NSColor {
        NSColor(srgbRed: CGFloat((rgb >> 16) & 255) / 255,
                green: CGFloat((rgb >> 8) & 255) / 255,
                blue: CGFloat(rgb & 255) / 255, alpha: 1)
    }

    private func drawMonitor(in rect: NSRect, ink: NSColor, accent: NSColor, active: Bool) {
        ink.setStroke()
        let outline = NSBezierPath(roundedRect: NSRect(x: rect.minX, y: rect.minY + 3, width: 40, height: 27), xRadius: 4, yRadius: 4)
        outline.lineWidth = 1.8
        outline.stroke()
        let base = NSBezierPath()
        base.move(to: NSPoint(x: rect.midX, y: rect.minY + 30))
        base.line(to: NSPoint(x: rect.midX, y: rect.minY + 37))
        base.move(to: NSPoint(x: rect.midX - 7, y: rect.minY + 37))
        base.line(to: NSPoint(x: rect.midX + 7, y: rect.minY + 37))
        base.lineWidth = 1.8
        base.lineCapStyle = .round
        base.stroke()
        accent.setFill()
        NSBezierPath(ovalIn: NSRect(x: rect.midX - 4, y: rect.minY + 12, width: 8, height: 8)).fill()
        if active {
            accent.setStroke()
            let rays = NSBezierPath()
            for angle in stride(from: 0.0, to: Double.pi * 2, by: Double.pi / 4) {
                rays.move(to: NSPoint(x: rect.midX + cos(angle) * 7, y: rect.minY + 16 + sin(angle) * 7))
                rays.line(to: NSPoint(x: rect.midX + cos(angle) * 9, y: rect.minY + 16 + sin(angle) * 9))
            }
            rays.lineWidth = 1.3
            rays.lineCapStyle = .round
            rays.stroke()
        }
    }

    // Called only by the separate source-render helper.
    func measuredLayoutFailures() -> [String] {
        var failures: [String] = []
        for label in [product, eyebrow, state, detail, switchLabel, languageLabel, footer, errorLabel] {
            guard !label.stringValue.isEmpty else { continue }
            guard bounds.contains(label.frame) else { failures.append("Label outside panel: \(label.stringValue)"); continue }
            if let cell = label.cell {
                let measured = cell.cellSize(forBounds: NSRect(x: 0, y: 0, width: label.bounds.width, height: 1000))
                if measured.height > label.bounds.height + 1 { failures.append("Label height clipped: \(label.stringValue)") }
                if label.maximumNumberOfLines == 1 && measured.width > label.bounds.width + 1 {
                    failures.append("Label width clipped: \(label.stringValue)")
                }
            }
        }
        return failures
    }
}
