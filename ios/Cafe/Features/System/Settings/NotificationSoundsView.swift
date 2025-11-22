//
//  NotificationSoundsView.swift
//  Cafe
//
//  Notification sound preferences
//

import SwiftUI
import AVFoundation

struct NotificationSoundsView: View {
    @AppStorage("notification_sound") private var notificationSound = "default"
    @AppStorage("notification_vibrate") private var vibrate = true

    private let sounds = [
        ("default", "Default"),
        ("chime", "Chime"),
        ("ding", "Ding"),
        ("bell", "Bell"),
        ("ping", "Ping"),
        ("none", "None")
    ]

    var body: some View {
        List {
            Section {
                Toggle("Vibrate", isOn: $vibrate)
            } header: {
                Text("Haptics")
            }

            Section {
                ForEach(sounds, id: \.0) { sound in
                    Button(action: {
                        notificationSound = sound.0
                        playSound(sound.0)
                    }) {
                        HStack {
                            Text(sound.1)
                                .foregroundColor(.primary)

                            Spacer()

                            if notificationSound == sound.0 {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }

                            Button(action: { playSound(sound.0) }) {
                                Image(systemName: "speaker.wave.2.fill")
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Notification Sound")
            } footer: {
                Text("Tap the speaker icon to preview sounds")
            }
        }
        .navigationTitle("Sounds")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func playSound(_ soundName: String) {
        guard soundName != "none" else { return }

        // Play system sound
        AudioServicesPlaySystemSound(1007) // Default system sound
    }
}

#Preview {
    NavigationStack {
        NotificationSoundsView()
    }
}
