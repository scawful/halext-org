//
//  ConfigurableDashboardView.swift
//  Cafe
//
//  New configurable dashboard with drag & drop support
//

import SwiftUI
import UniformTypeIdentifiers

struct ConfigurableDashboardView: View {
    @Environment(ThemeManager.self) var themeManager
    @State private var viewModel = DashboardViewModel()
    @State private var layoutManager = DashboardLayoutManager.shared
    @State private var showAIGenerator = false
    @State private var isEditMode = false
    @State private var showingCustomization = false
    @State private var showingLayoutPicker = false
    @State private var draggedCard: DashboardCard?
    @State private var dragOffset: CGSize = .zero
    @State private var snapToGrid = false
    @State private var showPlaceholder = false
    @State private var placeholderIndex: Int?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Edit mode indicator
                    if isEditMode {
                        HStack {
                            Image(systemName: "pencil.circle.fill")
                                .foregroundColor(themeManager.accentColor)
                            Text("Edit Mode: Drag cards to reorder, tap × to remove")
                                .font(.subheadline)
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                        .padding()
                        .themedCardBackground(cornerRadius: 12, shadow: false)
                        .padding(.horizontal)
                    }
                    ForEach(Array(visibleCards.enumerated()), id: \.element.id) { index, card in
                        CardWrapperView(
                            card: card,
                            index: index,
                            isEditMode: isEditMode,
                            isDragging: draggedCard?.id == card.id,
                            showPlaceholder: showPlaceholder && placeholderIndex == index,
                            snapToGrid: snapToGrid,
                            onConfigure: {
                                // Open card configuration
                            },
                            onRemove: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    layoutManager.removeCard(card)
                                }
                            },
                            onDrag: {
                                draggedCard = card
                                hapticFeedback(style: .medium)
                            },
                            onDrop: { info in
                                handleDrop(card: card, info: info)
                            },
                            onDropEntered: {
                                if draggedCard?.id != card.id {
                                    placeholderIndex = index
                                    showPlaceholder = true
                                    hapticFeedback(style: .light)
                                }
                            },
                            onDropExited: {
                                if placeholderIndex == index {
                                    showPlaceholder = false
                                    placeholderIndex = nil
                                }
                            }
                        ) {
                            CardContentView(
                                card: card,
                                viewModel: viewModel,
                                showAIGenerator: $showAIGenerator
                            )
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isEditMode.toggle()
                                if !isEditMode {
                                    draggedCard = nil
                                    showPlaceholder = false
                                    placeholderIndex = nil
                                }
                            }
                        } label: {
                            Label(isEditMode ? "Done Editing" : "Edit Layout",
                                  systemImage: isEditMode ? "checkmark" : "pencil")
                        }

                        Button {
                            showingCustomization = true
                        } label: {
                            Label("Customize Cards", systemImage: "square.grid.3x3")
                        }
                        
                        if isEditMode {
                            Divider()
                            Toggle("Snap to Grid", isOn: $snapToGrid)
                        }

                        Divider()

                        Menu("Layout Presets") {
                            ForEach(DashboardLayout.allPresets) { preset in
                                Button(preset.name) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        layoutManager.applyPreset(preset)
                                    }
                                }
                            }
                        }

                        Divider()

                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                layoutManager.resetToDefaultLayout()
                            }
                        } label: {
                            Label("Reset to Default", systemImage: "arrow.counterclockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .refreshable {
                await viewModel.loadDashboardData()
            }
            .task {
                await viewModel.loadDashboardData()
            }
            .overlay {
                if viewModel.isLoading && viewModel.tasks.isEmpty {
                    ProgressView()
                }
            }
            .sheet(isPresented: $showAIGenerator) {
                SmartGeneratorView()
            }
            .sheet(isPresented: $showingCustomization) {
                DashboardCustomizationView(layout: $layoutManager.currentLayout)
            }
        }
    }

    private var visibleCards: [DashboardCard] {
        layoutManager.visibleCards()
            .filter { card in
                // Determine if the card is empty based on its type
                let isEmpty = isCardEmpty(card)
                return layoutManager.shouldShowCard(card, isEmpty: isEmpty)
            }
    }

    private func isCardEmpty(_ card: DashboardCard) -> Bool {
        switch card.type {
        case .todayTasks, .upcomingEvents:
            return viewModel.tasks.isEmpty && viewModel.events.isEmpty
        default:
            return false
        }
    }
    
    private func handleDrop(card: DashboardCard, info: DropInfo) -> Bool {
        guard let draggedCard = draggedCard,
              draggedCard.id != card.id else {
            self.draggedCard = nil
            showPlaceholder = false
            placeholderIndex = nil
            return false
        }

        let sortedCards = visibleCards
        guard let fromIndex = sortedCards.firstIndex(where: { $0.id == draggedCard.id }),
              let toIndex = sortedCards.firstIndex(where: { $0.id == card.id }) else {
            self.draggedCard = nil
            showPlaceholder = false
            placeholderIndex = nil
            return false
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            layoutManager.moveCard(from: fromIndex, to: toIndex)
        }
        
        hapticFeedback(style: .medium)
        self.draggedCard = nil
        showPlaceholder = false
        placeholderIndex = nil
        return true
    }
    
    private func hapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

