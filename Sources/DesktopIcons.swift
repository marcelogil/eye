import Foundation

/// Controls the "Show Items › On Desktop" / "In Stage Manager" switch from
/// System Settings › Desktop & Dock.
///
/// macOS keeps that switch in the `com.apple.WindowManager` preference domain.
/// WindowManager observes the domain and tells Finder to hide or show the
/// desktop icons, so writing the same key System Settings writes has exactly
/// the same effect, immediately and without restarting Finder.
///
/// Nothing on disk is touched: the files stay in ~/Desktop, keep their names
/// and keep their own hidden flags. A Finder window on the Desktop folder
/// shows them exactly as before.
final class DesktopIcons: NSObject {
    private enum Key {
        static let domain = "com.apple.WindowManager"
        /// "Show Items › On Desktop", used while Stage Manager is off. `true` hides the icons.
        static let hideOnDesktop = "StandardHideDesktopIcons"
        /// "Show Items › In Stage Manager", used while Stage Manager is on. `true` hides the icons.
        static let hideInStageManager = "HideDesktop"
        /// Whether Stage Manager is turned on.
        static let stageManagerEnabled = "GloballyEnabled"
        static let all = [hideOnDesktop, hideInStageManager, stageManagerEnabled]
    }

    /// Called on the main thread whenever the setting changes, whether from
    /// this app or from System Settings.
    var onChange: (() -> Void)?

    private let defaults: UserDefaults
    private static var kvoContext = 0

    override init() {
        guard let defaults = UserDefaults(suiteName: Key.domain) else {
            fatalError("Cannot open the \(Key.domain) preference domain")
        }
        self.defaults = defaults
        super.init()
        for key in Key.all {
            defaults.addObserver(self, forKeyPath: key, options: [], context: &Self.kvoContext)
        }
    }

    deinit {
        for key in Key.all {
            defaults.removeObserver(self, forKeyPath: key, context: &Self.kvoContext)
        }
    }

    var isStageManagerEnabled: Bool {
        defaults.bool(forKey: Key.stageManagerEnabled)
    }

    /// `true` while the desktop icons are hidden.
    var isHidden: Bool {
        if isStageManagerEnabled {
            // Stage Manager hides desktop items unless the user turned them on.
            return defaults.object(forKey: Key.hideInStageManager) as? Bool ?? true
        }
        return defaults.bool(forKey: Key.hideOnDesktop)
    }

    func setHidden(_ hidden: Bool) {
        let key = isStageManagerEnabled ? Key.hideInStageManager : Key.hideOnDesktop
        defaults.set(hidden, forKey: key)
    }

    func toggle() {
        setHidden(!isHidden)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?,
                               change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &Self.kvoContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        DispatchQueue.main.async { [weak self] in
            self?.onChange?()
        }
    }
}
