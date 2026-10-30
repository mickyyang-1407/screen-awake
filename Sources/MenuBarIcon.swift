import AppKit

@MainActor
enum MenuBarIcon {
    static func image(enabled: Bool) -> NSImage {
        let image = NSImage(size: NSSize(width: 20, height: 18))
        image.lockFocus()
        NSColor.black.setStroke()
        NSColor.black.setFill()
        let screen = NSBezierPath(roundedRect: NSRect(x: 1, y: 5, width: 18, height: 12),
                                  xRadius: 2, yRadius: 2)
        screen.lineWidth = 1.3
        screen.stroke()
        let stand = NSBezierPath()
        stand.move(to: NSPoint(x: 10, y: 5))
        stand.line(to: NSPoint(x: 10, y: 1.5))
        stand.move(to: NSPoint(x: 6, y: 1.5))
        stand.line(to: NSPoint(x: 14, y: 1.5))
        stand.lineWidth = 1.3
        stand.lineCapStyle = .round
        stand.stroke()
        if enabled {
            NSBezierPath(ovalIn: NSRect(x: 8.5, y: 9.5, width: 3, height: 3)).fill()
            let rays = NSBezierPath()
            for angle in stride(from: 0.0, to: Double.pi * 2, by: Double.pi / 2) {
                rays.move(to: NSPoint(x: 10 + cos(angle) * 3, y: 11 + sin(angle) * 3))
                rays.line(to: NSPoint(x: 10 + cos(angle) * 4.2, y: 11 + sin(angle) * 4.2))
            }
            rays.lineWidth = 1
            rays.lineCapStyle = .round
            rays.stroke()
        }
        image.unlockFocus()
        image.isTemplate = true
        image.accessibilityDescription = enabled ? "Screen Awake — on" : "Screen Awake — off"
        return image
    }
}
