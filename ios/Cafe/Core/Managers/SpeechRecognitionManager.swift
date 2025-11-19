//
//  SpeechRecognitionManager.swift
//  Cafe
//
//  Speech recognition for voice input
//

import SwiftUI
import Foundation
import Speech
import AVFoundation

@MainActor
@Observable
class SpeechRecognitionManager: NSObject {
    static let shared = SpeechRecognitionManager()

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    var isAuthorized = false
    var isRecording = false
    var transcribedText = ""
    var errorMessage: String?

    private override init() {
        super.init()
        checkAuthorization()
    }

    // MARK: - Authorization

    func checkAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            _Concurrency.Task { @MainActor in
                self?.isAuthorized = status == .authorized
            }
        }
    }

    func requestAuthorization() async -> Bool {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    // MARK: - Recording

    func startRecording() throws {
        // Cancel any existing task
        recognitionTask?.cancel()
        recognitionTask = nil

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let recognitionRequest = recognitionRequest else {
            throw SpeechError.recognitionRequestFailed
        }

        recognitionRequest.shouldReportPartialResults = true

        // Get input node
        let inputNode = audioEngine.inputNode

        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            _Concurrency.Task { @MainActor in
                var isFinal = false

                if let result = result {
                    self?.transcribedText = result.bestTranscription.formattedString
                    isFinal = result.isFinal
                }

                if error != nil || isFinal {
                    self?.audioEngine.stop()
                    inputNode.removeTap(onBus: 0)

                    self?.recognitionRequest = nil
                    self?.recognitionTask = nil

                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                    }
                }
            }
        }

        // Configure microphone input
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }

        // Start audio engine
        audioEngine.prepare()
        try audioEngine.start()

        isRecording = true
        transcribedText = ""
        errorMessage = nil
    }

    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        isRecording = false
    }

    // MARK: - Audio File Transcription

    func transcribeAudioFile(url: URL) async throws -> String {
        let recognizer = SFSpeechRecognizer()
        let request = SFSpeechURLRecognitionRequest(url: url)

        return try await withCheckedThrowingContinuation { continuation in
            recognizer?.recognitionTask(with: request) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                if let result = result, result.isFinal {
                    continuation.resume(returning: result.bestTranscription.formattedString)
                }
            }
        }
    }
}

// MARK: - Speech Errors

enum SpeechError: LocalizedError {
    case recognitionRequestFailed
    case notAuthorized
    case audioEngineFailed

    var errorDescription: String? {
        switch self {
        case .recognitionRequestFailed:
            return "Failed to create speech recognition request"
        case .notAuthorized:
            return "Speech recognition not authorized. Please enable in Settings."
        case .audioEngineFailed:
            return "Audio engine failed to start"
        }
    }
}

// MARK: - Voice Input Button

struct VoiceInputButton: View {
    @State private var speechManager = SpeechRecognitionManager.shared
    @Binding var text: String
    @State private var showingError = false

    var body: some View {
        Button(action: toggleRecording) {
            Image(systemName: speechManager.isRecording ? "mic.fill" : "mic")
                .font(.title2)
                .foregroundColor(speechManager.isRecording ? .red : .blue)
                .symbolEffect(.pulse, isActive: speechManager.isRecording)
        }
        .disabled(!speechManager.isAuthorized)
        .alert("Speech Recognition Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(speechManager.errorMessage ?? "Unknown error occurred")
        }
        .onChange(of: speechManager.transcribedText) { _, newValue in
            if !newValue.isEmpty {
                text = newValue
            }
        }
        .onChange(of: speechManager.errorMessage) { _, newValue in
            showingError = newValue != nil
        }
    }

    private func toggleRecording() {
        if speechManager.isRecording {
            speechManager.stopRecording()
        } else {
            do {
                try speechManager.startRecording()
            } catch {
                speechManager.errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Voice Input View

struct VoiceInputView: View {
    @State private var speechManager = SpeechRecognitionManager.shared
    @Binding var isPresented: Bool
    let onComplete: (String) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()

                // Microphone visualization
                ZStack {
                    Circle()
                        .fill(speechManager.isRecording ? Color.red.opacity(0.2) : Color.blue.opacity(0.2))
                        .frame(width: 200, height: 200)
                        .scaleEffect(speechManager.isRecording ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: speechManager.isRecording)

                    Image(systemName: "mic.fill")
                        .font(.system(size: 80))
                        .foregroundColor(speechManager.isRecording ? .red : .blue)
                }

                // Status text
                Text(speechManager.isRecording ? "Listening..." : "Tap to speak")
                    .font(.title2)
                    .fontWeight(.semibold)

                // Transcribed text
                ScrollView {
                    Text(speechManager.transcribedText.isEmpty ? "Your text will appear here" : speechManager.transcribedText)
                        .font(.body)
                        .foregroundColor(speechManager.transcribedText.isEmpty ? .secondary : .primary)
                        .padding()
                }
                .frame(maxHeight: 200)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)

                Spacer()

                // Control buttons
                HStack(spacing: 40) {
                    Button(action: toggleRecording) {
                        VStack {
                            Image(systemName: speechManager.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(speechManager.isRecording ? .red : .blue)

                            Text(speechManager.isRecording ? "Stop" : "Start")
                                .font(.caption)
                        }
                    }

                    if !speechManager.transcribedText.isEmpty {
                        Button(action: complete) {
                            VStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.green)

                                Text("Done")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .padding(.bottom, 40)
            }
            .navigationTitle("Voice Input")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if speechManager.isRecording {
                            speechManager.stopRecording()
                        }
                        isPresented = false
                    }
                }
            }
        }
    }

    private func toggleRecording() {
        if speechManager.isRecording {
            speechManager.stopRecording()
        } else {
            do {
                try speechManager.startRecording()
            } catch {
                speechManager.errorMessage = error.localizedDescription
            }
        }
    }

    private func complete() {
        if speechManager.isRecording {
            speechManager.stopRecording()
        }
        onComplete(speechManager.transcribedText)
        isPresented = false
    }
}
