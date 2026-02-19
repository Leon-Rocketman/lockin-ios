import SwiftUI

struct SpeechDebugView: View {
    @EnvironmentObject var speech: SystemSpeechService
    @EnvironmentObject var speechPrefs: SpeechPreferences

    @State private var voicesDump: String = ""
    @State private var testText: String = "里昂，早上好。今天是2月19号，晴天。你今天要做两件事：学习 Agentic Coding，完成 Codex Hackathon。"

    var body: some View {
        Form {
            Section("Voice") {
                TextField("Preferred Voice Identifier (optional)", text: Binding(
                    get: { speechPrefs.preferredVoiceIdentifier ?? "" },
                    set: { speechPrefs.preferredVoiceIdentifier = $0.isEmpty ? nil : $0 }
                ))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

                Button("Dump zh-CN Voices to Console & Screen") {
                    let dump = SpeechVoiceSelector.dumpChineseVoices()
                    voicesDump = dump
                    print(dump)
                }

                if !voicesDump.isEmpty {
                    ScrollView {
                        Text(voicesDump).font(.footnote).textSelection(.enabled)
                    }
                    .frame(minHeight: 160)
                }
            }

            Section("Tuning") {
                HStack {
                    Text("Rate")
                    Slider(value: Binding(get: { Double(speechPrefs.rate) }, set: { speechPrefs.rate = Float($0) }), in: 0.40...0.55)
                    Text(String(format: "%.2f", speechPrefs.rate)).monospacedDigit()
                }
                HStack {
                    Text("Pitch")
                    Slider(value: Binding(get: { Double(speechPrefs.pitch) }, set: { speechPrefs.pitch = Float($0) }), in: 0.85...1.15)
                    Text(String(format: "%.2f", speechPrefs.pitch)).monospacedDigit()
                }
                HStack {
                    Text("Volume")
                    Slider(value: Binding(get: { Double(speechPrefs.volume) }, set: { speechPrefs.volume = Float($0) }), in: 0.60...1.00)
                    Text(String(format: "%.2f", speechPrefs.volume)).monospacedDigit()
                }
            }

            Section("Test") {
                TextField("Test Text", text: $testText, axis: .vertical)
                    .lineLimit(3...8)

                Button("Speak Test") {
                    speech.speak(testText)
                }
            }
        }
        .navigationTitle("Speech Debug")
    }
}
