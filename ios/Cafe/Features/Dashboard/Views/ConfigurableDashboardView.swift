//
//  ConfigurableDashboardView.swift
//  Cafe
//
//  New configurable dashboard with drag & drop support
//

import SwiftUI
import UniformTypeIdentifiers

struct ConfigurableDashboardView: View {
    @State private var viewModel = DashboardViewModel()
    @State private var layoutManager = DashboardLayoutManager.shared
    @State private var showAIGenerator = false
    @State private var isEditMode = false
    @State private var showingCustomization = false
    @State private var showingLayoutPicker = false
    @State private var draggedCard: DashboardCard?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(visibleCards) { card in
                        DashboardCardView(
                            card: card,
                            isEditMode: isEditMode,
                            onConfigure: {
                                // Open card configuration
                            },
                            onRemove: {
                                withAnimation {
                                    layoutManager.removeCard(card)
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
                        .onDrag {
                            draggedCard = card
                            return NSItemProvider(object: card.id.uuidString as NSString)
                        }
                        .onDrop(of: [.text], delegate: CardDropDelegate(
                            card: card,
                            draggedCard: $draggedCard,
                            cards: $layoutManager.currentLayout.cards,
                            layoutManager: layoutManager
                        ))
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            withAnimation {
                                isEditMode.toggle()
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

                        Divider()

                        Menu("Layout Presets") {
                            ForEach(DashboardLayout.allPresets) { preset in
                                Button(preset.name) {
                                    withAnimation {
                                        layoutManager.applyPreset(preset)
                                    }
                                }
                            }
                        }

                        Divider()

                        Button {
                            withAnimation {
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
}

// MARK: - Card Drop Delegate

struct CardDropDelegate: DropDelegate {
    let card: DashboardCard
    @Binding var draggedCard: DashboardCard?
    @Binding var cards: [DashboardCard]
    let layoutManager: DashboardLayoutManager

    func performDrop(info: DropInfo) -> Bool {
        draggedCard = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let draggedCard = draggedCard,
              draggedCard.id != card.id else { return }

        let fromIndex = cards.firstIndex { $0.id == draggedCard.id }
        let toIndex = cards.firstIndex { $0.id == card.id }

        guard let from = fromIndex, let to = toIndex else { return }

        withAnimation {
            layoutManager.moveCard(from: from, to: to)
        }
    }
}

// MARK: - Preview

#Preview {
    ConfigurableDashboardView()
}
