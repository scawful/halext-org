//
//  MoreView.swift
//  Cafe
//
//  Grid view of all app features
//

import SwiftUI

struct MoreView: View {
    @Environment(ThemeManager.self) var themeManager

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(FeatureCard.allFeatures) { feature in
                        FeatureCardView(feature: feature)
                    }
                }
                .padding()
            }
            .navigationTitle("More")
            .background(themeManager.backgroundColor.ignoresSafeArea())
        }
    }
}

// MARK: - Feature Card Model

struct FeatureCard: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let destination: FeatureDestination

    static let allFeatures: [FeatureCard] = [
        FeatureCard(title: "Templates", icon: "doc.text", color: .purple, destination: .templates),
        FeatureCard(title: "Smart Lists", icon: "list.bullet.rectangle", color: .orange, destination: .smartLists),
        FeatureCard(title: "Pages", icon: "doc.richtext", color: .blue, destination: .pages),
        FeatureCard(title: "Messages", icon: "message", color: .green, destination: .messages),
        FeatureCard(title: "Finance", icon: "dollarsign.circle", color: .teal, destination: .finance),
        FeatureCard(title: "Calendar", icon: "calendar", color: .red, destination: .calendar),
        FeatureCard(title: "AI Chat", icon: "sparkles", color: .pink, destination: .chat),
        FeatureCard(title: "Settings", icon: "gearshape", color: .gray, destination: .settings)
    ]
}

enum FeatureDestination {
    case templates
    case smartLists
    case pages
    case messages
    case finance
    case calendar
    case chat
    case settings
}

// MARK: - Feature Card View

struct FeatureCardView: View {
    let feature: FeatureCard
    @Environment(ThemeManager.self) var themeManager

    var body: some View {
        NavigationLink(value: feature.destination) {
            VStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(feature.color.opacity(0.15))
                        .frame(width: 60, height: 60)

                    Image(systemName: feature.icon)
                        .font(.system(size: 28))
                        .foregroundColor(feature.color)
                }

                // Title
                Text(feature.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.textColor)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .navigationDestination(for: FeatureDestination.self) { destination in
            destinationView(for: destination)
        }
    }

    @ViewBuilder
    private func destinationView(for destination: FeatureDestination) -> some View {
        switch destination {
        case .templates:
            TaskTemplatesView()
        case .smartLists:
            SmartListsView()
        case .pages:
            PagesView()
        case .messages:
            MessagesView()
        case .finance:
            FinanceView()
        case .calendar:
            CalendarView()
        case .chat:
            ChatView()
        case .settings:
            SettingsView()
        }
    }
}

#Preview {
    MoreView()
        .environment(ThemeManager.shared)
}
