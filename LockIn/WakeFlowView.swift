//
//  WakeFlowView.swift
//  LockIn
//
//  Created by leon on 2026/2/10.
//

import SwiftUI

struct WakeFlowView: View {
    private let planText = "Today: Do the first card, then keep distractions blocked."
    private let speechService: SpeechService

    @State private var dragOffset: CGFloat = 0
    @State private var isAwake = false
    @State private var showContinue = false

    init(speechService: SpeechService = SystemSpeechService()) {
        self.speechService = speechService
    }

    var body: some View {
        NavigationStack {
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

                    Button("Continue") {
                        showContinue = true
                    }
                    .buttonStyle(.borderedProminent)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .navigationDestination(isPresented: $showContinue) {
                AlarmTestView()
            }
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
        isAwake = true
        withAnimation(.spring()) {
            dragOffset = maxOffset
        }
        speechService.speak(planText)
    }
}

#Preview {
    WakeFlowView()
}
