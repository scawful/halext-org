//
//  SplitViewManager.swift
//  Cafe
//
//  Manages split view state and configuration
//

import SwiftUI

@MainActor
@Observable
class SplitViewManager {
    static let shared = SplitViewManager()
    
    var configuration: SplitViewConfiguration {
        didSet {
            saveConfiguration()
        }
    }
    
    private let userDefaults = UserDefaults.standard
    private let configurationKey = "splitViewConfiguration"
    
    private init() {
        // Load saved configuration
        if let savedData = userDefaults.data(forKey: configurationKey),
           let config = try? JSONDecoder().decode(SplitViewConfiguration.self, from: savedData) {
            self.configuration = config
        } else {
            self.configuration = .default
        }
    }
    
    // MARK: - Configuration Management
    
    func toggleSplitView() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if configuration.state == .split {
                configuration.state = .single
            } else {
                enableSplitView()
            }
        }
    }
    
    func enableSplitView() {
        configuration.state = .split
        if configuration.primaryView == nil {
            configuration.primaryView = .dashboard
        }
        if configuration.secondaryView == nil {
            configuration.secondaryView = .tasks
        }
    }
    
    func disableSplitView() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            configuration.state = .single
            configuration.secondaryView = nil
        }
    }
    
    func setPrimaryView(_ view: NavigationTab) {
        configuration.primaryView = view
    }
    
    func setSecondaryView(_ view: NavigationTab) {
        guard configuration.state == .split else { return }
        configuration.secondaryView = view
    }
    
    func swapViews() {
        guard configuration.state == .split else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            let temp = configuration.primaryView
            configuration.primaryView = configuration.secondaryView
            configuration.secondaryView = temp
        }
    }
    
    func setSplitRatio(_ ratio: SplitRatio) {
        guard configuration.state == .split else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            configuration.splitRatio = ratio
        }
    }
    
    func setViewPair(_ pair: SplitViewPair) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            configuration.state = .split
            configuration.primaryView = pair.primary
            configuration.secondaryView = pair.secondary
        }
    }
    
    func toggleViewVisibility(position: ViewPosition) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            switch position {
            case .primary:
                configuration.isPrimaryVisible.toggle()
            case .secondary:
                configuration.isSecondaryVisible.toggle()
            }
        }
    }
    
    func setViewVisibility(position: ViewPosition, visible: Bool) {
        switch position {
        case .primary:
            configuration.isPrimaryVisible = visible
        case .secondary:
            configuration.isSecondaryVisible = visible
        }
    }
    
    // MARK: - Persistence
    
    private func saveConfiguration() {
        if let data = try? JSONEncoder().encode(configuration) {
            userDefaults.set(data, forKey: configurationKey)
        }
    }
    
    // MARK: - Computed Properties
    
    var isSplitMode: Bool {
        configuration.state == .split
    }
    
    var canSplit: Bool {
        configuration.primaryView != nil && configuration.secondaryView != nil &&
        configuration.primaryView != configuration.secondaryView
    }
    
    var primaryView: NavigationTab? {
        configuration.primaryView
    }
    
    var secondaryView: NavigationTab? {
        configuration.secondaryView
    }
    
    var splitRatio: SplitRatio {
        configuration.splitRatio
    }
}

