//
//  WakeFlowView.swift
//  LockIn
//
//  Created by leon on 2026/2/10.
//

import SwiftUI

struct WakeFlowView: View {
    private let planText = "Today: Do the first card, then keep distractions blocked."
    private let firstCardText = "第一张卡：回顾今天的最重要任务，然后开始一个25分钟的锁定专注。"

    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var alarmSession: AlarmSessionStore
    @EnvironmentObject private var speech: SystemSpeechService
    @Environment(\.scenePhase) private var scenePhase
    @State private var dragOffset: CGFloat = 0
    @State private var isAwake = false
    @State private var pendingSpeak = false

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
        pendingSpeak = true
        scheduleSpeakIfPossible()
        router.completeWakeFlow()
    }

    private func scheduleSpeakIfPossible() {
        guard pendingSpeak, scenePhase == .active else { return }
        pendingSpeak = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            speech.speak(firstCardText)
        }
    }
}

#Preview {
    WakeFlowView()
        .environmentObject(AppRouter())
        .environmentObject(AlarmSessionStore())
        .environmentObject(SystemSpeechService())
}
