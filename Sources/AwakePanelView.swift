import AppKit

@MainActor
final class AwakePanelView: NSView {
    static let panelSize = NSSize(width: 394, height: 354)
    override var isFlipped: Bool { true }
    let awakeSwitch = NSSwitch(frame: NSRect(x: 316, y: 190, width: 42, height: 28))
    let languagePopup = NSPopUpButton(frame: NSRect(x: 211, y: 261, width: 161, height: 28), pullsDown: false)
    var onToggle: ((Bool) -> Void)?
    var onLanguageChange: ((AppLanguage) -> Void)?
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
        configure(product, rect: NSRect(x: 80, y: 23, width: 290, height: 22), size: 15, weight: .semibold)
        configure(eyebrow, rect: NSRect(x: 80, y: 47, width: 290, height: 18), size: 12)
        configure(state, rect: NSRect(x: 24, y: 86, width: 346, height: 34), size: 26, weight: .semibold)
        configure(detail, rect: NSRect(x: 24, y: 128, width: 346, height: 22), size: 13)
        configure(errorLabel, rect: NSRect(x: 24, y: 151, width: 346, height: 27), size: 11)
        configure(switchLabel, rect: NSRect(x: 36, y: 195, width: 268, height: 24), size: 14, weight: .medium)
        configure(languageLabel, rect: NSRect(x: 24, y: 267, width: 170, height: 20), size: 12)
        configure(footer, rect: NSRect(x: 24, y: 307, width: 346, height: 34), size: 11)
        awakeSwitch.target = self
        awakeSwitch.action = #selector(toggle)
        addSubview(awakeSwitch)
        languagePopup.controlSize = .regular
        languagePopup.font = .systemFont(ofSize: 12)
        languagePopup.target = self
        languagePopup.action = #selector(changeLanguage)
        addSubview(languagePopup)
        awakeSwitch.nextKeyView = languagePopup
        languagePopup.nextKeyView = awakeSwitch
        update(enabled: false, language: .english, error: nil)
    }

    required init?(coder: NSCoder) { nil }
    convenience init() { self.init(frame: .zero) }

    private func configure(_ field: NSTextField, rect: NSRect, size: CGFloat, weight: NSFont.Weight = .regular) {
        field.frame = rect
        field.font = .systemFont(ofSize: size, weight: weight)
        field.lineBreakMode = field === footer || field === errorLabel ? .byWordWrapping : .byClipping
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
        languageLabel.stringValue = text.languageLabel
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
        let background = color(dark ? 0x252622 : 0xF8F7F3)
        let foreground = color(dark ? 0xF2F1E9 : 0x272A23)
        let secondary = color(dark ? 0xB9BBB0 : 0x65695F)
        let amber = color(dark ? 0xE7B85A : 0x986212)
        background.setFill()
        dirtyRect.fill()
        color(dark ? 0x32342D : 0xECEDE6).setFill()
        NSBezierPath(roundedRect: NSRect(x: 20, y: 178, width: 354, height: 54), xRadius: 12, yRadius: 12).fill()
        color(dark ? 0x43463C : 0xDCDDD4).setFill()
        NSRect(x: 24, y: 250, width: 346, height: 1).fill()
        product.textColor = foreground
        state.textColor = enabled ? amber : foreground
        switchLabel.textColor = foreground
        for label in [eyebrow, detail, languageLabel, footer] { label.textColor = secondary }
        errorLabel.textColor = .systemRed
        drawMonitor(in: NSRect(x: 24, y: 25, width: 40, height: 40), ink: foreground,
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
