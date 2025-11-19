//
//  ExamplePromptsView.swift
//  Cafe
//
//  Library of example prompts and templates for AI generation
//

import SwiftUI

struct ExamplePromptsView: View {
    @Environment(\.dismiss) private var dismiss
    let onSelectPrompt: (String) -> Void

    @State private var selectedCategory: PromptCategory = .personal
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(PromptCategory.allCases) { category in
                            CategoryChip(
                                category: category,
                                isSelected: selectedCategory == category
                            ) {
                                withAnimation {
                                    selectedCategory = category
                                }
                            }
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGray6))

                // Prompts list
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredPrompts) { prompt in
                            PromptCard(prompt: prompt) {
                                onSelectPrompt(prompt.text)
                                dismiss()
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
                .searchable(text: $searchText, prompt: "Search prompts...")
            }
            .navigationTitle("Example Prompts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var filteredPrompts: [ExamplePrompt] {
        let categoryPrompts = ExamplePrompt.allPrompts.filter { $0.category == selectedCategory }

        if searchText.isEmpty {
            return categoryPrompts
        } else {
            return categoryPrompts.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText) ||
                $0.text.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let category: PromptCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.caption)
                Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.blue : Color(.systemGray5))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

// MARK: - Prompt Card

struct PromptCard: View {
    let prompt: ExamplePrompt
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: prompt.icon)
                        .font(.title3)
                        .foregroundColor(prompt.color)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(prompt.color.opacity(0.15))
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(prompt.title)
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(prompt.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(prompt.text)
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.05))
                    )

                if !prompt.expectedOutputs.isEmpty {
                    HStack {
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("Creates: \(prompt.expectedOutputs.joined(separator: ", "))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
            )
        }
    }
}

// MARK: - Models

enum PromptCategory: String, CaseIterable, Identifiable {
    case personal = "Personal"
    case work = "Work"
    case home = "Home"
    case events = "Events"
    case health = "Health"
    case learning = "Learning"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .personal:
            return "person.fill"
        case .work:
            return "briefcase.fill"
        case .home:
            return "house.fill"
        case .events:
            return "calendar.badge.plus"
        case .health:
            return "heart.fill"
        case .learning:
            return "book.fill"
        }
    }
}

struct ExamplePrompt: Identifiable {
    let id = UUID()
    let category: PromptCategory
    let title: String
    let description: String
    let icon: String
    let color: Color
    let text: String
    let expectedOutputs: [String]

    // MARK: - Personal Prompts

    static let personalPrompts: [ExamplePrompt] = [
        ExamplePrompt(
            category: .personal,
            title: "Morning Routine",
            description: "Start your day with a structured routine",
            icon: "sunrise.fill",
            color: .orange,
            text: "Create a morning routine from 6am to 9am including exercise, breakfast, and planning",
            expectedOutputs: ["5 tasks", "3 events"]
        ),
        ExamplePrompt(
            category: .personal,
            title: "Reading Goals",
            description: "Track your reading objectives",
            icon: "book.fill",
            color: .purple,
            text: "Set up a reading goal to finish 2 books this month with weekly progress checks",
            expectedOutputs: ["4 tasks", "4 events"]
        ),
        ExamplePrompt(
            category: .personal,
            title: "Exercise Plan",
            description: "Weekly workout schedule",
            icon: "figure.run",
            color: .green,
            text: "Create a weekly exercise routine with cardio on Monday, Wednesday, Friday and strength training on Tuesday, Thursday",
            expectedOutputs: ["5 recurring events"]
        ),
        ExamplePrompt(
            category: .personal,
            title: "Meditation Practice",
            description: "Daily mindfulness routine",
            icon: "brain.head.profile",
            color: .cyan,
            text: "Daily meditation practice every morning at 7am for 15 minutes",
            expectedOutputs: ["1 recurring event", "1 task"]
        ),
        ExamplePrompt(
            category: .personal,
            title: "Digital Detox",
            description: "Reduce screen time",
            icon: "iphone.slash",
            color: .red,
            text: "Plan a digital detox weekend with outdoor activities and no social media",
            expectedOutputs: ["6 tasks", "3 events"]
        )
    ]

    // MARK: - Work Prompts

