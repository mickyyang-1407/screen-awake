import AppKit

let destination = CommandLine.arguments[1]
let image = NSImage(size: NSSize(width: 1024, height: 1024), flipped: false) { rect in
    NSColor(srgbRed: 0.16, green: 0.17, blue: 0.14, alpha: 1).setFill()
    NSBezierPath(roundedRect: rect.insetBy(dx: 64, dy: 64), xRadius: 190, yRadius: 190).fill()
    NSColor(srgbRed: 0.94, green: 0.93, blue: 0.88, alpha: 1).setStroke()
    let monitor = NSBezierPath(roundedRect: NSRect(x: 224, y: 330, width: 576, height: 382), xRadius: 36, yRadius: 36)
    monitor.lineWidth = 28
    monitor.stroke()
    let base = NSBezierPath()
    base.move(to: NSPoint(x: 512, y: 330))
    base.line(to: NSPoint(x: 512, y: 246))
    base.move(to: NSPoint(x: 414, y: 246))
    base.line(to: NSPoint(x: 610, y: 246))
    base.lineWidth = 28
    base.lineCapStyle = .round
    base.stroke()
    let amber = NSColor(srgbRed: 0.91, green: 0.72, blue: 0.35, alpha: 1)
    amber.setFill()
    NSBezierPath(ovalIn: NSRect(x: 461, y: 470, width: 102, height: 102)).fill()
    amber.setStroke()
    let rays = NSBezierPath()
    for angle in stride(from: 0.0, to: Double.pi * 2, by: Double.pi / 4) {
        rays.move(to: NSPoint(x: 512 + cos(angle) * 83, y: 521 + sin(angle) * 83))
        rays.line(to: NSPoint(x: 512 + cos(angle) * 109, y: 521 + sin(angle) * 109))
    }
    rays.lineWidth = 15
    rays.lineCapStyle = .round
    rays.stroke()
    return true
}
guard let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else { fatalError("Unable to render app icon") }
try png.write(to: URL(fileURLWithPath: destination))
