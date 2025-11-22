//
//  HelpSearchView.swift
//  Cafe
//
//  In-app help search functionality
//

import SwiftUI

struct HelpSearchView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(ThemeManager.self) private var themeManager
    @State private var searchText = ""
    @State private var searchResults: [HelpArticle] = []
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                SearchBar(text: $searchText, placeholder: "Search help articles...")
                    .padding()
                    .background(themeManager.cardBackgroundColor)
                
                // Results
                if searchText.isEmpty {
                    // Popular searches
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Popular Searches")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
                                ForEach(HelpManager.shared.popularSearches, id: \.self) { search in
                                    Button(action: {
                                        searchText = search
                                        performSearch()
                                    }) {
                                        HStack {
                                            Image(systemName: "magnifyingglass")
                                                .font(.caption)
                                            Text(search)
                                                .font(.subheadline)
                                        }
                                        .foregroundColor(themeManager.textColor)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(themeManager.cardBackgroundColor)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                            
                            // Recent searches
                            if !HelpManager.shared.recentSearches.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Recent Searches")
                                        .font(.headline)
                                    
                                    ForEach(HelpManager.shared.recentSearches, id: \.self) { search in
                                        Button(action: {
                                            searchText = search
                                            performSearch()
                                        }) {
                                            HStack {
                                                Image(systemName: "clock")
                                                    .font(.caption)
                                                    .foregroundColor(themeManager.secondaryTextColor)
                                                Text(search)
                                                    .font(.subheadline)
                                                    .foregroundColor(themeManager.textColor)
                                                Spacer()
                                            }
                                            .padding(.vertical, 8)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                } else if searchResults.isEmpty {
                    // No results
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(themeManager.secondaryTextColor.opacity(0.5))
                        
                        Text("No results found")
                            .font(.headline)
                            .foregroundColor(themeManager.textColor)
                        
                        Text("Try different keywords or browse popular searches")
                            .font(.subheadline)
                            .foregroundColor(themeManager.secondaryTextColor)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Search results
                    List(searchResults) { article in
                        NavigationLink(destination: HelpArticleDetailView(article: article)) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(article.title)
                                    .font(.headline)
                                    .foregroundColor(themeManager.textColor)
                                
                                Text(article.summary)
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.secondaryTextColor)
                                    .lineLimit(2)
                                
                                HStack(spacing: 8) {
                                    ForEach(article.tags, id: \.self) { tag in
                                        Text(tag)
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(
                                                Capsule()
                                                    .fill(themeManager.accentColor.opacity(0.1))
                                            )
                                            .foregroundColor(themeManager.accentColor)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("Help Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onChange(of: searchText) { _, newValue in
                if !newValue.isEmpty {
                    performSearch()
                } else {
                    searchResults = []
                }
            }
        }
    }
    
    private func performSearch() {
        searchResults = HelpManager.shared.search(query: searchText)
        if !searchText.isEmpty {
            HelpManager.shared.addRecentSearch(searchText)
        }
    }
}

// MARK: - Search Bar

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    @FocusState private var isFocused: Bool
    @Environment(ThemeManager.self) private var themeManager
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(themeManager.secondaryTextColor)
            
            TextField(placeholder, text: $text)
                .focused($isFocused)
                .textFieldStyle(.plain)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                    isFocused = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.secondaryBackgroundColor)
        )
    }
}

// MARK: - Help Article Detail

struct HelpArticleDetailView: View {
    let article: HelpArticle
    @Environment(ThemeManager.self) private var themeManager
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(article.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(article.content)
                    .font(.body)
                    .foregroundColor(themeManager.textColor)
                
                if !article.tags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags")
                            .font(.headline)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(article.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(themeManager.accentColor.opacity(0.1))
                                    )
                                    .foregroundColor(themeManager.accentColor)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(themeManager.backgroundColor.ignoresSafeArea())
        .navigationTitle(article.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// FlowLayout is already defined in AdvancedFeaturesView.swift

