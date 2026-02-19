//
//  SleepModeView.swift
//  LockIn
//
//  Created by leon on 2026/2/10.
//

import SwiftUI
import SwiftData

struct SleepModeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @StateObject private var audioPlayer: SleepAudioPlayer
    @State private var journalText = ""
    @State private var showManageTodosSheet = false

    @Query private var journals: [SleepJournal]
    private let todayStart: Date

    init() {
        let start = Calendar.current.startOfDay(for: Date())
        todayStart = start
        _journals = Query(filter: #Predicate<SleepJournal> { $0.date == start })
        _audioPlayer = StateObject(wrappedValue: SleepAudioPlayer())
    }

    var body: some View {
        List {
            Section("Music") {
                HStack {
                    Button("Play") {
                        audioPlayer.play()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Pause") {
                        audioPlayer.pause()
                    }
                    .buttonStyle(.bordered)
                }
            }

            Section("Sleep Journal") {
                TextEditor(text: $journalText)
                    .frame(minHeight: 160)
            }

            Section("Manage Todos") {
                Button("Manage Todos") {
                    showManageTodosSheet = true
                }
            }
        }
        .navigationTitle("Sleep Mode")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    finishSleepMode()
                }
            }
        }
        .onAppear {
            journalText = journals.first?.content ?? ""
        }
        .onDisappear {
            saveJournal()
            audioPlayer.stop()
        }
        .sheet(isPresented: $showManageTodosSheet) {
            ManageTodosSheet()
        }
    }

    private func finishSleepMode() {
        audioPlayer.stop()
        saveJournal()
        dismiss()
    }

    private func saveJournal() {
        let content = journalText.trimmingCharacters(in: .whitespacesAndNewlines)
        if let existing = journals.first {
            existing.content = content
        } else {
            let entry = SleepJournal(date: todayStart, content: content)
            modelContext.insert(entry)
        }
        try? modelContext.save()
    }
}

private struct ManageTodosSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var commitToken = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Done") {
                    commitToken += 1
                    dismiss()
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            TodoOverviewView(showsNavigationActions: false, commitToken: $commitToken)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
