//
//  SleepModeView.swift
//  LockIn
//
//  Created by leon on 2026/2/10.
//

import SwiftUI
import SwiftData
import UserNotifications

struct SleepModeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @StateObject private var audioPlayer: SleepAudioPlayer
    @State private var journalText = ""
    @State private var showManageTodosSheet = false
    @State private var showAlarmEditor = false
    @AppStorage("sleepAlarmHour") private var alarmHour = 7
    @AppStorage("sleepAlarmMinute") private var alarmMinute = 0

    @Query private var journals: [SleepJournal]
    private let todayStart: Date
    private let alarmNotificationID = "sleep-mode-alarm"

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

            Section("Alarm") {
                Button {
                    showAlarmEditor = true
                } label: {
                    HStack {
                        Text("Alarm")
                        Spacer()
                        Text(formattedAlarmTime)
                            .foregroundStyle(.secondary)
                    }
                }
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
            scheduleAlarmNotification(hour: alarmHour, minute: alarmMinute)
        }
        .onDisappear {
            saveJournal()
            audioPlayer.stop()
        }
        .sheet(isPresented: $showManageTodosSheet) {
            ManageTodosSheet()
        }
        .sheet(isPresented: $showAlarmEditor) {
            AlarmEditView(
                initialHour: alarmHour,
                initialMinute: alarmMinute
            ) { hour, minute in
                alarmHour = hour
                alarmMinute = minute
                scheduleAlarmNotification(hour: hour, minute: minute)
            }
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

    private var formattedAlarmTime: String {
        let calendar = Calendar.current
        let base = Date()
        guard let date = calendar.date(
            bySettingHour: alarmHour,
            minute: alarmMinute,
            second: 0,
            of: base
        ) else {
            return "7:00 AM"
        }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func scheduleAlarmNotification(hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [alarmNotificationID])

        let calendar = Calendar.current
        let now = Date()
        guard let todayTime = calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: now
        ) else {
            return
        }

        let fireDate: Date
        if todayTime > now {
            fireDate = todayTime
        } else {
            fireDate = calendar.date(byAdding: .day, value: 1, to: todayTime) ?? todayTime
        }

        let fireComponents = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: fireDate
        )

        let content = UNMutableNotificationContent()
        content.title = "LockIn Alarm"
        content.body = "Wake flow is ready."
        content.sound = .default
        content.userInfo = ["route": "wakeflow"]

        let trigger = UNCalendarNotificationTrigger(dateMatching: fireComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: alarmNotificationID,
            content: content,
            trigger: trigger
        )
        center.add(request) { _ in
            // Best effort scheduling.
        }
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

private struct AlarmEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTime: Date
    private let onSave: (Int, Int) -> Void

    init(initialHour: Int, initialMinute: Int, onSave: @escaping (Int, Int) -> Void) {
        let calendar = Calendar.current
        let base = Date()
        let date = calendar.date(
            bySettingHour: initialHour,
            minute: initialMinute,
            second: 0,
            of: base
        ) ?? base
        _selectedTime = State(initialValue: date)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "Alarm Time",
                    selection: $selectedTime,
                    displayedComponents: [.hourAndMinute]
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
                Spacer()
            }
            .navigationTitle("Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        let components = Calendar.current.dateComponents([.hour, .minute], from: selectedTime)
                        let hour = components.hour ?? 7
                        let minute = components.minute ?? 0
                        onSave(hour, minute)
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                    }
                }
            }
        }
    }
}
