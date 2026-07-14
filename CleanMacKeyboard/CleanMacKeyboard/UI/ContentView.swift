import SwiftUI
import Combine
import AppKit

struct ContentView: View {
    @EnvironmentObject var locker: KeyboardLocker
    @EnvironmentObject var settings: AppSettings

    @State private var sessionSeconds: Int = 0
    @State private var sessionTimer: AnyCancellable?

    var body: some View {
        HStack(spacing: 0) {
            statusPanel
            Divider().overlay(DS.borderColor)
            settingsPanel
        }
        .frame(width: 680, height: 480)
        .background(DS.windowBg)
        .onAppear { startSessionTimer() }
        .onDisappear { stopSessionTimer() }
        .onChange(of: locker.isLocked) { _, locked in
            if locked { sessionSeconds = 0; startSessionTimer() }
            if !locked { stopSessionTimer() }
        }
    }

    // MARK: - Status Panel (Left)

    private var statusPanel: some View {
        VStack(spacing: DS.Spacing.lg) {
            Spacer()

            if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
               let icon = NSImage(contentsOf: url) {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            VStack(spacing: 2) {
                Text("CleanMacKeyboard")
                    .font(.system(size: DS.FontSize.large, weight: .bold))
                    .foregroundStyle(.white)
                Text(locker.isLocked ? "Locked · \(formatTime(sessionSeconds))" : "Ready")
                    .font(.system(size: DS.FontSize.caption))
                    .foregroundStyle(locker.isLocked ? DS.lockAccent : DS.tertiaryLabel)
            }

            Button(action: { locker.toggle() }) {
                HStack(spacing: 6) {
                    Image(systemName: locker.isLocked ? "lock.open.fill" : "lock.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text(locker.isLocked ? "Unlock Keyboard" : "Lock Keyboard")
                        .font(.system(size: DS.FontSize.body, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(width: 170, height: 40)
                .background(locker.isLocked ? DS.unlockAccent : DS.lockAccent)
                .cornerRadius(20)
            }
            .buttonStyle(.plain)

            HStack(spacing: DS.Spacing.xl) {
                statItem(value: "\(locker.blockedEvents)", label: "Blocked")
                statItem(value: "\(settings.whitelistedRawKeys.count)", label: "Allowed")
            }

            Spacer()
        }
        .frame(width: 220)
        .background(DS.windowBg)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.system(size: DS.FontSize.title, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: DS.FontSize.caption))
                .foregroundStyle(DS.tertiaryLabel)
        }
    }

    // MARK: - Settings Panel (Right)

    private var settingsPanel: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xl) {
            forceQuitSection
            whitelistSection
            behaviorSection
        }
        .padding(DS.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(DS.windowBg)
    }

    private var forceQuitSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            sectionLabel("Force-Quit Shortcut")
            Text("This combo always unlocks, even during active cleaning.")
                .font(.system(size: DS.FontSize.caption))
                .foregroundStyle(DS.tertiaryLabel)
            HStack(spacing: DS.Spacing.xs) {
                ModifierButton("⌘", isOn: $settings.forceQuitUsesCmd)
                ModifierButton("⇧", isOn: $settings.forceQuitUsesShift)
                ModifierButton("⌥", isOn: $settings.forceQuitUsesOpt)
                ModifierButton("⌃", isOn: $settings.forceQuitUsesCtrl)
                Spacer()
                Picker("", selection: $settings.forceQuitKey) {
                    ForEach(Key.allCases) { key in
                        Text(key.rawValue.uppercased()).tag(key)
                    }
                }
                .frame(width: 56)
                .labelsHidden()
            }
            .padding(DS.Spacing.md)
            .background(DS.windowBg)
            .cornerRadius(DS.Radius.md)
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.md).stroke(DS.borderColor, lineWidth: 1))
        }
    }

    private var whitelistSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            sectionLabel("Whitelisted Keys")
            WhitelistKeyPicker(selectedCodes: $settings.whitelistedRawKeys)
        }
    }

    private var behaviorSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            sectionLabel("Behavior")
            VStack(spacing: DS.Spacing.sm) {
                toggleRow("Unlock when Mac sleeps", isOn: $settings.unlockOnSleep)
                toggleRow("Show lock overlay", isOn: $settings.showOverlay)
                toggleRow("Launch at login", isOn: $settings.launchAtLogin)
            }
        }
    }

    private func toggleRow(_ label: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(label)
                .font(.system(size: DS.FontSize.body))
                .foregroundStyle(.white)
            Spacer()
            Toggle("", isOn: isOn).toggleStyle(.switch).controlSize(.small)
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, 10)
        .background(DS.windowBg)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(DS.borderColor, lineWidth: 1))
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: DS.FontSize.subhead, weight: .semibold))
            .foregroundStyle(DS.tertiaryLabel)
    }

    private func startSessionTimer() {
        guard locker.isLocked else { return }
        sessionTimer?.cancel()
        sessionTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in sessionSeconds += 1 }
    }

    private func stopSessionTimer() {
        sessionTimer?.cancel()
        sessionTimer = nil
    }

    private func formatTime(_ s: Int) -> String {
        let m = s / 60
        let sec = s % 60
        return String(format: "%02d:%02d", m, sec)
    }
}
