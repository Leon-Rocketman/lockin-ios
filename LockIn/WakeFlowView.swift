//
//  WakeFlowView.swift
//  LockIn
//
//  Created by leon on 2026/2/10.
//

import SwiftUI
import SwiftData

struct WakeFlowView: View {
    private let planText = "Today: Do the first card, then keep distractions blocked."

    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var alarmSession: AlarmSessionStore
    @EnvironmentObject private var speech: SystemSpeechService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var dragOffset: CGFloat = 0
    @State private var isAwake = false
    @State private var pendingSpeak = false
    @State private var pendingSpeakText: String?
    @State private var isSpeakScheduled = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Good morning")
                .font(.largeTitle)
                .fontWeight(.semibold)

            Text(planText)
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            slideToWakeControl

            if isAwake {
                Text("Awake ✅")
                    .font(.title2)
                    .fontWeight(.semibold)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onChange(of: scenePhase) { _,_ in
            scheduleSpeakIfPossible()
        }
        .onChange(of: pendingSpeak) { _,_ in
            scheduleSpeakIfPossible()
        }
        .onAppear {
            alarmSession.enteredWakeFlow()
        }
    }

    private var slideToWakeControl: some View {
        GeometryReader { geometry in
            let horizontalPadding: CGFloat = 24
            let trackHeight: CGFloat = 56
            let knobSize: CGFloat = 48
            let inset: CGFloat = 4
            let trackWidth = geometry.size.width - (horizontalPadding * 2)
            let maxOffset = max(0, trackWidth - knobSize - (inset * 2))

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemGray5))
                    .frame(height: trackHeight)

                Text("Slide to wake")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)

                Circle()
                    .fill(Color(.systemBlue))
                    .frame(width: knobSize, height: knobSize)
                    .offset(x: (isAwake ? maxOffset : dragOffset) + inset)
                    .shadow(radius: 2)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                guard !isAwake else { return }
                                dragOffset = min(max(0, value.translation.width), maxOffset)
                            }
                            .onEnded { _ in
                                guard !isAwake else { return }
                                if dragOffset >= maxOffset * 0.95 {
                                    confirmAwake(maxOffset: maxOffset)
                                } else {
                                    withAnimation(.spring()) {
                                        dragOffset = 0
                                    }
                                }
                            }
                    )
            }
            .frame(width: trackWidth, height: trackHeight)
            .padding(.horizontal, horizontalPadding)
        }
        .frame(height: 72)
        .animation(.spring(), value: dragOffset)
    }

    private func confirmAwake(maxOffset: CGFloat) {
        alarmSession.completedWakeFlow()
        NotificationScheduler().cancelAlarmSeries()
        isAwake = true
        withAnimation(.spring()) {
            dragOffset = maxOffset
        }

        Task {
            let briefing = await buildMorningBriefingText()
            await MainActor.run {
                pendingSpeakText = briefing
                pendingSpeak = true
                scheduleSpeakIfPossible()
            }
        }

        router.completeWakeFlow()
    }

    private func scheduleSpeakIfPossible() {
        guard pendingSpeak, scenePhase == .active else { return }
        guard !isSpeakScheduled else { return }
        isSpeakScheduled = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            guard pendingSpeak, scenePhase == .active else {
                isSpeakScheduled = false
                return
            }
            guard let text = pendingSpeakText, !text.isEmpty else {
                isSpeakScheduled = false
                return
            }
            speech.speak(text)
            pendingSpeakText = nil
            pendingSpeak = false
            isSpeakScheduled = false
        }
    }

    private func buildMorningBriefingText() async -> String {
        let todos = TodoBriefingRepository.fetchUnfinishedTodoTitles(in: modelContext, limit: 7)
        let weather = await PlaceholderWeatherProvider(fixedText: "晴天")
            .fetchWeatherSummary(for: Date())

        return MorningBriefingBuilder.build(
            MorningBriefingInput(
                now: Date(),
                weatherText: weather,
                unfinishedTodos: todos,
                userName: "里昂"
            )
        )
    }
}

#Preview {
    WakeFlowView()
        .environmentObject(AppRouter())
        .environmentObject(AlarmSessionStore())
        .environmentObject(SystemSpeechService())
}
