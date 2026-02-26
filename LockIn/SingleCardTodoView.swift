//
//  SingleCardTodoView.swift
//  LockIn
//
//  Created by leon on 2026/2/10.
//

import SwiftUI
import SwiftData
import UIKit

struct SingleCardTodoView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TodoItem.orderIndex) private var todos: [TodoItem]

    @State private var isWalletExpanded = false
    @Namespace private var deckNamespace

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let cardHeight = min(max(430, proxy.size.height * 0.68), proxy.size.height - 118)

                ZStack {
                    deskBackground

                    VStack(alignment: .leading, spacing: 10) {
                        if !pendingTodos.isEmpty {
                            HStack {
                                Spacer()

                                Button {
                                    withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                                        isWalletExpanded.toggle()
                                    }
                                } label: {
                                    Image(systemName: isWalletExpanded ? "rectangle.stack.badge.person.crop.fill" : "rectangle.stack.fill")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color.white.opacity(0.92))
                                        .frame(width: 46, height: 46)
                                        .background(Color.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                            }
                            .accessibilityLabel(isWalletExpanded ? "Back to focus card" : "View all todos")
                        }

                        if let current = currentTodo {
                            Group {
                                if isWalletExpanded {
                                    expandedWalletStack(cardHeight: cardHeight)
                                } else {
                                    walletDeck(current: current, cardHeight: cardHeight)
                                }
                            }
                            .animation(.spring(response: 0.44, dampingFraction: 0.86), value: isWalletExpanded)
                        } else {
                            completedStateCard(height: cardHeight)
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 6)
                    .padding(.bottom, 18)
                }
            }
            .task {
                TodoStore.seedIfNeeded(in: modelContext)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink("Alarm Test") {
                        AlarmTestView()
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink("Speech Debug") {
                        SpeechDebugView()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SleepModeView()
                    } label: {
                        Image(systemName: "moon.zzz.fill")
                            .foregroundStyle(.white)
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var deskBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.14, green: 0.11, blue: 0.10),
                    Color(red: 0.17, green: 0.14, blue: 0.12),
                    Color(red: 0.10, green: 0.08, blue: 0.07)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 300, height: 300)
                .blur(radius: 12)
                .offset(x: -120, y: -300)

            Circle()
                .fill(Color.orange.opacity(0.09))
                .frame(width: 280, height: 280)
                .blur(radius: 12)
                .offset(x: 160, y: 360)

            VStack(spacing: 18) {
                ForEach(0..<28, id: \.self) { row in
                    Rectangle()
                        .fill(row.isMultiple(of: 2) ? Color.white.opacity(0.012) : Color.black.opacity(0.03))
                        .frame(height: 1)
                }
            }
            .ignoresSafeArea()
        }
    }

    private var pendingTodos: [TodoItem] {
        todos.filter { !$0.isDone }
    }

    private var currentTodo: TodoItem? {
        pendingTodos.first
    }

    private var completedCount: Int {
        todos.filter(\.isDone).count
    }

    private var pendingCount: Int {
        pendingTodos.count
    }

    private func walletDeck(current: TodoItem, cardHeight: CGFloat) -> some View {
        let upcoming = Array(pendingTodos.dropFirst().prefix(2))
        let verticalStep: CGFloat = 26

        return ZStack(alignment: .top) {
            ForEach(Array(upcoming.enumerated()), id: \.element.id) { index, todo in
                previewTodoCard(
                    todo,
                    depth: index + 1,
                    height: cardHeight,
                    verticalStep: verticalStep,
                    namespace: deckNamespace
                )
            }

            mainTodoCard(current, height: cardHeight)
                .id(current.id)
                .matchedGeometryEffect(id: current.id, in: deckNamespace, properties: .frame, anchor: .topLeading)
                .zIndex(3)
        }
        .frame(height: cardHeight + CGFloat(upcoming.count) * verticalStep + 10, alignment: .top)
        .animation(.spring(response: 0.68, dampingFraction: 0.92), value: pendingCount)
    }

    private func expandedWalletStack(cardHeight: CGFloat) -> some View {
        let cards = pendingTodos
        let expandedCardHeight = min(max(220, cardHeight * 0.50), 320)
        let visibleSpacing: CGFloat = max(120, expandedCardHeight * 0.56)
        let stackHeight = expandedCardHeight + CGFloat(max(0, cards.count - 1)) * visibleSpacing + 12

        return ScrollView(.vertical, showsIndicators: false) {
            ZStack(alignment: .top) {
                ForEach(Array(cards.enumerated()), id: \.element.id) { index, todo in
                    expandedTodoCard(
                        todo,
                        index: index,
                        height: expandedCardHeight,
                        visibleSpacing: visibleSpacing
                    )
                }
            }
            .frame(height: stackHeight, alignment: .top)
            .padding(.top, 0)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
        .frame(height: cardHeight + 16, alignment: .top)
        .transition(.opacity.combined(with: .scale(scale: 0.985, anchor: .top)))
    }

    private func mainTodoCard(_ todo: TodoItem, height: CGFloat) -> some View {
        let palette = palette(for: todo)

        return VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("TODAY'S CARD")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(palette.text.opacity(0.72))

                Spacer()

                Text("\(completedCount + 1) / \(max(1, todos.count))")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(palette.text.opacity(0.88))
            }

            Text(todo.title)
                .font(.system(size: 42, weight: .heavy, design: .rounded))
                .foregroundStyle(palette.text)
                .lineSpacing(3)
                .minimumScaleFactor(0.68)

            Spacer(minLength: 0)

            TearToCompleteStrip(tint: palette.accent) {
                complete(todo: todo)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .frame(height: height, alignment: .topLeading)
        .background(cardSurface(palette: palette, corner: 36))
        .shadow(color: Color.black.opacity(0.36), radius: 22, x: 0, y: 16)
    }

    private func expandedTodoCard(_ todo: TodoItem, index: Int, height: CGFloat, visibleSpacing: CGFloat) -> some View {
        let palette = palette(for: todo)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(index == 0 ? "CURRENT" : "NEXT #\(index + 1)")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(1.1)
                    .foregroundStyle(palette.text.opacity(0.68))
                Spacer()
            }

            Text(todo.title)
                .font(.system(size: 25, weight: .bold, design: .rounded))
                .foregroundStyle(palette.text)
                .lineSpacing(1)
                .lineLimit(4)
                .minimumScaleFactor(0.75)

            Spacer(minLength: 0)
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .frame(height: height, alignment: .topLeading)
        .background(cardSurface(palette: palette, corner: 34))
        .offset(y: CGFloat(index) * visibleSpacing)
        .rotationEffect(.degrees(Double(index % 2 == 0 ? -0.45 : 0.45)))
        .shadow(color: Color.black.opacity(0.26), radius: 14, x: 0, y: 10)
    }

    private func previewTodoCard(
        _ todo: TodoItem,
        depth: Int,
        height: CGFloat,
        verticalStep: CGFloat,
        namespace: Namespace.ID
    ) -> some View {
        let palette = palette(for: todo)
        let depthValue = CGFloat(depth)

        return VStack(alignment: .leading, spacing: 10) {
            Text(depth == 1 ? "NEXT CARD" : "LATER")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .tracking(1.1)
                .foregroundStyle(palette.text.opacity(0.68))

            Text(todo.title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(palette.text.opacity(0.88))
                .lineLimit(2)

            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .frame(height: max(170, height - depthValue * 38), alignment: .topLeading)
        .background(cardSurface(palette: palette, corner: 33))
        .scaleEffect(1 - depthValue * 0.024, anchor: .topLeading)
        .offset(x: depthValue * 4, y: depthValue * verticalStep)
        .rotationEffect(.degrees(Double(depth % 2 == 0 ? -2.0 : 1.4)), anchor: .topLeading)
        .opacity(0.9 - Double(depth) * 0.12)
        .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 9)
        .matchedGeometryEffect(id: todo.id, in: namespace, properties: .frame, anchor: .topLeading)
        .zIndex(Double(2 - depth))
    }

    private func completedStateCard(height: CGFloat) -> some View {
        let palette = CardPalette(
            top: Color(red: 0.96, green: 0.91, blue: 0.82),
            bottom: Color(red: 0.83, green: 0.77, blue: 0.68),
            accent: Color(red: 0.38, green: 0.53, blue: 0.36),
            text: Color(red: 0.20, green: 0.16, blue: 0.12)
        )

        return VStack(alignment: .leading, spacing: 20) {
            Text("ALL CLEAR")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(palette.text.opacity(0.7))

            Text("No card left today.")
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .foregroundStyle(palette.text)

            Spacer(minLength: 0)

            Button("Reset sample todos") {
                TodoStore.resetSampleTodos(in: modelContext)
            }
            .font(.system(.headline, design: .rounded, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(palette.accent, in: Capsule())
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .frame(height: height, alignment: .topLeading)
        .background(cardSurface(palette: palette, corner: 36))
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 14)
    }

    private func cardSurface(palette: CardPalette, corner: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [palette.top, palette.bottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.34), Color.white.opacity(0.02)],
                            startPoint: .topLeading,
                            endPoint: .center
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(Color.white.opacity(0.33), lineWidth: 1)
            )
            .overlay {
                PaperTextureOverlay(opacity: 0.13)
                    .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
            }
    }

    private func palette(for todo: TodoItem) -> CardPalette {
        let palettes: [CardPalette] = [
            CardPalette(
                top: Color(red: 0.96, green: 0.73, blue: 0.59),
                bottom: Color(red: 0.79, green: 0.44, blue: 0.31),
                accent: Color(red: 0.56, green: 0.20, blue: 0.12),
                text: Color(red: 0.22, green: 0.11, blue: 0.08)
            ),
            CardPalette(
                top: Color(red: 0.72, green: 0.89, blue: 0.85),
                bottom: Color(red: 0.43, green: 0.63, blue: 0.60),
                accent: Color(red: 0.17, green: 0.38, blue: 0.35),
                text: Color(red: 0.08, green: 0.20, blue: 0.18)
            ),
            CardPalette(
                top: Color(red: 0.78, green: 0.79, blue: 0.98),
                bottom: Color(red: 0.45, green: 0.47, blue: 0.76),
                accent: Color(red: 0.22, green: 0.24, blue: 0.55),
                text: Color(red: 0.11, green: 0.12, blue: 0.26)
            ),
            CardPalette(
                top: Color(red: 0.99, green: 0.80, blue: 0.85),
                bottom: Color(red: 0.83, green: 0.53, blue: 0.63),
                accent: Color(red: 0.54, green: 0.22, blue: 0.34),
                text: Color(red: 0.25, green: 0.09, blue: 0.15)
            ),
            CardPalette(
                top: Color(red: 0.89, green: 0.93, blue: 0.71),
                bottom: Color(red: 0.63, green: 0.71, blue: 0.43),
                accent: Color(red: 0.29, green: 0.43, blue: 0.16),
                text: Color(red: 0.17, green: 0.22, blue: 0.07)
            )
        ]

        let index = abs(todo.orderIndex) % palettes.count
        return palettes[index]
    }

    private func complete(todo: TodoItem) {
        withAnimation(.spring(response: 0.68, dampingFraction: 0.92, blendDuration: 0.2)) {
            todo.isDone = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            try? modelContext.save()
        }

        if pendingTodos.count <= 1 {
            isWalletExpanded = false
        }
    }
}

