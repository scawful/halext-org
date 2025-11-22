//
//  SplitViewContainer.swift
//  Cafe
//
//  Container view for split layout with adjustable divider
//

import SwiftUI

struct SplitViewContainer: View {
    @State private var splitManager = SplitViewManager.shared
    @Environment(AppState.self) var appState
    @State private var dividerOffset: CGFloat = 0
    @State private var isDraggingDivider = false
    @GestureState private var dragOffset: CGFloat = 0
    
    var body: some View {
        Group {
            if splitManager.isSplitMode {
                splitViewLayout
            } else {
                singleViewLayout
            }
        }
    }
    
    @ViewBuilder
    private var singleViewLayout: some View {
        if let primaryView = splitManager.primaryView {
            viewContent(for: primaryView, position: .primary)
        } else {
            EmptyView()
        }
    }
    
    @ViewBuilder
    private var splitViewLayout: some View {
        GeometryReader { geometry in
            let primaryWidth = calculatePrimaryWidth(in: geometry) + dividerOffset + dragOffset
            let dividerWidth: CGFloat = 8
            let secondaryWidth = geometry.size.width - primaryWidth - dividerWidth
            
            HStack(spacing: 0) {
                // Primary View
                if splitManager.configuration.isPrimaryVisible,
                   let primaryView = splitManager.primaryView {
                    viewContent(for: primaryView, position: .primary)
                        .frame(width: max(primaryWidth, 200))
                }
                
                // Divider
                if splitManager.configuration.isPrimaryVisible && splitManager.configuration.isSecondaryVisible {
                    DividerView(
                        isDragging: isDraggingDivider,
                        onDragChanged: { offset in
                            dividerOffset += offset
                        },
                        onDragEnded: {
                            updateSplitRatio(from: primaryWidth, totalWidth: geometry.size.width)
                            dividerOffset = 0
                        }
                    )
                    .frame(width: dividerWidth)
                }
                
                // Secondary View
                if splitManager.configuration.isSecondaryVisible,
                   let secondaryView = splitManager.secondaryView {
                    viewContent(for: secondaryView, position: .secondary)
                        .frame(width: max(secondaryWidth, 200))
                }
            }
        }
    }
    
    private func calculatePrimaryWidth(in geometry: GeometryProxy) -> CGFloat {
        geometry.size.width * splitManager.splitRatio.primaryRatio
    }
    
    private func updateSplitRatio(from primaryWidth: CGFloat, totalWidth: CGFloat) {
        let ratio = primaryWidth / totalWidth
        
        if ratio < 0.35 {
            splitManager.setSplitRatio(.primary30)
        } else if ratio > 0.65 {
            splitManager.setSplitRatio(.primary70)
        } else {
            splitManager.setSplitRatio(.equal)
        }
    }
    
    @ViewBuilder
    private func viewContent(for tab: NavigationTab, position: ViewPosition) -> some View {
        ZStack {
            tabContentView(for: tab)
            
            // Toggle button overlay
            if splitManager.isSplitMode {
                VStack {
                    if position == .primary {
                        Spacer()
                        toggleButton(position: .primary)
                            .padding()
                    } else {
                        toggleButton(position: .secondary)
                            .padding()
                        Spacer()
                    }
                }
            }
        }
        .background(ThemeManager.shared.backgroundStyle)
    }
    
    @ViewBuilder
    private func tabContentView(for tab: NavigationTab) -> some View {
        switch tab {
        case .dashboard:
            DashboardView()
        case .tasks:
            TaskListView()
        case .calendar:
            CalendarView()
        case .messages:
            MessagesView() // Unified: AI + Human conversations
        case .finance:
            FinanceView()
        case .pages:
            PagesView()
        case .admin:
            if appState.isAdmin {
                AdminView()
            } else {
                Text("Admin access required")
                    .foregroundColor(.secondary)
            }
        case .settings:
            SettingsView()
        case .templates:
            TaskTemplatesView()
        case .smartLists:
            SmartListsView()
        case .more:
            MoreView()
        }
    }
    
    private func toggleButton(position: ViewPosition) -> some View {
        Button(action: {
            splitManager.toggleViewVisibility(position: position)
        }) {
            Image(systemName: splitManager.configuration.isPrimaryVisible && position == .primary ||
                   splitManager.configuration.isSecondaryVisible && position == .secondary ?
                   "eye.fill" : "eye.slash.fill")
                .font(.caption)
                .foregroundColor(.white)
                .padding(8)
                .background(Circle().fill(Color.black.opacity(0.5)))
        }
    }
}

// MARK: - Divider View

struct DividerView: View {
    let isDragging: Bool
    let onDragChanged: (CGFloat) -> Void
    let onDragEnded: () -> Void
    