    static let workPrompts: [ExamplePrompt] = [
        ExamplePrompt(
            category: .work,
            title: "Project Launch",
            description: "Launch a new product or feature",
            icon: "rocket.fill",
            color: .blue,
            text: "Launch new mobile app next month with beta testing, marketing campaign, and release event",
            expectedOutputs: ["12 tasks", "5 events"]
        ),
        ExamplePrompt(
            category: .work,
            title: "Client Onboarding",
            description: "Onboard a new client smoothly",
            icon: "person.badge.plus",
            color: .indigo,
            text: "Onboard new enterprise client with kickoff meeting, requirements gathering, and initial setup",
            expectedOutputs: ["8 tasks", "3 events"]
        ),
        ExamplePrompt(
            category: .work,
            title: "Weekly Review",
            description: "Review progress and plan ahead",
            icon: "calendar.badge.checkmark",
            color: .purple,
            text: "Weekly review every Friday afternoon to assess progress and plan next week",
            expectedOutputs: ["1 recurring event", "3 tasks"]
        ),
        ExamplePrompt(
            category: .work,
            title: "Team Sprint",
            description: "2-week development sprint",
            icon: "figure.run.circle.fill",
            color: .orange,
            text: "Plan a 2-week development sprint with daily standups, mid-sprint review, and retrospective",
            expectedOutputs: ["15 tasks", "10 events"]
        ),
        ExamplePrompt(
            category: .work,
            title: "Presentation Prep",
            description: "Prepare for important presentation",
            icon: "rectangle.on.rectangle.angled",
            color: .pink,
            text: "Prepare quarterly business review presentation for executive team next Thursday",
            expectedOutputs: ["7 tasks", "2 events"]
        )
    ]

    // MARK: - Home Prompts

    static let homePrompts: [ExamplePrompt] = [
        ExamplePrompt(
            category: .home,
            title: "Spring Cleaning",
            description: "Deep clean your home",
            icon: "sparkles",
            color: .cyan,
            text: "Spring cleaning project over 2 weekends covering all rooms, garage, and outdoor spaces",
            expectedOutputs: ["15 tasks", "4 events"]
        ),
        ExamplePrompt(
            category: .home,
            title: "Garden Maintenance",
            description: "Monthly garden care routine",
            icon: "leaf.fill",
            color: .green,
            text: "Monthly garden maintenance including watering schedule, fertilizing, and pruning",
            expectedOutputs: ["8 tasks", "4 recurring events"]
        ),
        ExamplePrompt(
            category: .home,
            title: "Home Renovation",
            description: "Major home improvement project",
            icon: "hammer.fill",
            color: .orange,
            text: "Kitchen renovation project starting next month with contractor meetings, permits, and timeline",
            expectedOutputs: ["20 tasks", "8 events"]
        ),
        ExamplePrompt(
            category: .home,
            title: "Organize Garage",
            description: "Clean and organize storage",
            icon: "archivebox.fill",
            color: .gray,
            text: "Organize garage this weekend with sorting, disposal, and storage systems",
            expectedOutputs: ["6 tasks", "1 event"]
        ),
        ExamplePrompt(
            category: .home,
            title: "Moving Checklist",
            description: "Complete moving preparation",
            icon: "shippingbox.fill",
            color: .brown,
            text: "Moving to new house next month - complete checklist from packing to utilities setup",
            expectedOutputs: ["25 tasks", "10 events"]
        )
    ]

    // MARK: - Events Prompts

    static let eventsPrompts: [ExamplePrompt] = [
        ExamplePrompt(
            category: .events,
            title: "Birthday Party",
            description: "Plan a memorable celebration",
            icon: "birthday.cake.fill",
            color: .pink,
            text: "Plan Sarah's 30th birthday party next Saturday with venue, catering, decorations, and guest list",
            expectedOutputs: ["12 tasks", "3 events", "2 lists"]
        ),
        ExamplePrompt(
            category: .events,
            title: "Wedding Planning",
            description: "Organize your wedding",
            icon: "heart.fill",
            color: .red,
            text: "Plan wedding in 6 months including venue, vendors, invitations, and timeline",
            expectedOutputs: ["40 tasks", "15 events"]
        ),
        ExamplePrompt(
            category: .events,
            title: "Vacation Preparation",
            description: "Get ready for a trip",
            icon: "airplane",
            color: .blue,
            text: "Prepare for 2-week vacation to Hawaii including flights, accommodation, activities, and packing",
            expectedOutputs: ["15 tasks", "8 events", "2 lists"]
        ),
        ExamplePrompt(
            category: .events,
            title: "Conference Planning",
            description: "Organize a professional event",
            icon: "person.3.fill",
            color: .purple,
            text: "Organize tech conference for 200 attendees with speakers, venue, catering, and marketing",
            expectedOutputs: ["30 tasks", "12 events"]
        ),
        ExamplePrompt(
            category: .events,
            title: "Holiday Dinner",
            description: "Host a festive gathering",
            icon: "fork.knife",
            color: .green,
            text: "Host Thanksgiving dinner for 15 people with menu planning, shopping, cooking schedule, and table setup",
            expectedOutputs: ["18 tasks", "5 events", "2 lists"]
        )
    ]

