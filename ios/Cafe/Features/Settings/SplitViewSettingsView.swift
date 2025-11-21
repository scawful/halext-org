//
//  SplitViewSettingsView.swift
//  Cafe
//
//  Settings UI for split view configuration
//

import SwiftUI

struct SplitViewSettingsView: View {
    @State private var splitManager = SplitViewManager.shared
    
    var body: some View {
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
                Text("Display two views side-by-side for multitasking")
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
                } footer: {
                    Text("The main view displayed on the left")
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
                } footer: {
                    Text("The secondary view displayed on the right")
                }
                
                // Split Ratio
                Section {
                    Picker("Split Ratio", selection: Binding(
                        get: { splitManager.splitRatio },
                        set: { splitManager.setSplitRatio($0) }
                    )) {
                        ForEach(SplitRatio.allCases) { ratio in
                            HStack {
                                Text(ratio.displayName)
                                Spacer()
                                Text("\(Int(ratio.primaryRatio * 100))% / \(Int(ratio.secondaryRatio * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(ratio)
                        }
                    }
                } header: {
                    Text("Layout Ratio")
                } footer: {
                    Text("Adjust the size of each view. You can also drag the divider in split view mode.")
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
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Quick Pairs")
                } footer: {
                    Text("Common view combinations for quick setup")
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
                } footer: {
                    Text("Show or hide individual views in split mode")
                }
                
                // Actions
                Section {
                    Button(action: {
                        splitManager.swapViews()
                    }) {
                        HStack {
                            Image(systemName: "arrow.left.arrow.right")
                            Text("Swap Views")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Actions")
                }
            } else {
                // Help section when not in split mode
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Split view allows you to display two different views side-by-side, similar to iPad multitasking.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Enable split view to get started.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("About Split View")
                }
            }
        }
        .navigationTitle("Split View")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SplitViewSettingsView()
    }
}

