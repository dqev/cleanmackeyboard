import AppKit
import SwiftUI
import Combine

class MenuBarController: NSObject {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    let locker = KeyboardLocker()
    private let settings = AppSettings.shared
    private var cancellables = Set<AnyCancellable>()
    private var overlayWindows: [NSWindow] = []

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            updateStatusButtonImage(isLocked: false)
            button.action = #selector(togglePopover)
            button.target = self
        }

        let contentView = SettingsView()
            .environmentObject(locker)
            .environmentObject(settings)

        popover = NSPopover()
        popover.contentSize = NSSize(width: DS.popoverWidth, height: 520)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)

        locker.$isLocked
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLocked in
                self?.handleLockStateChange(isLocked)
            }
            .store(in: &cancellables)

        let nc = NSWorkspace.shared.notificationCenter
        nc.addObserver(self, selector: #selector(onSleep), name: NSWorkspace.willSleepNotification, object: nil)

        let dnc = DistributedNotificationCenter.default()
        dnc.addObserver(self, selector: #selector(onSystemLockEvent), name: NSNotification.Name("com.apple.screensaver.didstart"), object: nil)
        dnc.addObserver(self, selector: #selector(onSystemLockEvent), name: NSNotification.Name("com.apple.screenIsLocked"), object: nil)
    }

    private func updateStatusButtonImage(isLocked: Bool) {
        guard let button = statusItem.button else { return }
        let symbolName = isLocked ? "lock.keyboard.fill" : "keyboard"
        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "CleanMacKeyboard") {
            image.isTemplate = true
            button.image = image
        }
    }

    @objc func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private func handleLockStateChange(_ isLocked: Bool) {
        updateStatusButtonImage(isLocked: isLocked)

        if isLocked {
            popover.performClose(nil)
            if settings.showOverlay {
                showLockOverlays()
            }
        } else {
            hideLockOverlays()
        }
    }

    private func showLockOverlays() {
        guard overlayWindows.isEmpty else { return }

        NSCursor.setHiddenUntilMouseMoves(false)

        for screen in NSScreen.screens {
            let window = NSPanel(
                contentRect: screen.frame,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )

            window.level = .screenSaver
            window.backgroundColor = .clear
            window.isOpaque = false
            window.ignoresMouseEvents = false
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

            let overlayView = LockOverlayView()
                .environmentObject(locker)
                .environmentObject(settings)

            window.contentView = NSHostingView(rootView: overlayView)
            window.makeKeyAndOrderFront(nil)
            overlayWindows.append(window)
        }
    }

    private func hideLockOverlays() {
        for window in overlayWindows {
            window.close()
            window.contentView = nil
        }
        overlayWindows.removeAll()
    }

    @objc private func onSleep() {
        if settings.unlockOnSleep {
            locker.unlock()
        }
    }

    @objc private func onSystemLockEvent() {
        locker.unlock()
    }

    deinit {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        DistributedNotificationCenter.default().removeObserver(self)
        hideLockOverlays()
        cancellables.removeAll()
    }
}