    // MARK: - Health Prompts

    static let healthPrompts: [ExamplePrompt] = [
        ExamplePrompt(
            category: .health,
            title: "Meal Prep Routine",
            description: "Weekly healthy meal planning",
            icon: "fork.knife.circle.fill",
            color: .green,
            text: "Weekly meal prep every Sunday with shopping, cooking 5 healthy dinners, and portion control",
            expectedOutputs: ["6 tasks", "2 events", "1 list"]
        ),
        ExamplePrompt(
            category: .health,
            title: "Workout Schedule",
            description: "Comprehensive fitness plan",
            icon: "figure.strengthtraining.traditional",
            color: .orange,
            text: "12-week workout program with strength training, cardio, and flexibility sessions",
            expectedOutputs: ["10 recurring events", "5 tasks"]
        ),
        ExamplePrompt(
            category: .health,
            title: "Doctor Appointments",
            description: "Schedule health checkups",
            icon: "cross.case.fill",
            color: .red,
            text: "Schedule annual health checkups including dentist, eye doctor, and physical exam",
            expectedOutputs: ["6 tasks", "3 events"]
        ),
        ExamplePrompt(
            category: .health,
            title: "Sleep Optimization",
            description: "Improve sleep quality",
            icon: "moon.fill",
            color: .indigo,
            text: "Improve sleep quality with consistent bedtime routine, environment setup, and tracking",
            expectedOutputs: ["5 tasks", "2 recurring events"]
        ),
        ExamplePrompt(
            category: .health,
            title: "Hydration Goals",
            description: "Drink more water daily",
            icon: "drop.fill",
            color: .cyan,
            text: "Drink 8 glasses of water daily with hourly reminders during work hours",
            expectedOutputs: ["1 task", "8 recurring events"]
        )
    ]

    // MARK: - Learning Prompts

    static let learningPrompts: [ExamplePrompt] = [
        ExamplePrompt(
            category: .learning,
            title: "Learn Programming",
            description: "Master a new language",
            icon: "chevron.left.forwardslash.chevron.right",
            color: .blue,
            text: "Learn Swift programming in 3 months with daily practice, tutorials, and building projects",
            expectedOutputs: ["20 tasks", "12 events"]
        ),
        ExamplePrompt(
            category: .learning,
            title: "Language Study",
            description: "Study a foreign language",
            icon: "character.book.closed.fill",
            color: .purple,
            text: "Study Spanish with daily Duolingo practice, weekly tutor sessions, and conversation practice",
            expectedOutputs: ["8 recurring events", "5 tasks"]
        ),
        ExamplePrompt(
            category: .learning,
            title: "Online Course",
            description: "Complete certification course",
            icon: "graduationcap.fill",
            color: .indigo,
            text: "Complete iOS development certification course in 2 months with weekly modules and projects",
            expectedOutputs: ["12 tasks", "8 events"]
        ),
        ExamplePrompt(
            category: .learning,
            title: "Skill Practice",
            description: "Daily skill development",
            icon: "music.note",
            color: .pink,
            text: "Practice guitar 30 minutes daily with weekly song goals and monthly performance videos",
            expectedOutputs: ["4 recurring events", "8 tasks"]
        ),
        ExamplePrompt(
            category: .learning,
            title: "Reading Challenge",
            description: "Read more books",
            icon: "books.vertical.fill",
            color: .orange,
            text: "Read 24 books this year with 2 books per month and weekly reading time",
            expectedOutputs: ["12 tasks", "52 events"]
        )
    ]

    // MARK: - All Prompts

    static let allPrompts: [ExamplePrompt] =
        personalPrompts +
        workPrompts +
        homePrompts +
        eventsPrompts +
        healthPrompts +
        learningPrompts
}

// MARK: - Preview

#Preview {
    ExamplePromptsView { prompt in
        print("Selected: \(prompt)")
    }
}
