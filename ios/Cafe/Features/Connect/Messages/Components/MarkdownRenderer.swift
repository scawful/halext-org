//
//  MarkdownRenderer.swift
//  Cafe
//
//  Rich markdown rendering component for AI messages
//

import SwiftUI

struct MarkdownRenderer: View {
    let text: String
    @Environment(ThemeManager.self) private var themeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(parseMarkdown(text), id: \.id) { element in
                renderElement(element)
            }
        }
    }
    
    @ViewBuilder
    private func renderElement(_ element: MarkdownElement) -> some View {
        switch element {
        case .heading(let level, let text):
            Text(text)
                .font(level == 1 ? .title2 : (level == 2 ? .title3 : .headline))
                .fontWeight(.bold)
                .foregroundColor(themeManager.textColor)
                .padding(.top, level == 1 ? 8 : 4)
        
        case .paragraph(let text):
            Text(parseInlineMarkdown(text))
                .font(.body)
                .foregroundColor(themeManager.textColor)
                .fixedSize(horizontal: false, vertical: true)
        
        case .codeBlock(let code, let language):
            CodeBlockView(code: code, language: language)
        
        case .list(let items, let ordered):
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .top, spacing: 8) {
                        if ordered {
                            Text("\(index + 1).")
                                .font(.body)
                                .foregroundColor(themeManager.accentColor)
                                .fontWeight(.semibold)
                        } else {
                            Circle()
                                .fill(themeManager.accentColor)
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)
                        }
                        Text(parseInlineMarkdown(item))
                            .font(.body)
                            .foregroundColor(themeManager.textColor)
                    }
                }
            }
            .padding(.leading, 8)
        
        case .blockquote(let text):
            HStack(alignment: .top, spacing: 8) {
                Rectangle()
                    .fill(themeManager.accentColor)
                    .frame(width: 3)
                
                Text(parseInlineMarkdown(text))
                    .font(.body)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .italic()
            }
            .padding(.vertical, 4)
            .padding(.leading, 4)
        
        case .horizontalRule:
            Divider()
                .padding(.vertical, 8)
        }
    }
    
    private func parseMarkdown(_ text: String) -> [MarkdownElement] {
        var elements: [MarkdownElement] = []
        let lines = text.components(separatedBy: .newlines)
        var currentParagraph: [String] = []
        var inCodeBlock = false
        var codeBlockContent: [String] = []
        var codeBlockLanguage: String?
        
        for line in lines {
            // Check for code blocks
            if line.hasPrefix("```") {
                if inCodeBlock {
                    // End of code block
                    if !codeBlockContent.isEmpty {
                        elements.append(.codeBlock(
                            code: codeBlockContent.joined(separator: "\n"),
                            language: codeBlockLanguage
                        ))
                    }
                    codeBlockContent = []
                    codeBlockLanguage = nil
                    inCodeBlock = false
                    continue
                } else {
                    // Start of code block
                    if !currentParagraph.isEmpty {
                        elements.append(.paragraph(currentParagraph.joined(separator: " ")))
                        currentParagraph = []
                    }
                    let language = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                    codeBlockLanguage = language.isEmpty ? nil : language
                    inCodeBlock = true
                    continue
                }
            }
            
            if inCodeBlock {
                codeBlockContent.append(line)
                continue
            }
            
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Headings
            if trimmed.hasPrefix("# ") {
                if !currentParagraph.isEmpty {
                    elements.append(.paragraph(currentParagraph.joined(separator: " ")))
                    currentParagraph = []
                }
                elements.append(.heading(level: 1, text: String(trimmed.dropFirst(2))))
                continue
            } else if trimmed.hasPrefix("## ") {
                if !currentParagraph.isEmpty {
                    elements.append(.paragraph(currentParagraph.joined(separator: " ")))
                    currentParagraph = []
                }
                elements.append(.heading(level: 2, text: String(trimmed.dropFirst(3))))
                continue
            } else if trimmed.hasPrefix("### ") {
                if !currentParagraph.isEmpty {
                    elements.append(.paragraph(currentParagraph.joined(separator: " ")))
                    currentParagraph = []
                }
                elements.append(.heading(level: 3, text: String(trimmed.dropFirst(4))))
                continue
            }
            
            // Lists
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                if !currentParagraph.isEmpty {
                    elements.append(.paragraph(currentParagraph.joined(separator: " ")))
                    currentParagraph = []
                }
                let item = String(trimmed.dropFirst(2))
                // Collect list items
                var listItems: [String] = [item]
                // This is simplified - in a full implementation, we'd collect all consecutive list items
                elements.append(.list(items: listItems, ordered: false))
                continue
            } else if let match = trimmed.range(of: #"^\d+\.\s"#, options: .regularExpression) {
                if !currentParagraph.isEmpty {
                    elements.append(.paragraph(currentParagraph.joined(separator: " ")))
                    currentParagraph = []
                }
                let item = String(trimmed[match.upperBound...])
                var listItems: [String] = [item]
                elements.append(.list(items: listItems, ordered: true))
                continue
            }
            
            // Blockquote
            if trimmed.hasPrefix("> ") {
                if !currentParagraph.isEmpty {
                    elements.append(.paragraph(currentParagraph.joined(separator: " ")))
                    currentParagraph = []
                }
                elements.append(.blockquote(String(trimmed.dropFirst(2))))
                continue
            }
            
            // Horizontal rule
            if trimmed == "---" || trimmed == "***" {
                if !currentParagraph.isEmpty {
                    elements.append(.paragraph(currentParagraph.joined(separator: " ")))
                    currentParagraph = []
                }
                elements.append(.horizontalRule)
                continue
            }
            
            // Regular paragraph
            if !trimmed.isEmpty {
                currentParagraph.append(trimmed)
            } else {
                if !currentParagraph.isEmpty {
                    elements.append(.paragraph(currentParagraph.joined(separator: " ")))
                    currentParagraph = []
                }
            }
        }
        
        // Add remaining paragraph
        if !currentParagraph.isEmpty {
            elements.append(.paragraph(currentParagraph.joined(separator: " ")))
        }
        
        // Add remaining code block
        if inCodeBlock && !codeBlockContent.isEmpty {
            elements.append(.codeBlock(
                code: codeBlockContent.joined(separator: "\n"),
                language: codeBlockLanguage
            ))
        }
        
        return elements.isEmpty ? [.paragraph(text)] : elements
    }
    
    private func parseInlineMarkdown(_ text: String) -> AttributedString {
        var attributed = AttributedString(text)
        
        // Use NSRegularExpression for pattern matching
        let patterns: [(pattern: String, apply: (Range<String.Index>, inout AttributedString) -> Void)] = [
            // Bold (**text**)
            (#"\*\*([^*]+)\*\*"#, { range, attr in
                if let attrRange = Range(range, in: attr) {
                    attr[attrRange].font = .body.bold()
                }
            }),
            // Italic (*text*)
            (#"\*([^*]+)\*"#, { range, attr in
                if let attrRange = Range(range, in: attr) {
                    attr[attrRange].font = .body.italic()
                }
            }),
            // Code (`code`)
            (#"`([^`]+)`"#, { range, attr in
                if let attrRange = Range(range, in: attr) {
                    attr[attrRange].font = .system(.body, design: .monospaced)
                    attr[attrRange].foregroundColor = themeManager.accentColor
                    attr[attrRange].backgroundColor = themeManager.accentColor.opacity(0.1)
                }
            })
        ]
        
        for (pattern, apply) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let nsString = text as NSString
                let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
                
                for match in matches.reversed() {
                    if let range = Range(match.range, in: text) {
                        apply(range, &attributed)
                    }
                }
            }
        }
        
        return attributed
    }
}

