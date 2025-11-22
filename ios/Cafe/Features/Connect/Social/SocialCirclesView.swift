//
//  SocialCirclesView.swift
//  Cafe
//
//  Shows backend-powered social circles
//

import SwiftUI

struct SocialCirclesView: View {
    @Environment(ThemeManager.self) var themeManager
    @State private var circles: [BackendSocialCircle] = []
    @State private var pulses: [BackendSocialPulse] = []
    @State private var selectedCircle: BackendSocialCircle?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var inviteCode: String = ""
    @State private var pulseMessage: String = "Sending cozy encouragement"
    @State private var pressedCircleId: Int?
    @State private var isSendButtonPressed = false
    @State private var isJoinButtonPressed = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(themeManager.errorColor.opacity(0.1))
                        .foregroundColor(themeManager.errorColor)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                circlesStrip
                if let selectedCircle {
                    circleDetail(for: selectedCircle)
                } else {
                    Text("Create or join a circle to see updates")
                        .font(.subheadline)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            .padding()
        }
        .background(themeManager.backgroundColor.ignoresSafeArea())
        .navigationTitle("Social Circles")
        .task {
            await refreshCircles()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Halext Social")
                .font(.title2.bold())
                .foregroundColor(themeManager.textColor)
            Text("Keep circles updated without leaving the app. Perfect for group chats, crews, or fan clubs.")
                .font(.callout)
                .foregroundColor(themeManager.secondaryTextColor)
        }
    }

    private var circlesStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(circles) { circle in
                    CircleCardView(
                        circle: circle,
                        isSelected: selectedCircle?.id == circle.id,
                        isPressed: pressedCircleId == circle.id,
                        themeManager: themeManager
                    )
                    .scaleEffect(pressedCircleId == circle.id ? 0.95 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.7), value: pressedCircleId)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                if pressedCircleId != circle.id {
                                    pressedCircleId = circle.id
                                }
                            }
                            .onEnded { _ in
                                pressedCircleId = nil
                            }
                    )
                    .onTapGesture {
                        HapticManager.selection()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedCircle = circle
                        }
                        _Concurrency.Task {
                            await loadPulses(for: circle)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Circle Card Subview

    private struct CircleCardView: View {
        let circle: BackendSocialCircle
        let isSelected: Bool
        let isPressed: Bool
        let themeManager: ThemeManager

        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                Text(circle.emoji ?? "✨")
                    .font(.largeTitle)
                Text(circle.name)
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                Text("\(circle.memberCount) members")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
                Text(circle.inviteCode)
                    .font(.caption2.monospaced())
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Capsule())
                    .foregroundColor(themeManager.textColor)
            }
            .padding()
            .frame(width: 180, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: circle.themeColor ?? "#A855F7").opacity(isPressed ? 0.35 : 0.2))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? themeManager.accentColor : .clear, lineWidth: 2)
            )
            .animation(.easeInOut(duration: 0.15), value: isPressed)
        }
    }

    private func circleDetail(for circle: BackendSocialCircle) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(circle.description ?? "No description yet")
                .foregroundColor(themeManager.secondaryTextColor)

            VStack(alignment: .leading, spacing: 12) {
                Text("Pulses")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                ForEach(pulses) { pulse in
                    HStack(alignment: .top, spacing: 12) {
                        Text(pulse.mood ?? "✨")
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(pulse.message)
                                .font(.body)
                                .foregroundColor(themeManager.textColor)
                            Text("\(pulse.authorName ?? "Friend") • \(pulse.createdAt.formatted(date: .omitted, time: .shortened))")
                                .font(.caption)
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                    }
                    .padding(12)
                    .background(themeManager.secondaryBackgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                if pulses.isEmpty {
                    Text("No pulses yet — send the first one!")
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Share a pulse")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                TextField("Message", text: $pulseMessage)
                    .textFieldStyle(.roundedBorder)
                Button(action: {
                    HapticManager.success()
                    _Concurrency.Task { await sharePulse() }
                }) {
                    Label("Send sparkle", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(pulseMessage.isEmpty ? Color.gray.opacity(0.3) : themeManager.accentColor)
                        )
                        .foregroundColor(.white)
                        .scaleEffect(isSendButtonPressed ? 0.97 : 1.0)
                        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isSendButtonPressed)
                }
                .buttonStyle(.plain)
                .disabled(pulseMessage.isEmpty)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in isSendButtonPressed = true }
                        .onEnded { _ in isSendButtonPressed = false }
                )
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text("Join via invite")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                TextField("ABCD12", text: $inviteCode)
                    .textFieldStyle(.roundedBorder)
                    .textCase(.uppercase)
                Button(action: {
                    HapticManager.selection()
                    _Concurrency.Task { await joinCircle() }
                }) {
                    Text("Join circle")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(inviteCode.isEmpty ? Color.gray.opacity(0.3) : themeManager.accentColor.opacity(0.2))
                        )
                        .foregroundColor(inviteCode.isEmpty ? .gray : themeManager.accentColor)
                        .scaleEffect(isJoinButtonPressed ? 0.97 : 1.0)
                        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isJoinButtonPressed)
                }
                .buttonStyle(.plain)
                .disabled(inviteCode.isEmpty)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in isJoinButtonPressed = true }
                        .onEnded { _ in isJoinButtonPressed = false }
                )
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 28).fill(themeManager.cardBackgroundColor))
    }

    private func refreshCircles() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await APIClient.shared.getBackendCircles()
            await MainActor.run {
                circles = result
                selectedCircle = result.first
                errorMessage = nil // Clear any previous errors
            }
            if let first = result.first {
                await loadPulses(for: first)
            } else {
                await MainActor.run { pulses = [] }
            }
        } catch {
            // Silently handle errors - social circles are optional
            print("⚠️ Failed to load social circles: \(error.localizedDescription)")
            await MainActor.run {
                errorMessage = nil // Don't show error to user
                circles = [] // Ensure empty state
                pulses = []
            }
        }
    }

    private func loadPulses(for circle: BackendSocialCircle) async {
        do {
            let response = try await APIClient.shared.getBackendPulses(circleId: circle.id)
            await MainActor.run { pulses = response }
        } catch {
            // Silently handle errors - pulses are optional
            print("⚠️ Failed to load pulses: \(error.localizedDescription)")
            await MainActor.run { pulses = [] }
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
