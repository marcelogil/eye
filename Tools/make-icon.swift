// Builds the app icon from Resources/AppIcon.png: the photo is scaled to
// fill a macOS-style rounded square and exported as an .icns.
// Usage: make-icon <source.png> <output.icns>
import AppKit

guard CommandLine.arguments.count == 3 else {
    FileHandle.standardError.write(Data("usage: make-icon <source.png> <output.icns>\n".utf8))
    exit(2)
}
let sourcePath = CommandLine.arguments[1]
let output = CommandLine.arguments[2]
guard let source = NSImage(contentsOfFile: sourcePath) else {
    FileHandle.standardError.write(Data("cannot read \(sourcePath)\n".utf8))
    exit(1)
}

let canvas: CGFloat = 1024
/// How much the photo is zoomed inside the square, so the eye fills it well.
let zoom: CGFloat = 1.25

let icon = NSImage(size: NSSize(width: canvas, height: canvas), flipped: false) { rect in
    // Apple's macOS icon grid: the rounded square fills 824 of the 1024 points.
    let square = rect.insetBy(dx: canvas * 0.0977, dy: canvas * 0.0977)
    let radius = square.width * 0.2237
    let shape = NSBezierPath(roundedRect: square, xRadius: radius, yRadius: radius)

    NSGraphicsContext.saveGraphicsState()
    shape.addClip()
    NSColor.white.setFill()
    square.fill()

    // Scale the photo to cover the square, then zoom in around its centre.
    let scale = max(square.width / source.size.width, square.height / source.size.height) * zoom
    let drawn = NSSize(width: source.size.width * scale, height: source.size.height * scale)
    let origin = NSPoint(x: square.midX - drawn.width / 2, y: square.midY - drawn.height / 2)
    source.draw(in: NSRect(origin: origin, size: drawn), from: .zero,
                operation: .sourceOver, fraction: 1, respectFlipped: true,
                hints: [.interpolation: NSImageInterpolation.high])
    NSGraphicsContext.restoreGraphicsState()
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
