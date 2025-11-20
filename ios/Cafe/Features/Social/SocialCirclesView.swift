//
//  SocialCirclesView.swift
//  Cafe
//
//  Shows backend-powered social circles
//

import SwiftUI

struct SocialCirclesView: View {
    @State private var circles: [BackendSocialCircle] = []
    @State private var pulses: [BackendSocialPulse] = []
    @State private var selectedCircle: BackendSocialCircle?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var inviteCode: String = ""
    @State private var pulseMessage: String = "Sending cozy encouragement"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                circlesStrip
                if let selectedCircle {
                    circleDetail(for: selectedCircle)
                } else {
                    Text("Create or join a circle to see updates")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Social Circles")
        .task {
            await refreshCircles()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Halext Social")
                .font(.title2.bold())
            Text("Keep circles updated without leaving the app. Perfect for group chats, crews, or fan clubs.")
                .font(.callout)
                .foregroundColor(.secondary)
        }
    }

    private var circlesStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(circles) { circle in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(circle.emoji ?? "✨")
                            .font(.largeTitle)
                        Text(circle.name)
                            .font(.headline)
                        Text("\(circle.memberCount) members")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(circle.inviteCode)
                            .font(.caption2.monospaced())
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Capsule())
                    }
                    .padding()
                    .frame(width: 180, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(hex: circle.themeColor ?? "#A855F7").opacity(0.16))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(selectedCircle?.id == circle.id ? Color.accentColor : .clear, lineWidth: 2)
                    )
                    .onTapGesture {
                        _Concurrency.Task {
                            selectedCircle = circle
                            await loadPulses(for: circle)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func circleDetail(for circle: BackendSocialCircle) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(circle.description ?? "No description yet")
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                Text("Pulses")
                    .font(.headline)
                ForEach(pulses) { pulse in
                    HStack(alignment: .top, spacing: 12) {
                        Text(pulse.mood ?? "✨")
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(pulse.message)
                                .font(.body)
                            Text("\(pulse.authorName ?? "Friend") • \(pulse.createdAt.formatted(date: .omitted, time: .shortened))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                if pulses.isEmpty {
                    Text("No pulses yet — send the first one!")
                        .foregroundColor(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Share a pulse")
                    .font(.headline)
                TextField("Message", text: $pulseMessage)
                    .textFieldStyle(.roundedBorder)
                Button(action: {
                    _Concurrency.Task { await sharePulse() }
                }) {
                    Label("Send sparkle", systemImage: "sparkles")
                }
                .buttonStyle(.borderedProminent)
                .disabled(pulseMessage.isEmpty)
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text("Join via invite")
                    .font(.headline)
                TextField("ABCD12", text: $inviteCode)
                    .textFieldStyle(.roundedBorder)
                    .textCase(.uppercase)
                Button("Join circle") {
                    _Concurrency.Task { await joinCircle() }
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 28).fill(Color(.systemBackground)))
    }

    private func refreshCircles() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await APIClient.shared.getBackendCircles()
            await MainActor.run {
                circles = result
                selectedCircle = result.first
            }
            if let first = result.first {
                await loadPulses(for: first)
            } else {
                await MainActor.run { pulses = [] }
            }
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
        }
    }

    private func loadPulses(for circle: BackendSocialCircle) async {
        do {
            let response = try await APIClient.shared.getBackendPulses(circleId: circle.id)
            await MainActor.run { pulses = response }
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
        }
    }

    private func joinCircle() async {
        guard !inviteCode.isEmpty else { return }
        do {
            _ = try await APIClient.shared.joinBackendCircle(inviteCode: inviteCode)
            inviteCode = ""
            await refreshCircles()
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
        }
    }

    private func sharePulse() async {
        guard let circle = selectedCircle else { return }
        do {
            let payload = BackendSocialPulseCreate(message: pulseMessage, mood: "sparkles")
            _ = try await APIClient.shared.shareBackendPulse(circleId: circle.id, payload: payload)
            pulseMessage = "Dropping wholesome vibes"
            await loadPulses(for: circle)
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
        }
    }
}
