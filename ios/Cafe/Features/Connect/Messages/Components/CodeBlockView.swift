//
//  CodeBlockView.swift
//  Cafe
//
//  Syntax highlighting component for code blocks in AI messages
//

import SwiftUI

struct CodeBlockView: View {
    let code: String
    let language: String?
    
    @Environment(ThemeManager.self) private var themeManager
    @State private var copied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with language label and copy button
            HStack {
                if let language = language, !language.isEmpty {
                    Text(language.uppercased())
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Spacer()
                
                Button(action: {
                    UIPasteboard.general.string = code
                    HapticManager.success()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        copied = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation {
                            copied = false
                        }
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .font(.caption)
                        Text(copied ? "Copied" : "Copy")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(themeManager.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(themeManager.accentColor.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            
            // Code content
            ScrollView(.horizontal, showsIndicators: true) {
                Text(code)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(themeManager.textColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.backgroundColor.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    themeManager.accentColor.opacity(0.2),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        CodeBlockView(
            code: """
            func example() {
                print("Hello, World!")
                let x = 42
                return x * 2
            }
            """,
            language: "swift"
        )
        .padding()
        
        CodeBlockView(
            code: "const greeting = 'Hello';\nconsole.log(greeting);",
            language: "javascript"
        )
        .padding()
    }
    .background(Color.gray.opacity(0.1))
    .environment(ThemeManager.shared)
}

