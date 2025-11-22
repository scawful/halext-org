//
//  SharedCalendarView.swift
//  Cafe
//
//  View for shared calendar events with Chris
//

import SwiftUI

struct SharedCalendarView: View {
    @State private var viewModel = CalendarViewModel()
    @State private var selectedDate = Date()
    @State private var preferredContactUsername: String = "magicalgirl"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "person.2.fill")
                                .font(.title2)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.pink, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text("Shared with \(preferredContactUsername.capitalized)")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Text("Events you're sharing together")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top)

                    // Calendar month view
                    MonthCalendarView(
                        selectedDate: $selectedDate,
                        datesWithEvents: viewModel.datesWithEvents(in: selectedDate)
                    )
                    .padding(.horizontal)

                    Divider()

                    // Shared events for selected date
                    if !viewModel.sharedEvents(for: selectedDate).isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Shared Events on \(selectedDate.formatted(.dateTime.month().day()))")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(viewModel.sharedEvents(for: selectedDate)) { event in
                                SharedEventRow(event: event)
                                    .padding(.horizontal)
                            }
                        }
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                            
                            Text("No shared events on this date")
                                .font(.headline)
                            
                            Text("Create an event and share it with \(preferredContactUsername.capitalized)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    }

                    // Upcoming shared events
                    if !viewModel.sharedEvents.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Upcoming Shared Events")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(Array(viewModel.sharedEvents.prefix(5))) { event in
                                SharedEventRow(event: event)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Shared Calendar")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        // Navigate to create event with sharing enabled
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .task {
                await viewModel.loadEvents()
            }
            .refreshable {
                await viewModel.loadEvents()
            }
        }
    }
}

// MARK: - Shared Event Row

struct SharedEventRow: View {
    let event: Event
    
    var body: some View {
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
            .padding(.vertical, 8)
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
                HStack {
                    Text(event.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    // Shared indicator
                    Image(systemName: "person.2.fill")
                        .font(.caption2)
                        .foregroundColor(.pink)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(event.startTime, style: .time)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                
                if let location = event.location {
                    HStack(spacing: 4) {
                        Image(systemName: "location")
                            .font(.caption2)
                        Text(location)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
    }
}

#Preview {
    SharedCalendarView()
}

