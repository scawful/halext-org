//
//  UpcomingTogetherCard.swift
//  Cafe
//
//  Dashboard widget showing upcoming shared events with Chris
//

import SwiftUI

struct UpcomingTogetherCard: View {
    @State private var sharedEvents: [Event] = []
    @State private var isLoading = false
    @State private var preferredContactUsername: String = "magicalgirl"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.pink, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("Upcoming Together")
                    .font(.headline)
                
                Spacer()
                
                if !sharedEvents.isEmpty {
                    Text("\(sharedEvents.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.pink.opacity(0.2))
                        )
                }
            }
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if sharedEvents.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("No shared events")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Create an event and share it")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(sharedEvents.prefix(3)) { event in
                        HStack(spacing: 12) {
                            // Date badge
                            VStack(spacing: 2) {
                                Text(event.startTime, format: .dateTime.month(.abbreviated))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(event.startTime, format: .dateTime.day())
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                            .frame(width: 50)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: [.pink.opacity(0.2), .purple.opacity(0.2)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "clock")
                                        .font(.caption2)
                                    Text(event.startTime, style: .time)
                                        .font(.caption)
                                }
                                .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "person.2.fill")
                                .font(.caption2)
                                .foregroundColor(.pink)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                if sharedEvents.count > 3 {
                    NavigationLink {
                        SharedCalendarView()
                    } label: {
                        Text("View All (\(sharedEvents.count))")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ThemeManager.shared.cardBackgroundColor)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        )
        .task {
            await loadSharedEvents()
        }
    }
    
    private func loadSharedEvents() async {
        isLoading = true
        do {
            let events = try await APIClient.shared.getSharedEvents()
            await MainActor.run {
                sharedEvents = Array(events.prefix(5))
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
    UpcomingTogetherCard()
        .padding()
}

