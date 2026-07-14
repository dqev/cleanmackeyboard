import SwiftUI

@main
struct CleanMacKeyboardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        Window("CleanMacKeyboard", id: "main") {
            ContentView()
                .environmentObject(delegate.menuBarController.locker)
                .environmentObject(AppSettings.shared)
        }
        .windowResizability(.contentSize)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    let menuBarController = MenuBarController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBarController.setup()

        styleWindow()

        if !AXIsProcessTrusted() {
            showOnboarding()
        }
    }

    private func styleWindow() {
        guard let window = NSApp.windows.first else { return }
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.styleMask.insert(.fullSizeContentView)
        if let bg = NSColor(fromHex: "#181818") {
            window.backgroundColor = bg
        }
        window.setContentSize(NSSize(width: 680, height: 480))
        window.center()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        if !hasVisibleWindows {
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
        }
        return true
    }

    private func showOnboarding() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 300),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.title = "Setup Required"
        window.center()
        window.isMovableByWindowBackground = true
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true

        var isPresented = true
        let onboardingView = OnboardingView(isPresented: Binding(
            get: { isPresented },
            set: { newValue in
                isPresented = newValue
                if !newValue {
                    window.close()
                }
            }
        ))

        window.contentView = NSHostingView(rootView: onboardingView)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
