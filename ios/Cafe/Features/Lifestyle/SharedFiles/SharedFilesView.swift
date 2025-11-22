//
//  SharedFilesView.swift
//  Cafe
//
//  File storage and sharing feature
//

import SwiftUI

struct SharedFilesView: View {
    @Environment(ThemeManager.self) var themeManager

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "folder.badge.person.crop")
                    .font(.system(size: 60))
                    .foregroundColor(themeManager.accentColor)

                Text("Shared Files")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.textColor)

                Text("File storage and sharing feature coming soon")
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 12) {
                    FeatureComingSoonRow(
                        icon: "folder.fill",
                        title: "File Storage",
                        description: "Store and organize your files"
                    )

                    FeatureComingSoonRow(
                        icon: "person.2.fill",
                        title: "File Sharing",
                        description: "Share files with team members"
                    )

                    FeatureComingSoonRow(
                        icon: "arrow.down.doc.fill",
                        title: "File Downloads",
                        description: "Download and manage shared files"
                    )

                    FeatureComingSoonRow(
                        icon: "lock.fill",
                        title: "Secure Storage",
                        description: "End-to-end encrypted file storage"
                    )
                }
                .padding()
                .background(themeManager.cardBackgroundColor)
                .cornerRadius(16)
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 40)
            .navigationTitle("Shared Files")
            .background(themeManager.backgroundColor.ignoresSafeArea())
        }
    }
}

struct FeatureComingSoonRow: View {
    @Environment(ThemeManager.self) private var themeManager
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(themeManager.accentColor)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.textColor)

                Text(description)
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SharedFilesView()
        .environment(ThemeManager.shared)
}
