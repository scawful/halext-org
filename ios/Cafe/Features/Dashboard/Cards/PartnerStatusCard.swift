//
//  PartnerStatusCard.swift
//  Cafe
//
//  Dashboard widget showing partner (Chris) status and quick actions
//

import SwiftUI

struct PartnerStatusCard: View {
    @State private var chrisPresence: PartnerPresence?
    @State private var isLoading = false
    @State private var preferredContactUsername: String = "magicalgirl"
    @State private var showingMessage = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.pink, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Chris")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    if let presence = chrisPresence {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(presence.isOnline ? Color.green : Color.gray)
                                .frame(width: 8, height: 8)
                            
                            Text(presence.isOnline ? "Online" : "Offline")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("Loading...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button {
                    showingMessage = true
                } label: {
                    Image(systemName: "message.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
            
            // Status message
            if let presence = chrisPresence, let activity = presence.currentActivity {
                HStack {
                    Image(systemName: "ellipsis.bubble")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(activity)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                )
            }
            
            // Quick actions
            HStack(spacing: 12) {
                Button {
                    showingMessage = true
                } label: {
                    HStack {
                        Image(systemName: "message.fill")
                        Text("Message")
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue)
                    )
                    .foregroundColor(.white)
                }
                
                NavigationLink {
                    SharedCalendarView()
                } label: {
                    HStack {
                        Image(systemName: "calendar")
                        Text("Calendar")
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.pink.opacity(0.2))
                    )
                    .foregroundColor(.pink)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.pink.opacity(0.1),
                            Color.purple.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [.pink.opacity(0.3), .purple.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .task {
            await loadPresence()
        }
        .sheet(isPresented: $showingMessage) {
            // Navigate to messages with Chris
        }
    }
    
    private func loadPresence() async {
        isLoading = true
        do {
            let presence = try await APIClient.shared.getPartnerPresence(username: preferredContactUsername)
            await MainActor.run {
                chrisPresence = presence
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

#Preview {
    PartnerStatusCard()
        .padding()
}

