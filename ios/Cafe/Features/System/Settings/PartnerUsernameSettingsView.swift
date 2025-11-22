//
//  PartnerUsernameSettingsView.swift
//  Cafe
//
//  Configure preferred contact username (DEPRECATED - use Social Circles instead)
//  This view is kept for backward compatibility but Social Circles should be used for user connections
//

import SwiftUI

struct PartnerUsernameSettingsView: View {
    @State private var settingsManager = SettingsManager.shared
    @State private var username: String = ""
    @State private var showingValidationError = false
    @State private var validationError = ""
    
    var body: some View {
        List {
            Section {
                TextField("Username", text: $username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onChange(of: username) { _, newValue in
                        // Remove any whitespace
                        let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmed != newValue {
                            username = trimmed
                        }
                    }
                
                if !username.isEmpty {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text("Current: \(username)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Preferred Contact Username")
            } footer: {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Enter the username of your preferred contact or partner. This is used for partner status tracking, quick messaging, and presence features.")
                        .font(.caption)
                    
                    if settingsManager.preferredContactUsername != "magicalgirl" {
                        Text("Default: magicalgirl")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section {
                Button(action: saveUsername) {
                    HStack {
                        Spacer()
                        Text("Save")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(!isValidUsername(username))
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("How it works")
                            .fontWeight(.medium)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        InfoBullet(text: "This username is used to identify your partner in the dashboard")
                        InfoBullet(text: "Partner presence and status updates will use this username")
                        InfoBullet(text: "Quick messaging and conversation creation uses this setting")
                        InfoBullet(text: "Changes take effect immediately")
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("About")
            }
        }
        .navigationTitle("Partner Username")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            username = settingsManager.preferredContactUsername
        }
        .alert("Invalid Username", isPresented: $showingValidationError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(validationError)
        }
    }
    
    private func saveUsername() {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard isValidUsername(trimmed) else {
            validationError = "Username must be at least 1 character and no more than 50 characters."
            showingValidationError = true
            return
        }
        
        settingsManager.preferredContactUsername = trimmed
        settingsManager.recordSettingChange("preferred_contact_username")
    }
    
    private func isValidUsername(_ username: String) -> Bool {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= 50
    }
}

#Preview {
    NavigationStack {
        PartnerUsernameSettingsView()
    }
}
