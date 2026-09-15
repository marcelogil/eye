// Generates the app icon: the "eye" SF Symbol on a blue rounded square.
// Usage: make-icon <output.icns>
import AppKit

let output = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.icns"
let canvas: CGFloat = 1024

let icon = NSImage(size: NSSize(width: canvas, height: canvas), flipped: false) { rect in
    // Apple's macOS icon grid: the rounded square fills 824 of the 1024 points.
    let square = rect.insetBy(dx: canvas * 0.0977, dy: canvas * 0.0977)
    let radius = square.width * 0.2237
    let shape = NSBezierPath(roundedRect: square, xRadius: radius, yRadius: radius)
    NSGradient(starting: NSColor(srgbRed: 0.36, green: 0.65, blue: 1.00, alpha: 1),
               ending: NSColor(srgbRed: 0.07, green: 0.30, blue: 0.85, alpha: 1))?
        .draw(in: shape, angle: -90)

    let config = NSImage.SymbolConfiguration(pointSize: canvas * 0.40, weight: .medium)
    guard let symbol = NSImage(systemSymbolName: "eye", accessibilityDescription: nil)?
        .withSymbolConfiguration(config) else { return false }

    let white = NSImage(size: symbol.size, flipped: false) { symbolRect in
        symbol.draw(in: symbolRect)
        NSColor.white.set()
        symbolRect.fill(using: .sourceAtop)
        return true
    }
    white.draw(in: NSRect(x: (canvas - symbol.size.width) / 2,
                          y: (canvas - symbol.size.height) / 2,
                          width: symbol.size.width, height: symbol.size.height))
    return true
}

func png(side: Int) throws -> Data {
    guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: side, pixelsHigh: side,
                                     bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                     colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
          let context = NSGraphicsContext(bitmapImageRep: rep) else {
        throw CocoaError(.fileWriteUnknown)
    }
    rep.size = NSSize(width: side, height: side)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    icon.draw(in: NSRect(x: 0, y: 0, width: side, height: side))
    NSGraphicsContext.restoreGraphicsState()
    guard let data = rep.representation(using: .png, properties: [:]) else {
        throw CocoaError(.fileWriteUnknown)
    }
    return data
}

let fileManager = FileManager.default
let iconset = URL(fileURLWithPath: NSTemporaryDirectory())
    .appendingPathComponent("eye-\(ProcessInfo.processInfo.processIdentifier).iconset")
try fileManager.createDirectory(at: iconset, withIntermediateDirectories: true)
for base in [16, 32, 128, 256, 512] {
    try png(side: base).write(to: iconset.appendingPathComponent("icon_\(base)x\(base).png"))
    try png(side: base * 2).write(to: iconset.appendingPathComponent("icon_\(base)x\(base)@2x.png"))
}

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconset.path, "-o", output]
try iconutil.run()
iconutil.waitUntilExit()
try? fileManager.removeItem(at: iconset)
exit(iconutil.terminationStatus)
