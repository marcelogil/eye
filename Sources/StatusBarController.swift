import AppKit

/// Owns the status bar item. A left click toggles the desktop icons; a right
/// click or control-click opens the menu.
final class StatusBarController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let menu = NSMenu()
    private let desktop = DesktopIcons()

    private let toggleItem = NSMenuItem()
    private let launchAtLoginItem = NSMenuItem()

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        if let button = statusItem.button {
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        buildMenu()
        refresh()

        desktop.onChange = { [weak self] in
            self?.refresh()
        }
    }

    // MARK: - Menu

    private func buildMenu() {
        menu.delegate = self

        toggleItem.target = self
        toggleItem.action = #selector(toggleDesktopIcons(_:))
        menu.addItem(toggleItem)

        menu.addItem(.separator())

        launchAtLoginItem.title = "Launch at Login"
        launchAtLoginItem.target = self
        launchAtLoginItem.action = #selector(toggleLaunchAtLogin(_:))
        menu.addItem(launchAtLoginItem)

        let settingsItem = NSMenuItem(title: "Desktop & Dock Settings…",
                                      action: #selector(openDesktopSettings(_:)), keyEquivalent: "")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let aboutItem = NSMenuItem(title: "About Eye", action: #selector(showAbout(_:)), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        let quitItem = NSMenuItem(title: "Quit Eye", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.target = NSApp
        menu.addItem(quitItem)
    }

    /// Brings the icon and the menu in line with the current setting.
    private func refresh() {
        let hidden = desktop.isHidden
        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: hidden ? "eye.slash" : "eye",
                                accessibilityDescription: hidden ? "Desktop icons hidden" : "Desktop icons shown")
            image?.isTemplate = true
            button.image = image
            button.toolTip = hidden
                ? "Desktop icons are hidden. Click to show them."
                : "Desktop icons are shown. Click to hide them."
        }
        toggleItem.title = hidden ? "Show Desktop Icons" : "Hide Desktop Icons"
        launchAtLoginItem.state = LaunchAtLogin.isEnabled ? .on : .off
    }

    // MARK: - Actions

    @objc private func statusItemClicked(_ sender: Any?) {
        let event = NSApp.currentEvent
        let wantsMenu = event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true
        if wantsMenu {
            showMenu()
        } else {
            desktop.toggle()
            refresh()
        }
    }

    private func showMenu() {
        refresh()
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
    }

    func menuDidClose(_ menu: NSMenu) {
        // Detach the menu again, otherwise the next left click would open it
        // instead of toggling the icons.
        statusItem.menu = nil
    }

    @objc private func toggleDesktopIcons(_ sender: Any?) {
        desktop.toggle()
        refresh()
    }

    @objc private func toggleLaunchAtLogin(_ sender: Any?) {
        do {
            try LaunchAtLogin.setEnabled(!LaunchAtLogin.isEnabled)
        } catch {
            presentAlert(title: "Could not change the login item", message: error.localizedDescription)
        }
        if LaunchAtLogin.needsApproval {
            presentAlert(title: "Approval needed",
                         message: "macOS wants you to allow Eye under Login Items & Extensions. System Settings will open.")
            LaunchAtLogin.openSystemSettings()
        }
        refresh()
    }

    @objc private func openDesktopSettings(_ sender: Any?) {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Desktop-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func showAbout(_ sender: Any?) {
        NSApp.activate()
        NSApp.orderFrontStandardAboutPanel(options: [
            .credits: NSAttributedString(string: "Left click hides or shows the desktop icons.\nRight click opens this menu.")
        ])
    }

    private func presentAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        NSApp.activate()
        alert.runModal()
    }
}
