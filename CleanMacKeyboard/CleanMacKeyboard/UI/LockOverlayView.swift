import SwiftUI
import Combine

struct LockOverlayView: View {
    @EnvironmentObject var locker: KeyboardLocker
    @EnvironmentObject var settings: AppSettings

    @State private var timeElapsed: TimeInterval = 0
    @State private var isHolding = false
    @State private var holdProgress: CGFloat = 0
    @State private var holdStartTime: Date = .now
    @State private var timerCancellable: AnyCancellable?
    @State private var pulseAnim = false

    private let holdDuration: TimeInterval = 1.25

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)

            Rectangle()
                .fill(.ultraThinMaterial)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: DS.Spacing.xl + 4) {
                    statusBadge
                    timerDisplay
                    lockRing
                    instructionText
                    holdButton
                }

                Spacer()

                shortcutHint
                    .padding(.bottom, 40)
            }
        }
        .onAppear(perform: startTimer)
        .onDisappear(perform: cleanup)
        .onChange(of: locker.isLocked) { _, locked in
            if !locked { cleanup() }
        }
    }

    // MARK: - Status Badge

    private var statusBadge: some View {
        HStack(spacing: DS.Spacing.xs) {
            Circle()
                .fill(DS.lockAccent)
                .frame(width: 6, height: 6)
                .opacity(isHolding ? 1 : 0.5)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isHolding)

            Text("CLEANING ACTIVE")
                .font(.system(size: DS.FontSize.caption, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.5))
        }
    }

    // MARK: - Timer

    private var timerDisplay: some View {
        Text(formatTime(timeElapsed))
            .font(.system(size: DS.FontSize.timer, weight: .thin, design: .rounded))
            .foregroundColor(.white)
            .monospacedDigit()
            .contentTransition(.numericText())
    }

    // MARK: - Lock Ring

    private var lockRing: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.06), lineWidth: 3)
                .frame(width: 140, height: 140)

            Circle()
                .trim(from: 0, to: holdProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [DS.lockAccent.opacity(0.5), DS.lockAccent, .white.opacity(0.7)]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(-90))

            Circle()
                .fill(.white.opacity(0.04))
                .frame(width: 100, height: 100)
                .overlay(
                    Circle()
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )

            Image(systemName: holdProgress > 0.6 ? "lock.open.fill" : "lock.fill")
                .font(.system(size: 34, weight: .semibold))
                .foregroundColor(holdProgress > 0.6 ? .white : DS.lockAccent)
                .contentTransition(.symbolEffect(.replace))
        }
        .animation(.interactiveSpring(response: 0.35, dampingFraction: 0.7), value: holdProgress)
    }

    // MARK: - Instruction Text

    private var instructionText: some View {
        VStack(spacing: DS.Spacing.sm) {
            Text("Keyboard Locked")
                .font(.system(size: DS.FontSize.largeTitle, weight: .bold))
                .foregroundColor(.white)

            Text("Keys are deactivated. Safe to clean.")
                .font(.system(size: DS.FontSize.title))
                .foregroundColor(.white.opacity(0.55))
        }
    }

    // MARK: - Hold to Unlock Button

    private var holdButton: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(.white.opacity(0.08))
                .frame(width: 220, height: 44)

            Capsule()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [DS.lockAccent, DS.lockAccent.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 220 * max(holdProgress, 0.02), height: 44)

            HStack {
                Spacer()
                if holdProgress > 0 {
                    Text("Release to Unlock")
                        .font(.system(size: DS.FontSize.body, weight: .semibold))
                        .foregroundColor(holdProgress > 0.5 ? .black : .white)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 11))
                        Text("Hold to Unlock")
                            .font(.system(size: DS.FontSize.body, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .opacity(pulseAnim ? 0.6 : 1.0)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
                Spacer()
            }
            .animation(.easeInOut(duration: 0.25), value: holdProgress > 0)
        }
        .frame(width: 220, height: 44)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !isHolding else { return }
                    isHolding = true
                    holdStartTime = .now
                    nextHoldTick()
                }
                .onEnded { _ in
                    isHolding = false
                    if holdProgress < 1 {
                        withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.85)) {
                            holdProgress = 0
                        }
                    }
                }
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulseAnim = true
            }
        }
    }

    private func nextHoldTick() {
        guard isHolding, locker.isLocked else { return }
        let elapsed = Date.now.timeIntervalSince(holdStartTime)
        let progress = min(elapsed / holdDuration, 1.0)

        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.75)) {
            holdProgress = progress
        }

        if progress >= 1.0 {
            completeUnlock()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.016) {
                self.nextHoldTick()
            }
        }
    }

    private func completeUnlock() {
        isHolding = false
        holdProgress = 1
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            locker.unlock()
        }
    }

    // MARK: - Shortcut Hint

    private var shortcutHint: some View {
        HStack(spacing: DS.Spacing.xs) {
            Text("Press")
                .foregroundColor(.white.opacity(0.4))

            HStack(spacing: 2) {
                if settings.forceQuitUsesCmd   { badge("⌘") }
                if settings.forceQuitUsesShift { badge("⇧") }
                if settings.forceQuitUsesOpt   { badge("⌥") }
                if settings.forceQuitUsesCtrl  { badge("⌃") }
                badge(settings.forceQuitKey.rawValue.uppercased())
            }

            Text("to force unlock")
                .foregroundColor(.white.opacity(0.4))
        }
        .font(.system(size: DS.FontSize.body))
    }

    private func badge(_ text: String) -> some View {
        Text(text)
            .font(.system(size: DS.FontSize.caption, weight: .bold, design: .monospaced))
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(.white.opacity(0.08))
            .cornerRadius(3)
            .foregroundColor(.white.opacity(0.8))
    }

    // MARK: - Timer

    private func startTimer() {
        timeElapsed = 0
        holdProgress = 0
        isHolding = false

        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                guard locker.isLocked else { return }
                timeElapsed += 1
            }
    }

    private func cleanup() {
        timerCancellable?.cancel()
        timerCancellable = nil
        isHolding = false
        holdProgress = 0
        timeElapsed = 0
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
