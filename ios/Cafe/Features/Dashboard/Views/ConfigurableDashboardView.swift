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
    @State private var showingAddCardMenu = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    controlStrip

                    if layoutManager.currentLayout.cards.isEmpty {
                        emptyState
                    }

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

    private var controlStrip: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(layoutManager.currentLayout.name.isEmpty ? "Custom Layout" : layoutManager.currentLayout.name)
                        .font(.headline)
                    Text("\(layoutManager.currentLayout.cards.count) cards • drag to rearrange")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Toggle(isOn: $isEditMode.animation()) {
                    Text("Edit")
                }
                .toggleStyle(.switch)
                .frame(maxWidth: 120)
            }

            HStack(spacing: 12) {
                Button {
                    showingAddCardMenu = true
                } label: {
                    Label("Add Card", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Menu {
                    ForEach(DashboardLayout.allPresets) { preset in
                        Button(preset.name) {
                            withAnimation {
                                layoutManager.applyPreset(preset)
                            }
                        }
                    }
                    Divider()
                    Button("Reset to Default", systemImage: "arrow.counterclockwise") {
                        withAnimation { layoutManager.resetToDefaultLayout() }
                    }
                } label: {
                    Label("Presets", systemImage: "square.grid.3x3.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    showingCustomization = true
                } label: {
                    Label("Customize", systemImage: "slider.horizontal.3")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal)
        .popover(isPresented: $showingAddCardMenu) {
            CardPickerView { cardType in
                layoutManager.addCard(
                    DashboardCard(type: cardType, position: (layoutManager.currentLayout.cards.map(\.position).max() ?? -1) + 1)
                )
                showingAddCardMenu = false
            }
            .presentationCompactAdaptation(.popover)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "rectangle.grid.2x2")
                .font(.system(size: 34))
                .foregroundColor(.secondary)
            Text("Add cards to build your dashboard")
                .font(.headline)
            Text("Use Add Card or apply a preset to start editing like widgets.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            HStack(spacing: 12) {
                Button("Use Default Layout") {
                    withAnimation { layoutManager.resetToDefaultLayout() }
                }
                .buttonStyle(.borderedProminent)
                Button("Open Presets") {
                    showingAddCardMenu = true
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal)
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