    @State private var dragLocation: CGPoint = .zero
    @GestureState private var isDraggingGesture = false
    
    var body: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .overlay(
                HStack(spacing: 2) {
                    ForEach(0..<3) { _ in
                        Circle()
                            .fill(Color.gray.opacity(0.6))
                            .frame(width: 4, height: 4)
                    }
                }
            )
            .gesture(
                DragGesture()
                    .updating($isDraggingGesture) { _, state, _ in
                        state = true
                    }
                    .onChanged { value in
                        onDragChanged(value.translation.width)
                    }
                    .onEnded { _ in
                        onDragEnded()
                    }
            )
            .scaleEffect(isDraggingGesture ? 1.1 : 1.0)
            .animation(.spring(response: 0.2), value: isDraggingGesture)
    }
}

// MARK: - Split View Toggle Button

struct SplitViewToggleButton: View {
    @State private var splitManager = SplitViewManager.shared
    
    var body: some View {
        Button(action: {
            splitManager.toggleSplitView()
        }) {
            Image(systemName: splitManager.isSplitMode ? "rectangle.split.2x1.fill" : "rectangle.split.2x1")
                .font(.title3)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Split View Control Panel

struct SplitViewControlPanel: View {
    @State private var splitManager = SplitViewManager.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                // Split View Toggle
                Section {
                    Toggle("Split View", isOn: Binding(
                        get: { splitManager.isSplitMode },
                        set: { enabled in
                            if enabled {
                                splitManager.enableSplitView()
                            } else {
                                splitManager.disableSplitView()
                            }
                        }
                    ))
                } header: {
                    Text("Mode")
                } footer: {
                    Text("Display two views side-by-side")
                }
                
                if splitManager.isSplitMode {
                    // Primary View Selection
                    Section {
                        Picker("Primary View", selection: Binding(
                            get: { splitManager.primaryView ?? .dashboard },
                            set: { splitManager.setPrimaryView($0) }
                        )) {
                            ForEach(NavigationTab.allCases.filter { $0 != splitManager.secondaryView }) { tab in
                                HStack {
                                    Image(systemName: tab.icon)
                                    Text(tab.rawValue)
                                }
                                .tag(tab)
                            }
                        }
                    } header: {
                        Text("Primary View")
                    }
                    
                    // Secondary View Selection
                    Section {
                        Picker("Secondary View", selection: Binding(
                            get: { splitManager.secondaryView ?? .tasks },
                            set: { splitManager.setSecondaryView($0) }
                        )) {
                            ForEach(NavigationTab.allCases.filter { $0 != splitManager.primaryView }) { tab in
                                HStack {
                                    Image(systemName: tab.icon)
                                    Text(tab.rawValue)
                                }
                                .tag(tab)
                            }
                        }
                    } header: {
                        Text("Secondary View")
                    }
                    
                    // Split Ratio
                    Section {
                        Picker("Split Ratio", selection: Binding(
                            get: { splitManager.splitRatio },
                            set: { splitManager.setSplitRatio($0) }
                        )) {
                            ForEach(SplitRatio.allCases) { ratio in
                                Text(ratio.displayName).tag(ratio)
                            }
                        }
                    } header: {
                        Text("Layout")
                    } footer: {
                        Text("Adjust the size of each view")
                    }
                    
                    // Quick Pairs
                    Section {
                        ForEach(SplitViewPair.commonPairs) { pair in
                            Button(action: {
                                splitManager.setViewPair(pair)
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(pair.displayName)
                                            .foregroundColor(.primary)
                                        Text("Common combination")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    if splitManager.primaryView == pair.primary &&
                                       splitManager.secondaryView == pair.secondary {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    } header: {
                        Text("Quick Pairs")
                    }
                    
                    // Visibility Toggles
                    Section {
                        Toggle("Show Primary View", isOn: Binding(
                            get: { splitManager.configuration.isPrimaryVisible },
                            set: { splitManager.setViewVisibility(position: .primary, visible: $0) }
                        ))
                        
                        Toggle("Show Secondary View", isOn: Binding(
                            get: { splitManager.configuration.isSecondaryVisible },
                            set: { splitManager.setViewVisibility(position: .secondary, visible: $0) }
                        ))
                    } header: {
                        Text("Visibility")
                    }
                    
                    // Actions
                    Section {
                        Button(action: {
                            splitManager.swapViews()
                        }) {
                            HStack {
                                Image(systemName: "arrow.left.arrow.right")
                                Text("Swap Views")
                            }
                        }
                    } header: {
                        Text("Actions")
                    }
                }
            }
            .navigationTitle("Split View")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SplitViewContainer()
        .environment(AppState())
}

