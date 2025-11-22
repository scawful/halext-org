//
//  ContentManagementView.swift
//  Cafe
//
//  Site content CMS interface
//

import SwiftUI

struct ContentManagementView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            SitePagesView()
                .tabItem {
                    Label("Pages", systemImage: "doc.text")
                }
                .tag(0)

            PhotoAlbumsView()
                .tabItem {
                    Label("Albums", systemImage: "photo.on.rectangle.angled")
                }
                .tag(1)

            BlogPostsView()
                .tabItem {
                    Label("Blog", systemImage: "text.book.closed")
                }
                .tag(2)
        }
        .navigationTitle("Content Management")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Site Pages View

struct SitePagesView: View {
    @State private var pages: [SitePage] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            if isLoading && pages.isEmpty {
                Section {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
            } else if let error = errorMessage {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundColor(.red)
                }
            } else {
                Section {
                    HStack {
                        Label("Total Pages", systemImage: "doc.text.fill")
                        Spacer()
                        Text("\(pages.count)")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }

                    HStack {
                        Label("Published", systemImage: "checkmark.circle.fill")
                        Spacer()
                        Text("\(pages.filter { $0.isPublished }.count)")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                }

                Section("Pages") {
                    if pages.isEmpty {
                        Text("No pages found")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        ForEach(pages) { page in
                            SitePageRow(page: page)
                        }
                    }
                }
            }
        }
        .refreshable {
            await loadPages()
        }
        .task {
            await loadPages()
        }
    }

    @MainActor
    private func loadPages() async {
        isLoading = true
        errorMessage = nil

        do {
            pages = try await APIClient.shared.getSitePages()
        } catch {
            errorMessage = error.localizedDescription
            print("Failed to load pages: \(error)")
        }

        isLoading = false
    }
}

struct SitePageRow: View {
    let page: SitePage

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(.blue)

                Text(page.title)
                    .font(.headline)

                Spacer()

                if page.isPublished {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                } else {
                    Image(systemName: "clock")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
            }

            Text("/\(page.slug)")
                .font(.caption)
                .foregroundColor(.secondary)

            if let summary = page.summary {
                Text(summary)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            HStack {
                Text("Theme: \(page.theme)")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(4)

                Text("Updated \(page.updatedAt, style: .relative)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Photo Albums View

struct PhotoAlbumsView: View {
    @State private var albums: [PhotoAlbum] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            if isLoading && albums.isEmpty {
                Section {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
            } else if let error = errorMessage {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundColor(.red)
                }
            } else {
                Section {
                    HStack {
                        Label("Total Albums", systemImage: "photo.on.rectangle.angled")
                        Spacer()
                        Text("\(albums.count)")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.purple)
                    }

                    HStack {
                        Label("Public Albums", systemImage: "globe")
                        Spacer()
                        Text("\(albums.filter { $0.isPublic }.count)")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                }

                Section("Albums") {
                    if albums.isEmpty {
                        Text("No albums found")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        ForEach(albums) { album in
                            PhotoAlbumRow(album: album)
                        }
                    }
                }
            }
        }
        .refreshable {
            await loadAlbums()
        }
        .task {
            await loadAlbums()
        }
    }

    @MainActor
    private func loadAlbums() async {
        isLoading = true
        errorMessage = nil

        do {
            albums = try await APIClient.shared.getPhotoAlbums()
        } catch {
            errorMessage = error.localizedDescription
            print("Failed to load albums: \(error)")
        }

        isLoading = false
    }
}

struct PhotoAlbumRow: View {
    let album: PhotoAlbum

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "photo.on.rectangle.angled")
                    .foregroundColor(.purple)

                Text(album.title)
                    .font(.headline)

                Spacer()

                if album.isPublic {
                    Image(systemName: "globe")
                        .foregroundColor(.green)
                        .font(.caption)
                } else {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }

            Text("/albums/\(album.slug)")
                .font(.caption)
                .foregroundColor(.secondary)

            if let description = album.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            HStack {
                Text("\(album.photos.count) photos")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(4)

                Text("Updated \(album.updatedAt, style: .relative)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Blog Posts View

struct BlogPostsView: View {
    @State private var posts: [BlogPost] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            if isLoading && posts.isEmpty {
                Section {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
            } else if let error = errorMessage {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundColor(.red)
                }
            } else {
                Section {
                    HStack {
                        Label("Total Posts", systemImage: "text.book.closed")
                        Spacer()
                        Text("\(posts.count)")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.indigo)
                    }

                    HStack {
                        Label("Published", systemImage: "checkmark.circle.fill")
                        Spacer()
                        Text("\(posts.filter { $0.isPublished }.count)")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                }

                Section("Blog Posts") {
                    if posts.isEmpty {
                        Text("No posts found")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        ForEach(posts) { post in
                            BlogPostRow(post: post)
                        }
                    }
                }
            }
        }
        .refreshable {
            await loadPosts()
        }
        .task {
            await loadPosts()
        }
    }

    @MainActor
    private func loadPosts() async {
        isLoading = true
        errorMessage = nil

        do {
            posts = try await APIClient.shared.getBlogPosts()
        } catch {
            errorMessage = error.localizedDescription
            print("Failed to load posts: \(error)")
        }

        isLoading = false
    }
}

struct BlogPostRow: View {
    let post: BlogPost

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "text.book.closed")
                    .foregroundColor(.indigo)

                Text(post.title)
                    .font(.headline)

                Spacer()

                if post.isPublished {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                } else {
                    Image(systemName: "clock")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
            }

            Text("/blog/\(post.slug)")
                .font(.caption)
                .foregroundColor(.secondary)

            if let excerpt = post.excerpt {
                Text(excerpt)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            HStack {
                Text("By \(post.authorName)")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(4)

                if let publishedAt = post.publishedAt {
                    Text("Published \(publishedAt, style: .date)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("Draft")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        ContentManagementView()
    }
}
