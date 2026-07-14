import Cocoa
import Carbon
import Combine
import os

class KeyboardLocker: ObservableObject {
    @Published var isLocked: Bool = false
    @Published var blockedEvents: Int = 0

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var tapUserInfo: UnsafeMutableRawPointer?

    @Published var forceQuitCombo: KeyCombo = KeyCombo(key: .q, modifiers: [.command, .shift]) {
        didSet { syncCombo() }
    }
    @Published var whitelistedKeyCodes: Set<CGKeyCode> = [] {
        didSet { syncWhitelist() }
    }

    private let stateLock = os_unfair_lock_t.allocate(capacity: 1)
    private var lockSafeForceQuitCombo: KeyCombo = KeyCombo(key: .q, modifiers: [.command, .shift])
    private var lockSafeWhitelistedKeyCodes: Set<CGKeyCode> = []

    private var accessCheckTimer: AnyCancellable?

    init() {
        stateLock.initialize(to: os_unfair_lock())
        startAccessibilityMonitoring()
    }

    func lock() {
        guard !isLocked else { return }
        blockedEvents = 0
        guard AXIsProcessTrusted() else {
            requestAccessibility()
            return
        }

        let eventMask: CGEventMask =
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.keyUp.rawValue) |
            (1 << CGEventType.flagsChanged.rawValue)

        let ptr = Unmanaged.passRetained(self).toOpaque()
        tapUserInfo = ptr

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: eventTapCallback,
            userInfo: ptr
        )

        guard let tap = eventTap else {
            tapUserInfo = nil
            Unmanaged<KeyboardLocker>.fromOpaque(ptr).release()
            DispatchQueue.main.async {
                self.showTapError()
            }
            return
        }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        isLocked = true
    }

    func unlock() {
        guard isLocked else { return }

        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }

        if let ptr = tapUserInfo {
            Unmanaged<KeyboardLocker>.fromOpaque(ptr).release()
        }

        eventTap = nil
        runLoopSource = nil
        tapUserInfo = nil
        isLocked = false
    }

    func toggle() {
        isLocked ? unlock() : lock()
    }

    var safeForceQuitCombo: KeyCombo {
        os_unfair_lock_lock(stateLock)
        let val = lockSafeForceQuitCombo
        os_unfair_lock_unlock(stateLock)
        return val
    }

    var safeWhitelistedKeyCodes: Set<CGKeyCode> {
        os_unfair_lock_lock(stateLock)
        let val = lockSafeWhitelistedKeyCodes
        os_unfair_lock_unlock(stateLock)
        return val
    }

    private func syncCombo() {
        os_unfair_lock_lock(stateLock)
        lockSafeForceQuitCombo = forceQuitCombo
        os_unfair_lock_unlock(stateLock)
    }

    private func syncWhitelist() {
        os_unfair_lock_lock(stateLock)
        lockSafeWhitelistedKeyCodes = whitelistedKeyCodes
        os_unfair_lock_unlock(stateLock)
    }

    private func requestAccessibility() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true]
        AXIsProcessTrustedWithOptions(options)
    }

    private func showTapError() {
        let alert = NSAlert()
        alert.messageText = "Failed to Lock Keyboard"
        alert.informativeText = "CleanMacKeyboard could not create the event tap. Make sure you have granted Accessibility permission in System Settings > Privacy & Security > Accessibility."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    private func startAccessibilityMonitoring() {
        accessCheckTimer = Timer.publish(every: 10, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.isLocked else { return }
                if !AXIsProcessTrusted() {
                    self.unlock()
                }
            }
    }

    deinit {
        accessCheckTimer?.cancel()
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        if let ptr = tapUserInfo {
            Unmanaged<KeyboardLocker>.fromOpaque(ptr).release()
        }
        stateLock.deallocate()
    }
}

private func eventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let ptr = userInfo else { return Unmanaged.passRetained(event) }
    let locker = Unmanaged<KeyboardLocker>.fromOpaque(ptr).takeUnretainedValue()

    if type == .tapDisabledByUserInput || type == .tapDisabledByTimeout {
        DispatchQueue.main.async {
            if locker.isLocked {
                locker.unlock()
            }
        }
        return nil
    }

    let combo = locker.safeForceQuitCombo
    if type == .keyDown && combo.matches(event: event) {
        DispatchQueue.main.async {
            locker.unlock()
        }
        return Unmanaged.passRetained(event)
    }

    let whitelist = locker.safeWhitelistedKeyCodes
    let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
    if whitelist.contains(keyCode) {
        return Unmanaged.passRetained(event)
    }

    if type == .flagsChanged {
        return Unmanaged.passRetained(event)
    }

    DispatchQueue.main.async {
        locker.blockedEvents += 1
    }
    return nil
}