// MARK: - Card Wrapper View

struct CardWrapperView<Content: View>: View {
    let card: DashboardCard
    let index: Int
    let isEditMode: Bool
    let isDragging: Bool
    let showPlaceholder: Bool
    let snapToGrid: Bool
    let onConfigure: (() -> Void)?
    let onRemove: (() -> Void)?
    let onDrag: () -> Void
    let onDrop: (DropInfo) -> Bool
    let onDropEntered: () -> Void
    let onDropExited: () -> Void
    @ViewBuilder let content: () -> Content
    
    @State private var dragOffset: CGSize = .zero
    @State private var isHighlighted = false

    var body: some View {
        ZStack {
            // Placeholder
            if showPlaceholder {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.15),
                                Color.purple.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                    )
                    .frame(height: 100)
                    .transition(.opacity.combined(with: .scale))
            }
            
            // Actual card
            DashboardCardView(
                card: card,
                isEditMode: isEditMode,
                showDragHandle: isEditMode,
                isDragging: isDragging,
                onConfigure: onConfigure,
                onRemove: onRemove
            ) {
                content()
            }
            .opacity(isDragging ? 0.5 : 1.0)
            .scaleEffect(isDragging ? 0.95 : (isHighlighted ? 1.02 : 1.0))
            .offset(isDragging ? dragOffset : .zero)
            .shadow(
                color: isDragging ? Color.black.opacity(0.3) : Color.clear,
                radius: isDragging ? 10 : 0,
                y: isDragging ? 5 : 0
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHighlighted)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showPlaceholder)
        }
        .onDrag {
            onDrag()
            return NSItemProvider(object: card.id.uuidString as NSString)
        }
        .onDrop(of: [.text], delegate: EnhancedCardDropDelegate(
            card: card,
            onDrop: onDrop,
            onDropEntered: {
                isHighlighted = true
                onDropEntered()
            },
            onDropExited: {
                isHighlighted = false
                onDropExited()
            }
        ))
    }
}

// MARK: - Enhanced Card Drop Delegate

struct EnhancedCardDropDelegate: DropDelegate {
    let card: DashboardCard
    let onDrop: (DropInfo) -> Bool
    let onDropEntered: () -> Void
    let onDropExited: () -> Void
    
    func performDrop(info: DropInfo) -> Bool {
        return onDrop(info)
    }
    
    func dropEntered(info: DropInfo) {
        onDropEntered()
    }
    
    func dropExited(info: DropInfo) {
        onDropExited()
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}

// MARK: - Preview

#Preview {
    ConfigurableDashboardView()
}
