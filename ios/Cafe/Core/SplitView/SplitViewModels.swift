//
//  SplitViewModels.swift
//  Cafe
//
//  Models for split view configuration
//

import SwiftUI

// MARK: - Split View State

enum SplitViewState: String, Codable {
    case single = "Single"
    case split = "Split"
    
    var isSplit: Bool {
        self == .split
    }
}

// MARK: - Split Ratio

enum SplitRatio: String, Codable, CaseIterable, Identifiable {
    case equal = "50/50"
    case primary70 = "70/30"
    case primary30 = "30/70"
    
    var id: String { rawValue }
    
    var primaryRatio: CGFloat {
        switch self {
        case .equal: return 0.5
        case .primary70: return 0.7
        case .primary30: return 0.3
        }
    }
    
    var secondaryRatio: CGFloat {
        return 1.0 - primaryRatio
    }
    
    var displayName: String {
        rawValue
    }
}

// MARK: - Split View Configuration

struct SplitViewConfiguration: Codable, Identifiable {
    var id: UUID
    var state: SplitViewState
    var primaryView: NavigationTab?
    var secondaryView: NavigationTab?
    var splitRatio: SplitRatio
    var isPrimaryVisible: Bool
    var isSecondaryVisible: Bool
    
    init(
        id: UUID = UUID(),
        state: SplitViewState = .single,
        primaryView: NavigationTab? = nil,
        secondaryView: NavigationTab? = nil,
        splitRatio: SplitRatio = .equal,
        isPrimaryVisible: Bool = true,
        isSecondaryVisible: Bool = true
    ) {
        self.id = id
        self.state = state
        self.primaryView = primaryView
        self.secondaryView = secondaryView
        self.splitRatio = splitRatio
        self.isPrimaryVisible = isPrimaryVisible
        self.isSecondaryVisible = isSecondaryVisible
    }
    
    static let `default` = SplitViewConfiguration(
        state: .single,
        primaryView: .dashboard,
        secondaryView: nil,
        splitRatio: .equal
    )
}

// MARK: - Split View Pair

struct SplitViewPair: Identifiable, Hashable {
    let id = UUID()
    let primary: NavigationTab
    let secondary: NavigationTab
    
    var displayName: String {
        "\(primary.rawValue) + \(secondary.rawValue)"
    }
    
    static let commonPairs: [SplitViewPair] = [
        SplitViewPair(primary: .dashboard, secondary: .tasks),
        SplitViewPair(primary: .tasks, secondary: .calendar),
        SplitViewPair(primary: .messages, secondary: .pages), // Messages + Pages for AI context
        SplitViewPair(primary: .dashboard, secondary: .calendar),
        SplitViewPair(primary: .tasks, secondary: .finance)
    ]
}

// MARK: - View Position

enum ViewPosition {
    case primary
    case secondary
    
    var opposite: ViewPosition {
        switch self {
        case .primary: return .secondary
        case .secondary: return .primary
        }
    }
}

