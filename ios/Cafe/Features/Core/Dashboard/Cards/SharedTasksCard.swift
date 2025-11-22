//
//  SharedTasksCard.swift
//  Cafe
//
//  Dashboard widget showing shared tasks with Chris
//

import SwiftUI

struct SharedTasksCard: View {
    @State private var sharedTasks: [Task] = []
    @State private var isLoading = false
    @State private var preferredContactUsername: String = "magicalgirl"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.pink, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("Shared Tasks")
                    .font(.headline)
                
                Spacer()
                
                if !sharedTasks.isEmpty {
                    Text("\(sharedTasks.count)")
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
            } else if sharedTasks.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checklist")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("No shared tasks yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(sharedTasks.prefix(3)) { task in
                        HStack {
                            Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(task.completed ? .green : .secondary)
                            
                            Text(task.title)
                                .font(.subheadline)
                                .strikethrough(task.completed)
                                .foregroundColor(task.completed ? .secondary : .primary)
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                if sharedTasks.count > 3 {
                    NavigationLink {
                        // Navigate to shared tasks view
                        Text("All Shared Tasks")
                    } label: {
                        Text("View All (\(sharedTasks.count))")
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
            await loadSharedTasks()
        }
    }
    
    private func loadSharedTasks() async {
        isLoading = true
        // For now, we'll filter tasks that might be shared
        // This will be replaced with actual shared tasks API
        do {
            let allTasks = try await APIClient.shared.getTasks()
            // Filter tasks that have labels or descriptions indicating sharing
            // This is a placeholder until we have proper shared tasks API
            await MainActor.run {
                sharedTasks = Array(allTasks.filter { task in
                    task.labels.contains(where: { $0.name.lowercased().contains("shared") || $0.name.lowercased().contains(preferredContactUsername.lowercased()) })
                }.prefix(5))
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
    SharedTasksCard()
        .padding()
}

