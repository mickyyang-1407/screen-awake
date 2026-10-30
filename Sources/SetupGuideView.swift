import AppKit

@MainActor
final class GuideDocumentView: NSView {
    override var isFlipped: Bool { true }
}

@MainActor
final class SetupGuideView: NSView {
    static let panelSize = NSSize(width: 560, height: 650)
    override var isFlipped: Bool { true }
    var onDone: (() -> Void)?
    private let title = NSTextField(labelWithString: "")
    private let subtitle = NSTextField(labelWithString: "")
    private let scroll = NSScrollView()
    private let settings = NSButton(title: "", target: nil, action: nil)
    private let done = NSButton(title: "", target: nil, action: nil)
    private var labels: [NSTextField] = []

    override init(frame: NSRect) {
        super.init(frame: NSRect(origin: frame.origin, size: Self.panelSize))
        title.frame = NSRect(x: 24, y: 24, width: 512, height: 34)
        title.font = .systemFont(ofSize: 24, weight: .semibold)
        subtitle.frame = NSRect(x: 24, y: 64, width: 512, height: 22)
        subtitle.font = .systemFont(ofSize: 13)
        subtitle.textColor = .secondaryLabelColor
        addSubview(title)
        addSubview(subtitle)
        scroll.frame = NSRect(x: 24, y: 103, width: 512, height: 468)
        scroll.hasVerticalScroller = true
        scroll.drawsBackground = false
        scroll.autohidesScrollers = true
        addSubview(scroll)
        settings.frame = NSRect(x: 24, y: 599, width: 348, height: 30)
        settings.bezelStyle = .rounded
        settings.target = self
        settings.action = #selector(openSettings)
        addSubview(settings)
        done.frame = NSRect(x: 392, y: 599, width: 144, height: 30)
        done.bezelStyle = .rounded
        done.keyEquivalent = "\r"
        done.target = self
        done.action = #selector(closeGuide)
        addSubview(done)
        update(language: .english)
    }

    required init?(coder: NSCoder) { nil }
    convenience init() { self.init(frame: .zero) }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.windowBackgroundColor.setFill()
        dirtyRect.fill()
    }

    func update(language: AppLanguage) {
        let text = AppText(language: language.resolved)
        title.stringValue = text.guideTitle
        subtitle.stringValue = text.guideSubtitle
        settings.title = text.openSettings
        done.title = text.done
        labels.removeAll()
        let document = GuideDocumentView(frame: NSRect(x: 0, y: 0, width: 494, height: 468))
        var y: CGFloat = 0
        func paragraph(_ string: String, size: CGFloat = 13, weight: NSFont.Weight = .regular) {
            let label = NSTextField(wrappingLabelWithString: string)
            label.font = .systemFont(ofSize: size, weight: weight)
            label.maximumNumberOfLines = 0
            label.isSelectable = true
            let height = ceil(label.cell!.cellSize(forBounds: NSRect(x: 0, y: 0, width: 488, height: 2000)).height) + 6
            label.frame = NSRect(x: 0, y: y, width: 488, height: height)
            document.addSubview(label)
            labels.append(label)
            y += height + 10
        }
        paragraph(text.guideIntro)
        y += 8
        paragraph(text.guideAIHeading, size: 17, weight: .semibold)
        for (index, step) in text.guideAISteps.enumerated() {
            paragraph("\(index + 1). \(step.0)", weight: .semibold)
            paragraph(step.1)
            y += 12
        }
        paragraph(text.guideAILimits)
        y += 16
        paragraph(text.guideSecurityHeading, size: 17, weight: .semibold)
        paragraph(text.guideSecurityIntro)
        for (index, step) in text.guideSteps.enumerated() {
            paragraph("\(index + 1). \(step.0)", weight: .semibold)
            paragraph(step.1)
            y += 12
        }
        paragraph(text.guideFootnote, size: 12)
        labels.last?.textColor = .secondaryLabelColor
        document.setFrameSize(NSSize(width: 494, height: max(468, y)))
        scroll.documentView = document
        scroll.contentView.scroll(to: .zero)
    }

    @objc private func closeGuide() { onDone?() }
    @objc private func openSettings() {
        // Opens the pane only. Authentication and security changes stay with the user.
        if let url = URL(string: "x-apple.systempreferences:com.apple.Lock-Screen-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }

    func measuredLayoutFailures() -> [String] {
        labels.compactMap { label in
            guard let cell = label.cell else { return "Guide label has no cell" }
            return cell.cellSize(forBounds: NSRect(x: 0, y: 0, width: label.bounds.width, height: 2000)).height > label.bounds.height + 1
                ? "Guide text clipped: \(label.stringValue)" : nil
        }
    }
}
