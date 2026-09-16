# Eye

A small macOS menu bar app that hides and shows the icons on your desktop, so
the desktop is clean for presentations and screen sharing.

- **Left click** the eye in the menu bar to hide or show the desktop icons.
- **Right click** (or control-click) for the menu: *Show/Hide Desktop Icons*,
  *Launch at Login*, *Desktop & Dock Settings…*, *About Eye* and *Quit Eye*.

The icon shows the current state: an open eye while the icons are visible, a
crossed-out eye while they are hidden.

## How it works

Eye flips the same switch as System Settings › Desktop & Dock › **Show Items ›
On Desktop** (or *In Stage Manager* while Stage Manager is on). macOS keeps
that switch in the `com.apple.WindowManager` preference domain. WindowManager
watches the domain and tells Finder to hide or show the icons, so the change is
instant and Finder is never restarted.

Nothing on disk changes. Files stay in `~/Desktop`, keep their names and keep
their own hidden flags, and a Finder window on the Desktop folder shows them as
usual. Because it is a system setting, it survives quitting Eye: toggle it
again with Eye or in System Settings.

Eye also follows changes made elsewhere. Flip the switch in System Settings and
the menu bar icon updates.

## Requirements

- macOS 14 Sonoma or later (the *Show Items* switch appeared in Sonoma).
- Xcode or the Command Line Tools, for `swiftc`.

## Build and install

```sh
make            # builds build/Eye.app
make run        # builds and launches it from the build folder
make install    # builds, copies to /Applications and launches
```

`make install INSTALL_DIR=~/Applications` installs for the current user only.

Turn on **Launch at Login** from the right-click menu after installing. Login
items are tied to the app's location, so if you move `Eye.app` later, turn the
option off and on again.

## Uninstall

```sh
make uninstall  # quits Eye and removes /Applications/Eye.app
```

Turn off *Launch at Login* first, or remove Eye afterwards under System
Settings › General › Login Items & Extensions.

## Project layout

- `Sources/` Swift and AppKit sources
  - `StatusBarController.swift` status item, click handling and menu
  - `DesktopIcons.swift` reads and writes the Desktop & Dock setting and observes changes
  - `LaunchAtLogin.swift` `SMAppService` wrapper for the login item
- `Resources/Info.plist` bundle metadata (`LSUIElement` keeps Eye out of the Dock)
- `Resources/AppIcon.png` the icon artwork; `Tools/make-icon.swift` turns it into the .icns at build time
- `Makefile` build, ad-hoc sign, run, install