private struct CardPalette {
    let top: Color
    let bottom: Color
    let accent: Color
    let text: Color
}

private struct PaperTextureOverlay: View {
    let opacity: Double

    var body: some View {
        GeometryReader { proxy in
            let spacing = max(12, proxy.size.height / 15)

            VStack(spacing: spacing) {
                ForEach(0..<16, id: \.self) { row in
                    Rectangle()
                        .fill(row.isMultiple(of: 2) ? Color.white.opacity(opacity) : Color.black.opacity(opacity * 0.5))
                        .frame(height: 1)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .allowsHitTesting(false)
    }
}

private struct TearToCompleteStrip: View {
    let tint: Color
    let onComplete: () -> Void

    private let completionThreshold: CGFloat = 0.82
    private let feedbackSteps: Int = 14

    @State private var dragX: CGFloat = 0
    @State private var isCompleting = false
    @State private var isDragging = false
    @State private var lastFeedbackStep: Int = 0
    @State private var thresholdArmed = false
    @State private var didTriggerStartFeedback = false

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let maxTravel = max(0, width - height)
            let clamped = min(max(dragX, 0), maxTravel)
            let overshoot = max(0, dragX - maxTravel)
            let progress = maxTravel == 0 ? 0 : clamped / maxTravel
            let revealWidth = height + clamped + min(overshoot, 20) * 0.18
            let revealOpacity = clamped > 0 ? 1.0 : 0.0
            let chevronX = min(width - 34, 18 + clamped + overshoot * 0.18)

            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.17))

                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(0.36), lineWidth: 1)

