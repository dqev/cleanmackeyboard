import SwiftUI
import Combine

struct SettingsView: View {
    @EnvironmentObject var locker: KeyboardLocker
    @EnvironmentObject var settings: AppSettings

    @State private var sessionSeconds: Int = 0
    @State private var sessionTimer: AnyCancellable?

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().padding(.horizontal, DS.Spacing.lg)
            lockButton
            Divider().padding(.horizontal, DS.Spacing.lg)
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.xl) {
                    statusSection
                    forceQuitSection
                    whitelistSection
                    behaviorSection
                }
                .padding(.horizontal, DS.Spacing.lg)
                .padding(.vertical, DS.Spacing.lg)
            }
            Divider().padding(.horizontal, DS.Spacing.lg)
            footer
        }
        .frame(width: DS.popoverWidth)
        .background(DS.background)
        .onAppear { syncLocker(); startSessionTimer() }
        .onDisappear { stopSessionTimer() }
        .onChange(of: locker.isLocked) { _, locked in
            if locked { sessionSeconds = 0; startSessionTimer() }
            if !locked { stopSessionTimer() }
        }
        .onChange(of: settings.forceQuitKey) { _, _ in syncLocker() }
        .onChange(of: settings.forceQuitUsesCmd) { _, _ in syncLocker() }
        .onChange(of: settings.forceQuitUsesShift) { _, _ in syncLocker() }
        .onChange(of: settings.forceQuitUsesOpt) { _, _ in syncLocker() }
        .onChange(of: settings.forceQuitUsesCtrl) { _, _ in syncLocker() }
        .onChange(of: settings.whitelistedRawKeys) { _, _ in syncLocker() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: DS.Spacing.md) {
            Image(systemName: locker.isLocked ? "lock.keyboard.fill" : "keyboard")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(locker.isLocked ? DS.lockAccent : DS.secondaryLabel)

            VStack(alignment: .leading, spacing: 1) {
                Text("CleanMacKeyboard")
                    .font(.system(size: DS.FontSize.title, weight: .semibold))
                Text(locker.isLocked ? "Cleaning in progress" : "Ready")
                    .font(.system(size: DS.FontSize.caption + 1))
                    .foregroundColor(DS.tertiaryLabel)
            }

            Spacer()

            if locker.isLocked {
                HStack(spacing: DS.Spacing.xs) {
                    Circle()
                        .fill(DS.lockAccent)
                        .frame(width: 7, height: 7)
                    Text(formatSessionTime(sessionSeconds))
                        .font(.system(size: DS.FontSize.body, weight: .medium, design: .monospaced))
                        .foregroundColor(DS.lockAccent)
                }
                .padding(.horizontal, DS.Spacing.sm)
                .padding(.vertical, DS.Spacing.xs)
                .background(DS.lockDim)
                .cornerRadius(DS.Radius.sm)
            }
        }
        .padding(.horizontal, DS.Spacing.lg)
        .padding(.vertical, DS.Spacing.md)
    }

    // MARK: - Lock Button

    private var lockButton: some View {
        Button(action: { locker.toggle() }) {
            HStack(spacing: DS.Spacing.sm) {
                Image(systemName: locker.isLocked ? "lock.open.fill" : "lock.fill")
                    .font(.system(size: 13, weight: .semibold))
                Text(locker.isLocked ? "Unlock Keyboard" : "Lock Keyboard")
                    .fontWeight(.semibold)
            }
            .font(.system(size: DS.FontSize.body))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.md)
                    .fill(locker.isLocked ? DS.unlockAccent : DS.lockAccent)
            )
            .foregroundColor(.white)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, DS.Spacing.lg)
        .padding(.vertical, DS.Spacing.md)
    }

    // MARK: - Status Section

    private var statusSection: some View {
        VStack(spacing: DS.Spacing.sm) {
            sectionLabel("Session")

            HStack(spacing: DS.Spacing.md) {
                statusCard(
                    icon: "keyboard.badge.eye",
                    value: locker.isLocked ? "Active" : "—",
                    label: "Protection"
                )
                statusCard(
                    icon: "hand.raised.fill",
                    value: "\(locker.blockedEvents)",
                    label: "Events Blocked"
                )
                statusCard(
                    icon: "eye.fill",
                    value: "\(settings.whitelistedRawKeys.count)",
                    label: "Whitelisted Keys"
                )
            }
            .frame(maxHeight: 72)
        }
    }

    private func statusCard(icon: String, value: String, label: String) -> some View {
        VStack(spacing: DS.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(DS.lockAccent)
            Text(value)
                .font(.system(size: DS.FontSize.title, weight: .bold, design: .monospaced))
                .foregroundColor(.primary)
            Text(label)
                .font(.system(size: DS.FontSize.caption))
                .foregroundColor(DS.tertiaryLabel)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Spacing.md)
        .background(DS.cardFill)
        .cornerRadius(DS.Radius.md)
    }

    // MARK: - Force-Quit Section

    private var forceQuitSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            sectionLabel("Force-Quit Shortcut")

            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                Text("This combo always unlocks, even during active cleaning.")
                    .font(.system(size: DS.FontSize.caption + 0.5))
                    .foregroundColor(DS.tertiaryLabel)

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
                    .frame(width: 64)
                    .labelsHidden()
                }

                Text("Trigger: \(comboLabel)")
                    .font(.system(size: DS.FontSize.caption, weight: .medium, design: .monospaced))
                    .foregroundColor(DS.lockAccent)
            }
            .padding(DS.Spacing.md)
            .background(DS.cardFill)
            .cornerRadius(DS.Radius.md)
        }
    }

    // MARK: - Whitelist Section

    private var whitelistSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            sectionLabel("Always-Active Keys")
            WhitelistKeyPicker(selectedCodes: $settings.whitelistedRawKeys)
                .padding(DS.Spacing.md)
                .background(DS.cardFill)
                .cornerRadius(DS.Radius.md)
        }
    }

    // MARK: - Behavior Section

    private var behaviorSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            sectionLabel("Behavior")

            VStack(spacing: 0) {
                settingToggle("Unlock when Mac sleeps", isOn: $settings.unlockOnSleep)
                Separator()
                settingToggle("Show lock overlay", isOn: $settings.showOverlay)
                Separator()
                settingToggle("Launch at login", isOn: $settings.launchAtLogin)
            }
            .padding(.horizontal, DS.Spacing.md)
            .background(DS.cardFill)
            .cornerRadius(DS.Radius.md)
        }
    }

    private func settingToggle(_ label: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(label)
                .font(.system(size: DS.FontSize.body))
        }
        .toggleStyle(.switch)
        .controlSize(.small)
        .padding(.vertical, 10)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                .font(.system(size: DS.FontSize.caption))
                .foregroundColor(DS.tertiaryLabel)

            Spacer()

            Button("Quit") {
                NSApp.terminate(nil)
            }
            .font(.system(size: DS.FontSize.caption))
            .foregroundColor(DS.secondaryLabel)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, DS.Spacing.lg)
        .padding(.vertical, DS.Spacing.sm + 2)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: DS.FontSize.subhead, weight: .semibold))
            .foregroundColor(DS.secondaryLabel)
            .textCase(.uppercase)
    }

    private func syncLocker() {
        locker.forceQuitCombo = settings.builtCombo
        locker.whitelistedKeyCodes = settings.whitelistedKeyCodes
    }

    private var comboLabel: String {
        var parts: [String] = []
        if settings.forceQuitUsesCmd   { parts.append("⌘") }
        if settings.forceQuitUsesShift { parts.append("⇧") }
        if settings.forceQuitUsesOpt   { parts.append("⌥") }
        if settings.forceQuitUsesCtrl  { parts.append("⌃") }
        parts.append(settings.forceQuitKey.rawValue.uppercased())
        return parts.joined()
    }

    private func startSessionTimer() {
        guard locker.isLocked else { return }
        sessionTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in sessionSeconds += 1 }
    }

    private func stopSessionTimer() {
        sessionTimer?.cancel()
        sessionTimer = nil
    }

    private func formatSessionTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

struct Separator: View {
    var body: some View {
        DS.separator
            .frame(height: 0.5)
    }
}

struct ModifierButton: View {
    let label: String
    @Binding var isOn: Bool

    init(_ label: String, isOn: Binding<Bool>) {
        self.label = label
        self._isOn = isOn
    }

    var body: some View {
        Button(action: { isOn.toggle() }) {
            Text(label)
                .font(.system(size: DS.FontSize.body, weight: isOn ? .bold : .regular))
                .frame(minWidth: 32, minHeight: 28)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isOn ? DS.lockAccent : DS.windowBg)
                )
                .foregroundColor(isOn ? .white : .white)
        }
        .buttonStyle(.plain)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(DS.borderColor, lineWidth: 1))
    }
}
