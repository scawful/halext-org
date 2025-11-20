//
//  AboutView.swift
//  Cafe
//
//  About app information
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // App Icon and Name
                    VStack(spacing: 16) {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "cup.and.saucer.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                            )
                            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)

                        VStack(spacing: 4) {
                            Text("Cafe")
                                .font(.largeTitle)
                                .fontWeight(.bold)

                            Text("Version \(appVersion) (\(buildNumber))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 32)

                    // Description
                    VStack(spacing: 16) {
                        Text("Your All-in-One Productivity Hub")
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text("Cafe brings together tasks, events, messages, and AI assistance in one beautifully designed app. Work smarter, not harder.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        FeatureHighlight(
                            icon: "checkmark.circle.fill",
                            iconColor: .blue,
                            title: "Smart Tasks",
                            description: "AI-powered task management"
                        )

                        FeatureHighlight(
                            icon: "calendar",
                            iconColor: .red,
                            title: "Calendar",
                            description: "Seamless event scheduling"
                        )

                        FeatureHighlight(
                            icon: "sparkles",
                            iconColor: .purple,
                            title: "AI Assistant",
                            description: "Multiple AI agents to help you"
                        )

                        FeatureHighlight(
                            icon: "square.stack.3d.up.fill",
                            iconColor: .green,
                            title: "Widgets",
                            description: "Home and lock screen widgets"
                        )

                        FeatureHighlight(
                            icon: "icloud.fill",
                            iconColor: .cyan,
                            title: "iCloud Sync",
                            description: "Seamless across all devices"
                        )
                    }
                    .padding(.horizontal)

                    Divider()
                        .padding(.horizontal)

                    // Links
                    VStack(spacing: 12) {
                        AboutLinkButton(
                            icon: "globe",
                            title: "Visit Our Website",
                            url: "https://cafe.app"
                        )

                        AboutLinkButton(
                            icon: "envelope.fill",
                            title: "Contact Support",
                            url: "mailto:support@cafe.app"
                        )

                        AboutLinkButton(
                            icon: "hand.raised.fill",
                            title: "Privacy Policy",
                            url: "https://cafe.app/privacy"
                        )

                        AboutLinkButton(
                            icon: "doc.text.fill",
                            title: "Terms of Service",
                            url: "https://cafe.app/terms"
                        )
                    }
                    .padding(.horizontal)

                    // Copyright
                    VStack(spacing: 8) {
                        Text("© 2024 Cafe")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("Made with ❤️ for productivity enthusiasts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }
}

struct FeatureHighlight: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

struct AboutLinkButton: View {
    let icon: String
    let title: String
    let url: String

    var body: some View {
        Button(action: {
            if let url = URL(string: url) {
                UIApplication.shared.open(url)
            }
        }) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 24)

                Text(title)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "arrow.up.forward")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AboutView()
}
