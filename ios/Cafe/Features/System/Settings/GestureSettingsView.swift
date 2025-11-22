//
//  GestureSettingsView.swift
//  Cafe
//
//  UI for customizing gesture actions
//

import SwiftUI

struct GestureSettingsView: View {
    @State private var gestureManager = GestureManager.shared

    var body: some View {
        List {
            // Swipe Gestures
            Section {
                // Swipe Right
                HStack {
                    Image(systemName: "arrow.right")
                        .foregroundColor(.blue)
                        .frame(width: 30)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Swipe Right")
                            .font(.body)

                        Picker("", selection: $gestureManager.swipeRightAction) {
                            ForEach(SwipeAction.allCases) { action in
                                Label(action.rawValue, systemImage: action.icon)
                                    .tag(action)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }

                    Spacer()

                    Image(systemName: gestureManager.swipeRightAction.icon)
                        .foregroundColor(gestureManager.swipeRightAction.color)
                }

                // Swipe Left
                HStack {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.red)
                        .frame(width: 30)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Swipe Left")
                            .font(.body)

                        Picker("", selection: $gestureManager.swipeLeftAction) {
                            ForEach(SwipeAction.allCases) { action in
                                Label(action.rawValue, systemImage: action.icon)
                                    .tag(action)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }

                    Spacer()

                    Image(systemName: gestureManager.swipeLeftAction.icon)
                        .foregroundColor(gestureManager.swipeLeftAction.color)
                }
            } header: {
                Text("Swipe Gestures")
            } footer: {
                Text("Customize what happens when you swipe on a task")
            }

            // Tap Gestures
            Section {
                // Long Press
                HStack {
                    Image(systemName: "hand.point.up.left.fill")
                        .foregroundColor(.purple)
                        .frame(width: 30)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Long Press")
                            .font(.body)

                        Picker("", selection: $gestureManager.longPressAction) {
                            ForEach(LongPressAction.allCases) { action in
                                Label(action.rawValue, systemImage: action.icon)
                                    .tag(action)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }

                    Spacer()

                    Image(systemName: gestureManager.longPressAction.icon)
                        .foregroundColor(.purple)
                }

                // Double Tap
                HStack {
                    Image(systemName: "hand.tap.fill")
                        .foregroundColor(.orange)
                        .frame(width: 30)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Double Tap")
                            .font(.body)

                        Picker("", selection: $gestureManager.doubleTapAction) {
                            ForEach(DoubleTapAction.allCases) { action in
                                Label(action.rawValue, systemImage: action.icon)
                                    .tag(action)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }

                    Spacer()

                    Image(systemName: gestureManager.doubleTapAction.icon)
                        .foregroundColor(.orange)
                }
            } header: {
                Text("Tap Gestures")
            } footer: {
                Text("Customize tap and long press actions on tasks")
            }

            // Preview/Demo
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Try it out")
                        .font(.headline)

                    TaskGestureDemo()
                }
                .padding(.vertical, 8)
            } header: {
                Text("Preview")
            }

            // Action Descriptions
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    ActionDescriptionRow(
                        title: "Swipe Right",
                        action: gestureManager.swipeRightAction.rawValue,
                        description: gestureManager.swipeRightAction.description,
                        color: gestureManager.swipeRightAction.color
                    )

                    Divider()

                    ActionDescriptionRow(
                        title: "Swipe Left",
                        action: gestureManager.swipeLeftAction.rawValue,
                        description: gestureManager.swipeLeftAction.description,
                        color: gestureManager.swipeLeftAction.color
                    )

                    Divider()

                    ActionDescriptionRow(
                        title: "Long Press",
                        action: gestureManager.longPressAction.rawValue,
                        description: gestureManager.longPressAction.description,
                        color: .purple
                    )

                    Divider()

                    ActionDescriptionRow(
                        title: "Double Tap",
                        action: gestureManager.doubleTapAction.rawValue,
                        description: gestureManager.doubleTapAction.description,
                        color: .orange
                    )
                }
                .padding(.vertical, 8)
            } header: {
                Text("Current Actions")
            }
        }
        .navigationTitle("Gestures")
    }
}

// MARK: - Action Description Row

struct ActionDescriptionRow: View {
    let title: String
    let action: String
    let description: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Text(action)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }

            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Task Gesture Demo

struct TaskGestureDemo: View {
    @State private var offset: CGFloat = 0
    @State private var gestureManager = GestureManager.shared

    var body: some View {
        VStack(spacing: 8) {
            Text("Swipe this task left or right")
                .font(.caption)
                .foregroundColor(.secondary)

            ZStack {
                // Background actions
                HStack {
                    // Left action
                    HStack {
                        Image(systemName: gestureManager.swipeRightAction.icon)
                        Text(gestureManager.swipeRightAction.rawValue)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(gestureManager.swipeRightAction.color)

                    Spacer()

                    // Right action
                    HStack {
                        Text(gestureManager.swipeLeftAction.rawValue)
                            .fontWeight(.semibold)
                        Image(systemName: gestureManager.swipeLeftAction.icon)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(gestureManager.swipeLeftAction.color)
                }

                // Task card
                HStack {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)

                    Text("Demo Task")
                        .font(.body)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .shadow(radius: 2)
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            offset = value.translation.width
                        }
                        .onEnded { value in
                            withAnimation(.spring()) {
                                if abs(value.translation.width) > 100 {
                                    // Action triggered
                                    offset = 0
                                } else {
                                    offset = 0
                                }
                            }
                        }
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        GestureSettingsView()
    }
}
