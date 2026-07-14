# CleanMyKeyboard

A macOS menu-bar utility that temporarily **disables your keyboard** so you can safely clean it without unplugging or shutting down.

---

## Why

Cleaning a keyboard while the computer is on is risky — one accidental keystroke can delete code, send an unfinished message, or trigger something worse. CleanMyKeyboard blocks all key events (including modifiers) with a single click and restores them just as easily.

## How It Works

The app creates a system-level **CGEventTap** that intercepts every keyboard event (`keyDown`, `keyUp`, `flagsChanged`) before any other process receives it. While locked, only whitelisted keys (media keys, brightness controls) pass through. A configurable **force-quit combo** instantly unlocks the keyboard even if the app is frozen.

Events that are blocked are counted and displayed in the app so you know exactly what was prevented.

## Features

- **One-click lock/unlock** from the menu bar or the main app window
- **Full keyboard blocking** — modifiers, alphanumeric, function keys — everything is captured
- **Force-quit combo** — a customisable shortcut (default ⌘⇧Q) that unlocks instantly, even during a cleaning session
- **Whitelist media keys** — volume, brightness, play/pause, track skip still work while locked
- **Blocked-events counter** — see how many keystrokes were blocked during a session
- **Auto-unlock on sleep** — optionally unlock when the Mac goes to sleep
- **Lock overlay** — a full-screen overlay that shows on all displays while locked
- **Accessibility monitoring** — if the Accessibility permission is revoked mid-session, the app unlocks automatically
- **Hold-to-unlock** — requires a deliberate press on the lock overlay to unlock (prevents accidental unlock)
- **Session timer** — tracks how long the keyboard has been locked
- **Launch at login** — starts automatically in the menu bar

## Requirements

- macOS **14.0** or later
- **Accessibility permission** (required by CGEventTap)

## Installation

1. Download the latest DMG from the [releases page](https://github.com/your-username/CleanMyKeyboard/releases)
2. Drag **CleanMyKeyboard.app** to **Applications**
3. Right-click → **Open** (first launch only — Gatekeeper warning for developer-signed apps)
4. Grant **Accessibility** permission when prompted (System Settings > Privacy & Security > Accessibility)

## First Launch

The app will show an onboarding window that directs you to System Settings to grant Accessibility access. Without this permission, the keyboard cannot be locked.

Once granted, the app appears in the menu bar as a keyboard icon. Click it to open the settings popover, or open the main window from the dock.

## Security & Permissions

CleanMyKeyboard uses `CGEvent.tapCreate` which requires the **Accessibility** permission. This is the same system API used by legitimate utility apps like Karabiner-Elements, BetterTouchTool, and macOS's own Shortcuts.

The app does **not** require:
- Full Disk Access
- Screen Recording
- Input Monitoring (the legacy permission — Accessibility covers this)
- Network access (the app never connects to the internet)

## What Gets Blocked

When locked, **every** keyboard event is captured:
- All letter/number keys
- Modifier keys (⌘, ⌥, ⇧, ⌃)
- Function keys (F1–F12)
- Arrow keys, navigation keys
- Space, Enter, Delete, Escape
- Caps Lock, Tab

Whitelisted keys **pass through** (default: volume, brightness, media keys).

## Force-Quit Combo

By default, pressing **⌘⇧Q** unlocks the keyboard. This combo can be customised in Settings. The force-quit check happens inside the event tap — it works even if the app is unresponsive.

## Unlocking When the Tap Is Disabled

macOS can disable an event tap if:
- **Secure Input** is active (password field in Terminal, login screen, etc.)
- The screen is locked
- Accessibility permission is revoked

CleanMyKeyboard detects `tapDisabledByUserInput` / `tapDisabledByTimeout` events and **automatically unlocks**, so you're never stuck.

## Building from Source

```bash
git clone https://github.com/your-username/CleanMyKeyboard.git
cd CleanMyKeyboard
xcodebuild -project CleanMyKeyboard.xcodeproj -scheme CleanMyKeyboard -configuration Release build
```

The built app will be at `DerivedData/.../Build/Products/Release/CleanMyKeyboard.app`.

## Distribution

CleanMyKeyboard **cannot** be distributed through the **Mac App Store** because `CGEventTap` requires the Accessibility permission and is incompatible with the App Sandbox. The app is distributed as a Developer ID–signed, notarized DMG.

## Architecture

```
CleanMyKeyboard.app/
├── CleanMyKeyboardApp.swift       # App entry, window management
├── Core/
│   ├── KeyboardLocker.swift       # Event tap, lock/unlock, thread-safe state
│   └── KeyCombo.swift             # Key code + modifier matching
├── Models/
│   └── AppSettings.swift          # UserDefaults-backed settings
└── UI/
    ├── ContentView.swift          # Main app window
    ├── SettingsView.swift         # Menu-bar popover content
    ├── MenuBarController.swift    # NSStatusItem, popover, lock overlays
    ├── LockOverlayView.swift      # Full-screen lock overlay with hold gesture
    ├── OnboardingView.swift       # First-launch accessibility guide
    ├── WhitelistKeyPicker.swift   # Media key selection grid
    └── DesignSystem.swift         # Colors, spacing, typography constants
```

## License

MIT
