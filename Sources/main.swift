import AppKit

// Entry point. Eye has no windows and no Dock icon; everything happens from
// the status bar item.
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