// MARK: - Markdown Element

enum MarkdownElement: Identifiable {
    case heading(level: Int, text: String)
    case paragraph(String)
    case codeBlock(code: String, language: String?)
    case list(items: [String], ordered: Bool)
    case blockquote(String)
    case horizontalRule
    
    var id: String {
        switch self {
        case .heading(let level, let text):
            return "h\(level)-\(text.prefix(20))"
        case .paragraph(let text):
            return "p-\(text.prefix(20))"
        case .codeBlock(let code, _):
            return "code-\(code.prefix(20))"
        case .list(let items, _):
            return "list-\(items.joined().prefix(20))"
        case .blockquote(let text):
            return "quote-\(text.prefix(20))"
        case .horizontalRule:
            return "hr-\(UUID().uuidString)"
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(alignment: .leading, spacing: 20) {
            MarkdownRenderer(text: """
            # Heading 1
            
            This is a **bold** paragraph with *italic* text and `inline code`.
            
            ## Heading 2
            
            Here's a code block:
            
            ```swift
            func example() {
                print("Hello")
            }
            ```
            
            - List item 1
            - List item 2
            - List item 3
            
            > This is a blockquote
            """)
            .padding()
        }
    }
    .background(Color.gray.opacity(0.1))
    .environment(ThemeManager.shared)
}

