import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(DS.lockAccent.opacity(0.15))
                    .frame(width: 72, height: 72)

                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 34))
                    .foregroundColor(DS.lockAccent)
            }

            Spacer().frame(height: DS.Spacing.xl)

            VStack(spacing: DS.Spacing.sm) {
                Text("Accessibility Access Required")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Text("CleanMacKeyboard needs Accessibility permissions\nto block keyboard input during cleaning mode.")
                    .font(.system(size: DS.FontSize.body))
                    .multilineTextAlignment(.center)
                    .foregroundColor(DS.tertiaryLabel)
                    .lineSpacing(2)
            }

            Spacer().frame(height: DS.Spacing.xl + 4)

            VStack(spacing: DS.Spacing.md) {
                Button(action: {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    HStack(spacing: DS.Spacing.sm) {
                        Image(systemName: "gearshape.fill")
                        Text("Open System Settings")
                            .fontWeight(.medium)
                    }
                    .font(.system(size: DS.FontSize.body))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Spacing.sm + 2)
                    .foregroundColor(.white)
                    .background(DS.lockAccent)
                    .cornerRadius(DS.Radius.md)
                }
                .buttonStyle(.plain)

                Button(action: {
                    if AXIsProcessTrusted() {
                        isPresented = false
                    } else {
                        NSSound.beep()
                    }
                }) {
                    Text("I have granted access")
                        .fontWeight(.semibold)
                        .font(.system(size: DS.FontSize.body))
                }
                .buttonStyle(.plain)
                .foregroundColor(DS.lockAccent)
            }

            Spacer()
        }
        .padding(DS.Spacing.xl + 8)
        .frame(width: 380, height: 300)
        .background(DS.windowBg)
    }
}
