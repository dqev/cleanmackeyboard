import SwiftUI

struct WhitelistEntry: Identifiable {
    let id: UInt16
    let label: String
    let iconName: String
}

let commonWhitelistKeys: [WhitelistEntry] = [
    .init(id: 144, label: "Volume Up",     iconName: "speaker.wave.3.fill"),
    .init(id: 145, label: "Volume Down",   iconName: "speaker.wave.1.fill"),
    .init(id: 146, label: "Mute",          iconName: "speaker.slash.fill"),
    .init(id: 160, label: "Play/Pause",    iconName: "playpause.fill"),
    .init(id: 177, label: "Previous Track", iconName: "backward.fill"),
    .init(id: 176, label: "Next Track",    iconName: "forward.fill"),
    .init(id: 107, label: "Brightness +",  iconName: "sun.max.fill"),
    .init(id: 113, label: "Brightness -",  iconName: "sun.min.fill"),
]

struct WhitelistKeyPicker: View {
    @Binding var selectedCodes: [UInt16]
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DS.Spacing.sm), count: 2), spacing: DS.Spacing.sm) {
            ForEach(commonWhitelistKeys) { entry in
                let selected = selectedCodes.contains(entry.id)
                Button(action: { toggle(entry.id) }) {
                    HStack(spacing: DS.Spacing.xs) {
                        Image(systemName: entry.iconName)
                            .font(.system(size: 10))
                        Text(entry.label)
                            .font(.system(size: DS.FontSize.caption, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Spacing.sm - 1)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selected ? DS.lockAccent.opacity(0.15) : DS.windowBg)
                    )
                    .foregroundColor(selected ? DS.lockAccent : .white)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func toggle(_ code: UInt16) {
        if let idx = selectedCodes.firstIndex(of: code) {
            selectedCodes.remove(at: idx)
        } else {
            selectedCodes.append(code)
        }
    }
}