                Path { path in
                    let y = height / 2
                    path.move(to: CGPoint(x: 14, y: y))
                    path.addLine(to: CGPoint(x: width - 14, y: y))
                }
                .stroke(
                    Color.white.opacity(0.42),
                    style: StrokeStyle(lineWidth: 1, dash: [4, 4], dashPhase: -clamped * 1.1)
                )

                Text(progress > completionThreshold ? "Release to rip" : "Pull and tear to complete")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.94))
                    .frame(maxWidth: .infinity)

                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.95), tint.opacity(0.76)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: revealWidth)
                    .opacity(revealOpacity)
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.white.opacity(0.28), lineWidth: 1)
                            .frame(width: revealWidth)
                            .opacity(revealOpacity)
                    )
                    .overlay(alignment: .trailing) {
                        VStack(spacing: 3) {
                            ForEach(0..<11, id: \.self) { index in
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(Color.white.opacity(0.42))
                                    .frame(width: CGFloat(2 + (index % 3)), height: 1)
                                    .offset(x: (index.isMultiple(of: 2) ? 1 : -1) * max(0, 1.8 - progress * 1.8))
                            }
                        }
                        .padding(.trailing, 2)
                        .opacity(min(1, progress * 1.8))
                    }

                HStack(spacing: 6) {
                    Image(systemName: "ticket.fill")
                    Text("TORN")
                }
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(Color.white)
                .padding(.leading, 14)
                .opacity(max(0, progress * 1.5 - 0.2))

                HStack(spacing: 2) {
                    Image(systemName: "chevron.right")
                    Image(systemName: "chevron.right")
                }
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(Color.white.opacity(0.85))
                .offset(x: chevronX, y: 0)
                .opacity(1.0 - Double(progress) * 0.85)
                .scaleEffect(1 + progress * 0.09)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 3)
                    .onChanged { value in
                        guard !isCompleting else { return }
                        isDragging = true
                        let translation = max(value.translation.width, 0)
                        if !didTriggerStartFeedback && translation > 2 {
                            didTriggerStartFeedback = true
                            performDragStartFeedback()
                        }
                        let mapped = mappedDragDistance(translation, maxTravel: maxTravel)
                        let roughened = applyStickSlip(to: mapped, maxTravel: maxTravel)
                        dragX = roughened
                        applyDragFeedback(clamped: min(roughened, maxTravel), maxTravel: maxTravel)
                    }
                    .onEnded { _ in
                        guard !isCompleting else { return }
                        isDragging = false
                        didTriggerStartFeedback = false

                        if progress > completionThreshold {
                            isCompleting = true
                            performTearFeedback()

                            withAnimation(.interpolatingSpring(stiffness: 520, damping: 26)) {
                                dragX = maxTravel + 16
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                                withAnimation(.easeOut(duration: 0.06)) {
                                    dragX = maxTravel
                                }
                            }

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                                onComplete()
                                resetInteractionState()
                            }
                        } else {
                            performCancelFeedback()
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.62, blendDuration: 0.05)) {
                                dragX = 0
                            }
                            resetFeedbackState()
                        }
                    }
            )
        }
        .frame(height: 76)
    }

    private func mappedDragDistance(_ translation: CGFloat, maxTravel: CGFloat) -> CGFloat {
        guard maxTravel > 0 else { return 0 }

        let capped = min(translation, maxTravel)
        let progress = capped / maxTravel
        let easedProgress = CGFloat(pow(Double(progress), 1.10))
        let eased = easedProgress * maxTravel
        let overshoot = max(0, translation - maxTravel)

        return eased + overshoot * 0.12
    }

    private func applyStickSlip(to value: CGFloat, maxTravel: CGFloat) -> CGFloat {
        guard maxTravel > 0 else { return value }

        let progress = min(1, value / maxTravel)
        guard progress > 0.12 else { return value }

        let resistance = abs(sin(value * 0.36)) * (0.8 + progress * 2.2)
        return max(0, value - resistance)
    }

    private func applyDragFeedback(clamped: CGFloat, maxTravel: CGFloat) {
        guard maxTravel > 0 else { return }

        let progress = clamped / maxTravel
        let step = min(feedbackSteps, Int(progress * CGFloat(feedbackSteps)))

        if step > lastFeedbackStep {
            let intensity = 0.35 + (CGFloat(step) / CGFloat(feedbackSteps)) * 0.55
            impact(.rigid, intensity: intensity)
            lastFeedbackStep = step
        } else if step < lastFeedbackStep {
            lastFeedbackStep = step
        }

        if progress >= completionThreshold && !thresholdArmed {
            thresholdArmed = true
            impact(.heavy, intensity: 1.0)
        } else if progress < completionThreshold && thresholdArmed {
            thresholdArmed = false
            impact(.rigid, intensity: 0.7)
        }
    }

    private func resetFeedbackState() {
        lastFeedbackStep = 0
        thresholdArmed = false
    }

    private func resetInteractionState() {
        dragX = 0
        isCompleting = false
        isDragging = false
        didTriggerStartFeedback = false
        resetFeedbackState()
    }

    private func performDragStartFeedback() {
        impact(.heavy, intensity: 1.0)
    }

    private func performTearFeedback() {
        impact(.heavy, intensity: 1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
            impact(.rigid, intensity: 0.95)
        }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    private func performCancelFeedback() {
        impact(.rigid, intensity: 0.65)
    }

    private func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle, intensity: CGFloat) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred(intensity: min(max(intensity, 0.1), 1.0))
    }
}

#Preview {
    SingleCardTodoView()
        .modelContainer(for: TodoItem.self, inMemory: true)
}
